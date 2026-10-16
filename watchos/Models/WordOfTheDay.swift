import Foundation

/// One word a day, the same for everyone: chosen by the calendar day, so it needs no network and no state.
enum WordOfTheDay {
    static let words = ("nice salary quarantine sinister companion nostalgia precocious nightmare daisy galaxy candidate orient window " +
        "pedigree tragedy sarcasm sincere silly disaster muse pioneer sabotage trivial mortgage kindergarten tsunami safari pajamas " +
        "shampoo bungalow avocado ketchup boycott marathon mentor odyssey pandemonium tantalize robot vaccine").split(separator: " ").map(String.init)

    static func word(on date: Date = .now, calendar: Calendar = .current) -> String {
        // The local calendar day, so the word changes at the wearer's midnight, not at UTC's.
        let start = calendar.startOfDay(for: date)
        let day = Int(floor((start.timeIntervalSince1970 + Double(calendar.timeZone.secondsFromGMT(for: start))) / 86_400))
        return words[((day % words.count) + words.count) % words.count]
    }
}
