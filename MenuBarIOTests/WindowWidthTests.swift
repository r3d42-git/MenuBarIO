import XCTest

@testable import MenuBarIO

final class WindowWidthTests: XCTestCase {
    func testSmallerWidthStopsAtLowerBoundary() {
        XCTAssertNil(WindowWidth.normal.smaller)
        XCTAssertEqual(WindowWidth.big.smaller, .normal)
        XCTAssertEqual(WindowWidth.veryBig.smaller, .big)
        XCTAssertEqual(WindowWidth.huge.smaller, .veryBig)
    }

    func testLargerWidthStopsAtUpperBoundary() {
        XCTAssertEqual(WindowWidth.normal.larger, .big)
        XCTAssertEqual(WindowWidth.big.larger, .veryBig)
        XCTAssertEqual(WindowWidth.veryBig.larger, .huge)
        XCTAssertNil(WindowWidth.huge.larger)
    }
}
