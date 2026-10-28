import XCTest
@testable import Wordroot

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
