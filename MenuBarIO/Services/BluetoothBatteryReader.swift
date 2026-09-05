import CoreBluetooth
import Foundation
import IOKit

protocol BluetoothBatteryReading: AnyObject {
    var onChange: (() -> Void)? { get set }
    func refresh(connectedAddresses: Set<String>)
    func batteryLevel(for address: String) -> Int?
    func stop()
}

/// Only a complete Bluetooth address can associate a battery with a listed device.
enum BluetoothBatteryAddress {
    static func normalized(_ address: String?) -> String? {
        guard let address else { return nil }
        let compact = address.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: "-", with: "").lowercased()
        guard compact.utf8.count == 12,
            compact.utf8.allSatisfy({ (48...57).contains($0) || (97...102).contains($0) })
        else { return nil }
        return compact
    }
}

struct BluetoothBatteryRegistrySnapshot {
    let address: String
    let peripheralIdentifier: UUID?
    let batteryLevel: Int?

    init?(properties: [String: Any]) {
        guard let transport = properties["Transport"] as? String,
            ["Bluetooth", "Bluetooth Low Energy", "BluetoothLowEnergy"].contains(transport),
            let address = BluetoothBatteryAddress.normalized(properties["DeviceAddress"] as? String)
        else { return nil }
        self.address = address
        peripheralIdentifier = (properties["PhysicalDeviceUniqueID"] as? String).flatMap(UUID.init)
        batteryLevel = Self.percentage(properties["BatteryPercent"])
    }

    static func percentage(_ value: Any?) -> Int? {
        guard let number = value as? NSNumber,
            CFGetTypeID(number) != CFBooleanGetTypeID(),
            number.doubleValue.isFinite,
            (0...100).contains(number.doubleValue),
            number.doubleValue.rounded() == number.doubleValue
        else { return nil }
        return number.intValue
    }

    /// Reject both shared UUIDs and multiple UUIDs for one address. Names never participate.
    static func identities(
        from snapshots: [Self], connectedAddresses: Set<String>
    ) -> [UUID: String] {
        var addressesByIdentifier: [UUID: Set<String>] = [:]
        var identifiersByAddress: [String: Set<UUID>] = [:]
        for snapshot in snapshots where connectedAddresses.contains(snapshot.address) {
            guard let identifier = snapshot.peripheralIdentifier else { continue }
            addressesByIdentifier[identifier, default: []].insert(snapshot.address)
            identifiersByAddress[snapshot.address, default: []].insert(identifier)
        }
        return addressesByIdentifier.reduce(into: [:]) { result, entry in
            guard entry.value.count == 1, let address = entry.value.first,
                identifiersByAddress[address]?.count == 1
            else { return }
            result[entry.key] = address
        }
    }
}

struct BluetoothBatteryCache {
    private struct Sample {
        let level: Int
        let observedAt: Date
    }
    private var samples: [String: Sample] = [:]

    mutating func record(_ level: Int?, for address: String, at date: Date) {
        guard let address = BluetoothBatteryAddress.normalized(address) else { return }
        guard let level, (0...100).contains(level) else {
            samples.removeValue(forKey: address)
            return
        }
        samples[address] = Sample(level: level, observedAt: date)
    }

    func level(for address: String, at date: Date, maximumAge: TimeInterval = 900) -> Int? {
        guard let address = BluetoothBatteryAddress.normalized(address),
            let sample = samples[address]
        else { return nil }
        let age = date.timeIntervalSince(sample.observedAt)
        return age >= 0 && age < maximumAge ? sample.level : nil
    }

    mutating func retain(addresses: Set<String>) {
        samples = samples.filter { addresses.contains($0.key) }
    }
}

