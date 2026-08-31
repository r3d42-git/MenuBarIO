//
//  BluetoothDeviceManager.swift
//  MenuBarIO
//

import Foundation
import IOBluetooth

final class BluetoothDeviceManager: NSObject, ObservableObject {
    @Published private(set) var devices: [BluetoothDevice] = []

    var count: Int {
        devices.count
    }

    private var connectNotification: IOBluetoothUserNotification?
    private var disconnectNotifications: [String: IOBluetoothUserNotification] = [:]

    init(monitoringEnabled: Bool = true) {
        super.init()

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

        let pairedDevices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] ?? []
        var connectedSystemDevices: [String: IOBluetoothDevice] = [:]
        let snapshots = pairedDevices.map { device -> BluetoothDevice.Snapshot in
            let snapshot = BluetoothDevice.Snapshot(
                identifier: device.addressString,
                name: device.nameOrAddress,
                isConnected: device.isConnected(),
                deviceClassMajor: device.deviceClassMajor,
                deviceClassMinor: device.deviceClassMinor
            )

            if let connectedDevice = BluetoothDevice(snapshot: snapshot) {
                connectedSystemDevices[connectedDevice.id] = device
            }

            return snapshot
        }

        let connectedDevices = BluetoothDevice.connectedDevices(from: snapshots)
        devices = connectedDevices
        replaceDisconnectNotifications(for: connectedDevices, systemDevices: connectedSystemDevices)
    }

    private func startMonitoring() {
        connectNotification = IOBluetoothDevice.register(
            forConnectNotifications: self,
            selector: #selector(deviceConnected(_:device:))
        )
    }

    private func stopMonitoring() {
        connectNotification?.unregister()
        connectNotification = nil
        unregisterDisconnectNotifications()
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
