import XCTest

@testable import MenuBarIO

final class USBDeviceDiscoveryTests: XCTestCase {
    func testIncludesHostAndLegacyDeviceClasses() {
        XCTAssertEqual(
            Set(USBDeviceDiscovery.usbDeviceClassNames),
            Set(["IOUSBHostDevice", "IOUSBDevice"])
        )
    }
}
