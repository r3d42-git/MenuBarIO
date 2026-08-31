import IOKit.usb
import XCTest

@testable import PortGlance

final class USBDeviceTests: XCTestCase {
    func testSeriallessDevicesRemainDistinctByLocation() {
        let first = makeDevice(locationID: 0x0010_0000)
        let second = makeDevice(locationID: 0x0020_0000)

        XCTAssertNotEqual(first.id, second.id)
    }

    func testStableIdentifierIsAlsoSwiftUIIdentity() {
        let device = makeDevice(locationID: 0x0010_0000)

        XCTAssertEqual(device.id, device.uniqueId)
        XCTAssertEqual(device.id, makeDevice(locationID: 0x0010_0000).id)
    }

    func testHubClassificationOnlyAppliesToUSBClassNine() {
        let usbHub = makeDevice(deviceClass: 9)
        let thunderboltDevice = USBDevice(
            name: "Dock",
            vendor: nil,
            vendorId: 0,
            productId: 0,
            serialNumber: nil,
            locationId: nil,
            speedMbps: 40_000,
            portMaxSpeedMbps: nil,
            usbVersionBCD: nil,
            isExternalStorage: nil,
            deviceClass: 9,
            transport: .thunderbolt
        )

        XCTAssertTrue(usbHub.isHub)
        XCTAssertFalse(thunderboltDevice.isHub)
    }

    func testInternalClassificationUsesOnlyIOKitInternalPortType() {
        let internalDevice = makeDevice(
            productID: 1,
            portType: Int(kIOUSBHostPortTypeInternal.rawValue)
        )
        let captiveDevice = makeDevice(
            productID: 2,
            portType: Int(kIOUSBHostPortTypeCaptive.rawValue)
        )

        XCTAssertTrue(internalDevice.isInternal)
        XCTAssertFalse(internalDevice.countsTowardUSBDeviceTotal)
        XCTAssertFalse(captiveDevice.isInternal)
        XCTAssertTrue(captiveDevice.countsTowardUSBDeviceTotal)
    }

    func testUnnamedInternalUSBDeviceUsesFriendlyDisplayNameOnly() {
        let internalDevice = USBDevice(
            name: "IOUSBHostDevice",
            vendor: "Apple",
            vendorId: 0x05AC,
            productId: 1,
            serialNumber: nil,
            locationId: 0x8080_0000,
            speedMbps: 480,
            portMaxSpeedMbps: nil,
            usbVersionBCD: 0x0200,
            isExternalStorage: false,
            usbPortType: Int(kIOUSBHostPortTypeInternal.rawValue)
        )
        let externalDevice = makeDevice()

        XCTAssertEqual(internalDevice.displayName, "unnamed_internal_usb_component".localized)
        XCTAssertEqual(internalDevice.name, "IOUSBHostDevice")
        XCTAssertEqual(externalDevice.displayName, externalDevice.name)
    }

    func testGroupsClassifyExternalInternalAndHubDevicesOnce() {
        let externalDevice = makeDevice(productID: 1)
        let thunderboltDevice = makeThunderboltDevice(
            name: "Thunderbolt Device",
            vendor: "Example",
            identifier: "TB"
        )
        let internalDevice = makeDevice(
            productID: 2,
            portType: Int(kIOUSBHostPortTypeInternal.rawValue)
        )
        let hub = makeDevice(productID: 3, deviceClass: 9)

        let groups = USBDeviceGroups(
            devices: [externalDevice, thunderboltDevice, internalDevice, hub]
        )

        XCTAssertEqual(groups.usbDevices.map(\.id), [externalDevice.id])
        XCTAssertEqual(groups.thunderboltDevices.map(\.id), [thunderboltDevice.id])
        XCTAssertEqual(groups.countedExternalDeviceCount, 2)
        XCTAssertEqual(groups.internalDevices.map(\.id), [internalDevice.id])
        XCTAssertEqual(groups.hubs.map(\.id), [hub.id])
    }

