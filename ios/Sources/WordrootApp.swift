import AVFoundation
import Combine
import SwiftUI

@main
struct WordrootApp: App {
    @StateObject private var settings = Settings()

    init() { RootSans.register() }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .font(.root(.body))
                .environmentObject(settings)
                // Driving locale and layout direction from the in-app choice rather than from
                // the system means picking Arabic mirrors the whole interface even on a device
                // set to English — the picker would otherwise change only the words.
                .environment(\.locale, Locale(identifier: settings.uiLanguage))
                .environment(\.layoutDirection, settings.isRightToLeft ? .rightToLeft : .leftToRight)
        }
    }
}

// MARK: - Language settings

/// Interface and word language, persisted across launches.
///
/// Strings resolve through `Catalog` rather than `NSLocalizedString` so that the in-app picker
/// is authoritative: bundle localization can only follow the system language, and a reader who
/// wants a Spanish interface on an English device is exactly the case this app is adding.
final class Settings: ObservableObject {
    private static let uiKey = "wordroot.uiLanguage"
    private static let wordKey = "wordroot.wordLanguage"

    @Published var uiLanguage: String { didSet { UserDefaults.standard.set(uiLanguage, forKey: Self.uiKey) } }
    @Published var wordLanguage: String { didSet { UserDefaults.standard.set(wordLanguage, forKey: Self.wordKey) } }

    init() {
        let defaults = UserDefaults.standard
        let ui = Self.resolve(defaults.string(forKey: Self.uiKey)) ?? Self.systemLanguage()
        uiLanguage = ui
        let stored = defaults.string(forKey: Self.wordKey)
        wordLanguage = Catalog.wordLanguages.first { $0.code == stored }?.code
            ?? Self.defaultWordLanguage(for: ui)
    }

    var isRightToLeft: Bool {
        Catalog.uiLanguages.first { $0.code == uiLanguage }?.isRightToLeft ?? false
    }

    var word: WordLanguage {
        Catalog.wordLanguages.first { $0.code == wordLanguage } ?? Catalog.wordLanguages[0]
    }

    /// Translate `key`, substituting `{name}` placeholders.
    func t(_ key: String, _ vars: [String: String] = [:]) -> String {
        let table = Catalog.tables[uiLanguage] ?? Catalog.tables["en"]
        var s = table?[key] ?? Catalog.tables["en"]?[key] ?? key
        for (name, value) in vars { s = s.replacingOccurrences(of: "{\(name)}", with: value) }
        return s
    }

    /// Localized name for a language code out of a Wiktionary etymology template.
    /// Hand translations first, then the system's own CLDR data, then English, then the raw code.
    func languageName(_ code: String) -> String {
        if Catalog.tables["en"]?["lang.\(code)"] != nil { return t("lang.\(code)") }
        if let localized = Locale(identifier: uiLanguage).localizedString(forLanguageCode: code),
           localized != code {
            return localized
        }
        return Catalog.ancestorLanguages[code] ?? code
    }

    /// Match a stored or system tag to a shipped locale: exact, then progressively shorter,
    /// with every Chinese variant landing on the one script we ship.
    static func resolve(_ tag: String?) -> String? {
        guard var tag = tag?.replacingOccurrences(of: "_", with: "-"), !tag.isEmpty else { return nil }
        if tag.lowercased() == "zh" || tag.lowercased().hasPrefix("zh-") {
            return Catalog.uiLanguages.contains { $0.code == "zh-Hans" } ? "zh-Hans" : nil
        }
        while !tag.isEmpty {
            if let hit = Catalog.uiLanguages.first(where: { $0.code.caseInsensitiveCompare(tag) == .orderedSame }) {
                return hit.code
            }
            guard let cut = tag.lastIndex(of: "-") else { break }
            tag = String(tag[..<cut])
        }
        return nil
    }

    static func systemLanguage() -> String {
        Locale.preferredLanguages.lazy.compactMap { resolve($0) }.first ?? "en"
    }

    /// Look words up in the interface language when we have a dictionary for it.
    static func defaultWordLanguage(for ui: String) -> String {
        let base = ui.split(separator: "-").first.map(String.init) ?? ui  // zh-Hans -> zh
        return Catalog.wordLanguages.contains { $0.code == base } ? base : "en"
    }
}

