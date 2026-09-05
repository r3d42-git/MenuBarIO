import Combine
import XCTest

@testable import MenuBarIO

final class EthernetLinkMonitoringTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []
    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "MenuBarIOTests.Ethernet.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        defaults.set(true, forKey: StorageKeys.showEthernet)
    }

    override func tearDown() {
        cancellables.removeAll()
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    func testCableOnlyTransitionsRefreshEthernetWithoutUSBDiscovery() {
        let reader = TestEthernetReader(isConnected: true)
        let monitor = TestEthernetMonitor()
        let discovery = CountingEthernetTestDiscovery()
        let manager = USBDeviceManager(
            defaults: defaults,
            discovery: discovery,
            ethernetReader: reader,
            ethernetMonitor: monitor
        )

        waitForEthernet(true, manager: manager)
        let ready = expectation(description: "Initial USB discovery completes")
        manager.$sourceStatus.sink { status in
            if case .ready = status { ready.fulfill() }
        }.store(in: &cancellables)
        wait(for: [ready], timeout: 2)
        let initialDiscoveryCount = discovery.readCount

        reader.connected = false
        monitor.sendChange()
        waitForEthernet(false, manager: manager)
        reader.connected = true
        monitor.sendChange()
        waitForEthernet(true, manager: manager)

        XCTAssertEqual(discovery.readCount, initialDiscoveryCount)
        XCTAssertEqual(monitor.startCount, 1)
    }

    func testToggleStopsAndRestartsNotificationsAndClearsTheIndicator() {
        let reader = TestEthernetReader(isConnected: true)
        let monitor = TestEthernetMonitor()
        let manager = USBDeviceManager(
            defaults: defaults,
            discovery: CountingEthernetTestDiscovery(),
            ethernetReader: reader,
            ethernetMonitor: monitor
        )
        waitForEthernet(true, manager: manager)
        let oldCallback = monitor.onChange

        manager.setEthernetIndicatorEnabled(false)
        XCTAssertFalse(manager.ethernetCableConnected)
        XCTAssertNil(monitor.onChange)
        XCTAssertFalse(defaults.bool(forKey: StorageKeys.showEthernet))
        oldCallback?()
        XCTAssertFalse(manager.ethernetCableConnected)

        manager.setEthernetIndicatorEnabled(true)
        waitForEthernet(true, manager: manager)
        XCTAssertEqual(monitor.startCount, 2)
        XCTAssertNotNil(monitor.onChange)
    }

    func testDisabledAutomaticMonitoringStillAllowsExplicitRefreshWithoutRegistration() {
        let reader = TestEthernetReader(isConnected: true)
        let monitor = TestEthernetMonitor()
        let manager = USBDeviceManager(
            monitoringEnabled: false,
            defaults: defaults,
            discovery: CountingEthernetTestDiscovery(),
            ethernetReader: reader,
            ethernetMonitor: monitor
        )
        XCTAssertEqual(reader.readCount, 0)
        manager.refresh()
        waitForEthernet(true, manager: manager)
        manager.setEthernetIndicatorEnabled(false)
        manager.setEthernetIndicatorEnabled(true)
        waitForEthernet(true, manager: manager)
        XCTAssertEqual(monitor.startCount, 0)
    }

    func testDisabledIndicatorDoesNotRegisterOrReadEthernet() {
        defaults.set(false, forKey: StorageKeys.showEthernet)
        let reader = TestEthernetReader(isConnected: true)
        let monitor = TestEthernetMonitor()
        let manager = USBDeviceManager(
            monitoringEnabled: false,
            defaults: defaults,
            discovery: CountingEthernetTestDiscovery(),
            ethernetReader: reader,
            ethernetMonitor: monitor
        )
        manager.refresh()
        XCTAssertFalse(manager.ethernetCableConnected)
        XCTAssertEqual(reader.readCount, 0)
        XCTAssertEqual(monitor.startCount, 0)
    }

    func testInFlightReadCannotRestoreIndicatorAfterDisabling() {
        let started = expectation(description: "Ethernet read started")
        let releaseRead = DispatchSemaphore(value: 0)
        let reader = TestEthernetReader(isConnected: true) {
            started.fulfill()
            _ = releaseRead.wait(timeout: .now() + 2)
        }
        let manager = USBDeviceManager(
            monitoringEnabled: false,
            defaults: defaults,
            discovery: CountingEthernetTestDiscovery(),
            ethernetReader: reader,
            ethernetMonitor: TestEthernetMonitor()
        )
        manager.refresh()
        wait(for: [started], timeout: 2)
        manager.setEthernetIndicatorEnabled(false)

        let stalePublication = expectation(description: "Disabled indicator stays clear")
        stalePublication.isInverted = true
        manager.$ethernetCableConnected.sink { connected in
            if connected { stalePublication.fulfill() }
        }.store(in: &cancellables)
        releaseRead.signal()
        wait(for: [stalePublication], timeout: 0.2)
        XCTAssertFalse(manager.ethernetCableConnected)
    }

    func testManagerDeallocationStopsAndReleasesNotificationCallback() {
        let monitor = TestEthernetMonitor()
        var manager: USBDeviceManager? = USBDeviceManager(
            defaults: defaults,
            discovery: CountingEthernetTestDiscovery(),
            ethernetReader: TestEthernetReader(isConnected: true),
            ethernetMonitor: monitor
        )
        waitForEthernet(true, manager: manager!)
        let ready = expectation(description: "Initial USB discovery completes")
        let cancellable = manager!.$sourceStatus
            .filter { status in
                if case .ready = status { return true }
                return false
            }
            .prefix(1)
            .sink { _ in ready.fulfill() }
        wait(for: [ready], timeout: 2)
        cancellable.cancel()
        XCTAssertNotNil(monitor.onChange)
        weak var weakManager = manager
        manager = nil
        XCTAssertNil(weakManager)
        XCTAssertEqual(monitor.stopCount, 1)
        XCTAssertNil(monitor.onChange)
    }

    func testReadFromBeforeDisableAndReenableCannotPublishOldConnectionState() {
        let started = expectation(description: "First Ethernet read started")
        let releaseRead = DispatchSemaphore(value: 0)
        var invocation = 0
        let reader = TestEthernetReader(isConnected: true) {
            invocation += 1
            if invocation == 1 {
                started.fulfill()
                _ = releaseRead.wait(timeout: .now() + 2)
            }
        }
        let manager = USBDeviceManager(
            monitoringEnabled: false,
            defaults: defaults,
            discovery: CountingEthernetTestDiscovery(),
            ethernetReader: reader,
            ethernetMonitor: TestEthernetMonitor()
        )
        manager.refresh()
        wait(for: [started], timeout: 2)
        manager.setEthernetIndicatorEnabled(false)
        reader.connected = false
        manager.setEthernetIndicatorEnabled(true)

        let stalePublication = expectation(description: "Earlier connected read is discarded")
        stalePublication.isInverted = true
        manager.$ethernetCableConnected.sink { connected in
            if connected { stalePublication.fulfill() }
        }.store(in: &cancellables)
        let currentPublication = expectation(description: "Current disconnected read publishes")
        manager.$ethernetCableConnected.dropFirst().filter { !$0 }.prefix(1)
            .sink { _ in currentPublication.fulfill() }.store(in: &cancellables)

        releaseRead.signal()
        wait(for: [currentPublication, stalePublication], timeout: 0.3)
        XCTAssertFalse(manager.ethernetCableConnected)
    }

    private func waitForEthernet(_ connected: Bool, manager: USBDeviceManager) {
        if manager.ethernetCableConnected == connected { return }
        let published = expectation(description: "Ethernet becomes \(connected)")
        let cancellable = manager.$ethernetCableConnected
            .filter { $0 == connected }
            .prefix(1)
            .sink { _ in published.fulfill() }
        wait(for: [published], timeout: 2)
        cancellable.cancel()
    }
}

