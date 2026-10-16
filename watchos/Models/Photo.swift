import Foundation

/// A photo for the word's page, if there is an honest one: the Wikipedia article's lead image, and only
/// when the article talks about what the word means (Nice the city is not "nice"). Otherwise nil, and
/// the watch keeps its plain backdrop.
struct PhotoFinder: Sendable {
    var session: URLSession = .shared

    private struct Summary: Decodable {
        struct Thumbnail: Decodable { let source: String }
        let type: String?
        let extract: String?
        let thumbnail: Thumbnail?
    }

    private static let stop: Set<String> = ["that", "with", "from", "whic", "havi", "used", "this", "thei", "ther", "othe", "some",
        "whos", "wher", "when", "such", "also", "into", "than", "then", "them", "have", "been", "were", "will", "woul", "coul",
        "abou", "typi", "usual", "espec", "makes", "being", "kind", "type", "form", "thing"]

    /// The first five letters of each word of four or more, minus filler: enough to see "planet" in "planetary".
    static func stems(_ text: String) -> Set<String> {
        let letters = Set("abcdefghijklmnopqrstuvwxyz")
        let words = text.lowercased().split(whereSeparator: { !letters.contains($0) })
        return Set(words.filter { $0.count >= 4 }.map { String($0.prefix(5)) }.filter { !stop.contains($0) })
    }

    static func related(_ text: String?, to definitions: String) -> Bool {
        guard let text else { return false }
        return !stems(text).isDisjoint(with: stems(definitions))
    }

    /// Wikimedia serves only its standard widths (330, 500, 960, 1280...) and answers 400 to the rest, so
    /// 640 never loads. The summary hands back 330 px, soft on a watch.
    static func sized(_ source: String, width: Int = 960) -> URL? {
        URL(string: source.replacingOccurrences(of: #"/\d+px-"#, with: "/\(width)px-", options: .regularExpression))
    }

    func url(for word: String, definitions: String) async -> URL? {
        guard let clean = LookupClient.clean(word),
              let encoded = clean.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed.subtracting(CharacterSet(charactersIn: "/"))),
              let endpoint = URL(string: "https://en.wikipedia.org/api/rest_v1/page/summary/" + encoded) else { return nil }
        var request = URLRequest(url: endpoint)
        request.timeoutInterval = 10
        guard let (data, response) = try? await session.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let summary = try? JSONDecoder().decode(Summary.self, from: data),
              summary.type == "standard", let thumbnail = summary.thumbnail,
              Self.related(summary.extract, to: definitions) else { return nil }
        return Self.sized(thumbnail.source)
    }
}

extension Entry {
    /// The first few glosses, for judging whether a picture fits.
    var glossText: String { definitions.prefix(2).flatMap { $0.definitions.prefix(3) }.joined(separator: " ") }
}
