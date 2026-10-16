import XCTest

@testable import MenuBarIO

final class USBDeviceDiscoveryTests: XCTestCase {
    func testIncludesHostAndLegacyDeviceClasses() {
        XCTAssertEqual(
            Set(USBDeviceDiscovery.usbDeviceClassNames),
            Set(["IOUSBHostDevice", "IOUSBDevice"])
        )
    }

    func testReadsExplicitUSBCSocketInsteadOfLogicalUSBPortOrController() {
        XCTAssertEqual(
            USBDeviceDiscovery.directUSBHostConnectorNumber(
                portProperties: ["UsbCPortNumber": 1, "PortNumber": 2, "locationID": 0x0020_0000]
            ), 1
        )
        XCTAssertNil(
            USBDeviceDiscovery.directUSBHostConnectorNumber(
                portProperties: ["PortNumber": 1, "locationID": 0x0020_0000]
            )
        )
        for invalid in [0, -1] {
            XCTAssertNil(
                USBDeviceDiscovery.directUSBHostConnectorNumber(portProperties: ["UsbCPortNumber": invalid])
            )
        }
    }

    func testFollowsPhysicalIOPortReferenceOnNewerHosts() {
        let logicalPort: [String: Any] = [
            "UsbIOPort": "IOService:/platform/Port-USB-C@2",
            "PortNumber": 1, "locationID": 0x0120_0000,
        ]
        let physicalPort: [String: Any] = [
            "BuiltIn": true, "PortTypeDescription": "USB-C", "PortNumber": 2,
        ]
        XCTAssertEqual(
            USBDeviceDiscovery.directUSBHostConnectorNumber(
                portProperties: logicalPort, referencedPortProperties: physicalPort), 2)
        XCTAssertNil(USBDeviceDiscovery.directUSBHostConnectorNumber(portProperties: logicalPort))
        XCTAssertNil(
            USBDeviceDiscovery.directUSBHostConnectorNumber(
                portProperties: ["PortNumber": 2], referencedPortProperties: physicalPort))

        for replacement: [String: Any] in [
            ["BuiltIn": false], ["BuiltIn": NSNull()],
            ["PortTypeDescription": "USB-A"], ["PortNumber": 0], ["PortNumber": -1],
        ] {
            let invalid = physicalPort.merging(replacement) { _, new in new }
            XCTAssertNil(
                USBDeviceDiscovery.directUSBHostConnectorNumber(
                    portProperties: logicalPort, referencedPortProperties: invalid))
        }
        XCTAssertEqual(
            USBDeviceDiscovery.directUSBHostConnectorNumber(
                portProperties: logicalPort.merging(["UsbCPortNumber": 3]) { _, new in new },
                referencedPortProperties: physicalPort), 3)
    }
}
