import XCTest

@testable import PortGlance

final class USBDeviceDiscoveryTests: XCTestCase {
    func testIncludesHostAndLegacyDeviceClasses() {
        XCTAssertEqual(
            Set(USBDeviceDiscovery.usbDeviceClassNames),
            Set(["IOUSBHostDevice", "IOUSBDevice"])
        )
    }
}
