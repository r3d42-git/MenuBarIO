//
//  USBDevice.swift
//  MenuBarIO
//
//  Created by Rafael Neuwirth on 28/08/25.
//

import Foundation
import IOKit.usb

enum ConnectionTransport: String {
    case usb
    case thunderbolt

    var displayName: String {
        switch self {
        case .usb:
            return "USB"
        case .thunderbolt:
            return "Thunderbolt/USB4"
        }
    }
}

struct USBDevice: Identifiable, Equatable, Hashable {
    let name: String
    let vendor: String?
    let vendorId: Int
    let productId: Int
    let serialNumber: String?
    let locationId: UInt32?
    let speedMbps: Int?
    let portMaxSpeedMbps: Int?
    let usbVersionBCD: Int?
    let isExternalStorage: Bool?
    /// USB port type as reported by IOKit. The internal type identifies a
    /// device that is not physically disconnectable from this Mac.
    let usbPortType: Int?
    /// USB device class 9 identifies a standards-compliant USB hub.
    let deviceClass: Int?
    /// USB-C Billboard interfaces expose alternate-mode status. A Thunderbolt
    /// dock may expose one in addition to its native Thunderbolt topology.
    let isThunderboltBillboard: Bool
    let transport: ConnectionTransport
    /// Friendly transport protocol label, for example "USB4 v2".
    let transportVersion: String?
    /// Stable bus-specific ID. Thunderbolt UIDs must not be shown as USB serial numbers.
    let transportIdentifier: String?
    /// Stable ID of the native Thunderbolt device found in this USB device's
    /// IOService ancestry. Intel Macs expose tunneled USB controllers below
    /// the external Thunderbolt router instead of sharing its controller ID.
    let thunderboltOwnerID: String?
    /// True when the USB device reports a tunnel or appears below Intel's
    /// dedicated Thunderbolt USB host controller (`AppleUSBXHCITR`) in either
    /// the IOService or IOUSB registry plane.
    let isThunderboltTunneledUSB: Bool
    /// Location ID of the directly containing class-9 USB hub in the IOUSB
    /// plane. This is topology metadata and is never shown to the user.
    let parentHubLocationId: UInt32?
    /// Downstream port number relative to `parentHubLocationId`. Unlike the
    /// USB controller byte, this identifies the actual socket on that hub.
    let parentHubPortNumber: Int?
    /// Physical USB-C socket reported by the immediate host USB port. Never
    /// inferred from a controller byte or inherited through an external hub.
    let hostConnectorNumber: Int?

    var id: String { uniqueId }

    init(
        name: String,
        vendor: String?,
        vendorId: Int,
        productId: Int,
        serialNumber: String?,
        locationId: UInt32?,
        speedMbps: Int?,
        portMaxSpeedMbps: Int?,
        usbVersionBCD: Int?,
        isExternalStorage: Bool?,
        usbPortType: Int? = nil,
        deviceClass: Int? = nil,
        isThunderboltBillboard: Bool = false,
        transport: ConnectionTransport = .usb,
        transportVersion: String? = nil,
        transportIdentifier: String? = nil,
        thunderboltOwnerID: String? = nil,
        isThunderboltTunneledUSB: Bool = false,
        parentHubLocationId: UInt32? = nil,
        parentHubPortNumber: Int? = nil,
        hostConnectorNumber: Int? = nil
    ) {
        self.name = name
        self.vendor = vendor
        self.vendorId = vendorId
        self.productId = productId
        self.serialNumber = serialNumber
        self.locationId = locationId
        self.speedMbps = speedMbps
        self.portMaxSpeedMbps = portMaxSpeedMbps
        self.usbVersionBCD = usbVersionBCD
        self.isExternalStorage = isExternalStorage
        self.usbPortType = usbPortType
        self.deviceClass = deviceClass
        self.isThunderboltBillboard = isThunderboltBillboard
        self.transport = transport
        self.transportVersion = transportVersion
        self.transportIdentifier = transportIdentifier
        self.thunderboltOwnerID = thunderboltOwnerID
        self.isThunderboltTunneledUSB = isThunderboltTunneledUSB
        self.parentHubLocationId = parentHubLocationId
        self.parentHubPortNumber = parentHubPortNumber
        self.hostConnectorNumber = hostConnectorNumber
    }

    var uniqueId: String {
        if transport == .thunderbolt {
            let identifier = transportIdentifier?.trimmingCharacters(in: .whitespaces)
            let fallback = locationId.map(String.init) ?? "unknown"
            let stableIdentifier = identifier.flatMap { $0.isEmpty ? nil : $0 } ?? fallback
            return "thunderbolt-\(vendorId)-\(productId)-\(stableIdentifier)"
        }

        let serial = serialNumber?.trimmingCharacters(in: .whitespaces) ?? ""
        if !serial.isEmpty {
            return "\(vendorId)-\(productId)-\(serial)"
        }

        // VID/PID alone identifies a product model, not one physical device.
        // The USB location ID keeps identical, serial-less devices distinct while
        // they are connected to separate ports.
        if let locationId {
            return "\(vendorId)-\(productId)-\(String(format: "%08X", locationId))"
        }

        return "\(vendorId)-\(productId)"
    }

    var speedDescription: String {
        guard let devMbps = speedMbps else {
            var parts = ["unknown_speed".localized]
            if let port = portMaxSpeedMbps {
                parts.append("— \("supports_up_to".localized) \(USBFormatting.transferRate(port))")
            }
            return parts.joined(separator: " ")
        }
        var parts: [String] = [USBFormatting.speedTierLabel(for: devMbps)]

        if let port = portMaxSpeedMbps {
            if devMbps < port {
                parts.append("— \("supports_up_to".localized) \(USBFormatting.transferRate(port))")
            } else {
                parts.append("— \("supports".localized) \(USBFormatting.transferRate(port))")
            }
        }
        return parts.joined(separator: " ")
    }

    var connectionDescription: String {
        guard transport == .thunderbolt else { return speedDescription }
        return transport.displayName
    }

    var hardwareIdentifier: String {
        let identifier = String(format: "%04X:%04X", vendorId, productId)
        return transport == .thunderbolt ? "TB \(identifier)" : identifier
    }

    var displayNameWithVendor: String {
        let displayName = displayName
        guard let vendor = vendor?.trimmingCharacters(in: .whitespacesAndNewlines),
            !vendor.isEmpty,
            !displayName.localizedCaseInsensitiveContains(vendor)
        else {
            return displayName
        }
        return "\(vendor) \(displayName)"
    }

    /// Replaces IOKit's class-name fallback only after the device has already
    /// been identified as internal. The raw registry name remains available in
    /// `name` and in copied device details.
    var displayName: String {
        guard isInternal, hasGenericRegistryName else { return name }
        return "unnamed_internal_usb_component".localized
    }

    var hasGenericRegistryName: Bool {
        ["IOUSBHostDevice", "IOUSBDevice"].contains(name)
    }

    var usbControllerID: Int? {
        guard transport == .usb, let locationId else { return nil }
        return Int(locationId >> 24)
    }

    var isHub: Bool {
        transport == .usb && deviceClass == 9
    }

    /// Uses IOKit's port classification, rather than a device name, vendor, or
    /// location-ID heuristic. Captive ports intentionally remain separate.
    var isInternal: Bool {
        transport == .usb && usbPortType == Int(kIOUSBHostPortTypeInternal.rawValue)
    }

    /// Only external, non-hub USB and Thunderbolt devices contribute to the
    /// user-facing USB count in the menu bar and list header.
    var countsTowardUSBDeviceTotal: Bool {
        !isHub && !isInternal
    }
}
