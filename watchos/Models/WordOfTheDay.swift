import Foundation

/// One word a day, the same for everyone and the same as the phone, the widget and the web: the
/// shipped English list in `Catalog`, picked by the UTC day count. No network, no state.
enum WordOfTheDay {
    static let words = Catalog.wordsOfTheDay["en"] ?? ["word"]

    static func word(on date: Date = .now) -> String {
        words[Int(date.timeIntervalSince1970 / 86400) % words.count]
    }
}
