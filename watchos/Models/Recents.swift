import Foundation
import Observation

/// The last few words looked up, newest first, kept on the watch.
@MainActor @Observable
final class RecentsStore {
    static let limit = 8
    private let defaults: UserDefaults
    private let key = "recents"
    private(set) var words: [String]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.words = defaults.stringArray(forKey: "recents") ?? []
    }

    func add(_ word: String) {
        words = Array(([word] + words.filter { $0 != word }).prefix(Self.limit))
        defaults.set(words, forKey: key)
    }
}
