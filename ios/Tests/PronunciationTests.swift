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
