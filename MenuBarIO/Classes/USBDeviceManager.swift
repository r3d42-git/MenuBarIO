import Combine
import Foundation

struct DeviceRefreshCoordinator {
    enum Completion: Equatable {
        case publish
        case refresh(Int)
    }

    private(set) var latestGeneration = 0
    private(set) var isRefreshInFlight = false

    mutating func requestRefresh() -> Int? {
        latestGeneration &+= 1

        guard !isRefreshInFlight else { return nil }
        isRefreshInFlight = true
        return latestGeneration
    }

    mutating func completeRefresh(_ generation: Int) -> Completion {
        guard generation != latestGeneration else {
            isRefreshInFlight = false
            return .publish
        }
        return .refresh(latestGeneration)
    }

    func isCurrent(_ generation: Int) -> Bool {
        generation == latestGeneration
    }
}

final class USBDeviceManager: ObservableObject {
    @Published private(set) var devices: [USBDevice] = []
    @Published private(set) var thunderboltPorts: [ThunderboltPort] = []
    @Published private(set) var externalThunderboltPortGroups: [ExternalThunderboltPortGroup] = []
    @Published private(set) var chargeConnected = false
    @Published private(set) var chargePercentage: Int?
    @Published private(set) var batteryIsCharging = false
    @Published private(set) var chargingPowerWatts: Int?
    @Published private(set) var adapterPowerWatts: Int?
    @Published private(set) var powerSourceConnectorNumber: Int?
    @Published private(set) var ethernetCableConnected = false
    @Published private(set) var sourceStatus: HardwareSourceStatus = .refreshing(lastUpdated: nil)

    var deviceGroups: USBDeviceGroups {
        USBDeviceGroups(
            devices: devices,
            thunderboltPorts: thunderboltPorts,
            externalThunderboltPortGroups: externalThunderboltPortGroups
        )
    }

    var count: Int {
        deviceGroups.countedExternalDeviceCount
    }

    var externalThunderboltPortCount: Int {
        externalThunderboltPortGroups.reduce(0) { $0 + $1.ports.count }
    }

    private let defaults: UserDefaults
    private let discovery: USBDeviceDiscovering
    private let ethernetReader: EthernetLinkReading
    private let ethernetMonitor: EthernetLinkMonitoring
    private let monitoringEnabled: Bool
    private let now: () -> Date
    private let refreshQueue = DispatchQueue(
        label: "de.r3d.menubario.device-refresh",
        qos: .utility
    )

    private var refreshCoordinator = DeviceRefreshCoordinator()
    private let ethernetRefreshQueue = DispatchQueue(
        label: "de.r3d.menubario.ethernet-refresh",
        qos: .utility
    )
    private var ethernetGeneration = 0
    private var isEthernetMonitoring = false
    private var ethernetRetry: DispatchWorkItem?

    private var connectionMonitor: USBConnectionMonitor?
    private var powerSourceMonitor: PowerSourceMonitor?

    init(
        monitoringEnabled: Bool = true,
        defaults: UserDefaults = .standard,
        discovery: USBDeviceDiscovering = USBDeviceDiscovery(),
        ethernetReader: EthernetLinkReading = EthernetLinkReader(),
        ethernetMonitor: EthernetLinkMonitoring = EthernetLinkMonitor(),
        now: @escaping () -> Date = Date.init
    ) {
        self.defaults = defaults
        self.discovery = discovery
        self.ethernetReader = ethernetReader
        self.ethernetMonitor = ethernetMonitor
        self.monitoringEnabled = monitoringEnabled
        self.now = now
        connectionMonitor = USBConnectionMonitor { [weak self] in
            self?.refresh()
        }
        powerSourceMonitor = PowerSourceMonitor { [weak self] state in
            self?.applyPowerSourceState(state)
        }

        guard monitoringEnabled else { return }

        if isPowerSourceInfoEnabled {
            powerSourceMonitor?.start()
        }
        connectionMonitor?.start()
        refresh()
    }

    deinit {
        ethernetRetry?.cancel()
        ethernetMonitor.stop()
        connectionMonitor?.stop()
        powerSourceMonitor?.stop()
    }

    func setPowerSourceInfoEnabled(_ isEnabled: Bool) {
        defaults.set(isEnabled, forKey: StorageKeys.powerSourceInfo)

        if isEnabled {
            powerSourceMonitor?.start()
        } else {
            powerSourceMonitor?.stop()
            applyPowerSourceState(.disconnected)
        }
    }

    func setEthernetIndicatorEnabled(_ isEnabled: Bool) {
        defaults.set(isEnabled, forKey: StorageKeys.showEthernet)
        refreshEthernetStatus()
    }

