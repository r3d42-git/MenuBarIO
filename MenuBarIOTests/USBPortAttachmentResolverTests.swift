import XCTest

@testable import MenuBarIO

final class USBPortAttachmentResolverTests: XCTestCase {
    func testDirectUSBStickOccupiesHostPortAndIsCountedOnceWithItsUSBRate() throws {
        let stick = makeUSBDevice(
            name: "Ultra USB 3.0", productID: 1, locationID: 0x0020_0000,
            speedMbps: 5_000, hostConnectorNumber: 1
        )
        let keyboard = makeUSBDevice(name: "Keyboard", productID: 2, locationID: 0x0312_0000)
        let ports = USBPortAttachmentResolver.attachingDirectUSBDevices(
            to: makePorts(), usbDevices: [stick, keyboard]
        )
        let occupied = try XCTUnwrap(ports.first)
        let groups = USBDeviceGroups(devices: [stick, keyboard], thunderboltPorts: ports)

        XCTAssertEqual(occupied.connectedDevice, stick)
        XCTAssertEqual(occupied.negotiatedSpeedMbps, 5_000)
        XCTAssertNil(occupied.connectionMaximumSpeedMbps)
        XCTAssertEqual(occupied.connectedDevice?.transport, .usb)
        XCTAssertEqual(groups.portAttachedUSBDevices, [stick])
        XCTAssertEqual(groups.usbDevices, [keyboard])
        XCTAssertEqual(groups.countedExternalDeviceCount, 2)

        let path = ConnectionPathResolver(
            devices: [stick, keyboard], hostPorts: ports, externalGroups: [], localize: { $0 }
        ).path(to: stick)
        XCTAssertEqual(path, "this_mac → thunderbolt_port 1 → Ultra USB 3.0")
    }

    func testUSB2AndUSB3UseExplicitSocketsOnSharedHostController() {
        // Intel hosts can expose multiple sockets on one controller. Neither
        // its ID nor the USB location-ID byte defines the visible socket.
        let usb2 = makeUSBDevice(
            name: "USB2", productID: 1, locationID: 0x1410_0000,
            speedMbps: 480, hostConnectorNumber: 2
        )
        let usb3 = makeUSBDevice(
            name: "USB3", productID: 2, locationID: 0x1460_0000,
            speedMbps: 5_000, hostConnectorNumber: 1
        )
        let ports = USBPortAttachmentResolver.attachingDirectUSBDevices(
            to: makePorts(), usbDevices: [usb2, usb3]
        )
        XCTAssertEqual(ports.compactMap(\.connectedDevice), [usb3, usb2])
        XCTAssertNil(ports.last?.connectedDevice)
    }

    func testDirectUSBReplugAndDisconnectClearPreviousAssignment() {
        let first = makeUSBDevice(
            name: "Stick", productID: 1, locationID: 0x0020_0000, hostConnectorNumber: 1
        )
        let moved = makeUSBDevice(
            name: "Stick", productID: 1, locationID: 0x0120_0000, hostConnectorNumber: 2
        )
        let original = USBPortAttachmentResolver.attachingDirectUSBDevices(to: makePorts(), usbDevices: [first])
        let replugged = USBPortAttachmentResolver.attachingDirectUSBDevices(to: makePorts(), usbDevices: [moved])
        let disconnected = USBPortAttachmentResolver.attachingDirectUSBDevices(to: makePorts(), usbDevices: [])
        XCTAssertEqual(original[0].connectedDevice, first)
        XCTAssertNil(replugged[0].connectedDevice)
        XCTAssertEqual(replugged[1].connectedDevice, moved)
        XCTAssertTrue(disconnected.allSatisfy { $0.connectedDevice == nil })
    }

    func testDirectUSBLeavesNativeThunderboltAttachmentAndHubOwnerIntact() {
        let dock = makeThunderboltDevice()
        let nativePort = ThunderboltPort(
            id: "native", controllerID: 2, connectorNumber: 1,
            protocolVersion: 32, maximumSpeedMbps: 40_000, connectedDevice: dock
        )
        let stick = makeUSBDevice(
            name: "Stick", productID: 1, locationID: 0x0220_0000, hostConnectorNumber: 1
        )
        let ports = USBPortAttachmentResolver.attachingDirectUSBDevices(to: [nativePort], usbDevices: [stick])
        XCTAssertEqual(ports, [nativePort])

        let hub = makeUSBDevice(name: "Direct hub", productID: 2, locationID: 0x0210_0000, deviceClass: 9)
        let usbPorts = USBPortAttachmentResolver.attachingDirectUSBDevices(to: makePorts(), usbDevices: [stick])
        let groups = USBDeviceGroups(devices: [hub, stick], thunderboltPorts: usbPorts)
        XCTAssertEqual(groups.hubGroups.first?.owner, .direct)
    }