    func testHubGroupsUseInternalAndThunderboltTopologyOwners() {
        let d1 = makeThunderboltDevice(
            name: "D1 SSD Pro",
            vendor: "TerraMaster",
            identifier: "D1"
        )
        let anker = makeThunderboltDevice(
            name: "Thunderbolt 4 Mini Dock",
            vendor: "Anker",
            identifier: "ANKER"
        )
        let internalHub = makeDevice(
            productID: 1,
            locationID: 0x0310_0000,
            portType: Int(kIOUSBHostPortTypeInternal.rawValue),
            deviceClass: 9
        )
        let d1Hub = makeDevice(
            productID: 2,
            // The ancestry owner must win even when an Intel AppleUSBXHCITR
            // bus number happens to equal a different host router ID.
            locationID: 0x0210_0000,
            deviceClass: 9,
            thunderboltOwnerID: d1.id
        )
        let ankerHub = makeDevice(
            productID: 3,
            locationID: 0x0210_0000,
            deviceClass: 9
        )
        let ports = [
            ThunderboltPort(
                id: "port-2",
                controllerID: 1,
                connectorNumber: 2,
                protocolVersion: 64,
                maximumSpeedMbps: 120_000,
                connectedDevice: d1
            ),
            ThunderboltPort(
                id: "port-3",
                controllerID: 2,
                connectorNumber: 3,
                protocolVersion: 64,
                maximumSpeedMbps: 120_000,
                connectedDevice: anker
            ),
        ]

        let groups = USBDeviceGroups(
            devices: [internalHub, d1Hub, ankerHub],
            thunderboltPorts: ports
        )

        XCTAssertEqual(groups.hubGroups.map(\.devices), [[internalHub], [d1Hub], [ankerHub]])
        XCTAssertEqual(groups.hubGroups[0].owner, .thisMac)
        XCTAssertEqual(
            groups.hubGroups[1].owner,
            .thunderboltDevice(
                id: d1.id,
                displayName: "TerraMaster D1 SSD Pro",
                connectorNumber: 2
            )
        )
        XCTAssertEqual(
            groups.hubGroups[2].owner,
            .thunderboltDevice(
                id: anker.id,
                displayName: "Anker Thunderbolt 4 Mini Dock",
                connectorNumber: 3
            )
        )
    }

    func testThunderboltDescriptionLeavesNegotiatedSpeedToTrailingValue() {
        let device = USBDevice(
            name: "SSD",
            vendor: "Example",
            vendorId: 0x1111,
            productId: 0x2222,
            serialNumber: nil,
            locationId: 1,
            speedMbps: 80_000,
            portMaxSpeedMbps: nil,
            usbVersionBCD: nil,
            isExternalStorage: nil,
            transport: .thunderbolt,
            transportVersion: "USB4 v2",
            transportIdentifier: "ABC"
        )

        XCTAssertEqual(device.connectionDescription, "Thunderbolt/USB4")
        XCTAssertEqual(USBFormatting.transferRate(device.speedMbps ?? 0), "80.0 Gbps")
        XCTAssertEqual(device.id, "thunderbolt-4369-8738-ABC")
    }

    func testSingleThunderboltDeviceOwnsUnresolvedIntelTunneledHub() {
        let dock = makeThunderboltDevice(
            name: "TS3 Plus",
            vendor: "CalDigit, Inc.",
            identifier: "CALDIGIT"
        )
        let hub = makeDevice(
            locationID: 0x0010_0000,
            deviceClass: 9,
            isThunderboltTunneledUSB: true
        )
        let port = ThunderboltPort(
            id: "port-2",
            controllerID: 3,
            connectorNumber: 2,
            protocolVersion: 32,
            maximumSpeedMbps: 40_000,
            connectedDevice: nil
        )

        let groups = USBDeviceGroups(devices: [hub, dock], thunderboltPorts: [port])

        XCTAssertEqual(
            groups.hubGroups.first?.owner,
            .thunderboltDevice(
                id: dock.id,
                displayName: "CalDigit, Inc. TS3 Plus",
                connectorNumber: Int.max
            )
        )
    }

