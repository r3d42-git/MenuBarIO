struct USBDeviceGroups: Equatable {
    let usbDevices: [USBDevice]
    let portAttachedUSBDevices: [USBDevice]
    let thunderboltDevices: [USBDevice]
    let internalDevices: [USBDevice]
    let hubs: [USBDevice]
    let hubGroups: [USBHubGroup]

    var countedExternalDeviceCount: Int {
        usbDevices.count + portAttachedUSBDevices.count + thunderboltDevices.count
    }

    init(
        devices: [USBDevice],
        thunderboltPorts: [ThunderboltPort] = [],
        externalThunderboltPortGroups: [ExternalThunderboltPortGroup] = []
    ) {
        let externalUSBDevices = devices.filter {
            $0.countsTowardUSBDeviceTotal && $0.transport == .usb
        }
        let attachedDeviceIDs = Set(
            externalThunderboltPortGroups
                .flatMap(\.ports)
                .compactMap(\.connectedDevice)
                .filter { $0.transport == .usb }
                .map(\.id)
        )
        portAttachedUSBDevices = externalUSBDevices.filter {
            attachedDeviceIDs.contains($0.id)
        }
        usbDevices = externalUSBDevices.filter {
            !attachedDeviceIDs.contains($0.id)
        }
        thunderboltDevices = devices.filter {
            $0.countsTowardUSBDeviceTotal && $0.transport == .thunderbolt
        }
        internalDevices = devices.filter { $0.isInternal && !$0.isHub }
        hubs = devices.filter(\.isHub)
        hubGroups = Self.makeHubGroups(
            hubs: hubs,
            usbDevices: externalUSBDevices,
            thunderboltDevices: thunderboltDevices,
            thunderboltPorts: thunderboltPorts
        )
    }

    private static func makeHubGroups(
        hubs: [USBDevice],
        usbDevices: [USBDevice],
        thunderboltDevices: [USBDevice],
        thunderboltPorts: [ThunderboltPort]
    ) -> [USBHubGroup] {
        var devicesByOwner: [USBHubOwner: [USBDevice]] = [:]

        for hub in hubs {
            let owner: USBHubOwner
            if hub.isInternal {
                owner = .thisMac
            } else if let thunderboltOwnerID = hub.thunderboltOwnerID,
                let device = knownThunderboltDevice(
                    id: thunderboltOwnerID,
                    thunderboltDevices: thunderboltDevices,
                    thunderboltPorts: thunderboltPorts
                )
            {
                owner = makeThunderboltOwner(
                    device: device,
                    thunderboltPorts: thunderboltPorts
                )
            } else if let device = soleThunderboltOwner(
                for: hub,
                usbDevices: usbDevices,
                thunderboltDevices: thunderboltDevices
            ) {
                owner = makeThunderboltOwner(
                    device: device,
                    thunderboltPorts: thunderboltPorts
                )
            } else if let controllerID = hub.usbControllerID,
                let port = thunderboltPorts.first(where: {
                    $0.controllerID == controllerID && $0.connectedDevice != nil
                }),
                let device = port.connectedDevice
            {
                owner = .thunderboltDevice(
                    id: device.id,
                    displayName: device.displayNameWithVendor,
                    connectorNumber: port.connectorNumber
                )
            } else {
                owner = unresolvedHubOwner(
                    for: hub,
                    thunderboltDevices: thunderboltDevices
                )
            }
            devicesByOwner[owner, default: []].append(hub)
        }

        return devicesByOwner.map { owner, devices in
            USBHubGroup(owner: owner, devices: devices)
        }.sorted(by: USBHubGroup.sort)
    }

    private static func soleThunderboltOwner(
        for hub: USBDevice,
        usbDevices: [USBDevice],
        thunderboltDevices: [USBDevice]
    ) -> USBDevice? {
        guard thunderboltDevices.count == 1, let device = thunderboltDevices.first else {
            return nil
        }

        if hub.isThunderboltTunneledUSB {
            return device
        }

        // Some Intel/T2 systems expose a dock's class-9 hub only as a generic
        // IOUSBHostDevice and omit every tunnel flag. In that constrained case,
        // require a same-controller USB function whose vendor matches the sole
        // native Thunderbolt device before inferring ownership.
        guard hub.hasGenericRegistryName,
            let controllerID = hub.usbControllerID,
            let thunderboltVendor = device.vendor
        else {
            return nil
        }

        let hasMatchingUSBFunction = usbDevices.contains { usbDevice in
            usbDevice.usbControllerID == controllerID
                && vendorsMatch(usbDevice.vendor, thunderboltVendor)
        }
        return hasMatchingUSBFunction ? device : nil
    }

    private static func unresolvedHubOwner(
        for hub: USBDevice,
        thunderboltDevices: [USBDevice]
    ) -> USBHubOwner {
        // Preserve the direct group for ordinary named USB hubs. A generic
        // registry fallback while native Thunderbolt devices are present is
        // genuinely ambiguous: it may be a tunnelled dock function whose
        // owner is missing, so do not present it as proven direct hardware.
        let hasUnresolvedThunderboltEvidence =
            hub.thunderboltOwnerID != nil
            || hub.isThunderboltTunneledUSB
            || (hub.hasGenericRegistryName && !thunderboltDevices.isEmpty)
        return hasUnresolvedThunderboltEvidence ? .unknown : .direct
    }

    private static func makeThunderboltOwner(
        device: USBDevice,
        thunderboltPorts: [ThunderboltPort]
    ) -> USBHubOwner {
        let connectorNumber =
            thunderboltPorts.first {
                $0.connectedDevice?.id == device.id
            }?.connectorNumber ?? Int.max

        return .thunderboltDevice(
            id: device.id,
            displayName: device.displayNameWithVendor,
            connectorNumber: connectorNumber
        )
    }

    private static func knownThunderboltDevice(
        id: String,
        thunderboltDevices: [USBDevice],
        thunderboltPorts: [ThunderboltPort]
    ) -> USBDevice? {
        thunderboltDevices.first { $0.id == id }
            ?? thunderboltPorts.compactMap(\.connectedDevice).first { $0.id == id }
    }

    private static func vendorsMatch(_ lhs: String?, _ rhs: String?) -> Bool {
        guard let lhs = normalizedVendor(lhs), let rhs = normalizedVendor(rhs) else {
            return false
        }
        return lhs.contains(rhs) || rhs.contains(lhs)
    }

    private static func normalizedVendor(_ value: String?) -> String? {
        guard let value else { return nil }
        let normalized = value.lowercased().filter { $0.isLetter || $0.isNumber }
        return normalized.count >= 4 ? normalized : nil
    }
}