// MARK: - Model

struct Def: Identifiable {
    let id: String
    let n: Int
    let text: String
}

struct DefGroup: Identifiable {
    let id = UUID()
    let pos: String
    let defs: [String]

    // ponytail: rows need ids unique across sections, not just within one —
    // on macOS a bare offset id makes every section render the first one's rows.
    var items: [Def] {
        defs.enumerated().map { Def(id: "\(id)-\($0.offset)", n: $0.offset + 1, text: $0.element) }
    }
}

struct ChainLink: Identifiable {
    let id = UUID()
    let rel: String
    let langCode: String
    let ancestor: String
}

/// Definitions and the Wiktionary edition that wrote them — which is what decides the
/// language the prose is in.
struct Definitions {
    let edition: String
    let groups: [DefGroup]
}

struct Entry {
    let word: String
    let definitions: Definitions?
    let chain: [ChainLink]
    let photoURL: URL?
    var ipa: String? = nil
}

// MARK: - Wiktionary

enum Wiktionary {
    /// Etymology always comes from the English Wiktionary, whatever the interface language is:
    /// it carries entries for thousands of languages under one consistent set of etymology
    /// templates, whereas each other edition uses its own incompatible markup. The word
    /// language selects which `==Language==` section of the page to read.
    static let host = "https://en.wiktionary.org"

    /// The edition whose definitions would be in the reader's own language. As of 2026-08-27
    /// only en.wiktionary serves the REST definition endpoint — fr/es/de all answer 501 — so
    /// this names the edition we link out to, not one we fetch.
    /// ponytail: definitions always come from English; ask the reader's own edition first again
    /// if Wikimedia ever enables the endpoint beyond en.
    static func readerEdition(for uiLanguage: String) -> String {
        uiLanguage.split(separator: "-").first.map(String.init) ?? uiLanguage
    }

    // Only the three ancestry relations — pipeline/parse.py also collects `cog` and `root`,
    // which are deliberately left out here: cognates are siblings, not links in a chain.
    static let rels = ["inh": "rel.inherited", "der": "rel.derived", "bor": "rel.borrowed"]

    // Wikimedia's UA policy allows throttling or 403ing generic agents.
    static func request(_ url: URL) -> URLRequest {
        var r = URLRequest(url: url)
        r.setValue("wordroot/1.0 (trommatic@icloud.com)", forHTTPHeaderField: "User-Agent")
        return r
    }

    static func stripTags(_ s: String) -> String {
        let noStyleScript = s.replacingOccurrences(
            of: "(?s)<(style|script|ol|ul)\\b[^>]*>.*?</\\1>", with: "", options: [.regularExpression, .caseInsensitive])  // nested sub-senses also come as their own senses
        return noStyleScript.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }

    /// Definitions are prose, so the edition decides what language the reader gets — but only
    /// the English edition serves this endpoint, so English is what everyone gets. The response
    /// is keyed by language section, which is what makes the word-language picker mean anything.
    static func definitions(_ word: String, language: String) async -> Definitions? {
        let edition = "en"
        let encoded = word.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? word
        guard let url = URL(string: "https://\(edition).wiktionary.org/api/rest_v1/page/definition/\(encoded)")
        else { return nil }
        let data: Data
        let resp: URLResponse
        do {
            (data, resp) = try await URLSession.shared.data(for: request(url))
        } catch {
            return nil
        }
        let status = (resp as? HTTPURLResponse)?.statusCode ?? 0
        guard status == 200 else { return nil }
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              // Keyed by the language of each section on the page, so "chat" carries both an
              // `en` and an `fr` entry. Taking only the requested one is what makes the picker
              // mean anything; a page with no section in that language is a miss, not English.
              let entries = root[language] as? [[String: Any]] else { return nil }
        let groups: [DefGroup] = entries.compactMap { e in
            guard let pos = e["partOfSpeech"] as? String,
                  let defs = e["definitions"] as? [[String: Any]] else { return nil }
            let texts = defs.compactMap { $0["definition"] as? String }
                .map(stripTags)
                .filter { !$0.isEmpty }
                .prefix(4)
            return texts.isEmpty ? nil : DefGroup(pos: pos, defs: Array(texts))
        }
        return groups.isEmpty ? nil : Definitions(edition: edition, groups: groups)
    }

