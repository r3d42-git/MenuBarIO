struct USBDeviceGroups: Equatable {
    let usbDevices: [USBDevice]
    let thunderboltDevices: [USBDevice]
    let internalDevices: [USBDevice]
    let hubs: [USBDevice]
    let hubGroups: [USBHubGroup]

    var countedExternalDeviceCount: Int {
        usbDevices.count + thunderboltDevices.count
    }

    init(devices: [USBDevice], thunderboltPorts: [ThunderboltPort] = []) {
        usbDevices = devices.filter {
            $0.countsTowardUSBDeviceTotal && $0.transport == .usb
        }
        thunderboltDevices = devices.filter {
            $0.countsTowardUSBDeviceTotal && $0.transport == .thunderbolt
        }
        internalDevices = devices.filter { $0.isInternal && !$0.isHub }
        hubs = devices.filter(\.isHub)
        hubGroups = Self.makeHubGroups(hubs: hubs, thunderboltPorts: thunderboltPorts)
    }

    private static func makeHubGroups(
        hubs: [USBDevice],
        thunderboltPorts: [ThunderboltPort]
    ) -> [USBHubGroup] {
        var devicesByOwner: [USBHubOwner: [USBDevice]] = [:]

        for hub in hubs {
            let owner: USBHubOwner
            if hub.isInternal {
                owner = .thisMac
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
                owner = .directOrUnknown
            }
            devicesByOwner[owner, default: []].append(hub)
        }

        return devicesByOwner.map { owner, devices in
            USBHubGroup(owner: owner, devices: devices)
        }.sorted(by: USBHubGroup.sort)
    }
}

enum USBHubOwner: Equatable, Hashable {
    case thisMac
    case thunderboltDevice(id: String, displayName: String, connectorNumber: Int)
    case directOrUnknown
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
        case .directOrUnknown:
            return "direct-or-unknown"
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
        case .directOrUnknown:
            return (Int.max, "")
        }
    }
}