    func testDirectUSBRejectsUnknownSocketsAndAmbiguousDevicesOrHostPorts() {
        let first = makeUSBDevice(name: "First", productID: 1, locationID: 1, hostConnectorNumber: 1)
        let second = makeUSBDevice(name: "Second", productID: 2, locationID: 2, hostConnectorNumber: 1)
        let unknown = makeUSBDevice(name: "Unknown", productID: 3, locationID: 3)
        let usbOnlySocket = makeUSBDevice(name: "Front USB-C", productID: 4, locationID: 4, hostConnectorNumber: 6)
        let ambiguous = USBPortAttachmentResolver.attachingDirectUSBDevices(
            to: makePorts(), usbDevices: [first, second, unknown, usbOnlySocket]
        )
        XCTAssertTrue(ambiguous.allSatisfy { $0.connectedDevice == nil })
        let duplicateSocket = ThunderboltPort(
            id: "duplicate", controllerID: 99, connectorNumber: 1,
            protocolVersion: 32, maximumSpeedMbps: 40_000, connectedDevice: nil
        )
        let duplicatePorts = USBPortAttachmentResolver.attachingDirectUSBDevices(
            to: makePorts() + [duplicateSocket], usbDevices: [first]
        )
        XCTAssertTrue(duplicatePorts.allSatisfy { $0.connectedDevice == nil })
    }

    func testDirectUSBDoesNotPromoteDockDescendantsOrInternalFunctionsToHostSocket() {
        let devices = [
            makeUSBDevice(
                name: "Dock USB", productID: 1, locationID: 1,
                isThunderboltTunneledUSB: true, hostConnectorNumber: 1),
            makeUSBDevice(
                name: "Hub child", productID: 2, locationID: 2,
                parentHubLocationID: 0x0210_0000, parentHubPortNumber: 1, hostConnectorNumber: 1),
            makeUSBDevice(
                name: "Internal", productID: 3, locationID: 3,
                hostConnectorNumber: 1, usbPortType: 2),
            makeUSBDevice(
                name: "Billboard", productID: 4, locationID: 4,
                hostConnectorNumber: 1, isThunderboltBillboard: true),
        ]
        for device in devices {
            let ports = USBPortAttachmentResolver.attachingDirectUSBDevices(to: makePorts(), usbDevices: [device])
            XCTAssertTrue(ports.allSatisfy { $0.connectedDevice == nil }, device.name)
        }
    }

    func testParsesCompanionHubPortsAndSkipsUSBOnlySocket() {
        let map = ThunderboltUSBPortMapEntry.entries(
            from: Data([0x01, 0x81, 0x91, 0x02, 0x82, 0x92, 0x03, 0x83, 0x93, 0x04, 0x00, 0x00])
        )

        XCTAssertEqual(
            map,
            [
                ThunderboltUSBPortMapEntry(connectorNumber: 1, usbHubPortNumbers: [1]),
                ThunderboltUSBPortMapEntry(connectorNumber: 2, usbHubPortNumbers: [2]),
                ThunderboltUSBPortMapEntry(connectorNumber: 3, usbHubPortNumbers: [3]),
            ]
        )
    }

    func testDifferentUSB2AndUSB3CompanionPortsRemainOneConnector() {
        let map = ThunderboltUSBPortMapEntry.entries(
            from: Data([0x01, 0x81, 0x94, 0x02, 0x00, 0x00])
        )

        XCTAssertEqual(
            map,
            [
                ThunderboltUSBPortMapEntry(
                    connectorNumber: 1,
                    usbHubPortNumbers: [1, 4]
                )
            ]
        )
    }

