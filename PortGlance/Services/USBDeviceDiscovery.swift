import Foundation
import IOKit
import IOKit.usb

protocol USBDeviceDiscovering {
    func connectedTopology() -> USBTopologySnapshot
}

extension USBDeviceDiscovering {
    func connectedDevices() -> [USBDevice] {
        connectedTopology().devices
    }
}

final class USBDeviceDiscovery: USBDeviceDiscovering {
    static let usbDeviceClassNames = [kIOUSBHostDeviceClassName, kIOUSBDeviceClassName]

    func connectedTopology() -> USBTopologySnapshot {
        let discoveredUSBDevices = fetchUSBDevices()
        let thunderboltTopology = fetchThunderboltTopology(usbDevices: discoveredUSBDevices)
        let thunderboltDevices = thunderboltTopology.devices
        var devices = discoveredUSBDevices.filter { usbDevice in
            !thunderboltDevices.contains { thunderboltDevice in
                representsSamePhysicalDevice(usbDevice, as: thunderboltDevice)
            }
        }
        var seenDeviceIDs = Set(devices.map(\.id))

        for device in thunderboltDevices where seenDeviceIDs.insert(device.id).inserted {
            devices.append(device)
        }

        return USBTopologySnapshot(
            devices: devices,
            thunderboltPorts: thunderboltTopology.ports,
            externalThunderboltPortGroups: thunderboltTopology.externalPortGroups
        )
    }

    private func fetchUSBDevices() -> [USBDevice] {
        var devices: [USBDevice] = []
        var seenDeviceIDs = Set<String>()

        for className in Self.usbDeviceClassNames {
            for device in fetchMatchingDevices(className: className)
            where seenDeviceIDs.insert(device.id).inserted {
                devices.append(device)
            }
        }

        return devices
    }

    private func fetchMatchingDevices(className: String) -> [USBDevice] {
        let matching = IOServiceMatching(className)
        var iterator: io_iterator_t = 0

        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else {
            return []
        }
        defer { IOObjectRelease(iterator) }

        var devices: [USBDevice] = []
        while case let entry = IOIteratorNext(iterator), entry != 0 {
            if let device = makeUSBDevice(from: entry) {
                devices.append(device)
            }
            IOObjectRelease(entry)
        }
        return devices
    }

    private func fetchThunderboltTopology(
        usbDevices: [USBDevice]
    ) -> ThunderboltTopologyRecords {
        let matching = IOServiceMatching(USBConnectionMonitor.thunderboltClassName)
        var iterator: io_iterator_t = 0

        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else {
            return ThunderboltTopologyRecords(
                devices: [],
                ports: [],
                externalPortGroups: []
            )
        }
        defer { IOObjectRelease(iterator) }

        var devices: [USBDevice] = []
        var hostRouters: [ThunderboltHostRouterRecord] = []
        var attachments: [ThunderboltDeviceAttachment] = []
        var deviceRouters: [ThunderboltDeviceRouterRecord] = []

        while case let entry = IOIteratorNext(iterator), entry != 0 {
            let properties = registryProperties(for: entry)

            if let properties,
                properties.uint64Value("Route String") == 0,
                let hostRouter = makeThunderboltHostRouter(from: entry, properties: properties)
            {
                hostRouters.append(hostRouter)
            } else if let device = makeThunderboltDevice(from: entry) {
                devices.append(device)
                let router = ThunderboltDeviceRouterRecord(
                    controllerID: rootThunderboltRouterID(for: entry),
                    hostPortNumber: parentThunderboltPortNumber(for: entry),
                    depth: properties?.intValue("Depth") ?? 1,
                    protocolVersion: properties?.intValue("Thunderbolt Version"),
                    device: device,
                    downstreamConnectors: thunderboltDownstreamConnectors(for: entry),
                    usbPortMap: ThunderboltUSBPortMapEntry.entries(
                        from: properties?.dataValue("USB Port Map")
                    )
                )
                deviceRouters.append(router)
                attachments.append(router.attachment)
            }
            IOObjectRelease(entry)
        }

        let ports = makeThunderboltPorts(
            hostRouters: hostRouters,
            attachments: attachments
        )
        let externalPortGroups = makeExternalThunderboltPortGroups(
            deviceRouters: deviceRouters,
            hostPorts: ports,
            usbDevices: usbDevices
        )

        return ThunderboltTopologyRecords(
            devices: devices,
            ports: ports,
            externalPortGroups: externalPortGroups
        )
    }

