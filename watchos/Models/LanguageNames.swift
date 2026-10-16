import Foundation

/// Wiktionary's language codes, as words. The etymology codes (`ang`, `enm`, `ine-pro`) are not in
/// the system's locale data, so the common ones are spelled out here and the rest fall back to it.
enum LanguageNames {
    static let table: [String: String] = [
        "la": "Latin", "grc": "Ancient Greek", "ang": "Old English", "enm": "Middle English",
        "fro": "Old French", "frm": "Middle French", "non": "Old Norse", "goh": "Old High German",
        "gmh": "Middle High German", "gem-pro": "Proto-Germanic", "gmw-pro": "Proto-West Germanic",
        "ine-pro": "Proto-Indo-European", "itc-pro": "Proto-Italic", "sla-pro": "Proto-Slavic",
        "osp": "Old Spanish", "roa-opt": "Old Portuguese", "LL.": "Late Latin", "VL.": "Vulgar Latin",
        "ML.": "Medieval Latin", "NL.": "New Latin", "ar": "Arabic", "sa": "Sanskrit", "he": "Hebrew",
    ]

    static func name(for code: String) -> String {
        if let known = table[code] { return known }
        if let system = Locale(identifier: "en").localizedString(forLanguageCode: code), system != code { return system }
        return code
    }
}
