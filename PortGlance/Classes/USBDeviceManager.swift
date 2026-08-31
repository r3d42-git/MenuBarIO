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

private struct DeviceRefreshOptions {
    let showEthernet: Bool
}

final class USBDeviceManager: ObservableObject {
    @Published private(set) var devices: [USBDevice] = []
    @Published private(set) var thunderboltPorts: [ThunderboltPort] = []
    @Published private(set) var externalThunderboltPortGroups: [ExternalThunderboltPortGroup] = []
    @Published private(set) var chargeConnected = false
    @Published private(set) var chargePercentage: Int?
    @Published private(set) var ethernetCableConnected = false

    var deviceGroups: USBDeviceGroups {
        USBDeviceGroups(devices: devices, thunderboltPorts: thunderboltPorts)
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
    private let refreshQueue = DispatchQueue(
        label: "de.r3d.portglance.device-refresh",
        qos: .utility
    )

    private var refreshCoordinator = DeviceRefreshCoordinator()
    private var latestRefreshOptions = DeviceRefreshOptions(showEthernet: false)
    private var ethernetRetry: DispatchWorkItem?

    private var connectionMonitor: USBConnectionMonitor?
    private var powerSourceMonitor: PowerSourceMonitor?

    init(
        monitoringEnabled: Bool = true,
        defaults: UserDefaults = .standard,
        discovery: USBDeviceDiscovering = USBDeviceDiscovery(),
        ethernetReader: EthernetLinkReading = EthernetLinkReader()
    ) {
        self.defaults = defaults
        self.discovery = discovery
        self.ethernetReader = ethernetReader
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

    func refresh() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.refresh()
            }
            return
        }

        if isPowerSourceInfoEnabled {
            powerSourceMonitor?.refresh()
        }

        latestRefreshOptions = DeviceRefreshOptions(showEthernet: isEthernetIndicatorEnabled)
        ethernetRetry?.cancel()
        ethernetRetry = nil

        guard let generation = refreshCoordinator.requestRefresh() else { return }
        startRefresh(generation: generation, options: latestRefreshOptions)
    }

    private var isPowerSourceInfoEnabled: Bool {
        defaults.bool(forKey: StorageKeys.powerSourceInfo)
    }

    private var isEthernetIndicatorEnabled: Bool {
        defaults.bool(forKey: StorageKeys.showEthernet)
    }

    private func startRefresh(generation: Int, options: DeviceRefreshOptions) {
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
            let ethernetConnected =
                options.showEthernet
                ? self.ethernetReader.isConnected()
                : nil

            DispatchQueue.main.async { [weak self] in
                self?.completeRefresh(
                    generation: generation,
                    options: options,
                    devices: devices,
                    thunderboltPorts: thunderboltPorts,
                    externalThunderboltPortGroups: externalThunderboltPortGroups,
                    ethernetConnected: ethernetConnected
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
        options: DeviceRefreshOptions,
        devices: [USBDevice],
        thunderboltPorts: [ThunderboltPort],
        externalThunderboltPortGroups: [ExternalThunderboltPortGroup],
        ethernetConnected: Bool?
    ) {
        switch refreshCoordinator.completeRefresh(generation) {
        case .refresh(let nextGeneration):
            startRefresh(generation: nextGeneration, options: latestRefreshOptions)
        case .publish:
            self.devices = devices
            self.thunderboltPorts = thunderboltPorts
            self.externalThunderboltPortGroups = externalThunderboltPortGroups
            publishEthernetStatus(
                ethernetConnected,
                generation: generation,
                options: options
            )
        }
    }

    private func publishEthernetStatus(
        _ isConnected: Bool?,
        generation: Int,
        options: DeviceRefreshOptions
    ) {
        guard options.showEthernet,
            isEthernetIndicatorEnabled,
            let isConnected
        else {
            if !isEthernetIndicatorEnabled {
                ethernetCableConnected = false
            }
            return
        }

        ethernetCableConnected = isConnected
        if !isConnected {
            scheduleEthernetRetry(for: generation)
        }
    }

    private func scheduleEthernetRetry(for generation: Int) {
        let retry = DispatchWorkItem { [weak self] in
            guard let self,
                self.refreshCoordinator.isCurrent(generation),
                self.isEthernetIndicatorEnabled
            else {
                return
            }

            self.refreshQueue.async { [weak self] in
                guard let self else { return }
                let isConnected = self.ethernetReader.isConnected()

                DispatchQueue.main.async {
                    guard self.refreshCoordinator.isCurrent(generation),
                        self.isEthernetIndicatorEnabled
                    else {
                        return
                    }
                    self.ethernetCableConnected = isConnected
                }
            }
        }

        ethernetRetry = retry
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.3, execute: retry)
    }

    private func applyPowerSourceState(_ state: PowerSourceState) {
        guard isPowerSourceInfoEnabled else {
            chargeConnected = false
            chargePercentage = nil
            return
        }

        chargeConnected = state.isConnected
        chargePercentage = state.chargePercentage
    }
}