    private func makeExternalThunderboltPortGroups(
        deviceRouters: [ThunderboltDeviceRouterRecord],
        hostPorts: [ThunderboltPort],
        usbDevices: [USBDevice]
    ) -> [ExternalThunderboltPortGroup] {
        deviceRouters.compactMap { router in
            guard !router.downstreamConnectors.isEmpty else { return nil }

            let hostConnectorNumber =
                hostPorts.first {
                    $0.connectedDevice?.id == router.device.id
                }?.connectorNumber ?? Int.max
            let nativePorts = router.downstreamConnectors.enumerated().map { index, connector in
                ThunderboltPort(
                    id: "external-thunderbolt-port-\(router.device.id)-\(connector.hostPortNumber)",
                    controllerID: router.controllerID ?? -1,
                    connectorNumber: index + 1,
                    protocolVersion: router.protocolVersion,
                    maximumSpeedMbps: router.device.speedMbps,
                    connectedDevice: connector.connectedDevice
                )
            }
            let ports = USBPortAttachmentResolver.attachingUSBDevices(
                to: nativePorts,
                ownerID: router.device.id,
                controllerID: router.controllerID,
                hostConnectorNumber: hostConnectorNumber,
                portMap: router.usbPortMap,
                usbDevices: usbDevices
            )

            return ExternalThunderboltPortGroup(
                owner: router.device,
                hostConnectorNumber: hostConnectorNumber,
                depth: router.depth,
                ports: ports
            )
        }.sorted {
            $0.hostConnectorNumber < $1.hostConnectorNumber
                || ($0.hostConnectorNumber == $1.hostConnectorNumber && $0.depth < $1.depth)
                || ($0.hostConnectorNumber == $1.hostConnectorNumber
                    && $0.depth == $1.depth
                    && $0.owner.name.localizedCaseInsensitiveCompare($1.owner.name) == .orderedAscending)
        }
    }

    private func makeThunderboltPorts(
        hostRouters: [ThunderboltHostRouterRecord],
        attachments: [ThunderboltDeviceAttachment]
    ) -> [ThunderboltPort] {
        var ports: [ThunderboltPort] = []

        for router in hostRouters {
            for connector in router.connectors {
                let exactAttachment = attachments.first {
                    $0.controllerID == router.controllerID
                        && $0.depth == 1
                        && $0.hostPortNumber == connector.hostPortNumber
                }

                var attachment = exactAttachment
                if attachment == nil, router.connectors.count == 1 {
                    attachment = attachments.first {
                        $0.controllerID == router.controllerID && $0.depth == 1
                    }
                }

                ports.append(
                    ThunderboltPort(
                        id: "thunderbolt-port-\(router.uid)-\(connector.hostPortNumber)",
                        controllerID: router.controllerID,
                        connectorNumber: connector.connectorNumber,
                        protocolVersion: router.protocolVersion,
                        maximumSpeedMbps: router.maximumSpeedMbps,
                        connectedDevice: attachment?.device
                    )
                )
            }
        }

        return ports.sorted {
            $0.connectorNumber < $1.connectorNumber
                || ($0.connectorNumber == $1.connectorNumber && $0.id < $1.id)
        }
    }

    private func representsSamePhysicalDevice(
        _ usbDevice: USBDevice,
        as thunderboltDevice: USBDevice
    ) -> Bool {
        guard usbDevice.transport == .usb,
            thunderboltDevice.transport == .thunderbolt,
            // A USB-C Billboard interface is a standardized companion to a
            // native Thunderbolt/USB4 device. Restricting de-duplication to
            // it avoids hiding an unrelated USB product with the same name.
            usbDevice.isThunderboltBillboard,
            let usbVendor = normalizedVendor(usbDevice.vendor),
            let thunderboltVendor = normalizedVendor(thunderboltDevice.vendor)
        else {
            return false
        }

        return normalizedHardwareName(usbDevice.name) == normalizedHardwareName(thunderboltDevice.name)
            && usbVendor.caseInsensitiveCompare(thunderboltVendor) == .orderedSame
    }