    func refresh() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.refresh()
            }
            return
        }

        sourceStatus = .refreshing(lastUpdated: sourceStatus.lastUpdated)

        if isPowerSourceInfoEnabled {
            powerSourceMonitor?.refresh()
        }

        refreshEthernetStatus()

        guard let generation = refreshCoordinator.requestRefresh() else { return }
        startRefresh(generation: generation)
    }

    private var isPowerSourceInfoEnabled: Bool {
        defaults.bool(forKey: StorageKeys.powerSourceInfo)
    }

    private var isEthernetIndicatorEnabled: Bool {
        defaults.bool(forKey: StorageKeys.showEthernet)
    }

    private func startRefresh(generation: Int) {
        refreshQueue.async { [weak self] in
            guard let self else { return }

            var seenDeviceIDs = Set<String>()
            let topology = self.discovery.connectedTopology()
            let devices = topology.devices
                .filter { seenDeviceIDs.insert($0.id).inserted }
                .sorted(by: Self.sortDevices)
            let thunderboltPorts = topology.thunderboltPorts.sorted {
                $0.connectorNumber < $1.connectorNumber
            }
            let externalThunderboltPortGroups = topology.externalThunderboltPortGroups
            DispatchQueue.main.async { [weak self] in
                self?.completeRefresh(
                    generation: generation,
                    devices: devices,
                    thunderboltPorts: thunderboltPorts,
                    externalThunderboltPortGroups: externalThunderboltPortGroups,
                    discoveryIsComplete: topology.isComplete
                )
            }
        }
    }

    private static func sortDevices(_ lhs: USBDevice, _ rhs: USBDevice) -> Bool {
        let lhsVendor = lhs.vendor ?? ""
        let rhsVendor = rhs.vendor ?? ""
        return lhsVendor < rhsVendor || (lhsVendor == rhsVendor && lhs.name < rhs.name)
    }

    private func completeRefresh(
        generation: Int,
        devices: [USBDevice],
        thunderboltPorts: [ThunderboltPort],
        externalThunderboltPortGroups: [ExternalThunderboltPortGroup],
        discoveryIsComplete: Bool
    ) {
        switch refreshCoordinator.completeRefresh(generation) {
        case .refresh(let nextGeneration):
            startRefresh(generation: nextGeneration)
        case .publish:
            if discoveryIsComplete {
                self.devices = devices
                self.thunderboltPorts = thunderboltPorts
                self.externalThunderboltPortGroups = externalThunderboltPortGroups
                sourceStatus = .ready(lastUpdated: now())
            } else if let lastUpdated = sourceStatus.lastUpdated {
                sourceStatus = .stale(lastUpdated: lastUpdated)
            } else {
                sourceStatus = .unavailable(.discoveryFailed)
            }
        }
    }

    private func refreshEthernetStatus() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.refreshEthernetStatus()
            }
            return
        }

        ethernetGeneration &+= 1
        ethernetRetry?.cancel()
        ethernetRetry = nil

        guard isEthernetIndicatorEnabled else {
            ethernetMonitor.stop()
            isEthernetMonitoring = false
            ethernetCableConnected = false
            return
        }

        if monitoringEnabled, !isEthernetMonitoring {
            isEthernetMonitoring = ethernetMonitor.start { [weak self] in
                self?.refreshEthernetStatus()
            }
        }

        readEthernetStatus(generation: ethernetGeneration, retryIfDisconnected: true)
    }

    private func readEthernetStatus(generation: Int, retryIfDisconnected: Bool) {
        let reader = ethernetReader
        ethernetRefreshQueue.async { [weak self] in
            let isConnected = reader.isConnected()
            DispatchQueue.main.async { [weak self] in
                guard let self,
                    self.ethernetGeneration == generation,
                    self.isEthernetIndicatorEnabled
                else { return }

                self.ethernetCableConnected = isConnected
                if !isConnected, retryIfDisconnected {
                    self.scheduleEthernetRetry(for: generation)
                }
            }
        }
    }

    private func scheduleEthernetRetry(for generation: Int) {
        let retry = DispatchWorkItem { [weak self] in
            guard let self,
                self.ethernetGeneration == generation,
                self.isEthernetIndicatorEnabled
            else {
                return
            }

            self.readEthernetStatus(generation: generation, retryIfDisconnected: false)
        }

        ethernetRetry = retry
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.3, execute: retry)
    }

    private func applyPowerSourceState(_ state: PowerSourceState) {
        guard isPowerSourceInfoEnabled else {
            chargeConnected = false
            chargePercentage = nil
            batteryIsCharging = false
            chargingPowerWatts = nil
            adapterPowerWatts = nil
            powerSourceConnectorNumber = nil
            return
        }

        chargeConnected = state.isConnected
        chargePercentage = state.chargePercentage
        batteryIsCharging = state.isCharging
        chargingPowerWatts = state.chargingPowerWatts
        adapterPowerWatts = state.adapterPowerWatts
        powerSourceConnectorNumber = state.powerSourceConnectorNumber
    }
}
