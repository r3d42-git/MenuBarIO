import XCTest

@testable import MenuBarUSB

final class BluetoothDeviceTests: XCTestCase {
    func testFiltersDisconnectedDevicesSortsAndDeduplicates() {
        let devices = BluetoothDevice.connectedDevices(from: [
            .init(identifier: "AA:BB", name: "Zebra Mouse", isConnected: true),
            .init(identifier: "CC:DD", name: "Alpha Keyboard", isConnected: true),
            .init(identifier: "EE:FF", name: "Offline Headphones", isConnected: false),
            .init(identifier: "AA:BB", name: "Zebra Mouse", isConnected: true),
        ])

        XCTAssertEqual(devices.map(\.name), ["Alpha Keyboard", "Zebra Mouse"])
        XCTAssertEqual(devices.map(\.id), ["bluetooth-cc:dd", "bluetooth-aa:bb"])
    }

    func testUsesStableNameFallbackWhenAddressIsUnavailable() throws {
        let device = try XCTUnwrap(
            BluetoothDevice(
                snapshot: .init(
                    identifier: nil,
                    name: "Logi M650 L",
                    isConnected: true
                )))

        XCTAssertEqual(device.id, "bluetooth-name-logi m650 l")
        XCTAssertEqual(device.name, "Logi M650 L")
        XCTAssertEqual(device.icon, .system("computermouse"))
    }

    func testUsesMatchingIconsForAirPodsAndDeviceClasses() throws {
        let airPods = try XCTUnwrap(
            BluetoothDevice(
                snapshot: .init(
                    identifier: "AA:BB",
                    name: "AirPods",
                    isConnected: true,
                    deviceClassMajor: 0x04,
                    deviceClassMinor: 0x06
                )))
        let speaker = try XCTUnwrap(
            BluetoothDevice(
                snapshot: .init(
                    identifier: "CC:DD",
                    name: "JBL Soundgear Clips",
                    isConnected: true,
                    deviceClassMajor: 0x04,
                    deviceClassMinor: 0x05
                )))
        let unknown = try XCTUnwrap(
            BluetoothDevice(
                snapshot: .init(
                    identifier: "EE:FF",
                    name: "Unknown Device",
                    isConnected: true
                )))

        XCTAssertEqual(airPods.icon, .system("airpods"))
        XCTAssertEqual(speaker.icon, .system("speaker.wave.2"))
        XCTAssertEqual(unknown.icon, .bluetoothTemplate)
    }
}