    private func normalizedVendor(_ vendor: String?) -> String? {
        guard let vendor = vendor?.trimmingCharacters(in: .whitespacesAndNewlines),
            !vendor.isEmpty
        else {
            return nil
        }
        return vendor
    }

    private func normalizedHardwareName(_ value: String) -> String {
        String(value.lowercased().filter { $0.isLetter || $0.isNumber })
    }

    private func makeUSBDevice(from entry: io_registry_entry_t) -> USBDevice? {
        guard let properties = registryProperties(for: entry) else { return nil }

        let vendorID = properties.intValue(kUSBVendorID as String) ?? 0
        let productID = properties.intValue(kUSBProductID as String) ?? 0
        let registryName = registryName(for: entry) ?? "USB Device"
        let linkSpeed = deviceLinkSpeed(from: properties)
        let topologyContext = usbTopologyContext(for: entry)
        let locationId = properties.uint32Value(kUSBDevicePropertyLocationID as String)
        let parentHubContext = usbParentHubContext(
            for: entry,
            deviceLocationId: locationId
        )
        let isThunderboltTunneled =
            properties.boolValue("UsbTunnel") == true
            || topologyContext.isThunderboltTunneled
            || hasRegistryClass(
                "AppleUSBXHCITR",
                inParentPlane: "IOUSB",
                startingAt: entry
            )

        return USBDevice(
            name: properties.stringValue(kUSBProductString as String) ?? registryName,
            vendor: properties.stringValue(kUSBVendorString as String),
            vendorId: vendorID,
            productId: productID,
            serialNumber: properties.stringValue(kUSBSerialNumberString as String),
            locationId: locationId,
            speedMbps: linkSpeed ?? speedFromIOKitCode(properties.intValue(kUSBDevicePropertySpeed as String)),
            portMaxSpeedMbps: parentPortMaxSpeed(for: entry),
            usbVersionBCD: ["bcdUSB", "kUSBDevicePropertyUSBReleaseNumber", "USB-bcdUSB"]
                .compactMap(properties.intValue)
                .first,
            isExternalStorage: isExternalStorageDevice(entry),
            usbPortType: properties.intValue(kUSBHostMatchingPropertyPortType),
            deviceClass: properties.intValue("bDeviceClass"),
            isThunderboltBillboard: containsUSBInterfaceClass(entry, 0x11),
            thunderboltOwnerID: topologyContext.thunderboltOwnerID,
            isThunderboltTunneledUSB: isThunderboltTunneled,
            parentHubLocationId: parentHubContext?.locationId,
            parentHubPortNumber: parentHubContext?.portNumber
        )
    }

    private func usbParentHubContext(
        for entry: io_registry_entry_t,
        deviceLocationId: UInt32?
    ) -> (locationId: UInt32, portNumber: Int)? {
        var parent: io_registry_entry_t = 0
        guard IORegistryEntryGetParentEntry(entry, "IOUSB", &parent) == KERN_SUCCESS else {
            return nil
        }
        defer { IOObjectRelease(parent) }

        guard let properties = registryProperties(for: parent),
            properties.intValue("bDeviceClass") == 9,
            let parentLocationId = properties.uint32Value(kUSBDevicePropertyLocationID as String),
            let deviceLocationId,
            let portNumber = directUSBHubPortNumber(
                deviceLocationId: deviceLocationId,
                parentHubLocationId: parentLocationId
            )
        else {
            return nil
        }

        return (parentLocationId, portNumber)
    }

    private func directUSBHubPortNumber(
        deviceLocationId: UInt32,
        parentHubLocationId: UInt32
    ) -> Int? {
        guard deviceLocationId >> 24 == parentHubLocationId >> 24 else { return nil }

        for shift in stride(from: 20, through: 0, by: -4) {
            let deviceNibble = Int((deviceLocationId >> UInt32(shift)) & 0x0F)
            let parentNibble = Int((parentHubLocationId >> UInt32(shift)) & 0x0F)
            if deviceNibble != parentNibble {
                return deviceNibble > 0 ? deviceNibble : nil
            }
        }
        return nil
    }

