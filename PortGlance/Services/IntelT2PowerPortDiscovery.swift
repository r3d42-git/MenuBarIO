import Foundation
import IOKit

enum IntelT2PowerPortDiscovery {
    static func powerSourceConnectorNumber(
        batteryProperties: [String: Any]? = AppleSmartBatteryDiscovery.properties()
    ) -> Int? {
        guard let batteryProperties,
            let contracts = powerPortContracts(in: batteryProperties),
            !contracts.isEmpty
        else {
            return nil
        }

        return PowerPortResolver.connectorNumber(
            contracts: contracts,
            controllers: powerPortControllers(),
            thunderboltConnectors: thunderboltConnectors()
        )
    }

    private static func powerPortContracts(
        in batteryProperties: [String: Any]
    ) -> [PowerPortContractRecord]? {
        guard let controllers = batteryProperties["PortControllerInfo"] as? [[String: Any]]
        else {
            return nil
        }

        return controllers.compactMap { controller in
            guard let loserReason = integer("PortControllerLoserReason", in: controller),
                let powerDeliveryState = integer("PortControllerPDst", in: controller),
                let maximumPowerMilliwatts = integer("PortControllerMaxPower", in: controller),
                let fetStatus = integer("PortControllerFetStatus", in: controller)
            else {
                return nil
            }

            return PowerPortContractRecord(
                loserReason: loserReason,
                powerDeliveryState: powerDeliveryState,
                maximumPowerMilliwatts: maximumPowerMilliwatts,
                fetStatus: fetStatus
            )
        }
    }

    private static func powerPortControllers() -> [PowerPortControllerRecord] {
        matchingServices(className: "AppleHPMDevice").compactMap { entry in
            defer { IOObjectRelease(entry) }
            guard let values = properties(for: entry),
                let routerID = integer("RID", in: values),
                let address = integer("Address", in: values)
            else {
                return nil
            }
            return PowerPortControllerRecord(routerID: routerID, address: address)
        }
    }

    private static func thunderboltConnectors() -> [PowerPortThunderboltConnectorRecord] {
        var result: [PowerPortThunderboltConnectorRecord] = []

        for entry in matchingServices(className: "IOThunderboltSwitch") {
            defer { IOObjectRelease(entry) }
            guard let values = properties(for: entry),
                unsignedInteger("Route String", in: values) == 0,
                let routerID = integer("Router ID", in: values)
            else {
                continue
            }

            var iterator: io_iterator_t = 0
            guard
                IORegistryEntryGetChildIterator(entry, kIOServicePlane, &iterator)
                    == KERN_SUCCESS
            else {
                continue
            }
            defer { IOObjectRelease(iterator) }

            var connectors: [PowerPortThunderboltConnectorRecord] = []
            while case let child = IOIteratorNext(iterator), child != 0 {
                defer { IOObjectRelease(child) }
                guard let childValues = properties(for: child),
                    integer("Adapter Type", in: childValues) == 1,
                    integer("Lane", in: childValues) == 1,
                    let connectorNumber = integerOrString("Socket ID", in: childValues),
                    let hostPortNumber = integer("Port Number", in: childValues)
                else {
                    continue
                }

                connectors.append(
                    PowerPortThunderboltConnectorRecord(
                        routerID: routerID,
                        connectorNumber: connectorNumber,
                        hostPortNumber: hostPortNumber
                    )
                )
            }
            result.append(contentsOf: connectors)
        }

        return result
    }

    private static func matchingServices(className: String) -> [io_registry_entry_t] {
        var iterator: io_iterator_t = 0
        guard
            IOServiceGetMatchingServices(
                kIOMainPortDefault,
                IOServiceMatching(className),
                &iterator
            ) == KERN_SUCCESS
        else {
            return []
        }
        defer { IOObjectRelease(iterator) }

        var services: [io_registry_entry_t] = []
        while case let service = IOIteratorNext(iterator), service != 0 {
            services.append(service)
        }
        return services
    }

    private static func properties(for entry: io_registry_entry_t) -> [String: Any]? {
        var unmanagedProperties: Unmanaged<CFMutableDictionary>?
        guard
            IORegistryEntryCreateCFProperties(
                entry,
                &unmanagedProperties,
                kCFAllocatorDefault,
                0
            ) == KERN_SUCCESS
        else {
            return nil
        }
        return unmanagedProperties?.takeRetainedValue() as? [String: Any]
    }

    private static func integer(_ key: String, in values: [String: Any]) -> Int? {
        (values[key] as? NSNumber)?.intValue
    }

    private static func unsignedInteger(_ key: String, in values: [String: Any]) -> UInt64? {
        (values[key] as? NSNumber)?.uint64Value
    }

    private static func integerOrString(_ key: String, in values: [String: Any]) -> Int? {
        integer(key, in: values)
            ?? (values[key] as? String).flatMap(Int.init)
    }
}