/// Reads published HID percentages and the standard BLE Battery Service on devices
/// already connected to macOS. It never scans, pairs, writes a characteristic or opens HID input.
final class SystemBluetoothBatteryReader: NSObject, BluetoothBatteryReading,
    CBCentralManagerDelegate, CBPeripheralDelegate
{
    var onChange: (() -> Void)?

    private static let batteryService = CBUUID(string: "180F")
    private static let batteryLevelCharacteristic = CBUUID(string: "2A19")
    private let registrySnapshots: () -> [BluetoothBatteryRegistrySnapshot]
    private let now: () -> Date
    private var central: CBCentralManager?
    private var addresses: Set<String> = []
    private var identities: [UUID: String] = [:]
    private var registryLevels: [String: Int] = [:]
    private var cache = BluetoothBatteryCache()
    private var lastAttempts: [UUID: Date] = [:]
    private var requests: [UUID: CBPeripheral] = [:]
    private var requestAddresses: [UUID: String] = [:]
    private var timeouts: [UUID: DispatchWorkItem] = [:]

    init(
        registrySnapshots: @escaping () -> [BluetoothBatteryRegistrySnapshot] = SystemBluetoothBatteryReader
            .readRegistry,
        now: @escaping () -> Date = Date.init
    ) {
        self.registrySnapshots = registrySnapshots
        self.now = now
        super.init()
    }

    func batteryLevel(for address: String) -> Int? {
        guard let address = BluetoothBatteryAddress.normalized(address), addresses.contains(address)
        else { return nil }
        return registryLevels[address] ?? cache.level(for: address, at: now())
    }

    func refresh(connectedAddresses: Set<String>) {
        addresses = Set(connectedAddresses.compactMap(BluetoothBatteryAddress.normalized))
        cache.retain(addresses: addresses)
        let snapshots = addresses.isEmpty ? [] : registrySnapshots()
        identities = BluetoothBatteryRegistrySnapshot.identities(
            from: snapshots, connectedAddresses: addresses)

        let grouped = Dictionary(grouping: snapshots.filter { addresses.contains($0.address) }, by: \.address)
        registryLevels = grouped.reduce(into: [:]) { result, entry in
            let levels = Set(entry.value.compactMap(\.batteryLevel))
            if levels.count == 1 { result[entry.key] = levels.first }
        }
        for identifier in Array(requests.keys) where identities[identifier] != requestAddresses[identifier] {
            finish(identifier, level: nil)
        }
        lastAttempts = lastAttempts.filter { identities[$0.key] != nil }
        onChange?()

        guard !identities.isEmpty else { return }
        // IOBluetooth already handles the app's Bluetooth permission. Do not create a new
        // permission prompt merely to enrich a row, including when running unattended.
        guard CBManager.authorization == .allowedAlways else { return }
        if central == nil {
            central = CBCentralManager(
                delegate: self, queue: .main,
                options: [CBCentralManagerOptionShowPowerAlertKey: false])
        } else {
            requestAvailableBatteries()
        }
    }

    func stop() {
        for timeout in timeouts.values { timeout.cancel() }
        timeouts.removeAll()
        let peripherals = Array(requests.values)
        requests.removeAll()
        requestAddresses.removeAll()
        for peripheral in peripherals {
            peripheral.delegate = nil
            central?.cancelPeripheralConnection(peripheral)
        }
        addresses.removeAll()
        identities.removeAll()
        registryLevels.removeAll()
        lastAttempts.removeAll()
        cache = BluetoothBatteryCache()
        onChange?()
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            requestAvailableBatteries()
        } else {
            for identifier in Array(requests.keys) { finish(identifier, level: nil) }
            cache = BluetoothBatteryCache()
            onChange?()
        }
    }

    private func requestAvailableBatteries() {
        guard let central, central.state == .poweredOn else { return }
        let timestamp = now()
        let connected = central.retrieveConnectedPeripherals(withServices: [Self.batteryService])
        for peripheral in connected {
            let identifier = peripheral.identifier
            guard let address = identities[identifier], addresses.contains(address),
                registryLevels[address] == nil, requests[identifier] == nil,
                lastAttempts[identifier].map({ timestamp.timeIntervalSince($0) >= 300 }) ?? true
            else { continue }
            lastAttempts[identifier] = timestamp
            requests[identifier] = peripheral
            requestAddresses[identifier] = address
            peripheral.delegate = self
            let timeout = DispatchWorkItem { [weak self] in self?.finish(identifier, level: nil) }
            timeouts[identifier] = timeout
            DispatchQueue.main.asyncAfter(deadline: .now() + 10, execute: timeout)
            // A client reference to an existing system connection is required to read GATT.
            // Releasing that reference below does not disconnect other macOS clients.
            central.connect(peripheral)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        guard requests[peripheral.identifier] != nil else { return }
        peripheral.discoverServices([Self.batteryService])
    }

    func centralManager(
        _ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?
    ) {
        finish(peripheral.identifier, level: nil)
    }

    func centralManager(
        _ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?
    ) {
        finish(peripheral.identifier, level: nil)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard requests[peripheral.identifier] != nil else { return }
        let services = peripheral.services?.filter { $0.uuid == Self.batteryService } ?? []
        guard error == nil, services.count == 1, let service = services.first else {
            finish(peripheral.identifier, level: nil)
            return
        }
        peripheral.discoverCharacteristics([Self.batteryLevelCharacteristic], for: service)
    }

    func peripheral(
        _ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?
    ) {
        guard requests[peripheral.identifier] != nil else { return }
        let characteristics =
            service.characteristics?.filter {
                $0.uuid == Self.batteryLevelCharacteristic && $0.properties.contains(.read)
            } ?? []
        guard error == nil, characteristics.count == 1, let characteristic = characteristics.first else {
            finish(peripheral.identifier, level: nil)
            return
        }
        peripheral.readValue(for: characteristic)
    }

    func peripheral(
        _ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?
    ) {
        guard characteristic.uuid == Self.batteryLevelCharacteristic else { return }
        let level = error == nil ? Self.batteryLevel(from: characteristic.value) : nil
        finish(peripheral.identifier, level: level)
    }

    static func batteryLevel(from data: Data?) -> Int? {
        guard let data, data.count == 1, let value = data.first, value <= 100 else { return nil }
        return Int(value)
    }

    private func finish(_ identifier: UUID, level: Int?) {
        guard let peripheral = requests.removeValue(forKey: identifier) else { return }
        timeouts.removeValue(forKey: identifier)?.cancel()
        if let address = requestAddresses.removeValue(forKey: identifier),
            identities[identifier] == address, addresses.contains(address)
        {
            cache.record(level, for: address, at: now())
        }
        peripheral.delegate = nil
        central?.cancelPeripheralConnection(peripheral)
        onChange?()
    }

    private static func readRegistry() -> [BluetoothBatteryRegistrySnapshot] {
        var snapshots: [BluetoothBatteryRegistrySnapshot] = []
        for className in ["IOHIDDevice", "IOHIDEventService"] {
            var iterator: io_iterator_t = 0
            guard
                IOServiceGetMatchingServices(
                    kIOMainPortDefault, IOServiceMatching(className), &iterator) == KERN_SUCCESS
            else { continue }
            defer { IOObjectRelease(iterator) }
            while case let entry = IOIteratorNext(iterator), entry != 0 {
                defer { IOObjectRelease(entry) }
                var properties: [String: Any] = [:]
                for key in ["Transport", "DeviceAddress", "PhysicalDeviceUniqueID"] {
                    if let value = IORegistryEntrySearchCFProperty(
                        entry, kIOServicePlane, key as CFString, nil,
                        IOOptionBits(kIORegistryIterateRecursively | kIORegistryIterateParents))
                    {
                        properties[key] = value
                    }
                }
                if let value = IORegistryEntryCreateCFProperty(
                    entry, "BatteryPercent" as CFString, nil, 0)?.takeRetainedValue()
                {
                    properties["BatteryPercent"] = value
                }
                if let snapshot = BluetoothBatteryRegistrySnapshot(properties: properties) {
                    snapshots.append(snapshot)
                }
            }
        }
        return snapshots
    }
}