    static func etymology(_ word: String, section: String) async throws -> [ChainLink] {
        try chain(fromWikitext: try await wikitext(word), section: section)
    }

    /// The page's raw wikitext, which carries both the etymology and the pronunciation.
    static func wikitext(_ word: String) async throws -> String {
        var comps = URLComponents(string: "\(host)/w/api.php")!
        comps.queryItems = [
            .init(name: "action", value: "parse"), .init(name: "page", value: word),
            .init(name: "prop", value: "wikitext"), .init(name: "format", value: "json"),
        ]
        let (data, _) = try await URLSession.shared.data(for: request(comps.url!))
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let parse = root["parse"] as? [String: Any],
              let wikitext = (parse["wikitext"] as? [String: Any])?["*"] as? String else { return "" }
        return wikitext
    }

    /// Up to six completions for a prefix: single words that extend it, lowercase, no repeats. Same rule as the web.
    static func suggest(from titles: [String], query: String) -> [String] {
        var seen = Set<String>()
        return Array(titles.map { $0.lowercased() }
            .filter { $0.hasPrefix(query) && $0 != query && !$0.contains(" ") && seen.insert($0).inserted }
            .prefix(6))
    }

    static func suggestions(_ query: String) async -> [String] {
        var comps = URLComponents(string: "\(host)/w/api.php")!
        comps.queryItems = [
            .init(name: "action", value: "opensearch"), .init(name: "search", value: query),
            .init(name: "limit", value: "20"), .init(name: "namespace", value: "0"), .init(name: "format", value: "json"),
        ]
        guard let (data, _) = try? await URLSession.shared.data(for: request(comps.url!)),
              let root = try? JSONSerialization.jsonObject(with: data) as? [Any],
              root.count > 1, let titles = root[1] as? [String] else { return [] }
        return suggest(from: titles, query: query)
    }

    /// The first IPA transcription in the language section, like "/wɜːd/", or nil. Same rule as the web.
    static func ipa(fromWikitext wikitext: String, section name: String) -> String? {
        guard let body = languageSection(wikitext, named: name),
              let open = body.range(of: "{{IPA|"),
              let close = body[open.upperBound...].range(of: "}}") else { return nil }
        let params = body[open.upperBound..<close.lowerBound].split(separator: "|").dropFirst()   // first is the language code
        return params.first { !$0.contains("=") && !$0.isEmpty }.map(String.init)
    }

    /// Body of the `==Name==` language section, or nil. Stops at the next level-2 heading.
    static func languageSection(_ wikitext: String, named name: String) -> Substring? {
        let pattern = "(?m)^==\\s*\(NSRegularExpression.escapedPattern(for: name))\\s*==\\s*$"
        guard let heading = wikitext.range(of: pattern, options: .regularExpression) else { return nil }
        let after = wikitext[heading.upperBound...]
        guard let next = after.range(of: "(?m)^==[^=]", options: .regularExpression) else { return after }
        return after[..<next.lowerBound]
    }

    /// Pure: wikitext in, ancestry chain out. Split from `etymology` so it is testable offline.
    static func chain(fromWikitext wikitext: String, section name: String) throws -> [ChainLink] {
        // Without this scoping the first ===Etymology=== on the page wins, which for a word
        // spelled the same in several languages ("chat") is somebody else's history.
        guard let section = languageSection(wikitext, named: name) else { return [] }
        guard let secRange = section.range(of: "===?Etymology[^=]*===?\\n", options: .regularExpression) else { return [] }
        let after = section[secRange.upperBound...]
        let body = after.range(of: "\\n===?[^=]", options: .regularExpression)
            .map { String(after[..<$0.lowerBound]) } ?? String(after)
        let re = try NSRegularExpression(pattern: "\\{\\{(inh\\+?|der\\+?|bor\\+?)\\|[^|]*\\|([^|}]+)\\|([^|}]*)")
        let ns = body as NSString
        var chain: [ChainLink] = []
        for m in re.matches(in: body, range: NSRange(location: 0, length: ns.length)) {
            let relKey = ns.substring(with: m.range(at: 1)).replacingOccurrences(of: "+", with: "")
            let langKey = ns.substring(with: m.range(at: 2))
            let ancestor = ns.substring(with: m.range(at: 3))
            guard let rel = rels[relKey], !ancestor.isEmpty else { continue }
            chain.append(ChainLink(rel: rel, langCode: langKey, ancestor: ancestor))
            if chain.count >= 10 { break }
        }
        return chain
    }