private final class TestEthernetMonitor: EthernetLinkMonitoring {
    var onChange: (() -> Void)?
    private(set) var startCount = 0
    private(set) var stopCount = 0

    func start(onChange: @escaping () -> Void) -> Bool {
        startCount += 1
        self.onChange = onChange
        return true
    }

    func stop() {
        stopCount += 1
        onChange = nil
    }

    func sendChange() {
        onChange?()
    }
}

private final class TestEthernetReader: EthernetLinkReading {
    private let lock = NSLock()
    private var value: Bool
    private var reads = 0
    private let beforeRead: (() -> Void)?

    init(isConnected: Bool, beforeRead: (() -> Void)? = nil) {
        value = isConnected
        self.beforeRead = beforeRead
    }

    var connected: Bool {
        get {
            lock.lock()
            defer { lock.unlock() }
            return value
        }
        set {
            lock.lock()
            value = newValue
            lock.unlock()
        }
    }

    var readCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return reads
    }

    func isConnected() -> Bool {
        lock.lock()
        reads += 1
        let result = value
        lock.unlock()
        beforeRead?()
        return result
    }
}

private final class CountingEthernetTestDiscovery: USBDeviceDiscovering {
    private let lock = NSLock()
    private var reads = 0

    var readCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return reads
    }

    func connectedTopology() -> USBTopologySnapshot {
        lock.lock()
        reads += 1
        lock.unlock()
        return USBTopologySnapshot(
            devices: [], thunderboltPorts: [], externalThunderboltPortGroups: []
        )
    }
}