    func testAnkerPortMapAttachesThreeUSBDevicesAndLeavesUSBOnlySocketResidual() {
        let dock = makeThunderboltDevice()
        let usb2Hub = makeUSBDevice(
            name: "USB2.0 Hub",
            productID: 1,
            locationID: 0x0210_0000,
            deviceClass: 9
        )
        let usb3Hub = makeUSBDevice(
            name: "USB3.0 Hub",
            productID: 2,
            locationID: 0x0220_0000,
            deviceClass: 9,
            isThunderboltTunneledUSB: true
        )
        let maono = makeUSBDevice(
            name: "Maono Wireless Mic RX",
            productID: 3,
            locationID: 0x0211_0000,
            speedMbps: 12,
            parentHubLocationID: usb2Hub.locationId,
            parentHubPortNumber: 1
        )
        let storage = makeUSBDevice(
            name: "ASM1352R-Fast",
            productID: 4,
            locationID: 0x0222_0000,
            speedMbps: 10_000,
            parentHubLocationID: usb3Hub.locationId,
            parentHubPortNumber: 2
        )
        let loupedeck = makeUSBDevice(
            name: "Loupedeck Live S",
            productID: 5,
            locationID: 0x0213_0000,
            speedMbps: 480,
            parentHubLocationID: usb2Hub.locationId,
            parentHubPortNumber: 3
        )
        let yubiKey = makeUSBDevice(
            name: "YubiKey OTP+FIDO+CCID",
            productID: 6,
            locationID: 0x0214_0000,
            speedMbps: 12,
            parentHubLocationID: usb2Hub.locationId,
            parentHubPortNumber: 4
        )
        let devices = [usb2Hub, usb3Hub, maono, storage, loupedeck, yubiKey]
        let ports = makePorts()
        let portMap = ThunderboltUSBPortMapEntry.entries(
            from: Data([0x01, 0x81, 0x91, 0x02, 0x82, 0x92, 0x03, 0x83, 0x93, 0x04, 0x00, 0x00])
        )

        let attachedPorts = USBPortAttachmentResolver.attachingUSBDevices(
            to: ports,
            ownerID: dock.id,
            controllerID: 2,
            hostConnectorNumber: 3,
            portMap: portMap,
            usbDevices: devices
        )
        let externalGroup = ExternalThunderboltPortGroup(
            owner: dock,
            hostConnectorNumber: 3,
            depth: 1,
            ports: attachedPorts
        )
        let groups = USBDeviceGroups(
            devices: devices + [dock],
            externalThunderboltPortGroups: [externalGroup]
        )

        XCTAssertEqual(attachedPorts.compactMap(\.connectedDevice), [maono, storage, loupedeck])
        XCTAssertEqual(groups.portAttachedUSBDevices, [maono, storage, loupedeck])
        XCTAssertEqual(groups.usbDevices, [yubiKey])
        XCTAssertEqual(groups.countedExternalDeviceCount, 5)
    }

    func testNativeThunderboltDeviceKeepsPriorityOverUSBMap() {
        let nativeDevice = makeThunderboltDevice(name: "Native SSD")
        let hub = makeUSBDevice(
            name: "USB3 Hub",
            productID: 1,
            locationID: 0x0220_0000,
            deviceClass: 9,
            isThunderboltTunneledUSB: true
        )
        let usbDevice = makeUSBDevice(
            name: "USB SSD",
            productID: 2,
            locationID: 0x0221_0000,
            parentHubLocationID: hub.locationId,
            parentHubPortNumber: 1
        )
        let occupiedPort = ThunderboltPort(
            id: "external-port-1",
            controllerID: 2,
            connectorNumber: 1,
            protocolVersion: 32,
            maximumSpeedMbps: 40_000,
            connectedDevice: nativeDevice
        )

        let resolved = USBPortAttachmentResolver.attachingUSBDevices(
            to: [occupiedPort],
            ownerID: makeThunderboltDevice().id,
            controllerID: 2,
            hostConnectorNumber: 3,
            portMap: [
                ThunderboltUSBPortMapEntry(connectorNumber: 1, usbHubPortNumbers: [1])
            ],
            usbDevices: [hub, usbDevice]
        )

        XCTAssertEqual(resolved.first?.connectedDevice, nativeDevice)
    }

    func testMissingHostAttachmentLeavesIntelDockUSBDevicesUnassigned() {
        let dock = makeThunderboltDevice(name: "TS3 Plus")
        let hub = makeUSBDevice(
            name: "IOUSBHostDevice",
            productID: 1,
            locationID: 0x0110_0000,
            deviceClass: 9,
            isThunderboltTunneledUSB: true
        )
        let audio = makeUSBDevice(
            name: "CalDigit Thunderbolt 3 Audio",
            productID: 2,
            locationID: 0x0111_0000,
            parentHubLocationID: hub.locationId,
            parentHubPortNumber: 1
        )

        let resolved = USBPortAttachmentResolver.attachingUSBDevices(
            to: [makePorts().first!],
            ownerID: dock.id,
            controllerID: 1,
            hostConnectorNumber: Int.max,
            portMap: [
                ThunderboltUSBPortMapEntry(connectorNumber: 1, usbHubPortNumbers: [1])
            ],
            usbDevices: [hub, audio]
        )

        XCTAssertNil(resolved.first?.connectedDevice)
    }

