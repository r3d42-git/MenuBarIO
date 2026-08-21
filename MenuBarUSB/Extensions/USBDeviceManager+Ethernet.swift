//
//  USBDeviceManager+Ethernet.swift
//  MenuBarUSB
//

import SystemConfiguration

extension USBDeviceManager {
    /// Reads only the local link-state published by macOS. No traffic counters,
    /// packet data, or network request is involved.
    func isEthernetConnected() -> Bool {
        guard let store = persistentEthernetStore else { return false }

        for interface in ethernetInterfaces {
            let key = "State:/Network/Interface/\(interface)/Link" as CFString
            if let value = SCDynamicStoreCopyValue(store, key) as? [String: Any],
               let active = value["Active"] as? Bool,
               active
            {
                return true
            }
        }
        return false
    }

    private var ethernetInterfaces: [String] {
        guard let interfaces = SCNetworkInterfaceCopyAll() as? [SCNetworkInterface] else { return [] }
        return interfaces.compactMap { interface in
            guard SCNetworkInterfaceGetInterfaceType(interface) as String? == kSCNetworkInterfaceTypeEthernet as String else {
                return nil
            }
            return SCNetworkInterfaceGetBSDName(interface) as String?
        }
    }
}
