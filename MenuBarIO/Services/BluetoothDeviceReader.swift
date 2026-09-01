import Foundation
import IOBluetooth

enum BluetoothDiscoveryAvailability: Equatable {
    case available
    case poweredOff
    case unavailable
}

struct BluetoothDeviceReadResult {
    let availability: BluetoothDiscoveryAvailability
    let snapshots: [BluetoothDevice.Snapshot]
    let connectedSystemDevices: [String: IOBluetoothDevice]
}

protocol BluetoothDeviceReading {
    func read() -> BluetoothDeviceReadResult
}

final class SystemBluetoothDeviceReader: BluetoothDeviceReading {
    func read() -> BluetoothDeviceReadResult {
        guard let controller = IOBluetoothHostController.default() else {
            return BluetoothDeviceReadResult(
                availability: .unavailable,
                snapshots: [],
                connectedSystemDevices: [:]
            )
        }

        switch controller.powerState {
        case kBluetoothHCIPowerStateOFF:
            return BluetoothDeviceReadResult(
                availability: .poweredOff,
                snapshots: [],
                connectedSystemDevices: [:]
            )
        case kBluetoothHCIPowerStateON:
            break
        default:
            return BluetoothDeviceReadResult(
                availability: .unavailable,
                snapshots: [],
                connectedSystemDevices: [:]
            )
        }

        guard let pairedDevices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] else {
            return BluetoothDeviceReadResult(
                availability: .unavailable,
                snapshots: [],
                connectedSystemDevices: [:]
            )
        }

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

        return BluetoothDeviceReadResult(
            availability: .available,
            snapshots: snapshots,
            connectedSystemDevices: connectedSystemDevices
        )
    }
}
