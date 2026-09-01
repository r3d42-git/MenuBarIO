import AppKit
import XCTest

@testable import MenuBarIO

final class HardwareRefreshCoordinatorTests: XCTestCase {
    func testManualRefreshUpdatesBothSourcesImmediately() {
        let notificationCenter = NotificationCenter()
        let refreshed = expectation(description: "Both refresh handlers ran")
        refreshed.expectedFulfillmentCount = 2

        let coordinator = HardwareRefreshCoordinator(
            refreshHandlers: [
                { refreshed.fulfill() },
                { refreshed.fulfill() },
            ],
            notificationCenter: notificationCenter,
            debounceInterval: 0.01
        )

        coordinator.refresh()

        wait(for: [refreshed], timeout: 1)
    }

    func testWakeAndSessionActivationAreCoalescedIntoOneRefresh() {
        let notificationCenter = NotificationCenter()
        let refreshed = expectation(description: "One coalesced refresh ran")
        refreshed.expectedFulfillmentCount = 2

        let coordinator = HardwareRefreshCoordinator(
            refreshHandlers: [
                { refreshed.fulfill() },
                { refreshed.fulfill() },
            ],
            notificationCenter: notificationCenter,
            debounceInterval: 0.02
        )

        notificationCenter.post(name: NSWorkspace.didWakeNotification, object: nil)
        notificationCenter.post(name: NSWorkspace.sessionDidBecomeActiveNotification, object: nil)

        wait(for: [refreshed], timeout: 1)
        _ = coordinator
    }
}
