import XCTest

@testable import PortGlance

final class LaunchAtLoginServiceTests: XCTestCase {
    private enum TestError: LocalizedError {
        case failed

        var errorDescription: String? { "Login item update failed" }
    }

    func testPersistsRequestedValueOnSuccess() {
        let result = LaunchAtLoginUpdateResult.applying(
            requestedValue: true,
            currentValue: { false },
            operation: {}
        )

        XCTAssertEqual(result, LaunchAtLoginUpdateResult(persistedValue: true, errorMessage: nil))
    }

    func testRestoresActualValueOnFailure() {
        let result = LaunchAtLoginUpdateResult.applying(
            requestedValue: true,
            currentValue: { false },
            operation: { throw TestError.failed }
        )

        XCTAssertEqual(
            result,
            LaunchAtLoginUpdateResult(
                persistedValue: false,
                errorMessage: "Login item update failed"
            )
        )
    }
}