enum USBHubOwner: Equatable, Hashable {
    case thisMac
    case thunderboltDevice(id: String, displayName: String, connectorNumber: Int)
    case direct
    case unknown
}

struct USBHubGroup: Identifiable, Equatable {
    let owner: USBHubOwner
    let devices: [USBDevice]

    var id: String {
        switch owner {
        case .thisMac:
            return "this-mac"
        case .thunderboltDevice(let id, _, _):
            return "thunderbolt-\(id)"
        case .direct:
            return "direct"
        case .unknown:
            return "unknown"
        }
    }

    static func sort(_ lhs: USBHubGroup, _ rhs: USBHubGroup) -> Bool {
        let lhsKey = lhs.sortKey
        let rhsKey = rhs.sortKey
        return lhsKey.0 < rhsKey.0
            || (lhsKey.0 == rhsKey.0 && lhsKey.1.localizedCaseInsensitiveCompare(rhsKey.1) == .orderedAscending)
    }

    private var sortKey: (Int, String) {
        switch owner {
        case .thisMac:
            return (0, "")
        case .thunderboltDevice(_, let displayName, let connectorNumber):
            return (connectorNumber, displayName)
        case .direct:
            return (Int.max - 1, "")
        case .unknown:
            return (Int.max, "")
        }
    }
}
