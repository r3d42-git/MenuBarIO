//
//  BluetoothDeviceManager.swift
//  MenuBarIO
//

import Foundation
import IOBluetooth

final class BluetoothDeviceManager: NSObject, ObservableObject {
    @Published private(set) var devices: [BluetoothDevice] = []
    @Published private(set) var sourceStatus: HardwareSourceStatus = .refreshing(lastUpdated: nil)

    var count: Int {
        devices.count
    }

    private var connectNotification: IOBluetoothUserNotification?
    private var disconnectNotifications: [String: IOBluetoothUserNotification] = [:]
    private var controllerObservers: [NSObjectProtocol] = []
    private var batteryRefreshTimer: Timer?

    private let reader: BluetoothDeviceReading
    private let batteryReader: BluetoothBatteryReading
    private let notificationCenter: NotificationCenter
    private let now: () -> Date

    init(
        monitoringEnabled: Bool = true,
        reader: BluetoothDeviceReading = SystemBluetoothDeviceReader(),
        batteryReader: BluetoothBatteryReading = SystemBluetoothBatteryReader(),
        notificationCenter: NotificationCenter = .default,
        now: @escaping () -> Date = Date.init
    ) {
        self.reader = reader
        self.batteryReader = batteryReader
        self.notificationCenter = notificationCenter
        self.now = now
        super.init()
        batteryReader.onChange = { [weak self] in self?.updateBatteryLevels() }

        guard monitoringEnabled else { return }

        startMonitoring()
        refresh()
    }

    deinit {
        stopMonitoring()
    }

    func refresh() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.refresh()
            }
            return
        }

        sourceStatus = .refreshing(lastUpdated: sourceStatus.lastUpdated)
        let result = reader.read()

        switch result.availability {
        case .available:
            let connectedDevices = BluetoothDevice.connectedDevices(from: result.snapshots)
            devices = connectedDevices
            batteryReader.refresh(connectedAddresses: Set(connectedDevices.compactMap(\.address)))
            updateBatteryLevels()
            replaceDisconnectNotifications(
                for: connectedDevices,
                systemDevices: result.connectedSystemDevices
            )
            sourceStatus = .ready(lastUpdated: now())
        case .poweredOff:
            devices = []
            batteryReader.stop()
            unregisterDisconnectNotifications()
            sourceStatus = .unavailable(.bluetoothPoweredOff)
        case .unavailable:
            batteryReader.stop()
            if let lastUpdated = sourceStatus.lastUpdated {
                sourceStatus = .stale(lastUpdated: lastUpdated)
            } else {
                sourceStatus = .unavailable(.bluetoothUnavailable)
            }
        }
    }

    private func startMonitoring() {
        connectNotification = IOBluetoothDevice.register(
            forConnectNotifications: self,
            selector: #selector(deviceConnected(_:device:))
        )

        let names: [Notification.Name] = [
            .IOBluetoothHostControllerPoweredOn,
            .IOBluetoothHostControllerPoweredOff,
        ]
        controllerObservers = names.map { name in
            notificationCenter.addObserver(
                forName: name,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.refresh()
            }
        }
        let timer = Timer(timeInterval: 300, repeats: true) { [weak self] _ in
            guard let self, case .ready = self.sourceStatus else { return }
            self.batteryReader.refresh(connectedAddresses: Set(self.devices.compactMap(\.address)))
        }
        timer.tolerance = 30
        RunLoop.main.add(timer, forMode: .common)
        batteryRefreshTimer = timer
    }

    private func stopMonitoring() {
        batteryRefreshTimer?.invalidate()
        batteryRefreshTimer = nil
        batteryReader.onChange = nil
        batteryReader.stop()
        connectNotification?.unregister()
        connectNotification = nil
        for observer in controllerObservers {
            notificationCenter.removeObserver(observer)
        }
        controllerObservers.removeAll()
        unregisterDisconnectNotifications()
    }

    private func updateBatteryLevels() {
        let updated = devices.map { device in
            device.updatingBatteryLevel(device.address.flatMap(batteryReader.batteryLevel(for:)))
        }
        if devices != updated { devices = updated }
    }

    private func replaceDisconnectNotifications(
        for connectedDevices: [BluetoothDevice],
        systemDevices: [String: IOBluetoothDevice]
    ) {
        unregisterDisconnectNotifications()

        for device in connectedDevices {
            guard let systemDevice = systemDevices[device.id],
                let notification = systemDevice.register(
                    forDisconnectNotification: self,
                    selector: #selector(deviceDisconnected(_:device:))
                )
            else {
                continue
            }

            disconnectNotifications[device.id] = notification
        }
    }

    private func unregisterDisconnectNotifications() {
        for notification in disconnectNotifications.values {
            notification.unregister()
        }
        disconnectNotifications.removeAll()
    }

    @objc private func deviceConnected(
        _: IOBluetoothUserNotification,
        device _: IOBluetoothDevice
    ) {
        refresh()
    }

    @objc private func deviceDisconnected(
        _: IOBluetoothUserNotification,
        device _: IOBluetoothDevice
    ) {
        refresh()
    }
}
