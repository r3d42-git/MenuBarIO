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
}
