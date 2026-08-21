import Foundation
import IOKit
import IOKit.network
import IOKit.ps
import IOKit.usb
import SwiftUI
import SystemConfiguration
import UserNotifications

final class USBDeviceManager: ObservableObject {
    @Published private(set) var devices: [USBDeviceWrapper] = []
    @Published var connectedCamouflagedDevices: Int = 0

    @Published var count: Int = 0
    @Published var chargeConnected: Bool = false
    @Published var chargePercentage: Int?
    @Published var ethernetCableConnected: Bool = false

    private var powerSourceRunLoopSource: CFRunLoopSource?
    private var notifyPort: IONotificationPortRef?
    private var addedIterator: io_iterator_t = 0
    private var removedIterator: io_iterator_t = 0
    private var thunderboltAddedIterator: io_iterator_t = 0
    private var thunderboltRemovedIterator: io_iterator_t = 0
    private var isInitialPowerState = true

    lazy var persistentEthernetStore: SCDynamicStore? = {
        var context = SCDynamicStoreContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
        return SCDynamicStoreCreate(nil, "EthernetStatus" as CFString, nil, &context)
    }()

    @AS(Key.showNotifications) private var showNotifications = false
    @AS(Key.disableNotifCooldown) private var disableNotifCooldown = false
    @AS(Key.powerSourceInfo) private var powerSourceInfo: Bool = false
    @AS(Key.storeConnectionLogs) private var storeConnectionLogs: Bool = false
    @AS(Key.showEthernet) var showEthernet = false
    @AS(Key.storeDevices) private var storeDevices = false

    private var lastNotificationDate: Date = .distantPast
    private let notificationCooldown: TimeInterval = 3

    init() {
        if powerSourceInfo {
            startPowerMonitoring()
        }

        startMonitoring()

        refresh()
    }

    deinit {
        stopMonitoring()
    }

    private func setCount() {
        // The status-item count mirrors the visible "USB-Geräte" group. Standard
        // USB hubs stay available in their own group, but are not user devices.
        count = devices.filter { !$0.item.isHub }.count
    }

    private var canSendNotification: Bool {
        if disableNotifCooldown {
            return true
        }
        let now = Date()
        if now.timeIntervalSince(lastNotificationDate) < notificationCooldown {
            return false
        }
        lastNotificationDate = now
        return true
    }

