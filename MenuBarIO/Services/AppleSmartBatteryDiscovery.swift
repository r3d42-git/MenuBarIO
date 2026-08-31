import Foundation
import IOKit

struct BatteryElectricalMeasurement: Equatable {
    let currentMilliamps: Int
    let voltageMillivolts: Int
}

enum AppleSmartBatteryDiscovery {
    static func properties() -> [String: Any]? {
        let service = IOServiceGetMatchingService(
            kIOMainPortDefault,
            IOServiceMatching("AppleSmartBattery")
        )
        guard service != 0 else { return nil }
        defer { IOObjectRelease(service) }

        var unmanagedProperties: Unmanaged<CFMutableDictionary>?
        guard
            IORegistryEntryCreateCFProperties(
                service,
                &unmanagedProperties,
                kCFAllocatorDefault,
                0
            ) == KERN_SUCCESS
        else {
            return nil
        }

        return unmanagedProperties?.takeRetainedValue() as? [String: Any]
    }

    static func chargingMeasurement(
        properties: [String: Any]
    ) -> BatteryElectricalMeasurement? {
        let currentMilliamps: Int
        if let instantaneous = integer("InstantAmperage", in: properties) {
            currentMilliamps = instantaneous
        } else if let averaged = integer("Amperage", in: properties) {
            currentMilliamps = averaged
        } else {
            return nil
        }

        guard let voltageMillivolts = integer("Voltage", in: properties),
            currentMilliamps > 0,
            voltageMillivolts > 0
        else {
            return nil
        }

        return BatteryElectricalMeasurement(
            currentMilliamps: currentMilliamps,
            voltageMillivolts: voltageMillivolts
        )
    }

    private static func integer(_ key: String, in values: [String: Any]) -> Int? {
        (values[key] as? NSNumber)?.intValue
    }
}