    /// Intel Thunderbolt controllers such as AppleUSBXHCITR live below the
    /// external Thunderbolt router in the IOService plane. Walking that real
    /// parent chain associates their USB hubs with the dock without assuming
    /// that a USB location-ID byte equals a Thunderbolt controller number.
    private func usbTopologyContext(
        for entry: io_registry_entry_t
    ) -> (thunderboltOwnerID: String?, isThunderboltTunneled: Bool) {
        var current = entry
        var currentIsRetained = false
        var isThunderboltTunneled = false

        while true {
            if registryClassName(for: current) == "AppleUSBXHCITR" {
                isThunderboltTunneled = true
            }

            if current != entry, let device = makeThunderboltDevice(from: current) {
                if currentIsRetained { IOObjectRelease(current) }
                return (device.id, isThunderboltTunneled)
            }

            var parent: io_registry_entry_t = 0
            guard IORegistryEntryGetParentEntry(current, kIOServicePlane, &parent) == KERN_SUCCESS else {
                if currentIsRetained { IOObjectRelease(current) }
                return (nil, isThunderboltTunneled)
            }

            if currentIsRetained { IOObjectRelease(current) }
            current = parent
            currentIsRetained = true
        }
    }

    /// USB devices can participate in several IORegistry planes at once. On
    /// Intel Macs, `ioreg -p IOUSB` exposes AppleUSBXHCITR as the hub's parent
    /// even when the IOService provider chain does not. Follow that USB-plane
    /// topology explicitly instead of treating both planes as interchangeable.
    private func hasRegistryClass(
        _ className: String,
        inParentPlane plane: String,
        startingAt entry: io_registry_entry_t
    ) -> Bool {
        var current = entry
        var currentIsRetained = false

        while true {
            if registryClassName(for: current) == className {
                if currentIsRetained { IOObjectRelease(current) }
                return true
            }

            var parent: io_registry_entry_t = 0
            guard IORegistryEntryGetParentEntry(current, plane, &parent) == KERN_SUCCESS else {
                if currentIsRetained { IOObjectRelease(current) }
                return false
            }

            if currentIsRetained { IOObjectRelease(current) }
            current = parent
            currentIsRetained = true
        }
    }

    private func makeThunderboltDevice(from entry: io_registry_entry_t) -> USBDevice? {
        guard let properties = registryProperties(for: entry),
            // Local controllers use route 0. A positive route identifies a
            // physical Thunderbolt/USB4 device connected to that controller.
            let route = properties.uint64Value("Route String"),
            route > 0,
            let name = properties.stringValue("Device Model Name"),
            !name.isEmpty
        else {
            return nil
        }

        let locationID = UInt32(truncatingIfNeeded: route)

        let transportIdentifier = properties.numberValue("UID").map {
            String(format: "%016llX", $0.uint64Value)
        }

        return USBDevice(
            name: name,
            vendor: properties.stringValue("Device Vendor Name"),
            vendorId: properties.intValue("Device Vendor ID")
                ?? properties.intValue("Vendor ID")
                ?? 0,
            productId: properties.intValue("Device Model ID")
                ?? properties.intValue("Device ID")
                ?? 0,
            serialNumber: nil,
            locationId: locationID,
            speedMbps: thunderboltLinkSpeed(from: entry),
            portMaxSpeedMbps: nil,
            usbVersionBCD: nil,
            isExternalStorage: nil,
            transport: .thunderbolt,
            transportVersion: thunderboltTransportVersion(
                from: properties.intValue("Thunderbolt Version")
            ),
            transportIdentifier: transportIdentifier
        )
    }

    private func makeThunderboltHostRouter(
        from entry: io_registry_entry_t,
        properties: RegistryProperties
    ) -> ThunderboltHostRouterRecord? {
        guard let controllerID = properties.intValue("Router ID") else { return nil }

        let uid =
            properties.numberValue("UID").map {
                String(format: "%016llX", $0.uint64Value)
            } ?? "controller-\(controllerID)"

        let connectors = thunderboltHostConnectors(
            for: entry,
            fallbackConnectorNumber: controllerID + 1
        )

        return ThunderboltHostRouterRecord(
            controllerID: controllerID,
            uid: uid,
            protocolVersion: properties.intValue("Thunderbolt Version"),
            maximumSpeedMbps: thunderboltLinkSpeed(from: entry),
            connectors: connectors
        )
    }

