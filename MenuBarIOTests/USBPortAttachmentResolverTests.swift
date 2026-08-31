import XCTest

@testable import MenuBarIO

final class USBPortAttachmentResolverTests: XCTestCase {
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
        parentHubPortNumber: Int? = nil
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
            deviceClass: deviceClass,
            isThunderboltTunneledUSB: isThunderboltTunneledUSB,
            parentHubLocationId: parentHubLocationID,
            parentHubPortNumber: parentHubPortNumber
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
