import Foundation
import IOKit.ps

struct PowerSourceState: Equatable {
    let isConnected: Bool
    let chargePercentage: Int?
    let isCharging: Bool
    let chargingPowerWatts: Int?
    let adapterPowerWatts: Int?
    let powerSourceConnectorNumber: Int?

    static let disconnected = PowerSourceState(
        isConnected: false,
        chargePercentage: nil,
        isCharging: false,
        chargingPowerWatts: nil,
        adapterPowerWatts: nil,
        powerSourceConnectorNumber: nil
    )
}

final class PowerSourceMonitor {
    private static let refreshInterval: TimeInterval = 5

    private let onChange: (PowerSourceState) -> Void
    private var runLoopSource: CFRunLoopSource?
    private var refreshTimer: Timer?

    init(onChange: @escaping (PowerSourceState) -> Void) {
        self.onChange = onChange
    }

    deinit {
        stop()
    }

    func start() {
        guard runLoopSource == nil else {
            refresh()
            return
        }

        let callback: IOPowerSourceCallbackType = { context in
            guard let context else { return }
            Unmanaged<PowerSourceMonitor>
                .fromOpaque(context)
                .takeUnretainedValue()
                .refresh()
        }

        let context = Unmanaged.passUnretained(self).toOpaque()
        if let source = IOPSNotificationCreateRunLoopSource(callback, context)?.takeRetainedValue() {
            runLoopSource = source
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .defaultMode)
        }
        let timer = Timer(timeInterval: Self.refreshInterval, repeats: true) { [weak self] _ in
            self?.refresh()
        }
        refreshTimer = timer
        RunLoop.main.add(timer, forMode: .common)
        refresh()
    }

    func stop() {
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .defaultMode)
        }
        runLoopSource = nil
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    func refresh() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let state = Self.currentState()
            DispatchQueue.main.async {
                self?.onChange(state)
            }
        }
    }

    private static func currentState() -> PowerSourceState {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
            let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef]
        else {
            return .disconnected
        }

        let descriptions = sources.compactMap { source in
            IOPSGetPowerSourceDescription(snapshot, source)?
                .takeUnretainedValue() as? [String: Any]
        }
        let adapterDetails =
            IOPSCopyExternalPowerAdapterDetails()?
            .takeRetainedValue() as? [String: Any]
        let batteryProperties = AppleSmartBatteryDiscovery.properties()

        return state(
            descriptions: descriptions,
            adapterDetails: adapterDetails,
            fallbackChargingMeasurement: batteryProperties.flatMap(
                AppleSmartBatteryDiscovery.chargingMeasurement(properties:)
            ),
            powerSourceConnectorNumber: IntelT2PowerPortDiscovery.powerSourceConnectorNumber(
                batteryProperties: batteryProperties
            )
        )
    }

    static func state(
        descriptions: [[String: Any]],
        adapterDetails: [String: Any]?,
        fallbackChargingMeasurement: BatteryElectricalMeasurement? = nil,
        powerSourceConnectorNumber: Int? = nil
    ) -> PowerSourceState {
        var isConnected = adapterDetails != nil
        var chargePercentage: Int?
        var isCharging = false
        var chargingPowerWatts: Int?

        for description in descriptions {
            if description[kIOPSPowerSourceStateKey as String] as? String == kIOPSACPowerValue
                || description["ExternalConnected"] as? Bool == true
            {
                isConnected = true
            }

            guard description[kIOPSTypeKey as String] as? String == kIOPSInternalBatteryType as String
            else {
                continue
            }

            if let current = integerValue(kIOPSCurrentCapacityKey as String, in: description),
                let maximum = integerValue(kIOPSMaxCapacityKey as String, in: description)
            {
                chargePercentage = USBFormatting.chargePercentage(
                    currentCapacity: current,
                    maximumCapacity: maximum
                )
            }

            isCharging = description[kIOPSIsChargingKey as String] as? Bool == true
            if isCharging,
                let currentMilliamps = integerValue(kIOPSCurrentKey as String, in: description),
                let voltageMillivolts = integerValue(kIOPSVoltageKey as String, in: description)
            {
                chargingPowerWatts = chargingWatts(
                    currentMilliamps: currentMilliamps,
                    voltageMillivolts: voltageMillivolts
                )
            }
            if isCharging, chargingPowerWatts == nil, let fallbackChargingMeasurement {
                chargingPowerWatts = chargingWatts(
                    currentMilliamps: fallbackChargingMeasurement.currentMilliamps,
                    voltageMillivolts: fallbackChargingMeasurement.voltageMillivolts
                )
            }
        }

        let adapterPowerWatts =
            adapterDetails
            .flatMap { integerValue(kIOPSPowerAdapterWattsKey, in: $0) }
            .flatMap(validatedWatts)

        return PowerSourceState(
            isConnected: isConnected,
            chargePercentage: isConnected ? chargePercentage : nil,
            isCharging: isConnected && isCharging,
            chargingPowerWatts: isConnected && isCharging ? chargingPowerWatts : nil,
            adapterPowerWatts: isConnected ? adapterPowerWatts : nil,
            powerSourceConnectorNumber: isConnected ? powerSourceConnectorNumber : nil
        )
    }

    private static func integerValue(_ key: String, in values: [String: Any]) -> Int? {
        (values[key] as? NSNumber)?.intValue
    }

    private static func validatedWatts(_ watts: Int) -> Int? {
        guard watts > 0, watts <= 1_000 else { return nil }
        return watts
    }

    private static func chargingWatts(
        currentMilliamps: Int,
        voltageMillivolts: Int
    ) -> Int? {
        guard currentMilliamps > 0, voltageMillivolts > 0 else { return nil }

        let watts = Double(currentMilliamps) * Double(voltageMillivolts) / 1_000_000
        guard watts.isFinite, watts > 0, watts <= 1_000 else { return nil }
        return Int(watts.rounded())
    }
}
