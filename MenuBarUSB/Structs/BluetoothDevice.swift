//
//  BluetoothDevice.swift
//  MenuBarUSB
//

import Foundation

enum BluetoothDeviceIcon: Equatable, Hashable {
    case system(String)
    case bluetoothTemplate
}

struct BluetoothDevice: Identifiable, Equatable, Hashable {
    struct Snapshot: Equatable {
        let identifier: String?
        let name: String?
        let isConnected: Bool
        let deviceClassMajor: UInt32
        let deviceClassMinor: UInt32

        init(
            identifier: String?,
            name: String?,
            isConnected: Bool,
            deviceClassMajor: UInt32 = 0,
            deviceClassMinor: UInt32 = 0
        ) {
            self.identifier = identifier
            self.name = name
            self.isConnected = isConnected
            self.deviceClassMajor = deviceClassMajor
            self.deviceClassMinor = deviceClassMinor
        }
    }

    let id: String
    let name: String
    let icon: BluetoothDeviceIcon

    init?(snapshot: Snapshot) {
        guard snapshot.isConnected else { return nil }

        let resolvedName = snapshot.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !resolvedName.isEmpty else { return nil }

        let resolvedIdentifier = snapshot.identifier?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        if let resolvedIdentifier, !resolvedIdentifier.isEmpty {
            id = "bluetooth-\(resolvedIdentifier)"
        } else {
            let normalizedName = resolvedName.folding(
                options: [.caseInsensitive, .diacriticInsensitive],
                locale: .current
            )
            id = "bluetooth-name-\(normalizedName.lowercased())"
        }

        name = resolvedName
        icon = Self.icon(
            for: resolvedName,
            deviceClassMajor: snapshot.deviceClassMajor,
            deviceClassMinor: snapshot.deviceClassMinor
        )
    }

    static func connectedDevices(from snapshots: [Snapshot]) -> [BluetoothDevice] {
        var uniqueDevices: [String: BluetoothDevice] = [:]

        for snapshot in snapshots {
            guard let device = BluetoothDevice(snapshot: snapshot) else { continue }
            uniqueDevices[device.id] = device
        }

        return uniqueDevices.values.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    private static func icon(
        for name: String,
        deviceClassMajor: UInt32,
        deviceClassMinor: UInt32
    ) -> BluetoothDeviceIcon {
        let normalizedName = name.folding(
            options: [.caseInsensitive, .diacriticInsensitive],
            locale: .current
        ).lowercased()

        if normalizedName.contains("airpods max") {
            return .system("airpodsmax")
        }
        if normalizedName.contains("airpods pro") {
            return .system("airpodspro")
        }
        if normalizedName.contains("airpods") {
            return .system("airpods")
        }
        if normalizedName.contains("trackpad") {
            return .system("rectangle.and.hand.point.up.left")
        }
        if normalizedName.contains("mouse") || normalizedName.contains("maus")
            || ["m650", "mx master", "mx anywhere", "trackball"].contains(where: { normalizedName.contains($0) })
        {
            return .system("computermouse")
        }
        if normalizedName.contains("keyboard") || normalizedName.contains("neo") {
            return .system("keyboard")
        }
        if normalizedName.contains("gamepad") || normalizedName.contains("controller") {
            return .system("gamecontroller")
        }

        switch deviceClassMajor {
        case 0x01:
            return .system(deviceClassMinor == 0x03 ? "laptopcomputer" : "desktopcomputer")
        case 0x02:
            return .system("iphone")
        case 0x04:
            switch deviceClassMinor {
            case 0x05:
                return .system("speaker.wave.2")
            case 0x01, 0x02, 0x06, 0x07:
                return .system("headphones")
            default:
                return .system("headphones")
            }
        case 0x05:
            switch deviceClassMinor & 0x30 {
            case 0x10:
                return .system("keyboard")
            case 0x20, 0x30:
                return .system("computermouse")
            default:
                switch deviceClassMinor & 0x0F {
                case 0x01, 0x02:
                    return .system("gamecontroller")
                default:
                    return .system("computermouse")
                }
            }
        default:
            return .bluetoothTemplate
        }
    }
}