    private func thunderboltHostConnectors(
        for entry: io_registry_entry_t,
        fallbackConnectorNumber: Int
    ) -> [ThunderboltConnectorRecord] {
        var iterator: io_iterator_t = 0
        guard
            IORegistryEntryGetChildIterator(entry, kIOServicePlane, &iterator) == KERN_SUCCESS
        else {
            return [
                ThunderboltConnectorRecord(
                    connectorNumber: fallbackConnectorNumber,
                    hostPortNumber: 1,
                    connectedDevice: nil
                )
            ]
        }
        defer { IOObjectRelease(iterator) }

        var connectors: [ThunderboltConnectorRecord] = []
        while case let child = IOIteratorNext(iterator), child != 0 {
            if let properties = registryProperties(for: child),
                properties.intValue("Adapter Type") == 1,
                properties.intValue("Lane") == 1,
                let hostPortNumber = properties.intValue("Port Number")
            {
                let connectorNumber =
                    properties.intValueOrString("Socket ID")
                    ?? fallbackConnectorNumber
                connectors.append(
                    ThunderboltConnectorRecord(
                        connectorNumber: connectorNumber,
                        hostPortNumber: hostPortNumber,
                        connectedDevice: nil
                    )
                )
            }
            IOObjectRelease(child)
        }

        if connectors.isEmpty {
            connectors.append(
                ThunderboltConnectorRecord(
                    connectorNumber: fallbackConnectorNumber,
                    hostPortNumber: 1,
                    connectedDevice: nil
                )
            )
        }

        return connectors.sorted {
            $0.connectorNumber < $1.connectorNumber
                || ($0.connectorNumber == $1.connectorNumber && $0.hostPortNumber < $1.hostPortNumber)
        }
    }

    private func thunderboltDownstreamConnectors(
        for entry: io_registry_entry_t
    ) -> [ThunderboltConnectorRecord] {
        var iterator: io_iterator_t = 0
        guard
            IORegistryEntryGetChildIterator(entry, kIOServicePlane, &iterator) == KERN_SUCCESS
        else {
            return []
        }
        defer { IOObjectRelease(iterator) }

        var connectors: [ThunderboltConnectorRecord] = []
        while case let child = IOIteratorNext(iterator), child != 0 {
            if let properties = registryProperties(for: child),
                properties.intValue("Adapter Type") == 1,
                properties.intValue("Lane") == 1,
                let portNumber = properties.intValue("Port Number")
            {
                connectors.append(
                    ThunderboltConnectorRecord(
                        connectorNumber: portNumber,
                        hostPortNumber: portNumber,
                        connectedDevice: firstThunderboltDeviceDescendant(of: child)
                    )
                )
            }
            IOObjectRelease(child)
        }

        return connectors.sorted { $0.hostPortNumber < $1.hostPortNumber }
    }

    private func firstThunderboltDeviceDescendant(
        of entry: io_registry_entry_t
    ) -> USBDevice? {
        var iterator: io_iterator_t = 0
        guard
            IORegistryEntryCreateIterator(
                entry,
                kIOServicePlane,
                IOOptionBits(kIORegistryIterateRecursively),
                &iterator
            ) == KERN_SUCCESS
        else {
            return nil
        }
        defer { IOObjectRelease(iterator) }

        while case let child = IOIteratorNext(iterator), child != 0 {
            let device = makeThunderboltDevice(from: child)
            IOObjectRelease(child)
            if let device {
                return device
            }
        }
        return nil
    }

    private func parentThunderboltPortNumber(for entry: io_registry_entry_t) -> Int? {
        var parent: io_registry_entry_t = 0
        guard IORegistryEntryGetParentEntry(entry, kIOServicePlane, &parent) == KERN_SUCCESS else {
            return nil
        }
        defer { IOObjectRelease(parent) }
        return registryProperties(for: parent)?.intValue("Port Number")
    }

