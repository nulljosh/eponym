import XCTest
@testable import Eponym

// Saved and recent words: newest first, no duplicates, capped.
final class ShelfTests: XCTestCase {
    func testAddingMovesToFrontDropsDuplicateAndCaps() {
        let a = ShelfWord(w: "nice", l: "en"), b = ShelfWord(w: "muscle", l: "en"), c = ShelfWord(w: "nice", l: "fr")
        let list = Shelf.adding(a, to: [b, a, c], max: 2)
        XCTAssertEqual(list, [a, b])
        XCTAssertEqual(Shelf.adding(c, to: list, max: 8), [c, a, b], "the same word in another language is its own entry")
    }
}
