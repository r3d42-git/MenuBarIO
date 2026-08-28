import Foundation
import IOKit
import IOKit.usb

final class USBConnectionMonitor {
    static let thunderboltClassName = "IOThunderboltSwitch"

    private let onChange: () -> Void
    private var notificationPort: IONotificationPortRef?
    private var iterators: [io_iterator_t] = []

    init(onChange: @escaping () -> Void) {
        self.onChange = onChange
    }

    deinit {
        stop()
    }

    func start() {
        guard notificationPort == nil else { return }

        let port = IONotificationPortCreate(kIOMainPortDefault)
        notificationPort = port
        guard let port else { return }

        if let source = IONotificationPortGetRunLoopSource(port)?.takeUnretainedValue() {
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .defaultMode)
        }

        let classNames = USBDeviceDiscovery.usbDeviceClassNames + [Self.thunderboltClassName]
        for className in classNames {
            register(className: className, notification: kIOMatchedNotification, on: port)
            register(className: className, notification: kIOTerminatedNotification, on: port)
        }
    }

    func stop() {
        for iterator in iterators where iterator != 0 {
            IOObjectRelease(iterator)
        }
        iterators.removeAll()

        guard let notificationPort else { return }
        if let source = IONotificationPortGetRunLoopSource(notificationPort)?.takeUnretainedValue() {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .defaultMode)
        }
        IONotificationPortDestroy(notificationPort)
        self.notificationPort = nil
    }

    private func register(
        className: String,
        notification: String,
        on port: IONotificationPortRef
    ) {
        guard let matching = IOServiceMatching(className) else { return }

        var iterator: io_iterator_t = 0
        let result = IOServiceAddMatchingNotification(
            port,
            notification,
            matching,
            Self.notificationCallback,
            Unmanaged.passUnretained(self).toOpaque(),
            &iterator
        )
        guard result == KERN_SUCCESS else {
            if iterator != 0 { IOObjectRelease(iterator) }
            return
        }

        iterators.append(iterator)
        Self.drain(iterator)
    }

    private static let notificationCallback: IOServiceMatchingCallback = { context, iterator in
        drain(iterator)
        guard let context else { return }
        Unmanaged<USBConnectionMonitor>
            .fromOpaque(context)
            .takeUnretainedValue()
            .onChange()
    }

    private static func drain(_ iterator: io_iterator_t) {
        var service = IOIteratorNext(iterator)
        while service != 0 {
            IOObjectRelease(service)
            service = IOIteratorNext(iterator)
        }
    }
}
