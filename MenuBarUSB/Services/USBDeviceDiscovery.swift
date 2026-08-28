import Foundation
import IOKit
import IOKit.usb

protocol USBDeviceDiscovering {
    func connectedDevices() -> [USBDevice]
}

final class USBDeviceDiscovery: USBDeviceDiscovering {
    static let usbDeviceClassNames = [kIOUSBHostDeviceClassName, kIOUSBDeviceClassName]

    func connectedDevices() -> [USBDevice] {
        let thunderboltDevices = fetchThunderboltDevices()
        var devices = fetchUSBDevices().filter { usbDevice in
            !thunderboltDevices.contains { thunderboltDevice in
                representsSamePhysicalDevice(usbDevice, as: thunderboltDevice)
            }
        }
        var seenDeviceIDs = Set(devices.map(\.id))

        for device in thunderboltDevices where seenDeviceIDs.insert(device.id).inserted {
            devices.append(device)
        }

        return devices
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

    private func fetchThunderboltDevices() -> [USBDevice] {
        let matching = IOServiceMatching(USBConnectionMonitor.thunderboltClassName)
        var iterator: io_iterator_t = 0

        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else {
            return []
        }
        defer { IOObjectRelease(iterator) }

        var devices: [USBDevice] = []
        while case let entry = IOIteratorNext(iterator), entry != 0 {
            if let device = makeThunderboltDevice(from: entry) {
                devices.append(device)
            }
            IOObjectRelease(entry)
        }
        return devices
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

        return USBDevice(
            name: properties.stringValue(kUSBProductString as String) ?? registryName,
            vendor: properties.stringValue(kUSBVendorString as String),
            vendorId: vendorID,
            productId: productID,
            serialNumber: properties.stringValue(kUSBSerialNumberString as String),
            locationId: properties.uint32Value(kUSBDevicePropertyLocationID as String),
            speedMbps: linkSpeed ?? speedFromIOKitCode(properties.intValue(kUSBDevicePropertySpeed as String)),
            portMaxSpeedMbps: parentPortMaxSpeed(for: entry),
            usbVersionBCD: ["bcdUSB", "kUSBDevicePropertyUSBReleaseNumber", "USB-bcdUSB"]
                .compactMap(properties.intValue)
                .first,
            isExternalStorage: isExternalStorageDevice(entry),
            usbPortType: properties.intValue(kUSBHostMatchingPropertyPortType),
            deviceClass: properties.intValue("bDeviceClass"),
            isThunderboltBillboard: containsUSBInterfaceClass(entry, 0x11)
        )
    }

    private func makeThunderboltDevice(from entry: io_registry_entry_t) -> USBDevice? {
        guard let properties = registryProperties(for: entry),
            // Local controllers use route 0. A positive route identifies a
            // physical Thunderbolt/USB4 device connected to that controller.
            let locationID = properties.uint32Value("Route String"),
            locationID > 0,
            let name = properties.stringValue("Device Model Name"),
            !name.isEmpty
        else {
            return nil
        }

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
        // These values are how IOKit represents the USB4 modes shown by
        // System Information on current Apple platforms.
        switch rawVersion {
        case 32: "USB4"
        case 64: "USB4 v2"
        default: nil
        }
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

    func doubleValue(_ key: String) -> Double? {
        numberValue(key)?.doubleValue
    }

    func stringValue(_ key: String) -> String? {
        values[key] as? String
    }
}
