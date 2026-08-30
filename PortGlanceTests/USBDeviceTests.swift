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

    func testGroupsClassifyExternalInternalAndHubDevicesOnce() {
        let externalDevice = makeDevice(productID: 1)
        let internalDevice = makeDevice(
            productID: 2,
            portType: Int(kIOUSBHostPortTypeInternal.rawValue)
        )
        let hub = makeDevice(productID: 3, deviceClass: 9)

        let groups = USBDeviceGroups(devices: [externalDevice, internalDevice, hub])

        XCTAssertEqual(groups.externalDevices.map(\.id), [externalDevice.id])
        XCTAssertEqual(groups.internalDevices.map(\.id), [internalDevice.id])
        XCTAssertEqual(groups.hubs.map(\.id), [hub.id])
    }

    func testThunderboltDescriptionUsesNegotiatedLinkSpeed() {
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

        XCTAssertEqual(device.connectionDescription, "Thunderbolt/USB4 — 80.0 Gbps")
        XCTAssertEqual(device.id, "thunderbolt-4369-8738-ABC")
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
        productID: Int = 0x5678,
        locationID: UInt32? = nil,
        portType: Int? = nil,
        deviceClass: Int? = nil
    ) -> USBDevice {
        USBDevice(
            name: "USB Device",
            vendor: "Example",
            vendorId: 0x1234,
            productId: productID,
            serialNumber: nil,
            locationId: locationID,
            speedMbps: 480,
            portMaxSpeedMbps: nil,
            usbVersionBCD: nil,
            isExternalStorage: false,
            usbPortType: portType,
            deviceClass: deviceClass
        )
    }
}
