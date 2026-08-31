import AppKit
import XCTest

@testable import PortGlance

@MainActor
final class WindowAppearanceBridgeTests: XCTestCase {
    func testAppliesEveryAppearanceToItsHostWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 100, height: 100),
            styleMask: [],
            backing: .buffered,
            defer: false
        )
        let bridgeView = WindowAppearanceView()
        window.contentView = bridgeView

        bridgeView.appAppearance = .light
        XCTAssertEqual(window.appearance?.name, .aqua)

        bridgeView.appAppearance = .dark
        XCTAssertEqual(window.appearance?.name, .darkAqua)

        bridgeView.appAppearance = .system
        XCTAssertNil(window.appearance)
    }
}