    /// A photo for the word itself, from Wikipedia's own summary endpoint — the one page most
    /// likely to carry a real photo of the thing the word names, rather than a stock-photo search.
    /// Best-effort: any failure (no article, no image, offline) just means no photo.
    static func photo(_ word: String) async -> URL? {
        let encoded = word.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? word
        guard let url = URL(string: "https://en.wikipedia.org/api/rest_v1/page/summary/\(encoded)") else { return nil }
        guard let (data, resp) = try? await URLSession.shared.data(for: request(url)),
              (resp as? HTTPURLResponse)?.statusCode == 200,
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let source = (root["originalimage"] as? [String: Any])?["source"] as? String
                ?? (root["thumbnail"] as? [String: Any])?["source"] as? String
        else { return nil }
        return URL(string: source)
    }

    /// Throws only on transport failure, so the UI can tell "offline" from "no such word".
    /// Only the etymology request can throw: a failed definition lookup leaves the etymology.
    static func entry(_ word: String, language: WordLanguage) async throws -> Entry? {
        async let d = definitions(word, language: language.code)
        async let w = wikitext(word)
        async let p = photo(word)
        let (found, text, photoURL) = try await (d, w, p)
        let chain = try chain(fromWikitext: text, section: language.section)
        if found == nil && chain.isEmpty { return nil }
        return Entry(word: word, definitions: found, chain: chain, photoURL: photoURL,
                     ipa: ipa(fromWikitext: text, section: language.section))
    }
}

// MARK: - UI

/// Stable per-word hue (same formula as web's `hueForWord`), so the same word always paints
/// the same background across platforms.
private func hueForWord(_ word: String) -> Double {
    var h: UInt32 = 0
    for scalar in word.unicodeScalars { h = h &* 31 &+ scalar.value }
    return Double(h % 360)
}

/// One flat per-word tint behind the list. ponytail: no blobs, no gradients, no drift;
/// the photo carries the mood when there is one, and a plain wash is quieter when there is not.
private struct WordBackground: View {
    var hue: Double

    var body: some View {
        Color(hue: hue / 360, saturation: 0.45, brightness: 0.55).ignoresSafeArea()
    }
}

/// The word's own photo, cropped to fill and dimmed so list text stays legible over it.
/// Falls back to the hue-blob wash when the word has no Wikipedia photo (proper nouns aside,
/// most dictionary words — verbs, function words — never will).
private struct PhotoBackground: View {
    var url: URL?
    var hue: Double

    var body: some View {
        ZStack {
            if let url {
                AsyncImage(url: url) { imagePhase in
                    if case .success(let image) = imagePhase {
                        image.resizable().scaledToFill()
                    } else {
                        WordBackground(hue: hue)
                    }
                }
            } else {
                WordBackground(hue: hue)
            }
            Color.black.opacity(0.5)
        }
        .ignoresSafeArea()
    }
}

/// Says a word aloud with the device's own voice, in the word's language when one is installed.
@MainActor
enum Voice {
    private static let synth = AVSpeechSynthesizer()
    static func speak(_ word: String, language: String) {
        synth.stopSpeaking(at: .immediate)
        let u = AVSpeechUtterance(string: word)
        u.voice = AVSpeechSynthesisVoice(language: language)
        synth.speak(u)
    }
}

/// A saved or recent word: the word and its word language, the same shape the web app keeps.
struct ShelfWord: Codable, Hashable {
    let w: String
    let l: String
}