    private func rootThunderboltRouterID(for entry: io_registry_entry_t) -> Int? {
        var current = entry
        var currentIsRetained = false

        while true {
            if let properties = registryProperties(for: current),
                properties.uint64Value("Route String") == 0,
                let routerID = properties.intValue("Router ID")
            {
                if currentIsRetained { IOObjectRelease(current) }
                return routerID
            }

            var parent: io_registry_entry_t = 0
            guard IORegistryEntryGetParentEntry(current, kIOServicePlane, &parent) == KERN_SUCCESS else {
                if currentIsRetained { IOObjectRelease(current) }
                return nil
            }

            if currentIsRetained { IOObjectRelease(current) }
            current = parent
            currentIsRetained = true
        }
    }

    private func deviceLinkSpeed(from properties: RegistryProperties) -> Int? {
        let candidates = [
            "kUSBDevicePropertyLinkSpeed", "LinkSpeed", "DeviceLinkSpeed", "link-speed",
        ]
        return candidates.compactMap { key in
            guard let bitsPerSecond = properties.doubleValue(key) else { return nil }
            return USBFormatting.megabitsPerSecond(fromBitsPerSecond: bitsPerSecond)
        }.first
    }

    private func speedFromIOKitCode(_ code: Int?) -> Int? {
        switch code {
        case 0: 2
        case 1: 12
        case 2: 480
        case 3: 5_000
        case 4: 10_000
        default: nil
        }
    }

    private func parentPortMaxSpeed(for entry: io_registry_entry_t) -> Int? {
        var parent: io_registry_entry_t = 0
        guard IORegistryEntryGetParentEntry(entry, kIOServicePlane, &parent) == KERN_SUCCESS else {
            return nil
        }
        defer { IOObjectRelease(parent) }

        guard let properties = registryProperties(for: parent) else { return nil }
        let candidates = [
            "kUSBHostPortPropertyLinkSpeed", "PortLinkSpeed", "PortSpeed",
            "LinkSpeed", "MaxLinkRate", "maxLinkSpeed",
        ]
        if let speed = candidates.compactMap({ key in
            properties.doubleValue(key).flatMap(USBFormatting.megabitsPerSecond)
        }).first {
            return speed
        }

        guard let portType = properties.stringValue("PortType") else { return nil }
        if portType.localizedCaseInsensitiveContains("SuperSpeedPlus") { return 10_000 }
        if portType.localizedCaseInsensitiveContains("SuperSpeed") { return 5_000 }
        return nil
    }

    private func isExternalStorageDevice(_ entry: io_registry_entry_t) -> Bool {
        var iterator: io_iterator_t = 0
        guard
            IORegistryEntryCreateIterator(
                entry,
                kIOServicePlane,
                IOOptionBits(kIORegistryIterateRecursively),
                &iterator
            ) == KERN_SUCCESS
        else {
            return false
        }
        defer { IOObjectRelease(iterator) }

        while true {
            let child = IOIteratorNext(iterator)
            guard child != 0 else { return false }
            defer { IOObjectRelease(child) }

            var className = [CChar](repeating: 0, count: 128)
            guard IOObjectGetClass(child, &className) == KERN_SUCCESS else { continue }

            let name = String(cString: className)
            if name.contains("IOUSBMassStorageInterface")
                || name.contains("IOBlockStorageDevice")
                || name.contains("IOMedia")
            {
                return true
            }
        }
    }

    private func containsUSBInterfaceClass(
        _ entry: io_registry_entry_t,
        _ interfaceClass: Int
    ) -> Bool {
        var iterator: io_iterator_t = 0
        guard
            IORegistryEntryCreateIterator(
                entry,
                kIOServicePlane,
                IOOptionBits(kIORegistryIterateRecursively),
                &iterator
            ) == KERN_SUCCESS
        else {
            return false
        }
        defer { IOObjectRelease(iterator) }

        while true {
            let child = IOIteratorNext(iterator)
            guard child != 0 else { return false }
            defer { IOObjectRelease(child) }

            if registryProperties(for: child)?.intValue("bInterfaceClass") == interfaceClass {
                return true
            }
        }
    }

    private func thunderboltTransportVersion(from rawVersion: Int?) -> String? {
        guard rawVersion != nil else { return nil }
        return USBFormatting.thunderboltProtocolLabel(for: rawVersion)
    }

