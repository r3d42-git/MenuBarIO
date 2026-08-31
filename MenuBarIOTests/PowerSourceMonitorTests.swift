import IOKit.ps
import XCTest

@testable import MenuBarIO

final class PowerSourceMonitorTests: XCTestCase {
    func testChargingStateReportsBatteryAndAdapterPower() {
        let state = PowerSourceMonitor.state(
            descriptions: [
                [
                    kIOPSTypeKey as String: kIOPSInternalBatteryType as String,
                    kIOPSPowerSourceStateKey as String: kIOPSACPowerValue,
                    kIOPSCurrentCapacityKey as String: 75,
                    kIOPSMaxCapacityKey as String: 100,
                    kIOPSIsChargingKey as String: true,
                    kIOPSCurrentKey as String: 4_500,
                    kIOPSVoltageKey as String: 20_000,
                ]
            ],
            adapterDetails: [kIOPSPowerAdapterWattsKey: 100],
            powerSourceConnectorNumber: 2
        )

        XCTAssertTrue(state.isConnected)
        XCTAssertEqual(state.chargePercentage, 75)
        XCTAssertTrue(state.isCharging)
        XCTAssertEqual(state.chargingPowerWatts, 90)
        XCTAssertEqual(state.adapterPowerWatts, 100)
        XCTAssertEqual(state.powerSourceConnectorNumber, 2)
    }

    func testConnectedBatteryDoesNotClaimChargingPowerWhenNotCharging() {
        let state = PowerSourceMonitor.state(
            descriptions: [
                [
                    kIOPSTypeKey as String: kIOPSInternalBatteryType as String,
                    kIOPSPowerSourceStateKey as String: kIOPSACPowerValue,
                    kIOPSCurrentCapacityKey as String: 100,
                    kIOPSMaxCapacityKey as String: 100,
                    kIOPSIsChargingKey as String: false,
                    kIOPSCurrentKey as String: -500,
                    kIOPSVoltageKey as String: 12_000,
                ]
            ],
            adapterDetails: [kIOPSPowerAdapterWattsKey: 67],
            fallbackChargingMeasurement: BatteryElectricalMeasurement(
                currentMilliamps: 2_000,
                voltageMillivolts: 12_000
            )
        )

        XCTAssertTrue(state.isConnected)
        XCTAssertEqual(state.chargePercentage, 100)
        XCTAssertFalse(state.isCharging)
        XCTAssertNil(state.chargingPowerWatts)
        XCTAssertEqual(state.adapterPowerWatts, 67)
        XCTAssertNil(state.powerSourceConnectorNumber)
    }

    func testMissingOrInvalidPowerValuesAreOmitted() {
        let state = PowerSourceMonitor.state(
            descriptions: [
                [
                    kIOPSTypeKey as String: kIOPSInternalBatteryType as String,
                    kIOPSPowerSourceStateKey as String: kIOPSACPowerValue,
                    kIOPSCurrentCapacityKey as String: 50,
                    kIOPSMaxCapacityKey as String: 100,
                    kIOPSIsChargingKey as String: true,
                    kIOPSCurrentKey as String: 0,
                    kIOPSVoltageKey as String: 12_000,
                ]
            ],
            adapterDetails: [kIOPSPowerAdapterWattsKey: -1]
        )

        XCTAssertTrue(state.isConnected)
        XCTAssertTrue(state.isCharging)
        XCTAssertNil(state.chargingPowerWatts)
        XCTAssertNil(state.adapterPowerWatts)
    }

    func testIntelRegistryMeasurementFillsMissingPublicCurrent() {
        let state = PowerSourceMonitor.state(
            descriptions: [
                [
                    kIOPSTypeKey as String: kIOPSInternalBatteryType as String,
                    kIOPSPowerSourceStateKey as String: kIOPSACPowerValue,
                    kIOPSCurrentCapacityKey as String: 86,
                    kIOPSMaxCapacityKey as String: 100,
                    kIOPSIsChargingKey as String: true,
                ]
            ],
            adapterDetails: [kIOPSPowerAdapterWattsKey: 100],
            fallbackChargingMeasurement: BatteryElectricalMeasurement(
                currentMilliamps: 997,
                voltageMillivolts: 12_618
            )
        )

        XCTAssertEqual(state.chargingPowerWatts, 13)
    }

    func testPublicMeasurementTakesPriorityOverRegistryFallback() {
        let state = PowerSourceMonitor.state(
            descriptions: [
                [
                    kIOPSTypeKey as String: kIOPSInternalBatteryType as String,
                    kIOPSPowerSourceStateKey as String: kIOPSACPowerValue,
                    kIOPSCurrentCapacityKey as String: 75,
                    kIOPSMaxCapacityKey as String: 100,
                    kIOPSIsChargingKey as String: true,
                    kIOPSCurrentKey as String: 4_500,
                    kIOPSVoltageKey as String: 20_000,
                ]
            ],
            adapterDetails: [kIOPSPowerAdapterWattsKey: 100],
            fallbackChargingMeasurement: BatteryElectricalMeasurement(
                currentMilliamps: 997,
                voltageMillivolts: 12_618
            )
        )

        XCTAssertEqual(state.chargingPowerWatts, 90)
    }
}
