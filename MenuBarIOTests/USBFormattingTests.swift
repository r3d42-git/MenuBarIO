import XCTest

@testable import MenuBarIO

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

    func testSpeedTierAndTransferRateHaveSeparateDisplayRoles() {
        XCTAssertEqual(
            USBFormatting.speedTierLabel(for: 5_000),
            "USB 3.0 / 3.1 Gen1 / 3.2 Gen1x1"
        )
        XCTAssertEqual(USBFormatting.speedTierLabel(for: 7_500), "USB")
        XCTAssertEqual(USBFormatting.transferRate(5_000), "5.0 Gbps")
        XCTAssertEqual(USBFormatting.transferRate(1), "1.5 Mbps")
        XCTAssertEqual(USBFormatting.transferRate(2), "1.5 Mbps")
    }

    func testThunderboltProtocolLabelsDistinguishUSB4Generations() {
        XCTAssertEqual(
            USBFormatting.thunderboltProtocolLabel(for: 64),
            "Thunderbolt 5 / USB4 v2"
        )
        XCTAssertEqual(
            USBFormatting.thunderboltProtocolLabel(for: 32),
            "Thunderbolt 3/4 / USB4"
        )
        XCTAssertEqual(
            USBFormatting.thunderboltProtocolLabel(for: nil),
            "Thunderbolt/USB4"
        )
    }

    func testDeviceCountFormatting() {
        XCTAssertEqual(DeviceCountFormatter.string(for: 7), "7")
        XCTAssertEqual(DeviceCountFormatter.string(for: 100), "99＋")
    }

    func testBoostNormalizationRequiresBothKnownProtocolAndAsymmetricMaximum() {
        func port(_ protocolVersion: Int?, _ maximum: Int?) -> ThunderboltPort {
            ThunderboltPort(
                id: "host", controllerID: 0, connectorNumber: 1,
                protocolVersion: protocolVersion, maximumSpeedMbps: maximum, connectedDevice: nil)
        }
        XCTAssertEqual(port(64, 120_000).standardMaximumSpeedMbps, 80_000)
        XCTAssertEqual(port(64, 120_000).bandwidthBoostSpeedMbps, 120_000)
        XCTAssertEqual(port(64, 80_000).standardMaximumSpeedMbps, 80_000)
        XCTAssertNil(port(64, 80_000).bandwidthBoostSpeedMbps)
        XCTAssertEqual(port(nil, 120_000).standardMaximumSpeedMbps, 120_000)
        XCTAssertNil(port(nil, 120_000).bandwidthBoostSpeedMbps)
        XCTAssertNil(port(64, nil).standardMaximumSpeedMbps)
    }
}
