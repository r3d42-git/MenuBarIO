import SystemConfiguration

protocol EthernetLinkReading {
    func isConnected() -> Bool
}

final class EthernetLinkReader: EthernetLinkReading {
    private lazy var dynamicStore: SCDynamicStore? = {
        var context = SCDynamicStoreContext(
            version: 0,
            info: nil,
            retain: nil,
            release: nil,
            copyDescription: nil
        )
        return SCDynamicStoreCreate(nil, "EthernetStatus" as CFString, nil, &context)
    }()

    /// Reads only the local link-state published by macOS. No traffic counters,
    /// packet data, or network request is involved.
    func isConnected() -> Bool {
        guard let dynamicStore else { return false }

        for interface in ethernetInterfaces {
            let key = "State:/Network/Interface/\(interface)/Link" as CFString
            if let value = SCDynamicStoreCopyValue(dynamicStore, key) as? [String: Any],
                value["Active"] as? Bool == true
            {
                return true
            }
        }
        return false
    }

    private var ethernetInterfaces: [String] {
        guard let interfaces = SCNetworkInterfaceCopyAll() as? [SCNetworkInterface] else {
            return []
        }
        return interfaces.compactMap { interface in
            guard
                SCNetworkInterfaceGetInterfaceType(interface) as String?
                    == kSCNetworkInterfaceTypeEthernet as String
            else {
                return nil
            }
            return SCNetworkInterfaceGetBSDName(interface) as String?
        }
    }
}
