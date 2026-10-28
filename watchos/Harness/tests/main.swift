import Foundation

// Runs the watch app's models on the Mac, against the live API. `sh test.sh` builds and runs it.
var failures = 0
@MainActor func check(_ ok: Bool, _ name: String) { print(ok ? "ok   " : "FAIL ", name); if !ok { failures += 1 } }

// word cleaning
check(LookupClient.clean("  Volcano ") == "volcano", "trims and lowercases")
check(LookupClient.clean("") == nil && LookupClient.clean("   ") == nil, "rejects empty")
check(LookupClient.clean(String(repeating: "a", count: 101)) == nil, "rejects over 100 characters")
check(LookupClient.clean("a|b") == nil && LookupClient.clean("{{x}}") == nil && LookupClient.clean("a\nb") == nil, "rejects markup characters")
check(LookupClient.clean("café") == "café", "keeps accents")

// URL building
let client = LookupClient()
check(client.url(for: "volcano")?.absoluteString == "https://eponym.jaybulb.com/api/word/volcano", "plain url")
check(client.url(for: "ice cream")?.absoluteString == "https://eponym.jaybulb.com/api/word/ice%20cream", "space is escaped")
check(client.url(for: "a/b")?.absoluteString == "https://eponym.jaybulb.com/api/word/a%2Fb", "slash cannot change the route")

// language names
check(LanguageNames.name(for: "la") == "Latin" && LanguageNames.name(for: "ine-pro") == "Proto-Indo-European", "etymology codes")
check(LanguageNames.name(for: "it") == "Italian" && LanguageNames.name(for: "fr") == "French", "iso codes from the system")
check(LanguageNames.name(for: "zz-unknown") == "zz-unknown", "unknown code falls back to itself")

// decoding is forgiving
let sparse = #"{"word":"x"}"#.data(using: .utf8)!
let decoded = try? JSONDecoder().decode(Entry.self, from: sparse)
check(decoded == Entry(word: "x"), "missing lists decode as empty")

// word of the day: the phone's list and day count
var cal = Calendar(identifier: .gregorian); cal.timeZone = TimeZone(identifier: "UTC")!
let d1 = cal.date(from: DateComponents(year: 2026, month: 10, day: 16, hour: 1))!
let d1b = cal.date(from: DateComponents(year: 2026, month: 10, day: 16, hour: 23))!
let d2 = cal.date(from: DateComponents(year: 2026, month: 10, day: 17, hour: 1))!
check(WordOfTheDay.word(on: d1) == WordOfTheDay.word(on: d1b), "same word all day")
check(WordOfTheDay.word(on: d1) != WordOfTheDay.word(on: d2), "a new word tomorrow")
let en = Catalog.wordsOfTheDay["en"]!
check(WordOfTheDay.word(on: d1) == en[Int(d1.timeIntervalSince1970 / 86400) % en.count], "matches the phone and widget")

// recents
let suite = UserDefaults(suiteName: "eponym-watch-tests")!
suite.removePersistentDomain(forName: "eponym-watch-tests")
let recents = RecentsStore(defaults: suite)
for w in ["a", "b", "c", "a"] { recents.add(w) }
check(recents.words == ["a", "c", "b"], "newest first, no duplicates")
for i in 0..<20 { recents.add("w\(i)") }
check(recents.words.count == RecentsStore.limit, "capped at \(RecentsStore.limit)")
check(RecentsStore(defaults: suite).words == recents.words, "persists")
suite.removePersistentDomain(forName: "eponym-watch-tests")

// photos: a picture has to relate to the meaning
check(PhotoFinder.related("A volcano is a rupture in the crust of a planetary-mass object", to: "A vent on the surface of a planet erupting lava"), "volcano's article relates to its definition")
check(!PhotoFinder.related("Nice is a city on the French Riviera in southeastern France", to: "Pleasant; agreeable; kind"), "Nice the city is not nice")
check(!PhotoFinder.related(nil, to: "anything"), "no text, no photo")
check(PhotoFinder.sized("https://upload.wikimedia.org/wikipedia/commons/thumb/a/ab/F.jpg/320px-F.jpg")?.absoluteString.hasSuffix("/960px-F.jpg") == true, "thumbnail is resized to a width Wikimedia serves")

// live API
for word in ["volcano", "nice", "salary", "avocado", "quarantine", "husband", "ice cream", "Café"] {
    do {
        let entry = try await client.lookup(word)
        check(!entry.definitions.isEmpty, "live: \(word) has definitions (\(entry.definitions.count) groups, \(entry.etymology.count) ancestors)")
    } catch { check(false, "live: \(word) threw \(error)") }
}
let volcanoEntry = try await client.lookup("volcano")
let volcanoPhoto = await PhotoFinder().url(for: "volcano", definitions: volcanoEntry.glossText)
check(volcanoPhoto != nil, "live: volcano gets a photo")
if let volcanoPhoto, let (bytes, reply) = try? await URLSession.shared.data(from: volcanoPhoto) {
    check((reply as? HTTPURLResponse)?.statusCode == 200 && bytes.count > 10_000, "live: the photo URL actually loads")
} else { check(false, "live: the photo URL actually loads") }
let niceEntry = try await client.lookup("nice")
check(await PhotoFinder().url(for: "nice", definitions: niceEntry.glossText) == nil, "live: nice gets no photo")
do { _ = try await client.lookup("zzzzqqxxvv"); check(false, "live: nonsense is not found") }
catch let e as LookupError { check(e == .notFound, "live: nonsense is not found (\(e))") } catch { check(false, "live: nonsense threw \(error)") }
do { _ = try await client.lookup("a|b"); check(false, "invalid never reaches the network") }
catch let e as LookupError { check(e == .invalidWord, "invalid never reaches the network") } catch { check(false, "invalid threw \(error)") }
var offline = LookupClient(); offline.base = URL(string: "http://127.0.0.1:9")!
do { _ = try await offline.lookup("volcano"); check(false, "offline is reported") }
catch let e as LookupError { check(e == .offline, "offline is reported (\(e))") } catch { check(false, "offline threw \(error)") }

print(failures == 0 ? "ALL PASSED" : "\(failures) FAILED")
exit(failures == 0 ? 0 : 1)