    func testAmbiguousUSBTopologyLeavesPortFree() {
        let dock = makeThunderboltDevice()
        let hub = makeUSBDevice(
            name: "USB Hub",
            productID: 1,
            locationID: 0x0210_0000,
            deviceClass: 9,
            isThunderboltTunneledUSB: true
        )
        let first = makeUSBDevice(
            name: "First",
            productID: 2,
            locationID: 0x0211_0000,
            parentHubLocationID: hub.locationId,
            parentHubPortNumber: 1
        )
        let second = makeUSBDevice(
            name: "Second",
            productID: 3,
            locationID: 0x0221_0000,
            parentHubLocationID: hub.locationId,
            parentHubPortNumber: 1
        )

        let resolved = USBPortAttachmentResolver.attachingUSBDevices(
            to: [makePorts().first!],
            ownerID: dock.id,
            controllerID: 2,
            hostConnectorNumber: 3,
            portMap: [
                ThunderboltUSBPortMapEntry(connectorNumber: 1, usbHubPortNumbers: [1])
            ],
            usbDevices: [hub, first, second]
        )

        XCTAssertNil(resolved.first?.connectedDevice)
    }

    func testDisplayPortEvidenceRequiresEstablishedOutputTunnel() {
        XCTAssertTrue(
            DisplayPortConnectionEvidence.isActiveOutput(
                adapterType: 917_762, dpState: 2, hpdState: true, establishedLaneCount: 2, hasTunnel: true))
        for evidence in [
            (917_762, 0, false, 0, false),  // inactive output from the live Anker snapshot
            (917_761, 2, true, 2, true),  // DP input is not an attached display output
            (917_762, 0, true, 2, true),
            (917_762, 2, false, 2, true),
            (917_762, 2, true, 0, true),
            (917_762, 2, true, 2, false),
        ] {
            XCTAssertFalse(
                DisplayPortConnectionEvidence.isActiveOutput(
                    adapterType: evidence.0, dpState: evidence.1, hpdState: evidence.2,
                    establishedLaneCount: evidence.3, hasTunnel: evidence.4))
        }
        XCTAssertFalse(
            DisplayPortConnectionEvidence.isActiveOutput(
                adapterType: nil, dpState: nil, hpdState: nil, establishedLaneCount: nil, hasTunnel: true))
    }

    func testActiveDisplayPortMarksOnlyUnassignedConnectorsAndDoesNotChangeCounts() {
        let dock = makeThunderboltDevice()
        let native = makeThunderboltDevice(name: "Native SSD")
        let stick = makeUSBDevice(name: "Stick", productID: 1, locationID: 1)
        let ports = [
            makePorts()[0],
            ThunderboltPort(
                id: "usb", controllerID: 2, connectorNumber: 2,
                protocolVersion: 32, maximumSpeedMbps: 40_000, connectedDevice: stick),
            ThunderboltPort(
                id: "native", controllerID: 2, connectorNumber: 3,
                protocolVersion: 32, maximumSpeedMbps: 40_000, connectedDevice: native),
        ]
        let group = ExternalThunderboltPortGroup(
            owner: dock, hostConnectorNumber: 1, depth: 1,
            ports: ports, activeDisplayOutputCount: 2)
        XCTAssertEqual(group.activeDisplayOutputCount, 2)
        XCTAssertTrue(group.ports[0].hasUnresolvedDisplayConnection)
        XCTAssertEqual(group.ports[0].unoccupiedStatusKey, "port_occupancy_unknown")
        XCTAssertNil(group.ports[0].connectedDevice)  // never fabricate a physical display assignment
        XCTAssertEqual(Array(group.ports.dropFirst()), Array(ports.dropFirst()))
        let fullyOccupied = ExternalThunderboltPortGroup(
            owner: dock, hostConnectorNumber: 1, depth: 1,
            ports: Array(ports.dropFirst()), activeDisplayOutputCount: 1)
        XCTAssertEqual(fullyOccupied.activeDisplayOutputCount, 1)
        XCTAssertEqual(fullyOccupied.ports, Array(ports.dropFirst()))
        XCTAssertTrue(fullyOccupied.ports.allSatisfy { !$0.hasUnresolvedDisplayConnection })
        let groups = USBDeviceGroups(devices: [dock, native, stick], externalThunderboltPortGroups: [group])
        XCTAssertEqual(groups.countedExternalDeviceCount, 3)
        XCTAssertEqual(groups.portAttachedUSBDevices, [stick])

        let disconnected = ExternalThunderboltPortGroup(
            owner: dock, hostConnectorNumber: 1, depth: 1,
            ports: group.ports, activeDisplayOutputCount: 0)
        XCTAssertFalse(disconnected.ports[0].hasUnresolvedDisplayConnection)
        XCTAssertEqual(disconnected.ports[0].unoccupiedStatusKey, "port_free")
        XCTAssertEqual(Array(disconnected.ports.dropFirst()), Array(ports.dropFirst()))
    }

