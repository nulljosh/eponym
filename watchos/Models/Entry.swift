import Foundation

/// One word as `GET /api/word/:word` returns it. Decoding is forgiving: a missing list is an empty list.
struct Entry: Codable, Equatable, Sendable {
    struct Group: Codable, Equatable, Sendable {
        let pos: String
        let definitions: [String]
    }
    struct Ancestor: Codable, Equatable, Sendable {
        let relation: String
        let langCode: String
        let ancestor: String
    }

    let word: String
    let language: String
    let definitions: [Group]
    let etymology: [Ancestor]

    init(word: String, language: String = "English", definitions: [Group] = [], etymology: [Ancestor] = []) {
        self.word = word; self.language = language; self.definitions = definitions; self.etymology = etymology
    }

    enum CodingKeys: String, CodingKey { case word, language, definitions, etymology }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        word = try c.decode(String.self, forKey: .word)
        language = try c.decodeIfPresent(String.self, forKey: .language) ?? "English"
        definitions = try c.decodeIfPresent([Group].self, forKey: .definitions) ?? []
        etymology = try c.decodeIfPresent([Ancestor].self, forKey: .etymology) ?? []
    }
}
