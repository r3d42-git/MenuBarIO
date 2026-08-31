import XCTest

@testable import PortGlance

final class AppleSmartBatteryDiscoveryTests: XCTestCase {
    func testInstantaneousCurrentHasPriorityOverAverageCurrent() {
        let measurement = AppleSmartBatteryDiscovery.chargingMeasurement(
            properties: [
                "InstantAmperage": 997,
                "Amperage": 1_028,
                "Voltage": 12_618,
            ]
        )

        XCTAssertEqual(
            measurement,
            BatteryElectricalMeasurement(currentMilliamps: 997, voltageMillivolts: 12_618)
        )
    }

    func testAverageCurrentIsUsedOnlyWhenInstantaneousCurrentIsMissing() {
        let measurement = AppleSmartBatteryDiscovery.chargingMeasurement(
            properties: [
                "Amperage": 1_028,
                "Voltage": 12_618,
            ]
        )

        XCTAssertEqual(
            measurement,
            BatteryElectricalMeasurement(currentMilliamps: 1_028, voltageMillivolts: 12_618)
        )
    }

    func testPresentNonpositiveInstantaneousCurrentDoesNotUseAverageCurrent() {
        let measurement = AppleSmartBatteryDiscovery.chargingMeasurement(
            properties: [
                "InstantAmperage": 0,
                "Amperage": 1_028,
                "Voltage": 12_618,
            ]
        )

        XCTAssertNil(measurement)
    }

    func testInvalidOrIncompleteElectricalValuesAreRejected() {
        XCTAssertNil(
            AppleSmartBatteryDiscovery.chargingMeasurement(
                properties: ["InstantAmperage": -500, "Voltage": 12_618]
            )
        )
        XCTAssertNil(
            AppleSmartBatteryDiscovery.chargingMeasurement(
                properties: ["InstantAmperage": 997]
            )
        )
        XCTAssertNil(
            AppleSmartBatteryDiscovery.chargingMeasurement(
                properties: ["InstantAmperage": 997, "Voltage": 0]
            )
        )
    }
}
