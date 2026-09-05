import XCTest

@testable import MenuBarIO

final class ConnectionPathResolverTests: XCTestCase {
    func testDeviceAtDockPortHasFullPhysicalPath() {
        let dock = device("Dock", location: 1)
        let storage = device("SSD", location: 2)
        let host = port("host", number: 3, device: dock)
        let downstream = port("downstream", number: 2, device: storage)
        let resolver = ConnectionPathResolver(
            devices: [dock, storage], hostPorts: [host],
            externalGroups: [.init(owner: dock, hostConnectorNumber: 3, depth: 1, ports: [downstream])],
            localize: { $0 }
        )
        XCTAssertEqual(resolver.path(to: storage), "this_mac → thunderbolt_port 3 → Dock → thunderbolt_port 2 → SSD")
        XCTAssertEqual(resolver.path(to: downstream), resolver.path(to: storage))
    }

    func testUnknownOwnerAndAmbiguousAssignmentsStayUnknown() {
        let dock = device("Dock", location: 1)
        let storage = device("SSD", location: 2)
        let downstream = port("downstream", number: 2, device: storage)
        let unresolved = ConnectionPathResolver(
            devices: [dock, storage], hostPorts: [],
            externalGroups: [.init(owner: dock, hostConnectorNumber: Int.max, depth: 1, ports: [downstream])]
        )
        XCTAssertNil(unresolved.path(to: storage))
        XCTAssertNil(unresolved.path(to: downstream))
        let ambiguous = ConnectionPathResolver(
            devices: [storage],
            hostPorts: [port("one", number: 1, device: storage), port("two", number: 2, device: storage)],
            externalGroups: []
        )
        XCTAssertNil(ambiguous.path(to: storage))
    }

    func testCyclicDockTopologyDoesNotRecurseForever() {
        let first = device("First", location: 1)
        let second = device("Second", location: 2)
        let resolver = ConnectionPathResolver(
            devices: [first, second], hostPorts: [],
            externalGroups: [
                .init(
                    owner: first, hostConnectorNumber: Int.max, depth: 1,
                    ports: [port("one", number: 1, device: second)]),
                .init(
                    owner: second, hostConnectorNumber: Int.max, depth: 2,
                    ports: [port("two", number: 1, device: first)]),
            ]
        )
        XCTAssertNil(resolver.path(to: first))
    }

    func testFreeHostPortKeepsItsKnownPathAndDetail() {
        let host = port("host", number: 1, device: nil)
        let resolver = ConnectionPathResolver(devices: [], hostPorts: [host], externalGroups: [], localize: { $0 })
        XCTAssertEqual(resolver.path(to: host), "this_mac → thunderbolt_port 1")
        let detail = DeviceDetailsBuilder(paths: resolver).port(host, powerConnected: false, powerWatts: nil)
        XCTAssertEqual(detail.fields.first { $0.label == "bandwidth_boost" }?.value, "120.0 Gbps")
        XCTAssertEqual(detail.fields.first { $0.label == "port_max" }?.value, "80.0 Gbps")
        XCTAssertTrue(detail.notes.contains("bandwidth_boost_explanation"))
    }

    func testMissingNegotiatedRateDoesNotUsePortMaximum() {
        let unknown = device("Unknown", location: 3)
        let detail = DeviceDetailsBuilder(paths: .init(devices: [unknown], hostPorts: [], externalGroups: [])).usb(
            unknown)
        XCTAssertNotEqual(detail.fields.first { $0.label == "negotiated_speed" }?.value, "10.0 Gbps")
        XCTAssertEqual(detail.fields.first { $0.label == "port_max" }?.value, "10.0 Gbps")
    }

    func testUSBCompanionPortCapacityDoesNotBecomeThunderboltCapacity() {
        let storage = device("USB SSD", location: 4)
        let downstream = port("dock-port", number: 1, device: storage)
        let detail = DeviceDetailsBuilder(paths: .init(devices: [storage], hostPorts: [], externalGroups: []))
            .port(downstream, powerConnected: false, powerWatts: nil)
        XCTAssertEqual(detail.fields.first { $0.label == "port_max" }?.value, "10.0 Gbps")
        XCTAssertFalse(detail.fields.contains { $0.label == "bandwidth_boost" })
        XCTAssertFalse(detail.notes.contains("bandwidth_boost_explanation"))
    }

    private func device(_ name: String, location: UInt32) -> USBDevice {
        USBDevice(
            name: name, vendor: nil, vendorId: 1, productId: 1, serialNumber: nil,
            locationId: location, speedMbps: nil, portMaxSpeedMbps: 10_000,
            usbVersionBCD: nil, isExternalStorage: nil)
    }

    private func port(_ id: String, number: Int, device: USBDevice?) -> ThunderboltPort {
        ThunderboltPort(
            id: id, controllerID: 1, connectorNumber: number,
            protocolVersion: 64, maximumSpeedMbps: 120_000, connectedDevice: device)
    }
}
