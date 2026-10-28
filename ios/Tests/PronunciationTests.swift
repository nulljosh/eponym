import XCTest
@testable import Eponym

// The IPA shown under the word: first transcription in the right language section, named params skipped.
final class PronunciationTests: XCTestCase {
    func testFirstTranscriptionInTheLanguageSection() {
        let wikitext = """
        ==English==
        ===Pronunciation===
        * {{a|UK}} {{IPA|en|/wɜːd/|[wɜːd]|a=RP}}
        ==French==
        ===Pronunciation===
        * {{IPA|fr|/mo/}}
        """
        XCTAssertEqual(Wiktionary.ipa(fromWikitext: wikitext, section: "English"), "/wɜːd/")
        XCTAssertEqual(Wiktionary.ipa(fromWikitext: wikitext, section: "French"), "/mo/")
        XCTAssertEqual(Wiktionary.ipa(fromWikitext: "==English==\n{{IPA|en|a=US|/wɝd/}}", section: "English"), "/wɝd/")
        XCTAssertNil(Wiktionary.ipa(fromWikitext: wikitext, section: "German"))
    }
}

// Suggestions while typing: same filter as the web app.
final class SuggestionTests: XCTestCase {
    func testSingleWordsThatExtendThePrefix() {
        let titles = ["etym", "etymology", "Etymology", "etymon", "etymology of words", "stem", "etymologia", "etymologie", "etymological", "etymologist"]
        XCTAssertEqual(Wiktionary.suggest(from: titles, query: "etym"),
                       ["etymology", "etymon", "etymologia", "etymologie", "etymological", "etymologist"])
    }
}

// The root tree's links: same URLs as the web app.
final class AncestorURLTests: XCTestCase {
    func testReconstructionAndSectionLinks() {
        XCTAssertEqual(Wiktionary.ancestorURL("*wódr̥", langCode: "ine-pro").absoluteString,
                       "https://en.wiktionary.org/wiki/Reconstruction:Proto-Indo-European/w%C3%B3dr%CC%A5")
        XCTAssertEqual(Wiktionary.ancestorURL("wæter", langCode: "ang").absoluteString,
                       "https://en.wiktionary.org/wiki/w%C3%A6ter#Old_English")
    }
}

// Same-root words: the named root first, else the oldest ancestor; same rule as the web.
final class RelativesTests: XCTestCase {
    func testRootQueryAndFilter() {
        XCTAssertEqual(Wiktionary.rootQuery("{{root|en|ine-pro|*wed-}} From {{inh|en|enm|water}}", chain: [], langCode: "en"), "root|en|ine-pro|*wed-")
        XCTAssertEqual(Wiktionary.rootQuery("From {{der|en|la|mūsculus}}", chain: [ChainLink(rel: "rel.derived", langCode: "la", ancestor: "mūsculus")], langCode: "en"), "en|la|mūsculus")
        XCTAssertNil(Wiktionary.rootQuery("", chain: [], langCode: "en"))
        XCTAssertEqual(Wiktionary.relatives(of: "water", titles: ["water", "wet", "Otter", "otter", "rectus abdominis muscle", "hydra"]), ["wet", "otter", "hydra"])
    }
}