    func refresh() {
        let powerSourceInfoEnabled = powerSourceInfo
        let showEthernetEnabled = showEthernet

        DispatchQueue.global(qos: .utility).async {
            let snapshot = self.fetchConnectedDevices()

            var seenIds = Set<String>()
            var uniqueDevices: [USBDeviceWrapper] = []
            for device in snapshot {
                let id = device.item.uniqueId
                if !seenIds.contains(id) {
                    seenIds.insert(id)
                    uniqueDevices.append(device)
                }
            }

            let camouflagedIds = Set(CSM.Camouflaged.devices.map { $0.deviceId })
            var filteredDevices: [USBDeviceWrapper] = []
            var camouflagedCount = 0

            for device in uniqueDevices {
                let id = device.item.uniqueId
                if camouflagedIds.contains(id) {
                    camouflagedCount += 1
                } else {
                    filteredDevices.append(device)
                }
            }

            DispatchQueue.main.async {
                self.devices = filteredDevices.sorted(by: {
                    ($0.item.vendor ?? "") < ($1.item.vendor ?? "") ||
                        ($0.item.vendor == $1.item.vendor && $0.item.name < $1.item.name)
                })

                self.connectedCamouflagedDevices = camouflagedCount
                self.setCount()
            }

            if powerSourceInfoEnabled, self.isChargerConnected {
                let value = self.getChargePercentage()
                DispatchQueue.main.async {
                    self.chargePercentage = value
                }
            }

            if showEthernetEnabled {
                let ethernetStatus = self.isEthernetConnected()
                DispatchQueue.main.async {
                    self.ethernetCableConnected = ethernetStatus
                }

                if !ethernetStatus {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.3) {
                        let retryStatus = self.isEthernetConnected()
                        DispatchQueue.main.async {
                            self.ethernetCableConnected = retryStatus
                        }
                    }
                }
            }
        }
    }

    func addDummy(amount: Int) {
        guard amount > 0 else { return }

        var dummyDevices: [USBDeviceWrapper] = []
        for i in 0 ..< amount {
            let newDevice = USBDevice(
                name: "Dummy (\(i))",
                vendor: "Dummy Vendor",
                vendorId: i,
                productId: i,
                serialNumber: "\(i)-DUMMY",
                locationId: UInt32(i),
                speedMbps: i,
                portMaxSpeedMbps: i,
                usbVersionBCD: i,
                isExternalStorage: false
            )
            let newDeviceWrapper = USBDeviceWrapper(newDevice)
            dummyDevices.append(newDeviceWrapper)
        }

        DispatchQueue.main.async {
            self.devices.append(contentsOf: dummyDevices)
            self.setCount()
            for device in dummyDevices {
                CSM.ConnectionLog.add(withId: device.item.uniqueId, disconnect: false)
            }
        }
    }

    private func isExternalStorageDevice(_ entry: io_registry_entry_t) -> Bool {
        var iterator: io_iterator_t = 0
        guard IORegistryEntryCreateIterator(
            entry,
            kIOServicePlane,
            IOOptionBits(kIORegistryIterateRecursively),
            &iterator
        ) == KERN_SUCCESS else {
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
            if name.contains("IOUSBMassStorageInterface") ||
                name.contains("IOBlockStorageDevice") ||
                name.contains("IOMedia")
            {
                return true
            }
        }
    }

    private func startPowerMonitoring() {
        let callback: IOPowerSourceCallbackType = { context in
            let mySelf = Unmanaged<USBDeviceManager>
                .fromOpaque(context!)
                .takeUnretainedValue()

            DispatchQueue.global(qos: .utility).async {
                mySelf.updatePowerState()
            }
        }

        let refcon = Unmanaged.passUnretained(self).toOpaque()

        if let source = IOPSNotificationCreateRunLoopSource(callback, refcon)?.takeRetainedValue() {
            powerSourceRunLoopSource = source
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .defaultMode)
        }

        DispatchQueue.global(qos: .utility).async {
            self.updatePowerState()
        }
    }

    private func updatePowerState() {
        if !powerSourceInfo {
            DispatchQueue.main.async {
                self.chargePercentage = nil
            }
            return
        }

        let charging = isChargerConnected
        let percentage = getChargePercentage()

        DispatchQueue.main.async {
            if self.isInitialPowerState {
                self.isInitialPowerState = false
                self.chargeConnected = charging
                self.chargePercentage = charging ? percentage : nil
                return
            }

            if self.chargeConnected != charging && self.storeConnectionLogs {
                CSM.ConnectionLog.addChargerLog(disconnect: !charging)
            }

            if self.chargeConnected != charging,
               self.showNotifications,
               self.canSendNotification
            {
                Utils.TemplateNotification.charger(self.chargePercentage, charging: charging)
            }

            self.chargeConnected = charging
            self.chargePercentage = charging ? percentage : nil
        }
    }

    private var isChargerConnected: Bool {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef]
        else { return false }

        for ps in sources {
            guard let description = IOPSGetPowerSourceDescription(snapshot, ps)?
                .takeUnretainedValue() as? [String: Any] else { continue }

            if let state = description[kIOPSPowerSourceStateKey as String] as? String {
                if state == kIOPSACPowerValue {
                    return true
                }
            }

            if let external = description["ExternalConnected"] as? Bool {
                if external { return true }
            }
        }

        return false
    }

    private func getChargePercentage() -> Int? {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef]
        else { return nil }

        for ps in sources {
            guard let description = IOPSGetPowerSourceDescription(snapshot, ps)?
                .takeUnretainedValue() as? [String: Any] else { continue }

            if let type = description[kIOPSTypeKey as String] as? String,
               type == kIOPSInternalBatteryType as String,
               let current = description[kIOPSCurrentCapacityKey as String] as? Int,
               let max = description[kIOPSMaxCapacityKey as String] as? Int
            {
                return Int((Double(current) / Double(max)) * 100)
            }
        }

        return nil
    }

    private func fetchUSBDevices() -> [USBDeviceWrapper] {
        var result: [USBDeviceWrapper] = []
        var seenDeviceIds = Set<String>()

        func addUniqueDevices(from name: String) {
            let devices = fetchMatchingDevices(name: name)
            for device in devices {
                let deviceId = device.item.uniqueId
                if !seenDeviceIds.contains(deviceId) {
                    result.append(device)
                    seenDeviceIds.insert(deviceId)
                }
            }
        }

        addUniqueDevices(from: "IOUSBHostDevice")
        addUniqueDevices(from: kIOUSBDeviceClassName)

        return result
    }

    private func fetchConnectedDevices() -> [USBDeviceWrapper] {
        let thunderboltDevices = fetchThunderboltDevices()
        var result = fetchUSBDevices().filter { usbDevice in
            !thunderboltDevices.contains { thunderboltDevice in
                representsSamePhysicalDevice(usbDevice, as: thunderboltDevice)
            }
        }
        var seenDeviceIds = Set(result.map { $0.item.uniqueId })

        for device in thunderboltDevices {
            let deviceId = device.item.uniqueId
            if seenDeviceIds.insert(deviceId).inserted {
                result.append(device)
            }
        }

        return result
    }

    private func representsSamePhysicalDevice(
        _ usbDevice: USBDeviceWrapper,
        as thunderboltDevice: USBDeviceWrapper
    ) -> Bool {
        guard usbDevice.item.transport == .usb,
              thunderboltDevice.item.transport == .thunderbolt,
              // A USB-C Billboard interface is a standardized companion to a
              // native Thunderbolt/USB4 device. Restricting de-duplication to
              // it avoids hiding an unrelated USB product with the same name.
              usbDevice.item.isThunderboltBillboard,
              let usbVendor = usbDevice.item.vendor?.trimmingCharacters(in: .whitespacesAndNewlines),
              let thunderboltVendor = thunderboltDevice.item.vendor?.trimmingCharacters(in: .whitespacesAndNewlines),
              !usbVendor.isEmpty,
              !thunderboltVendor.isEmpty
        else {
            return false
        }

        let normalizedUSBName = normalizedHardwareName(usbDevice.item.name)
        let normalizedThunderboltName = normalizedHardwareName(thunderboltDevice.item.name)

        return normalizedUSBName == normalizedThunderboltName &&
            usbVendor.caseInsensitiveCompare(thunderboltVendor) == .orderedSame
    }

    private func normalizedHardwareName(_ value: String) -> String {
        String(value.lowercased().filter { $0.isLetter || $0.isNumber })
    }

    private func fetchMatchingDevices(name: String) -> [USBDeviceWrapper] {
        var result: [USBDeviceWrapper] = []
        let matching = IOServiceMatching(name)

        var iterator: io_iterator_t = 0
        let kr = IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator)
        guard kr == KERN_SUCCESS else { return [] }
        defer { IOObjectRelease(iterator) }

        while case let entry = IOIteratorNext(iterator), entry != 0 {
            if let dev = makeDevice(from: entry) {
                if storeDevices {
                    CSM.Stored.add(dev)
                }
                result.append(dev)
            }
            IOObjectRelease(entry)
        }
        return result
    }

    private func fetchThunderboltDevices() -> [USBDeviceWrapper] {
        var result: [USBDeviceWrapper] = []
        let matching = IOServiceMatching("IOThunderboltSwitch")

        var iterator: io_iterator_t = 0
        let kr = IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator)
        guard kr == KERN_SUCCESS else { return [] }
        defer { IOObjectRelease(iterator) }

        while case let entry = IOIteratorNext(iterator), entry != 0 {
            if let device = makeThunderboltDevice(from: entry) {
                if storeDevices {
                    CSM.Stored.add(device)
                }
                result.append(device)
            }
            IOObjectRelease(entry)
        }

        return result
    }

    private func makeDevice(from entry: io_registry_entry_t) -> USBDeviceWrapper? {
        var props: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(entry, &props, kCFAllocatorDefault, 0) == KERN_SUCCESS,
              let dict = props?.takeRetainedValue() as? [String: Any] else { return nil }

        func num(_ key: String) -> NSNumber? { dict[key] as? NSNumber }
        func intValue(_ key: String) -> Int? { num(key)?.intValue }
        func uint32Value(_ key: String) -> UInt32? { num(key)?.uint32Value }
        func doubleValue(_ key: String) -> Double? { num(key)?.doubleValue }
        func stringValue(_ key: String) -> String? { dict[key] as? String }

        let vendorId = intValue(kUSBVendorID as String) ?? 0
        let productId = intValue(kUSBProductID as String) ?? 0
        let registryName = tryGetIORegistryName(entry) ?? "USB Device"
        let productString = stringValue(kUSBProductString as String)
        let vendorString = stringValue(kUSBVendorString as String)
        let serial = stringValue(kUSBSerialNumberString as String)
        let locationId = uint32Value(kUSBDevicePropertyLocationID as String)
        let deviceClass = intValue("bDeviceClass")

        let linkSpeedBpsCandidates = [
            "kUSBDevicePropertyLinkSpeed", "LinkSpeed", "DeviceLinkSpeed", "link-speed",
        ]
        let linkSpeedBps: Double? = linkSpeedBpsCandidates
            .compactMap { doubleValue($0) ?? intValue($0).map(Double.init) }
            .first
        let linkSpeedMbpsFromDevice = linkSpeedBps.map { Int($0 / 1_000_000.0) }

        let speedCode = intValue(kUSBDevicePropertySpeed as String)
        let speedMbpsFromCode: Int? = speedCode.flatMap {
            switch $0 {
            case 0: return 2
            case 1: return 12
            case 2: return 480
            case 3: return 5000
            case 4: return 10000
            default: return nil
            }
        }

        func parentPortMaxMbps(_ entry: io_registry_entry_t) -> Int? {
            var parent: io_registry_entry_t = 0
            guard IORegistryEntryGetParentEntry(entry, kIOServicePlane, &parent) == KERN_SUCCESS else { return nil }
            defer { IOObjectRelease(parent) }

            var pprops: Unmanaged<CFMutableDictionary>?
            guard IORegistryEntryCreateCFProperties(parent, &pprops, kCFAllocatorDefault, 0) == KERN_SUCCESS,
                  let pdict = pprops?.takeRetainedValue() as? [String: Any] else { return nil }

            func pnum(_ k: String) -> NSNumber? { pdict[k] as? NSNumber }
            func pint(_ k: String) -> Int? { pnum(k)?.intValue }
            func pdouble(_ k: String) -> Double? { pnum(k)?.doubleValue }

            let candidates = [
                "kUSBHostPortPropertyLinkSpeed", "PortLinkSpeed", "PortSpeed",
                "LinkSpeed", "MaxLinkRate", "maxLinkSpeed",
            ]
            if let bps = candidates.compactMap({ pdouble($0) ?? pint($0).map(Double.init) }).first {
                return Int(bps / 1_000_000.0)
            }

            if let portType = pdict["PortType"] as? String {
                if portType.localizedCaseInsensitiveContains("SuperSpeedPlus") { return 10000 }
                if portType.localizedCaseInsensitiveContains("SuperSpeed") { return 5000 }
            }
            return nil
        }

        let portMaxSpeedMbps = parentPortMaxMbps(entry)
        let bcdUSBCandidates = ["bcdUSB", "kUSBDevicePropertyUSBReleaseNumber", "USB-bcdUSB"]
        let usbVersionBCD = bcdUSBCandidates.compactMap { intValue($0) }.first
        let speedMbps = linkSpeedMbpsFromDevice ?? speedMbpsFromCode

        let wrapper = USBDeviceWrapper(USBDevice(
            name: productString ?? registryName,
            vendor: vendorString,
            vendorId: vendorId,
            productId: productId,
            serialNumber: serial,
            locationId: locationId,
            speedMbps: speedMbps,
            portMaxSpeedMbps: portMaxSpeedMbps,
            usbVersionBCD: usbVersionBCD,
            isExternalStorage: isExternalStorageDevice(entry),
            deviceClass: deviceClass,
            isThunderboltBillboard: containsUSBInterfaceClass(entry, 0x11)
        ))

        return wrapper
    }

    private func containsUSBInterfaceClass(
        _ entry: io_registry_entry_t,
        _ interfaceClass: Int
    ) -> Bool {
        var iterator: io_iterator_t = 0
        guard IORegistryEntryCreateIterator(
            entry,
            kIOServicePlane,
            IOOptionBits(kIORegistryIterateRecursively),
            &iterator
        ) == KERN_SUCCESS else {
            return false
        }
        defer { IOObjectRelease(iterator) }

        while true {
            let child = IOIteratorNext(iterator)
            guard child != 0 else { return false }
            defer { IOObjectRelease(child) }

            var properties: Unmanaged<CFMutableDictionary>?
            guard IORegistryEntryCreateCFProperties(
                child,
                &properties,
                kCFAllocatorDefault,
                0
            ) == KERN_SUCCESS,
            let dictionary = properties?.takeRetainedValue() as? [String: Any]
            else {
                continue
            }

            if (dictionary["bInterfaceClass"] as? NSNumber)?.intValue == interfaceClass {
                return true
            }
        }
    }

    private func makeThunderboltDevice(from entry: io_registry_entry_t) -> USBDeviceWrapper? {
        var props: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(entry, &props, kCFAllocatorDefault, 0) == KERN_SUCCESS,
              let dict = props?.takeRetainedValue() as? [String: Any]
        else { return nil }

        func intValue(_ key: String) -> Int? { (dict[key] as? NSNumber)?.intValue }
        func uint32Value(_ key: String) -> UInt32? { (dict[key] as? NSNumber)?.uint32Value }
        func stringValue(_ key: String) -> String? { dict[key] as? String }

        // The local controllers use route 0. A positive route identifies a
        // physical Thunderbolt/USB4 device connected to that controller.
        guard let locationId = uint32Value("Route String"), locationId > 0,
              let name = stringValue("Device Model Name"), !name.isEmpty
        else {
            return nil
        }

        let vendor = stringValue("Device Vendor Name")
        let vendorId = intValue("Device Vendor ID") ?? intValue("Vendor ID") ?? 0
        let productId = intValue("Device Model ID") ?? intValue("Device ID") ?? 0
        let transportVersion = thunderboltTransportVersion(
            from: intValue("Thunderbolt Version")
        )
        let transportIdentifier = (dict["UID"] as? NSNumber).map {
            String(format: "%016llX", $0.uint64Value)
        }
        let linkSpeedMbps = thunderboltLinkSpeedMbps(from: entry)

        return USBDeviceWrapper(USBDevice(
            name: name,
            vendor: vendor,
            vendorId: vendorId,
            productId: productId,
            serialNumber: nil,
            locationId: locationId,
            speedMbps: linkSpeedMbps,
            portMaxSpeedMbps: nil,
            usbVersionBCD: nil,
            isExternalStorage: nil,
            transport: .thunderbolt,
            transportVersion: transportVersion,
            transportIdentifier: transportIdentifier
        ))
    }

    private func thunderboltTransportVersion(from rawVersion: Int?) -> String? {
        // These values are how IOKit represents the USB4 modes shown by
        // System Information on current Apple platforms.
        switch rawVersion {
        case 32:
            return "USB4"
        case 64:
            return "USB4 v2"
        default:
            return nil
        }
    }

    private func thunderboltLinkSpeedMbps(from entry: io_registry_entry_t) -> Int? {
        var upstreamPort: io_registry_entry_t = 0
        guard IORegistryEntryGetParentEntry(entry, kIOServicePlane, &upstreamPort) == KERN_SUCCESS
        else {
            return nil
        }
        defer { IOObjectRelease(upstreamPort) }

        var properties: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(
            upstreamPort,
            &properties,
            kCFAllocatorDefault,
            0
        ) == KERN_SUCCESS,
        let dict = properties?.takeRetainedValue() as? [String: Any],
        let linkBandwidth = (dict["Link Bandwidth"] as? NSNumber)?.intValue,
        linkBandwidth > 0
        else {
            return nil
        }

        // IOThunderboltPort reports Link Bandwidth in 100 Mbit/s units.
        return linkBandwidth * 100
    }

    private func tryGetIORegistryName(_ entry: io_registry_entry_t) -> String? {
        var cName = [CChar](repeating: 0, count: 128)
        let res = IORegistryEntryGetName(entry, &cName)
        if res == KERN_SUCCESS {
            return String(cString: cName)
        }
        return nil
    }

    private func startMonitoring() {
        notifyPort = IONotificationPortCreate(kIOMainPortDefault)
        guard let notifyPort else { return }

        if let runloopSource = IONotificationPortGetRunLoopSource(notifyPort)?.takeUnretainedValue() {
            CFRunLoopAddSource(CFRunLoopGetMain(), runloopSource, .defaultMode)
        }

        let matchAdded = IOServiceMatching(kIOUSBDeviceClassName)
        let matchRemoved = IOServiceMatching(kIOUSBDeviceClassName)
        let thunderboltMatchAdded = IOServiceMatching("IOThunderboltSwitch")
        let thunderboltMatchRemoved = IOServiceMatching("IOThunderboltSwitch")

        let addedCallback: IOServiceMatchingCallback = { refcon, iterator in
            let mySelf = Unmanaged<USBDeviceManager>.fromOpaque(refcon!).takeUnretainedValue()

            var addedDevices: [USBDeviceWrapper] = []

            var service: io_object_t = IOIteratorNext(iterator)
            while service != 0 {
                if let wrapper = mySelf.makeDevice(from: service) {
                    addedDevices.append(wrapper)
                }

                IOObjectRelease(service)
                service = IOIteratorNext(iterator)
            }

            DispatchQueue.main.async {
                mySelf.refresh()
                
                if mySelf.storeConnectionLogs {
                    for dev in addedDevices {
                        let id = dev.item.uniqueId
                        CSM.ConnectionLog.add(withId: id, disconnect: false)
                    }
                }

                if mySelf.showNotifications, mySelf.canSendNotification {
                    let names = addedDevices.compactMap { dev -> String? in
                        let vendor = dev.item.vendor ?? ""
                        let name = dev.item.name
                        let combined = "\(vendor) \(name)".trimmingCharacters(in: .whitespaces)
                        return combined.isEmpty ? nil : combined
                    }

                    let deviceList = names.joined(separator: ", ")
                    
                    Utils.TemplateNotification.deviceConnection(devices: deviceList, connected: true)
                }
            }
        }

        let removedCallback: IOServiceMatchingCallback = { refcon, iterator in
            let mySelf = Unmanaged<USBDeviceManager>.fromOpaque(refcon!).takeUnretainedValue()

            var removedDevices: [USBDeviceWrapper] = []

            var service: io_object_t = IOIteratorNext(iterator)
            while service != 0 {
                if let wrapper = mySelf.makeDevice(from: service) {
                    removedDevices.append(wrapper)
                }

                IOObjectRelease(service)
                service = IOIteratorNext(iterator)
            }

            DispatchQueue.main.async {
                mySelf.refresh()
                
                if mySelf.storeConnectionLogs {
                    for dev in removedDevices {
                        let id = dev.item.uniqueId
                        CSM.ConnectionLog.add(withId: id, disconnect: true)
                    }
                }

                if mySelf.showNotifications, mySelf.canSendNotification {
                    let deviceList = removedDevices.map {
                        "\($0.item.vendor ?? "") \($0.item.name)"
                    }.joined(separator: ", ")

                    Utils.TemplateNotification.deviceConnection(devices: deviceList, connected: false)
                }
            }
        }

        let thunderboltAddedCallback: IOServiceMatchingCallback = { refcon, iterator in
            let mySelf = Unmanaged<USBDeviceManager>.fromOpaque(refcon!).takeUnretainedValue()
            var addedDevices: [USBDeviceWrapper] = []

            var service: io_object_t = IOIteratorNext(iterator)
            while service != 0 {
                if let wrapper = mySelf.makeThunderboltDevice(from: service) {
                    addedDevices.append(wrapper)
                }
                IOObjectRelease(service)
                service = IOIteratorNext(iterator)
            }

            mySelf.handleDeviceEvent(addedDevices, disconnect: false)
        }

        let thunderboltRemovedCallback: IOServiceMatchingCallback = { refcon, iterator in
            let mySelf = Unmanaged<USBDeviceManager>.fromOpaque(refcon!).takeUnretainedValue()
            var removedDevices: [USBDeviceWrapper] = []

            var service: io_object_t = IOIteratorNext(iterator)
            while service != 0 {
                if let wrapper = mySelf.makeThunderboltDevice(from: service) {
                    removedDevices.append(wrapper)
                }
                IOObjectRelease(service)
                service = IOIteratorNext(iterator)
            }

            mySelf.handleDeviceEvent(removedDevices, disconnect: true)
        }

        let refcon = Unmanaged.passUnretained(self).toOpaque()

        let kr1 = IOServiceAddMatchingNotification(
            notifyPort,
            kIOMatchedNotification,
            matchAdded,
            addedCallback,
            refcon,
            &addedIterator
        )
        if kr1 == KERN_SUCCESS {
            var service = IOIteratorNext(addedIterator)
            while service != 0 {
                IOObjectRelease(service)
                service = IOIteratorNext(addedIterator)
            }
        }

        let kr2 = IOServiceAddMatchingNotification(
            notifyPort,
            kIOTerminatedNotification,
            matchRemoved,
            removedCallback,
            refcon,
            &removedIterator
        )
        if kr2 == KERN_SUCCESS {
            var service = IOIteratorNext(removedIterator)
            while service != 0 {
                IOObjectRelease(service)
                service = IOIteratorNext(removedIterator)
            }
        }

        let kr3 = IOServiceAddMatchingNotification(
            notifyPort,
            kIOMatchedNotification,
            thunderboltMatchAdded,
            thunderboltAddedCallback,
            refcon,
            &thunderboltAddedIterator
        )
        if kr3 == KERN_SUCCESS {
            var service = IOIteratorNext(thunderboltAddedIterator)
            while service != 0 {
                IOObjectRelease(service)
                service = IOIteratorNext(thunderboltAddedIterator)
            }
        }

        let kr4 = IOServiceAddMatchingNotification(
            notifyPort,
            kIOTerminatedNotification,
            thunderboltMatchRemoved,
            thunderboltRemovedCallback,
            refcon,
            &thunderboltRemovedIterator
        )
        if kr4 == KERN_SUCCESS {
            var service = IOIteratorNext(thunderboltRemovedIterator)
            while service != 0 {
                IOObjectRelease(service)
                service = IOIteratorNext(thunderboltRemovedIterator)
            }
        }
    }

    private func handleDeviceEvent(_ devices: [USBDeviceWrapper], disconnect: Bool) {
        DispatchQueue.main.async {
            self.refresh()
            guard !devices.isEmpty else { return }

            if self.storeConnectionLogs {
                for device in devices {
                    CSM.ConnectionLog.add(withId: device.item.uniqueId, disconnect: disconnect)
                }
            }

            if self.showNotifications, self.canSendNotification {
                let deviceList = devices.map {
                    "\($0.item.vendor ?? "") \($0.item.name)"
                }.joined(separator: ", ")
                Utils.TemplateNotification.deviceConnection(devices: deviceList, connected: !disconnect)
            }
        }
    }

    private func stopMonitoring() {
        if let source = powerSourceRunLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .defaultMode)
        }
        powerSourceRunLoopSource = nil

        if addedIterator != 0 { IOObjectRelease(addedIterator); addedIterator = 0 }
        if removedIterator != 0 { IOObjectRelease(removedIterator); removedIterator = 0 }
        if thunderboltAddedIterator != 0 { IOObjectRelease(thunderboltAddedIterator); thunderboltAddedIterator = 0 }
        if thunderboltRemovedIterator != 0 { IOObjectRelease(thunderboltRemovedIterator); thunderboltRemovedIterator = 0 }
        if let notifyPort {
            if let runloopSource = IONotificationPortGetRunLoopSource(notifyPort)?.takeUnretainedValue() {
                CFRunLoopRemoveSource(CFRunLoopGetMain(), runloopSource, .defaultMode)
            }
            IONotificationPortDestroy(notifyPort)
            self.notifyPort = nil
        }
    }
}
