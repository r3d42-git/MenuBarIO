import Foundation
import XCTest

func withIsolatedDefaults(
    _ body: (UserDefaults) throws -> Void,
    file: StaticString = #filePath,
    line: UInt = #line
) rethrows {
    let suiteName = "MenuBarIOTests.\(UUID().uuidString)"
    guard let defaults = UserDefaults(suiteName: suiteName) else {
        XCTFail("Could not create isolated defaults suite", file: file, line: line)
        return
    }
    defer { defaults.removePersistentDomain(forName: suiteName) }
    try body(defaults)
}
