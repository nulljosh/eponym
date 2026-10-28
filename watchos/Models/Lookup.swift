import Foundation

enum LookupError: Error, Equatable, Sendable {
    case invalidWord, notFound, offline, server
}

/// Looks a word up through the Eponym API, which reads Wiktionary. The watch has no keyboard worth
/// the name, so a lookup is one word, dictated or scribbled, and one request.
struct LookupClient: Sendable {
    var base = URL(string: "https://wordroot.jaybulb.com")!
    var session: URLSession = .shared

    /// The word as the API wants it: trimmed, lowercase, at most 100 characters, and none of the
    /// characters that could smuggle markup into a Wiktionary query. nil means "not a word".
    static func clean(_ raw: String) -> String? {
        let word = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let banned = Set("|{}[]<>\\\n\r")
        guard !word.isEmpty, word.count <= 100, !word.contains(where: banned.contains) else { return nil }
        return word
    }

    func url(for word: String) -> URL? {
        var allowed = CharacterSet.urlPathAllowed
        allowed.remove("/")
        guard let encoded = word.addingPercentEncoding(withAllowedCharacters: allowed) else { return nil }
        var parts = URLComponents(url: base, resolvingAgainstBaseURL: false)
        parts?.percentEncodedPath = "/api/word/" + encoded
        return parts?.url
    }

    func lookup(_ raw: String) async throws -> Entry {
        guard let word = Self.clean(raw), let url = url(for: word) else { throw LookupError.invalidWord }
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let data: Data, response: URLResponse
        do { (data, response) = try await session.data(for: request) } catch is URLError { throw LookupError.offline }
        guard let http = response as? HTTPURLResponse else { throw LookupError.server }
        switch http.statusCode {
        case 200: break
        case 400: throw LookupError.invalidWord
        case 404: throw LookupError.notFound
        default: throw LookupError.server
        }
        guard let entry = try? JSONDecoder().decode(Entry.self, from: data) else { throw LookupError.server }
        if entry.definitions.isEmpty && entry.etymology.isEmpty { throw LookupError.notFound }
        return entry
    }
}