    func testUnresolvedDisplayOccupancyAppearsInDetailsCopyAndOverview() {
        let dock = makeThunderboltDevice()
        let group = ExternalThunderboltPortGroup(
            owner: dock, hostConnectorNumber: 1, depth: 1,
            ports: makePorts(), activeDisplayOutputCount: 1)
        let port = group.ports[0]
        let reportBuilder = DiagnosticReportBuilder(localize: { $0 })
        let copy = reportBuilder.thunderboltPortDetails(port)
        XCTAssertTrue(copy.contains("port_occupancy_unknown"))
        XCTAssertTrue(copy.contains("displayport_connector_unknown"))
        XCTAssertFalse(copy.contains("port_free"))
        let details = DeviceDetailsBuilder(paths: .init(devices: [dock], hostPorts: [], externalGroups: [group]))
        let content = details.port(port, powerConnected: false, powerWatts: nil)
        XCTAssertTrue(content.notes.contains("displayport_connector_unknown"))
        XCTAssertTrue(
            content.fields.contains { $0.label == "status" && $0.value == "port_occupancy_unknown".localized })
        XCTAssertTrue(details.usb(dock).notes.contains("displayport_connector_unknown"))
        let now = Date(timeIntervalSince1970: 0)
        let overview = reportBuilder.overview(
            .init(
                appVersion: "test", appBuild: "1", generatedAt: now, operatingSystemVersion: "macOS",
                modelIdentifier: nil, devices: [dock], thunderboltPorts: [],
                externalThunderboltPortGroups: [group], bluetoothDevices: [],
                deviceSourceStatus: .ready(lastUpdated: now), bluetoothSourceStatus: .ready(lastUpdated: now),
                powerSource: nil, powerSourceConnectorNumber: nil))
        XCTAssertTrue(overview.contains("active_displayport_outputs"))
        XCTAssertTrue(overview.contains("port\\_occupancy\\_unknown"))
        XCTAssertTrue(overview.contains("displayport\\_connector\\_unknown"))
        XCTAssertFalse(overview.contains("port_free"))
    }

    private func makePorts() -> [ThunderboltPort] {
        (1...3).map { connectorNumber in
            ThunderboltPort(
                id: "external-port-\(connectorNumber)",
                controllerID: 2,
                connectorNumber: connectorNumber,
                protocolVersion: 32,
                maximumSpeedMbps: 40_000,
                connectedDevice: nil
            )
        }
    }

    private func makeUSBDevice(
        name: String,
        productID: Int,
        locationID: UInt32,
        speedMbps: Int = 480,
        deviceClass: Int? = nil,
        isThunderboltTunneledUSB: Bool = false,
        parentHubLocationID: UInt32? = nil,
        parentHubPortNumber: Int? = nil,
        hostConnectorNumber: Int? = nil,
        usbPortType: Int? = nil,
        isThunderboltBillboard: Bool = false
    ) -> USBDevice {
        USBDevice(
            name: name,
            vendor: "Example",
            vendorId: 0x1234,
            productId: productID,
            serialNumber: nil,
            locationId: locationID,
            speedMbps: speedMbps,
            portMaxSpeedMbps: nil,
            usbVersionBCD: nil,
            isExternalStorage: false,
            usbPortType: usbPortType,
            deviceClass: deviceClass,
            isThunderboltBillboard: isThunderboltBillboard,
            isThunderboltTunneledUSB: isThunderboltTunneledUSB,
            parentHubLocationId: parentHubLocationID,
            parentHubPortNumber: parentHubPortNumber,
            hostConnectorNumber: hostConnectorNumber
        )
    }

    private func makeThunderboltDevice(
        name: String = "Thunderbolt 4 Mini Dock"
    ) -> USBDevice {
        USBDevice(
            name: name,
            vendor: "Anker",
            vendorId: 0x291A,
            productId: 0x8498,
            serialNumber: nil,
            locationId: 1,
            speedMbps: 40_000,
            portMaxSpeedMbps: nil,
            usbVersionBCD: nil,
            isExternalStorage: nil,
            transport: .thunderbolt,
            transportVersion: "Thunderbolt 3/4 / USB4",
            transportIdentifier: name
        )
    }
}
