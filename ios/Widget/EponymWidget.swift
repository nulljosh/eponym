import SwiftUI
import WidgetKit

/// Today's word on the Home Screen (iPhone) or desktop (Mac): the same word the app opens on,
/// picked by the same day count from the same shipped list, so the two always agree.
/// The language follows the device's, since the widget cannot read the app's setting without an App Group.
struct WordEntry: TimelineEntry {
    let date: Date
    let word: String
    let label: String
    var definition: String? = nil
}

enum Today {
    static var language: String {
        let code = Locale.current.language.languageCode?.identifier ?? "en"
        return Catalog.wordsOfTheDay[code] == nil ? "en" : code
    }

    static func entry(at date: Date = .now) -> WordEntry {
        let list = Catalog.wordsOfTheDay[language] ?? []
        let word = list.isEmpty ? "word" : list[Int(date.timeIntervalSince1970 / 86400) % list.count]   // same as the app and the web
        let table = Catalog.tables[language == "zh" ? "zh-Hans" : language] ?? Catalog.tables["en"]
        return WordEntry(date: date, word: word, label: table?["ui.wotd"] ?? "Word of the day")
    }

    /// The first English gloss, from Wiktionary's definition endpoint, for the medium widget. Nil on any failure.
    static func definition(_ word: String) async -> String? {
        let path = word.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? word
        var request = URLRequest(url: URL(string: "https://en.wiktionary.org/api/rest_v1/page/definition/\(path)")!)
        request.setValue("eponym/1.0 (trommatic@icloud.com)", forHTTPHeaderField: "User-Agent")
        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let groups = root[language] as? [[String: Any]],
              let defs = groups.first?["definitions"] as? [[String: Any]],
              let html = defs.first?["definition"] as? String else { return nil }
        let text = html
            .replacingOccurrences(of: "(?s)<(ol|ul|style|script)\\b[^>]*>.*?</\\1>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? nil : text
    }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> WordEntry { Today.entry() }

    func getSnapshot(in context: Context, completion: @escaping (WordEntry) -> Void) { completion(Today.entry()) }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WordEntry>) -> Void) {
        Task {
            var entry = Today.entry()
            if context.family != .systemSmall { entry.definition = await Today.definition(entry.word) }
            // The word changes at the next UTC day boundary, the same clock the app counts days on.
            let next = Date(timeIntervalSince1970: (floor(Date.now.timeIntervalSince1970 / 86400) + 1) * 86400)
            completion(Timeline(entries: [entry], policy: .after(next)))
        }
    }
}

struct WordWidgetView: View {
    let entry: WordEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.label.uppercased())
                .font(.custom("Root Sans", size: 11).weight(.semibold))
                .tracking(0.6)
                .opacity(0.8)
            Spacer(minLength: 0)
            Text(verbatim: entry.word)
                .font(.custom("Root Sans", size: family == .systemSmall ? 30 : 34).weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            if family != .systemSmall, let definition = entry.definition {
                Text(verbatim: definition)
                    .font(.custom("Root Sans", size: 14))
                    .lineLimit(2)
                    .opacity(0.88)
            }
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(for: .widget) {
            LinearGradient(colors: [Color(red: 0.302, green: 0.639, blue: 1.0), Color(red: 0.039, green: 0.373, blue: 0.839)],
                           startPoint: .top, endPoint: .bottom)   // the icon's gradient, tokens.css --accent-light to --accent-deep
        }
        .widgetURL(URL(string: "eponym://word/\(entry.word.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? entry.word)"))
    }
}

@main
struct EponymWidget: Widget {
    init() { RootSans.register() }

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "WordOfTheDay", provider: Provider()) { entry in
            WordWidgetView(entry: entry)
        }
        .configurationDisplayName(Today.entry().label)
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