/// Saved and recent words in UserDefaults, newest first. ponytail: no sync; add iCloud when someone asks.
enum Shelf {
    static let savedKey = "wordroot.saved", recentKey = "wordroot.recent"
    static func load(_ key: String) -> [ShelfWord] {
        guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([ShelfWord].self, from: data)) ?? []
    }
    static func store(_ list: [ShelfWord], _ key: String) {
        UserDefaults.standard.set(try? JSONEncoder().encode(list), forKey: key)
    }
    /// `word` first, its older copy dropped, at most `max` kept.
    static func adding(_ word: ShelfWord, to list: [ShelfWord], max: Int) -> [ShelfWord] {
        Array(([word] + list.filter { $0 != word }).prefix(max))
    }
}

struct ContentView: View {
    @EnvironmentObject private var settings: Settings
    @State private var query = ""
    @State private var entry: Entry?
    @State private var loading = false
    @State private var failed = false
    @State private var showingSettings = false
    @State private var searchTask: Task<Void, Never>?
    @State private var completions: [String] = []
    @State private var completionTask: Task<Void, Never>?
    @State private var saved = Shelf.load(Shelf.savedKey)
    @State private var recent = Shelf.load(Shelf.recentKey)

    private func isSaved(_ word: String) -> Bool { saved.contains(ShelfWord(w: word, l: settings.wordLanguage)) }

    private func toggleSaved(_ word: String) {
        let item = ShelfWord(w: word, l: settings.wordLanguage)
        saved = isSaved(word) ? saved.filter { $0 != item } : Shelf.adding(item, to: saved, max: 200)
        Shelf.store(saved, Shelf.savedKey)
    }

    private func remember(_ word: String) {
        guard !word.isEmpty else { return }
        recent = Shelf.adding(ShelfWord(w: word, l: settings.wordLanguage), to: recent, max: 8)
        Shelf.store(recent, Shelf.recentKey)
    }

    /// Saved or recent words for the current word language, as one inset grouped section.
    @ViewBuilder private func shelfSection(_ key: String, _ list: [ShelfWord]) -> some View {
        let words = list.filter { $0.l == settings.wordLanguage }
        if !words.isEmpty {
            Section {
                ForEach(words, id: \.self) { item in
                    Button {
                        query = item.w
                        remember(item.w)
                    } label: {
                        Text(verbatim: item.w)
                    }
                    .tint(.primary)
                }
            } header: {
                Text(settings.t(key)).font(.root(.subheadline, .semibold)).foregroundStyle(.white)
            }
        }
    }

    /// The line above an entry, with the save toggle at its end.
    /// The word itself, large, is the title; there is no app name on screen.
    private func entryHeader(_ title: String, _ word: String, ipa: String?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.root(.subheadline, .semibold)).textCase(nil)
            HStack(alignment: .firstTextBaseline, spacing: 16) {
                Text(verbatim: word).font(.root(.largeTitle, .bold)).textCase(nil)
                Spacer()
                Button {
                    Voice.speak(word, language: settings.wordLanguage)
                } label: {
                    Image(systemName: "speaker.wave.2").font(.title2)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(settings.t("ui.speak"))
                Button {
                    toggleSaved(word)
                } label: {
                    Image(systemName: isSaved(word) ? "bookmark.fill" : "bookmark").font(.title2)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(settings.t(isSaved(word) ? "ui.unsave" : "ui.save"))
            }
            if let ipa { Text(verbatim: ipa).font(.root(.body)).opacity(0.8).textCase(nil) }
        }
        .foregroundStyle(.white)
    }

    /// The Wiktionary edition whose definitions would be in the reader's own language.
    private var readerEdition: String {
        Wiktionary.readerEdition(for: settings.uiLanguage)
    }

    private func readerWiktionaryURL(for word: String) -> URL? {
        let encoded = word.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? word
        return URL(string: "https://\(readerEdition).wiktionary.org/wiki/\(encoded)")
    }

    /// Today's word in the current word language, or nil if we ship no list for it —
    /// better than offering an English word that has no entry in the selected language.
    private var wordOfTheDay: String? {
        guard let list = Catalog.wordsOfTheDay[settings.wordLanguage], !list.isEmpty else { return nil }
        return list[Int(Date().timeIntervalSince1970 / 86400) % list.count]
    }

#if os(iOS)
    private static let controlsPlacement = ToolbarItemPlacement.bottomBar
#else
    private static let controlsPlacement = ToolbarItemPlacement.automatic
#endif