    func testGenericIntelHubUsesSoleThunderboltVendorSiblingWithoutHostPortAttachment() {
        let dock = makeThunderboltDevice(
            name: "TS3 Plus",
            vendor: "CalDigit, Inc.",
            identifier: "CALDIGIT"
        )
        let hub = makeDevice(
            name: "IOUSBHostDevice",
            productID: 1,
            locationID: 0x0110_0000,
            deviceClass: 9
        )
        let dockUSBFunction = makeDevice(
            name: "CalDigit Thunderbolt 3 Audio",
            vendor: "CalDigit",
            productID: 2,
            locationID: 0x0111_0000
        )

        let groups = USBDeviceGroups(devices: [hub, dockUSBFunction, dock])

        XCTAssertEqual(
            groups.hubGroups.first?.owner,
            .thunderboltDevice(
                id: dock.id,
                displayName: "CalDigit, Inc. TS3 Plus",
                connectorNumber: Int.max
            )
        )
    }

    func testGenericHubHasUnknownOwnerWithoutMatchingThunderboltVendorSibling() {
        let dock = makeThunderboltDevice(
            name: "TS3 Plus",
            vendor: "CalDigit, Inc.",
            identifier: "CALDIGIT"
        )
        let hub = makeDevice(
            name: "IOUSBHostDevice",
            productID: 1,
            locationID: 0x0110_0000,
            deviceClass: 9
        )
        let unrelatedUSBFunction = makeDevice(
            name: "Webcam",
            vendor: "Polycom Inc.",
            productID: 2,
            locationID: 0x0111_0000
        )

        let groups = USBDeviceGroups(devices: [hub, unrelatedUSBFunction, dock])

        XCTAssertEqual(groups.hubGroups.first?.owner, .unknown)
    }

    func testNamedDirectHubRemainsDirectWhileThunderboltDeviceIsConnected() {
        let dock = makeThunderboltDevice(
            name: "TS3 Plus",
            vendor: "CalDigit, Inc.",
            identifier: "CALDIGIT"
        )
        let directHub = makeDevice(
            name: "Standalone USB Hub",
            vendor: "Example",
            productID: 1,
            locationID: 0x0110_0000,
            deviceClass: 9
        )

        let groups = USBDeviceGroups(devices: [directHub, dock])

        XCTAssertEqual(groups.hubGroups.first?.owner, .direct)
    }

    func testGenericHubRemainsDirectWithoutThunderboltAmbiguity() {
        let directHub = makeDevice(
            name: "IOUSBHostDevice",
            productID: 1,
            locationID: 0x0110_0000,
            deviceClass: 9
        )

        let groups = USBDeviceGroups(devices: [directHub])

        XCTAssertEqual(groups.hubGroups.first?.owner, .direct)
    }

    func testThunderboltPortUsesConnectedProtocolAndFreePortCapability() {
        let dock = makeThunderboltDevice(
            name: "Dock",
            vendor: "Example",
            identifier: "DOCK",
            transportVersion: "Thunderbolt 3/4 / USB4"
        )
        let connectedPort = ThunderboltPort(
            id: "port-1",
            controllerID: 0,
            connectorNumber: 1,
            protocolVersion: 64,
            maximumSpeedMbps: 120_000,
            connectedDevice: dock
        )
        let freePort = ThunderboltPort(
            id: "port-2",
            controllerID: 1,
            connectorNumber: 2,
            protocolVersion: 64,
            maximumSpeedMbps: 120_000,
            connectedDevice: nil
        )

        XCTAssertEqual(connectedPort.protocolDescription, "Thunderbolt 3/4 / USB4")
        XCTAssertEqual(freePort.protocolDescription, "Thunderbolt 5 / USB4 v2")
    }

