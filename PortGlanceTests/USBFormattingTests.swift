import XCTest

@testable import PortGlance

final class USBFormattingTests: XCTestCase {
    func testClipboardDeviceFieldsEscapeControlAndBidiCharacters() {
        let rawValue = "USB\n\u{001B}[2J\u{202E}device\u{2028}\u{2066}"

        XCTAssertEqual(
            SystemActions.sanitizedDeviceField(rawValue),
            "USB\\u{000A}\\u{001B}[2J\\u{202E}device\\u{2028}\\u{2066}"
        )
        XCTAssertEqual(SystemActions.sanitizedDeviceField("USB Café 4"), "USB Café 4")
    }

    func testExternalNumericValuesAreValidated() {
        XCTAssertEqual(USBFormatting.chargePercentage(currentCapacity: 50, maximumCapacity: 100), 50)
        XCTAssertEqual(USBFormatting.chargePercentage(currentCapacity: 150, maximumCapacity: 100), 100)
        XCTAssertNil(USBFormatting.chargePercentage(currentCapacity: -1, maximumCapacity: 100))
        XCTAssertNil(USBFormatting.chargePercentage(currentCapacity: 50, maximumCapacity: 0))

        XCTAssertEqual(USBFormatting.megabitsPerSecond(fromBitsPerSecond: 5_000_000_000), 5_000)
        XCTAssertNil(USBFormatting.megabitsPerSecond(fromBitsPerSecond: .nan))
        XCTAssertNil(USBFormatting.megabitsPerSecond(fromBitsPerSecond: .infinity))
        XCTAssertNil(USBFormatting.megabitsPerSecond(fromBitsPerSecond: -1))
        XCTAssertNil(USBFormatting.megabitsPerSecond(fromBitsPerSecond: .greatestFiniteMagnitude))

        XCTAssertEqual(
            USBFormatting.thunderboltMegabitsPerSecond(fromLinkBandwidth: 800),
            80_000
        )
        XCTAssertNil(USBFormatting.thunderboltMegabitsPerSecond(fromLinkBandwidth: Int.max))
    }

    func testDeviceCountRepresentations() {
        XCTAssertEqual(DeviceCountFormatter.string(for: 100, representation: .base10), "99＋")
        XCTAssertEqual(DeviceCountFormatter.string(for: 14, representation: .roman), "XIV")
        XCTAssertEqual(DeviceCountFormatter.string(for: 12, representation: .greek), "ιβ")
        XCTAssertEqual(DeviceCountFormatter.string(for: 12, representation: .egyptian), "𓎆𓏺𓏺")
    }
}