    private func thunderboltLinkSpeed(from entry: io_registry_entry_t) -> Int? {
        var upstreamPort: io_registry_entry_t = 0
        guard IORegistryEntryGetParentEntry(entry, kIOServicePlane, &upstreamPort) == KERN_SUCCESS else {
            return nil
        }
        defer { IOObjectRelease(upstreamPort) }

        guard let linkBandwidth = registryProperties(for: upstreamPort)?.intValue("Link Bandwidth"),
            linkBandwidth > 0
        else {
            return nil
        }

        // IOThunderboltPort reports Link Bandwidth in 100 Mbit/s units.
        return USBFormatting.thunderboltMegabitsPerSecond(fromLinkBandwidth: linkBandwidth)
    }

    private func registryProperties(for entry: io_registry_entry_t) -> RegistryProperties? {
        var properties: Unmanaged<CFMutableDictionary>?
        guard
            IORegistryEntryCreateCFProperties(
                entry,
                &properties,
                kCFAllocatorDefault,
                0
            ) == KERN_SUCCESS,
            let dictionary = properties?.takeRetainedValue() as? [String: Any]
        else {
            return nil
        }
        return RegistryProperties(dictionary)
    }

    private func registryName(for entry: io_registry_entry_t) -> String? {
        var name = [CChar](repeating: 0, count: 128)
        guard IORegistryEntryGetName(entry, &name) == KERN_SUCCESS else { return nil }
        return String(cString: name)
    }

    private func registryClassName(for entry: io_registry_entry_t) -> String? {
        var name = [CChar](repeating: 0, count: 128)
        guard IOObjectGetClass(entry, &name) == KERN_SUCCESS else { return nil }
        return String(cString: name)
    }
}

struct USBTopologySnapshot: Equatable {
    let devices: [USBDevice]
    let thunderboltPorts: [ThunderboltPort]
    let externalThunderboltPortGroups: [ExternalThunderboltPortGroup]
}

private struct ThunderboltTopologyRecords {
    let devices: [USBDevice]
    let ports: [ThunderboltPort]
    let externalPortGroups: [ExternalThunderboltPortGroup]
}

private struct ThunderboltHostRouterRecord {
    let controllerID: Int
    let uid: String
    let protocolVersion: Int?
    let maximumSpeedMbps: Int?
    let connectors: [ThunderboltConnectorRecord]
}

private struct ThunderboltConnectorRecord {
    let connectorNumber: Int
    let hostPortNumber: Int
    let connectedDevice: USBDevice?
}

private struct ThunderboltDeviceAttachment {
    let controllerID: Int?
    let hostPortNumber: Int?
    let depth: Int
    let device: USBDevice
}

private struct ThunderboltDeviceRouterRecord {
    let controllerID: Int?
    let hostPortNumber: Int?
    let depth: Int
    let protocolVersion: Int?
    let device: USBDevice
    let downstreamConnectors: [ThunderboltConnectorRecord]
    let usbPortMap: [ThunderboltUSBPortMapEntry]

    var attachment: ThunderboltDeviceAttachment {
        ThunderboltDeviceAttachment(
            controllerID: controllerID,
            hostPortNumber: hostPortNumber,
            depth: depth,
            device: device
        )
    }
}

private struct RegistryProperties {
    let values: [String: Any]

    init(_ values: [String: Any]) {
        self.values = values
    }

    func numberValue(_ key: String) -> NSNumber? {
        values[key] as? NSNumber
    }

    func intValue(_ key: String) -> Int? {
        numberValue(key)?.intValue
    }

    func uint32Value(_ key: String) -> UInt32? {
        numberValue(key)?.uint32Value
    }

    func uint64Value(_ key: String) -> UInt64? {
        numberValue(key)?.uint64Value
    }

    func doubleValue(_ key: String) -> Double? {
        numberValue(key)?.doubleValue
    }

    func boolValue(_ key: String) -> Bool? {
        numberValue(key)?.boolValue
    }

    func dataValue(_ key: String) -> Data? {
        values[key] as? Data
    }

    func stringValue(_ key: String) -> String? {
        values[key] as? String
    }

    func intValueOrString(_ key: String) -> Int? {
        intValue(key) ?? stringValue(key).flatMap(Int.init)
    }
}