    func testUSBDeviceCanOccupyThunderboltCapableConnectorWithoutChangingTransport() {
        let usbDevice = makeDevice(productID: 4)
        let port = ThunderboltPort(
            id: "external-port-1",
            controllerID: 2,
            connectorNumber: 1,
            protocolVersion: 32,
            maximumSpeedMbps: 40_000,
            connectedDevice: usbDevice
        )
        let owner = makeThunderboltDevice(
            name: "Dock",
            vendor: "Example",
            identifier: "DOCK"
        )
        let externalGroup = ExternalThunderboltPortGroup(
            owner: owner,
            hostConnectorNumber: 1,
            depth: 1,
            ports: [port]
        )
        let groups = USBDeviceGroups(
            devices: [usbDevice],
            externalThunderboltPortGroups: [externalGroup]
        )

        XCTAssertEqual(port.connectedDevice, usbDevice)
        XCTAssertEqual(port.protocolDescription, usbDevice.connectionDescription)
        XCTAssertTrue(groups.usbDevices.isEmpty)
        XCTAssertEqual(groups.portAttachedUSBDevices, [usbDevice])
        XCTAssertTrue(groups.thunderboltDevices.isEmpty)
        XCTAssertEqual(groups.countedExternalDeviceCount, 1)
    }

    func testUSBDescriptionKeepsTierAndDifferentPortMaximum() {
        let device = USBDevice(
            name: "Keyboard",
            vendor: "Example",
            vendorId: 0x1111,
            productId: 0x2222,
            serialNumber: nil,
            locationId: 1,
            speedMbps: 480,
            portMaxSpeedMbps: 5_000,
            usbVersionBCD: 0x0200,
            isExternalStorage: false
        )

        XCTAssertTrue(device.connectionDescription.hasPrefix("USB 2.0 "))
        XCTAssertTrue(device.connectionDescription.contains("5.0 Gbps"))
        XCTAssertFalse(device.connectionDescription.contains("480 Mbps"))
    }

    func testUSBDescriptionKeepsPortMaximumWhenNegotiatedSpeedIsMissing() {
        let device = USBDevice(
            name: "Device",
            vendor: "Example",
            vendorId: 0x1111,
            productId: 0x2222,
            serialNumber: nil,
            locationId: 1,
            speedMbps: nil,
            portMaxSpeedMbps: 5_000,
            usbVersionBCD: nil,
            isExternalStorage: false
        )

        XCTAssertTrue(device.connectionDescription.contains("5.0 Gbps"))
    }

    func testThunderboltBillboardIsExplicitOptIn() {
        let regularDevice = makeDevice()
        let billboard = USBDevice(
            name: "Thunderbolt4 Mini Dock",
            vendor: "Anker",
            vendorId: 0x291A,
            productId: 0x8358,
            serialNumber: "11AD1D0AB6073C0A31200B00",
            locationId: 0x0215_0000,
            speedMbps: 12,
            portMaxSpeedMbps: nil,
            usbVersionBCD: 0x0201,
            isExternalStorage: false,
            isThunderboltBillboard: true
        )

        XCTAssertFalse(regularDevice.isThunderboltBillboard)
        XCTAssertTrue(billboard.isThunderboltBillboard)
    }

    private func makeDevice(
        name: String = "USB Device",
        vendor: String? = "Example",
        productID: Int = 0x5678,
        locationID: UInt32? = nil,
        portType: Int? = nil,
        deviceClass: Int? = nil,
        thunderboltOwnerID: String? = nil,
        isThunderboltTunneledUSB: Bool = false
    ) -> USBDevice {
        USBDevice(
            name: name,
            vendor: vendor,
            vendorId: 0x1234,
            productId: productID,
            serialNumber: nil,
            locationId: locationID,
            speedMbps: 480,
            portMaxSpeedMbps: nil,
            usbVersionBCD: nil,
            isExternalStorage: false,
            usbPortType: portType,
            deviceClass: deviceClass,
            thunderboltOwnerID: thunderboltOwnerID,
            isThunderboltTunneledUSB: isThunderboltTunneledUSB
        )
    }

    private func makeThunderboltDevice(
        name: String,
        vendor: String,
        identifier: String,
        transportVersion: String = "USB4"
    ) -> USBDevice {
        USBDevice(
            name: name,
            vendor: vendor,
            vendorId: 0x8087,
            productId: 1,
            serialNumber: nil,
            locationId: 1,
            speedMbps: 40_000,
            portMaxSpeedMbps: nil,
            usbVersionBCD: nil,
            isExternalStorage: nil,
            transport: .thunderbolt,
            transportVersion: transportVersion,
            transportIdentifier: identifier
        )
    }
}
