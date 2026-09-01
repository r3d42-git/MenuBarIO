import AppKit
import Foundation

final class HardwareRefreshCoordinator: ObservableObject {
    private let refreshHandlers: [() -> Void]
    private let notificationCenter: NotificationCenter
    private let debounceInterval: TimeInterval

    private var observers: [NSObjectProtocol] = []
    private var pendingRefresh: DispatchWorkItem?

    init(
        deviceManager: USBDeviceManager,
        bluetoothManager: BluetoothDeviceManager,
        monitoringEnabled: Bool = true,
        notificationCenter: NotificationCenter = NSWorkspace.shared.notificationCenter,
        debounceInterval: TimeInterval = 0.35
    ) {
        refreshHandlers = [deviceManager.refresh, bluetoothManager.refresh]
        self.notificationCenter = notificationCenter
        self.debounceInterval = debounceInterval

        if monitoringEnabled {
            startMonitoring()
        }
    }

    init(
        refreshHandlers: [() -> Void],
        notificationCenter: NotificationCenter,
        debounceInterval: TimeInterval
    ) {
        self.refreshHandlers = refreshHandlers
        self.notificationCenter = notificationCenter
        self.debounceInterval = debounceInterval
        startMonitoring()
    }

    deinit {
        pendingRefresh?.cancel()
        for observer in observers {
            notificationCenter.removeObserver(observer)
        }
    }

    func refresh() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.refresh()
            }
            return
        }

        pendingRefresh?.cancel()
        pendingRefresh = nil
        for refreshHandler in refreshHandlers {
            refreshHandler()
        }
    }

    private func startMonitoring() {
        let names: [Notification.Name] = [
            NSWorkspace.didWakeNotification,
            NSWorkspace.sessionDidBecomeActiveNotification,
        ]

        observers = names.map { name in
            notificationCenter.addObserver(
                forName: name,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.scheduleRefresh()
            }
        }
    }

    private func scheduleRefresh() {
        pendingRefresh?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            self?.refresh()
        }
        pendingRefresh = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + debounceInterval, execute: workItem)
    }
}
