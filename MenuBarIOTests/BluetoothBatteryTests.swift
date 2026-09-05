import Foundation
import IOBluetooth
import XCTest

@testable import MenuBarIO

final class BluetoothBatteryTests: XCTestCase {
    private let address = "AA:BB:CC:DD:EE:01"
    private let identifier = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

    func testAddressMatchingRequiresFullExactIdentity() {
        XCTAssertEqual(BluetoothBatteryAddress.normalized(" AA-bb-CC-dd-EE-01 "), "aabbccddee01")
        XCTAssertNil(BluetoothBatteryAddress.normalized("Mouse"))
        XCTAssertNil(BluetoothBatteryAddress.normalized("AA:BB"))
        XCTAssertNil(BluetoothBatteryAddress.normalized("AA:BB:CC:DD:EE:0G"))
        XCTAssertNil(BluetoothBatteryAddress.normalized(nil))
    }

    func testPublishedRegistryPercentageRejectsMalformedAndNonBluetoothValues() throws {
        XCTAssertEqual(try snapshot(level: 0).batteryLevel, 0)
        XCTAssertEqual(try snapshot(level: 100).batteryLevel, 100)
        for value: Any in [-1, 101, 45.5, true, "45", NSNull()] {
            XCTAssertNil(try snapshot(level: value).batteryLevel)
        }
        XCTAssertNil(
            BluetoothBatteryRegistrySnapshot(properties: [
                "Transport": "USB", "DeviceAddress": address, "BatteryPercent": 42,
            ]))
        XCTAssertNil(
            BluetoothBatteryRegistrySnapshot(properties: [
                "Transport": "Bluetooth", "Product": "Mouse", "BatteryPercent": 42,
            ]))
    }

    func testUUIDAssociationRejectsAmbiguousOrDisconnectedDevices() throws {
        let first = try snapshot(level: 45)
        let connected: Set<String> = ["aabbccddee01", "aabbccddee02"]
        XCTAssertEqual(
            BluetoothBatteryRegistrySnapshot.identities(from: [first, first], connectedAddresses: connected),
            [identifier: "aabbccddee01"])
        XCTAssertTrue(
            BluetoothBatteryRegistrySnapshot.identities(
                from: [first], connectedAddresses: []
            ).isEmpty)
        let secondAddress = try snapshot(address: "AA:BB:CC:DD:EE:02", level: 50)
        XCTAssertTrue(
            BluetoothBatteryRegistrySnapshot.identities(
                from: [first, secondAddress], connectedAddresses: connected
            ).isEmpty)
        let secondUUID = try snapshot(identifier: UUID(), level: 50)
        XCTAssertTrue(
            BluetoothBatteryRegistrySnapshot.identities(
                from: [first, secondUUID], connectedAddresses: connected
            ).isEmpty)
    }

    func testStandardBatteryLevelRequiresOneValidByte() {
        XCTAssertEqual(SystemBluetoothBatteryReader.batteryLevel(from: Data([0])), 0)
        XCTAssertEqual(SystemBluetoothBatteryReader.batteryLevel(from: Data([45])), 45)
        XCTAssertEqual(SystemBluetoothBatteryReader.batteryLevel(from: Data([100])), 100)
        for data in [nil, Data(), Data([101]), Data([255]), Data([45, 0])] {
            XCTAssertNil(SystemBluetoothBatteryReader.batteryLevel(from: data))
        }
    }

    func testCacheExpiresRejectsFutureDatesAndClearsMissingOrDisconnectedReadings() {
        let date = Date(timeIntervalSince1970: 1000)
        var cache = BluetoothBatteryCache()
        cache.record(45, for: address, at: date)
        XCTAssertEqual(cache.level(for: "aa-bb-cc-dd-ee-01", at: date), 45)
        XCTAssertNil(cache.level(for: "AA:BB:CC:DD:EE:02", at: date))
        XCTAssertNil(cache.level(for: address, at: date.addingTimeInterval(900)))
        XCTAssertNil(cache.level(for: address, at: date.addingTimeInterval(-1)))
        cache.record(nil, for: address, at: date)
        XCTAssertNil(cache.level(for: address, at: date))
        cache.record(0, for: address, at: date)
        XCTAssertEqual(cache.level(for: address, at: date), 0)
        cache.retain(addresses: [])
        XCTAssertNil(cache.level(for: address, at: date))
    }