    var body: some View {
        NavigationStack {
            List {
                if query.isEmpty {
                    shelfSection("ui.saved", saved)
                    shelfSection("ui.recent", recent)
                }
                if loading {
                    HStack { Spacer(); ProgressView(); Spacer() }
                } else if let entry {
                    if query.isEmpty {
                        Section {} header: { entryHeader(settings.t("ui.wotdWord", ["word": entry.word]), entry.word, ipa: entry.ipa) }
                    } else {
                        Section {} header: { entryHeader(settings.t("ui.resultsFor", ["word": entry.word]), entry.word, ipa: entry.ipa) }
                    }
                    entrySections(entry)
                } else if failed {
                    // Reachable on launch with an empty query, so it cannot be gated on `query`.
                    Text(settings.t("ui.offline"))
                } else if !query.isEmpty {
                    Text(settings.t("ui.nothingFound"))
                }
            }
            .scrollContentBackground(.hidden)
            .background(PhotoBackground(url: entry?.photoURL, hue: hueForWord(entry?.word ?? wordOfTheDay ?? "wordroot")))
            // Everything drawn straight on the darkened background is white; the cards keep
            // the system look, so their text stays as it is.
#if os(iOS)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.hidden, for: .navigationBar)
#endif
#if os(iOS)
            // Pinned at the top like the web app; on iOS 26 the default placement folds it away.
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: Text(settings.t("ui.searchPlaceholder")))
            .navigationBarTitleDisplayMode(.inline)
#else
            .searchable(text: $query, prompt: Text(settings.t("ui.searchPlaceholder")))
#endif
            .navigationTitle("")   // no app name on screen: people know which app they opened
            // Controls live in the bottom bar on the phone, never in the top corner (Joshua 2026-10-28).
            .onSubmit(of: .search) { remember(query.trimmingCharacters(in: .whitespaces).lowercased()) }
            .toolbar {
                ToolbarItem(placement: Self.controlsPlacement) {
                    Button {
                        query = ""
                    } label: {
                        Label(settings.t("ui.saved"), systemImage: "bookmark")
                    }
                }
                ToolbarItem(placement: Self.controlsPlacement) {
                    Button {
                        showingSettings = true
                    } label: {
                        Label(settings.t("ui.settings"), systemImage: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                LanguageSettingsView()
                    .environmentObject(settings)
                    .environment(\.locale, Locale(identifier: settings.uiLanguage))
                    .environment(\.layoutDirection, settings.isRightToLeft ? .rightToLeft : .leftToRight)
            }
            .onChange(of: query) { _, q in
                let word = q.trimmingCharacters(in: .whitespaces).lowercased()
                search(word)
                completionTask?.cancel()
                guard word.count >= 2 else { completions = []; return }
                completionTask = Task {
                    try? await Task.sleep(for: .milliseconds(150))
                    guard !Task.isCancelled else { return }
                    let found = await Wiktionary.suggestions(word)
                    if !Task.isCancelled { completions = found }
                }
            }
            .searchSuggestions {
                ForEach(completions, id: \.self) { word in
                    Text(verbatim: word).searchCompletion(word)
                }
            }
            // Switching either language invalidates what is on screen: a word only exists in
            // one language, and the chain's labels are rendered in the interface language.
            .onChange(of: settings.wordLanguage) { _, _ in
                query = ""
                entry = nil
                if let w = wordOfTheDay { search(w) }
            }
            // The interface language also picks the edition the definitions come from, so it
            // has to re-run the lookup rather than only re-render the labels.
            .onChange(of: settings.uiLanguage) { _, _ in
                search(query.isEmpty ? (wordOfTheDay ?? "") : query)
            }
            .task {
                if let w = wordOfTheDay { search(w) }
            }
        }
    }

    @ViewBuilder
    private func entrySections(_ entry: Entry) -> some View {
        if let definitions = entry.definitions {
            ForEach(definitions.groups) { group in
                Section {
                    ForEach(group.items) { def in
                        Text("\(def.n). \(def.text)")
                    }
                } header: {
                    Text(group.pos).font(.root(.subheadline, .semibold)).foregroundStyle(.white)
                }
            }
            // Say so when the reader asked for one language and got English prose, rather than
            // letting them wonder — and offer the one route to definitions in their own language.
            if definitions.edition != readerEdition, let url = readerWiktionaryURL(for: entry.word) {
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(settings.t("ui.definitionsInEnglish"))
                        Link(settings.t("ui.openOnWiktionary", ["wiktionary": settings.t("ui.wiktionary")]),
                             destination: url)
                    }
                    .font(.root(.caption))
                    .foregroundStyle(.secondary)
                }
            }
        }
        if !entry.chain.isEmpty {
            Section {
                ForEach(entry.chain) { link in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(link.ancestor).fontWeight(.semibold)
                        // Ancestor first, relation and language beneath: a single run-on line
                        // cannot be reordered per language, and word order differs across the
                        // twelve locales.
                        Text(verbatim: "\(settings.t(link.rel)) · \(settings.languageName(link.langCode))")
                            .font(.root(.caption))
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text(settings.t("ui.origin")).font(.root(.subheadline, .semibold)).foregroundStyle(.white)
            }
        }
        // CC BY-SA 4.0 requires attribution; App Review flags uncredited third-party content.
        Section {
            Text(settings.t("ui.attribution"))
                .font(.root(.caption))
                .foregroundStyle(.secondary)
        }
    }

    private func search(_ word: String) {
        searchTask?.cancel()
        guard !word.isEmpty else { return }
        let language = settings.word
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            loading = true
            // Not `try?`: it flattens Entry?? to Entry?, which would merge a transport
            // failure back into the "no such word" case this whole branch exists to separate.
            do {
                let result = try await Wiktionary.entry(word, language: language)
                guard !Task.isCancelled else { return }
                entry = result
                failed = false
            } catch {
                guard !Task.isCancelled else { return }
                entry = nil
                failed = true
            }
            loading = false
        }
    }
}

