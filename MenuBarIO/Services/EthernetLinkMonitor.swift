import Foundation
import SystemConfiguration

protocol EthernetLinkMonitoring: AnyObject {
    @discardableResult func start(onChange: @escaping () -> Void) -> Bool
    func stop()
}

/// Observes local link and interface configuration changes; it never opens a connection.
/// Registration and callbacks belong to the main run loop, like the other device monitors.
final class EthernetLinkMonitor: EthernetLinkMonitoring {
    private var dynamicStore: SCDynamicStore?
    private var runLoopSource: CFRunLoopSource?
    private var onChange: (() -> Void)?

    deinit {
        stop()
    }

    @discardableResult
    func start(onChange: @escaping () -> Void) -> Bool {
        self.onChange = onChange
        guard runLoopSource == nil else { return true }

        var context = SCDynamicStoreContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )
        guard
            let store = SCDynamicStoreCreate(
                nil, "MenuBarIO.EthernetLinkMonitor" as CFString, Self.callback, &context
            )
        else { return false }

        let keys = ["State:/Network/Interface"] as CFArray
        let patterns =
            [
                "State:/Network/Interface/[^/]+/Link",
                "Setup:/Network/Service/[^/]+/Interface",
                "Setup:/Network/Interface/[^/]+/Ethernet",
            ] as CFArray
        guard SCDynamicStoreSetNotificationKeys(store, keys, patterns),
            let source = SCDynamicStoreCreateRunLoopSource(nil, store, 0)
        else { return false }

        dynamicStore = store
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        return true
    }

    func stop() {
        onChange = nil
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
            CFRunLoopSourceInvalidate(runLoopSource)
        }
        runLoopSource = nil
        dynamicStore = nil
    }

    private static let callback: SCDynamicStoreCallBack = { _, _, context in
        guard let context else { return }
        let monitor = Unmanaged<EthernetLinkMonitor>.fromOpaque(context).takeUnretainedValue()
        guard monitor.runLoopSource != nil else { return }
        monitor.onChange?()
    }
}
