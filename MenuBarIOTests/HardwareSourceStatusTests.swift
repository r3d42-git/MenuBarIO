import Combine
import XCTest

@testable import MenuBarIO

final class HardwareSourceStatusTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    func testValidEmptyUSBResultBecomesReady() {
        let timestamp = Date(timeIntervalSince1970: 100)
        let discovery = SequencedUSBDiscovery([
            USBTopologySnapshot(
                devices: [],
                thunderboltPorts: [],
                externalThunderboltPortGroups: []
            )
        ])
        let manager = USBDeviceManager(
            monitoringEnabled: false,
            discovery: discovery,
            now: { timestamp }
        )
        let ready = expectation(description: "Ready status published")

        manager.$sourceStatus
            .dropFirst()
            .sink { status in
                if status == .ready(lastUpdated: timestamp) {
                    ready.fulfill()
                }
            }
            .store(in: &cancellables)

        manager.refresh()
        wait(for: [ready], timeout: 2)
        XCTAssertTrue(manager.devices.isEmpty)
    }

    func testFailedUSBRefreshPreservesLastSuccessfulSnapshotAsStale() {
        let timestamp = Date(timeIntervalSince1970: 200)
        let device = makeUSBDevice(name: "Camera", serialNumber: "SERIAL")
        let discovery = SequencedUSBDiscovery([
            USBTopologySnapshot(
                devices: [device],
                thunderboltPorts: [],
                externalThunderboltPortGroups: []
            ),
            USBTopologySnapshot(
                devices: [],
                thunderboltPorts: [],
                externalThunderboltPortGroups: [],
                isComplete: false
            ),
        ])
        let manager = USBDeviceManager(
            monitoringEnabled: false,
            discovery: discovery,
            now: { timestamp }
        )

        waitForUSBStatus(.ready(lastUpdated: timestamp), manager: manager)
        XCTAssertEqual(manager.devices, [device])

        waitForUSBStatus(.stale(lastUpdated: timestamp), manager: manager)
        XCTAssertEqual(manager.devices, [device])
    }

    func testInitialUSBFailureBecomesUnavailable() {
        let discovery = SequencedUSBDiscovery([
            USBTopologySnapshot(
                devices: [],
                thunderboltPorts: [],
                externalThunderboltPortGroups: [],
                isComplete: false
            )
        ])
        let manager = USBDeviceManager(monitoringEnabled: false, discovery: discovery)

        waitForUSBStatus(.unavailable(.discoveryFailed), manager: manager)
    }

    func testBluetoothPoweredOffIsNotReportedAsReadyWithZeroDevices() {
        let reader = SequencedBluetoothReader([
            BluetoothDeviceReadResult(
                availability: .poweredOff,
                snapshots: [],
                connectedSystemDevices: [:]
            )
        ])
        let manager = BluetoothDeviceManager(monitoringEnabled: false, reader: reader)

        manager.refresh()

        XCTAssertEqual(manager.sourceStatus, .unavailable(.bluetoothPoweredOff))
        XCTAssertTrue(manager.devices.isEmpty)
    }

    func testBluetoothFailurePreservesLastSuccessfulDevicesAsStale() throws {
        let timestamp = Date(timeIntervalSince1970: 300)
        let snapshot = BluetoothDevice.Snapshot(
            identifier: "AA:BB",
            name: "Mouse",
            isConnected: true
        )
        let reader = SequencedBluetoothReader([
            BluetoothDeviceReadResult(
                availability: .available,
                snapshots: [snapshot],
                connectedSystemDevices: [:]
            ),
            BluetoothDeviceReadResult(
                availability: .unavailable,
                snapshots: [],
                connectedSystemDevices: [:]
            ),
        ])
        let manager = BluetoothDeviceManager(
            monitoringEnabled: false,
            reader: reader,
            now: { timestamp }
        )

        manager.refresh()
        XCTAssertEqual(manager.sourceStatus, .ready(lastUpdated: timestamp))
        XCTAssertEqual(manager.devices.map(\.name), ["Mouse"])

        manager.refresh()
        XCTAssertEqual(manager.sourceStatus, .stale(lastUpdated: timestamp))
        XCTAssertEqual(manager.devices.map(\.name), ["Mouse"])
    }

    private func waitForUSBStatus(
        _ expectedStatus: HardwareSourceStatus,
        manager: USBDeviceManager
    ) {
        let published = expectation(description: "USB status \(expectedStatus) published")
        manager.$sourceStatus
            .dropFirst()
            .sink { status in
                if status == expectedStatus {
                    published.fulfill()
                }
            }
            .store(in: &cancellables)

        manager.refresh()
        wait(for: [published], timeout: 2)
    }

    private func makeUSBDevice(name: String, serialNumber: String?) -> USBDevice {
        USBDevice(
            name: name,
            vendor: "Vendor",
            vendorId: 1,
            productId: 2,
            serialNumber: serialNumber,
            locationId: 0x0100_0000,
            speedMbps: 480,
            portMaxSpeedMbps: 5_000,
            usbVersionBCD: 0x0200,
            isExternalStorage: false
        )
    }
}

private final class SequencedUSBDiscovery: USBDeviceDiscovering {
    private let lock = NSLock()
    private var snapshots: [USBTopologySnapshot]

    init(_ snapshots: [USBTopologySnapshot]) {
        self.snapshots = snapshots
    }

    func connectedTopology() -> USBTopologySnapshot {
        lock.lock()
        defer { lock.unlock() }
        precondition(!snapshots.isEmpty)
        return snapshots.removeFirst()
    }
}

private final class SequencedBluetoothReader: BluetoothDeviceReading {
    private var results: [BluetoothDeviceReadResult]

    init(_ results: [BluetoothDeviceReadResult]) {
        self.results = results
    }

    func read() -> BluetoothDeviceReadResult {
        precondition(!results.isEmpty)
        return results.removeFirst()
    }
}