struct LanguageSettingsView: View {
    @EnvironmentObject private var settings: Settings
    @Environment(\.dismiss) private var dismiss

    /// Word languages sorted by their name in the reader's own language.
    private var wordLanguages: [WordLanguage] {
        Catalog.wordLanguages.sorted {
            settings.languageName($0.code)
                .localizedCaseInsensitiveCompare(settings.languageName($1.code)) == .orderedAscending
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(settings.t("ui.language")) {
                    Picker(settings.t("ui.wordLanguage"), selection: $settings.wordLanguage) {
                        ForEach(wordLanguages) { language in
                            Text(settings.languageName(language.code)).tag(language.code)
                        }
                    }
                    Picker(settings.t("ui.interfaceLanguage"), selection: $settings.uiLanguage) {
                        ForEach(Catalog.uiLanguages) { language in
                            // The endonym, so a reader can find their language without already
                            // being able to read the current one.
                            Text(language.endonym).tag(language.code)
                        }
                    }
                }
                // The brand lives here, not on the main screen (Joshua 2026-10-28).
                Section {
                    HStack(spacing: 12) {
                        Image("AboutIcon").resizable().frame(width: 56, height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 12.3, style: .continuous))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(verbatim: "Wordroot").font(.root(.headline, .semibold))
                            Text(settings.t("ui.tagline")).font(.root(.subheadline)).foregroundStyle(.secondary)
                            Text(verbatim: "\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""))")
                                .font(.root(.caption)).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                    Link(settings.t("ui.about"), destination: URL(string: "https://wordroot.jaybulb.com/about/")!)
                    Link(settings.t("ui.privacy"), destination: URL(string: "https://wordroot.jaybulb.com/privacy.html")!)
                    Link(destination: URL(string: "https://github.com/nulljosh/wordroot")!) { Text(verbatim: "GitHub") }
                } header: {
                    Text(settings.t("ui.about"))
                } footer: {
                    Text(settings.t("ui.attribution")).font(.root(.caption))
                }
            }
            .navigationTitle(settings.t("ui.settings"))
            .toolbar {
                Button(settings.t("ui.done")) { dismiss() }
            }
        }
    }
}
