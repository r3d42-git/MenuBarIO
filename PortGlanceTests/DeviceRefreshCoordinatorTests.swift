import XCTest

@testable import PortGlance

final class DeviceRefreshCoordinatorTests: XCTestCase {
    func testCoalescesBurstsAndPublishesOnlyTheLatestGeneration() throws {
        var coordinator = DeviceRefreshCoordinator()

        let firstGeneration = try XCTUnwrap(coordinator.requestRefresh())
        XCTAssertNil(coordinator.requestRefresh())
        XCTAssertFalse(coordinator.isCurrent(firstGeneration))

        let secondGeneration = firstGeneration + 1
        XCTAssertEqual(coordinator.completeRefresh(firstGeneration), .refresh(secondGeneration))
        XCTAssertTrue(coordinator.isCurrent(secondGeneration))
        XCTAssertEqual(coordinator.completeRefresh(secondGeneration), .publish)
        XCTAssertEqual(coordinator.requestRefresh(), secondGeneration + 1)
    }
}
