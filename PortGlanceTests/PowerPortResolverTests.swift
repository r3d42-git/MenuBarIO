import XCTest

@testable import PortGlance

final class PowerPortResolverTests: XCTestCase {
    func testIntelT2WinnerMapsFirstControllerAddressToSecondVisiblePort() {
        XCTAssertEqual(
            PowerPortResolver.connectorNumber(
                contracts: contracts(supplyingIndex: 0),
                controllers: controllers,
                thunderboltConnectors: thunderboltConnectors
            ),
            2
        )
    }

    func testIntelT2WinnerMovesToFirstVisiblePortWithSecondControllerAddress() {
        XCTAssertEqual(
            PowerPortResolver.connectorNumber(
                contracts: contracts(supplyingIndex: 1),
                controllers: controllers,
                thunderboltConnectors: thunderboltConnectors
            ),
            1
        )
    }

    func testSecondRouterUsesItsOwnSocketNumbers() {
        XCTAssertEqual(
            PowerPortResolver.connectorNumber(
                contracts: contracts(supplyingIndex: 3),
                controllers: controllers,
                thunderboltConnectors: thunderboltConnectors
            ),
            3
        )
    }

    func testResolverRejectsMultipleSupplyingControllers() {
        var records = contracts(supplyingIndex: 0)
        records[1] = supplyingContract

        XCTAssertNil(
            PowerPortResolver.connectorNumber(
                contracts: records,
                controllers: controllers,
                thunderboltConnectors: thunderboltConnectors
            )
        )
    }

    func testResolverRejectsIncompleteTopology() {
        XCTAssertNil(
            PowerPortResolver.connectorNumber(
                contracts: contracts(supplyingIndex: 0),
                controllers: Array(controllers.dropLast()),
                thunderboltConnectors: thunderboltConnectors
            )
        )
    }

    private var controllers: [PowerPortControllerRecord] {
        [
            PowerPortControllerRecord(routerID: 0, address: 0),
            PowerPortControllerRecord(routerID: 0, address: 1),
            PowerPortControllerRecord(routerID: 1, address: 0),
            PowerPortControllerRecord(routerID: 1, address: 1),
        ]
    }

    private var thunderboltConnectors: [PowerPortThunderboltConnectorRecord] {
        [
            PowerPortThunderboltConnectorRecord(
                routerID: 0,
                connectorNumber: 2,
                hostPortNumber: 1
            ),
            PowerPortThunderboltConnectorRecord(
                routerID: 0,
                connectorNumber: 1,
                hostPortNumber: 3
            ),
            PowerPortThunderboltConnectorRecord(
                routerID: 1,
                connectorNumber: 4,
                hostPortNumber: 1
            ),
            PowerPortThunderboltConnectorRecord(
                routerID: 1,
                connectorNumber: 3,
                hostPortNumber: 3
            ),
        ]
    }

    private var supplyingContract: PowerPortContractRecord {
        PowerPortContractRecord(
            loserReason: 0,
            powerDeliveryState: 5,
            maximumPowerMilliwatts: 100_000,
            fetStatus: 12
        )
    }

    private var idleContract: PowerPortContractRecord {
        PowerPortContractRecord(
            loserReason: 1,
            powerDeliveryState: 0,
            maximumPowerMilliwatts: 0,
            fetStatus: 0
        )
    }

    private func contracts(supplyingIndex: Int) -> [PowerPortContractRecord] {
        (0..<4).map { $0 == supplyingIndex ? supplyingContract : idleContract }
    }
}
