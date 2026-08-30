import Foundation
import IOKit.ps

struct PowerSourceState: Equatable {
    let isConnected: Bool
    let chargePercentage: Int?

    static let disconnected = PowerSourceState(isConnected: false, chargePercentage: nil)
}

final class PowerSourceMonitor {
    private let onChange: (PowerSourceState) -> Void
    private var runLoopSource: CFRunLoopSource?

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
        refresh()
    }

    func stop() {
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .defaultMode)
        }
        runLoopSource = nil
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

        var isConnected = false
        var chargePercentage: Int?

        for source in sources {
            guard
                let description = IOPSGetPowerSourceDescription(snapshot, source)?
                    .takeUnretainedValue() as? [String: Any]
            else {
                continue
            }

            if description[kIOPSPowerSourceStateKey as String] as? String == kIOPSACPowerValue
                || description["ExternalConnected"] as? Bool == true
            {
                isConnected = true
            }

            if description[kIOPSTypeKey as String] as? String == kIOPSInternalBatteryType as String,
                let current = description[kIOPSCurrentCapacityKey as String] as? Int,
                let maximum = description[kIOPSMaxCapacityKey as String] as? Int
            {
                chargePercentage = USBFormatting.chargePercentage(
                    currentCapacity: current,
                    maximumCapacity: maximum
                )
            }
        }

        return PowerSourceState(
            isConnected: isConnected,
            chargePercentage: isConnected ? chargePercentage : nil
        )
    }
}
