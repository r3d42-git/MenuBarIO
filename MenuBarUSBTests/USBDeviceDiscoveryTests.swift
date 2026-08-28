import XCTest

@testable import MenuBarUSB

final class USBDeviceDiscoveryTests: XCTestCase {
    func testIncludesHostAndLegacyDeviceClasses() {
        XCTAssertEqual(
            Set(USBDeviceDiscovery.usbDeviceClassNames),
            Set(["IOUSBHostDevice", "IOUSBDevice"])
        )
    }
}