    func testInjectedRegistryReaderUpdatesAndOmitsConflictingPercentages() throws {
        var entries = [try snapshot(identifier: nil, level: 45)]
        let reader = SystemBluetoothBatteryReader(registrySnapshots: { entries })
        reader.refresh(connectedAddresses: [address])
        XCTAssertEqual(reader.batteryLevel(for: address), 45)
        entries.append(try snapshot(identifier: nil, level: 80))
        reader.refresh(connectedAddresses: [address])
        XCTAssertNil(reader.batteryLevel(for: address))
        entries = []
        reader.refresh(connectedAddresses: [address])
        XCTAssertNil(reader.batteryLevel(for: address))
    }

    func testManagerPublishesAsynchronousBatteryUpdatesAndClearsOnPowerOff() {
        let reader = BatteryTestDeviceReader(address: address)
        let batteryReader = BatteryTestBatteryReader()
        let manager = BluetoothDeviceManager(
            monitoringEnabled: false, reader: reader, batteryReader: batteryReader)
        manager.refresh()
        XCTAssertNil(manager.devices.first?.batteryLevel)
        batteryReader.level = 45
        batteryReader.onChange?()
        XCTAssertEqual(manager.devices.first?.batteryLevel, 45)
        batteryReader.level = 0
        batteryReader.onChange?()
        XCTAssertEqual(manager.devices.first?.batteryLevel, 0)
        reader.poweredOff = true
        manager.refresh()
        XCTAssertTrue(manager.devices.isEmpty)
        XCTAssertTrue(batteryReader.stopped)
    }

    func testDeviceModelValidatesOptionalPercentage() throws {
        for level in [0, 45, 100] {
            let device = try XCTUnwrap(
                BluetoothDevice(
                    snapshot: .init(
                        identifier: address, name: "Mouse", isConnected: true, batteryLevel: level)))
            XCTAssertEqual(device.batteryLevel, level)
            XCTAssertNil(device.updatingBatteryLevel(101).batteryLevel)
        }
        XCTAssertNil(
            BluetoothDevice(
                snapshot: .init(
                    identifier: address, name: "Mouse", isConnected: true, batteryLevel: -1))?.batteryLevel)
    }

    private func snapshot(
        address: String? = nil,
        identifier: UUID? = UUID(uuidString: "00000000-0000-0000-0000-000000000001"),
        level: Any
    ) throws -> BluetoothBatteryRegistrySnapshot {
        var properties: [String: Any] = [
            "Transport": "Bluetooth Low Energy", "DeviceAddress": address ?? self.address,
            "BatteryPercent": level,
        ]
        if let identifier {
            properties["PhysicalDeviceUniqueID"] = identifier.uuidString
        }
        return try XCTUnwrap(BluetoothBatteryRegistrySnapshot(properties: properties))
    }
}

private final class BatteryTestDeviceReader: BluetoothDeviceReading {
    let address: String
    var poweredOff = false
    init(address: String) { self.address = address }
    func read() -> BluetoothDeviceReadResult {
        BluetoothDeviceReadResult(
            availability: poweredOff ? .poweredOff : .available,
            snapshots: [.init(identifier: address, name: "Mouse", isConnected: !poweredOff)],
            connectedSystemDevices: [:])
    }
}

private final class BatteryTestBatteryReader: BluetoothBatteryReading {
    var onChange: (() -> Void)?
    var level: Int?
    var stopped = false
    func refresh(connectedAddresses: Set<String>) {}
    func batteryLevel(for address: String) -> Int? { level }
    func stop() {
        stopped = true
        level = nil
        onChange?()
    }
}
