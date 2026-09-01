import SwiftUI

@main
struct MenuBarIOApp: App {
    @StateObject private var deviceManager: USBDeviceManager
    @StateObject private var bluetoothManager: BluetoothDeviceManager
    @StateObject private var refreshCoordinator: HardwareRefreshCoordinator
    @State private var currentWindow: AppWindow = .devices

    @AS(Key.appAppearance) private var appAppearance: AppAppearance = .system
    @AS(Key.appLanguage) private var appLanguageIdentifier = AppLanguage.automatic.rawValue

    init() {
        LegacyDataMigrator.runIfNeeded()
        AppDefaults.register()

        let isRunningTests =
            ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
            || NSClassFromString("XCTestCase") != nil
        let deviceManager = USBDeviceManager(monitoringEnabled: !isRunningTests)
        let bluetoothManager = BluetoothDeviceManager(monitoringEnabled: !isRunningTests)
        _deviceManager = StateObject(wrappedValue: deviceManager)
        _bluetoothManager = StateObject(wrappedValue: bluetoothManager)
        _refreshCoordinator = StateObject(
            wrappedValue: HardwareRefreshCoordinator(
                deviceManager: deviceManager,
                bluetoothManager: bluetoothManager,
                monitoringEnabled: !isRunningTests
            )
        )
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarRootView(currentWindow: $currentWindow)
                .appColorScheme(appAppearance)
                .environment(\.locale, appLanguage.locale)
                .environmentObject(deviceManager)
                .environmentObject(bluetoothManager)
                .environmentObject(refreshCoordinator)
                .id(appLanguage.id)
        } label: {
            MenuBarLabel(
                deviceManager: deviceManager,
                bluetoothManager: bluetoothManager
            )
        }
        .menuBarExtraStyle(.window)

        Window("settings", id: "legacy_settings") {
            LegacySettingsView()
                .appColorScheme(.dark)
                .environment(\.locale, appLanguage.locale)
                .environmentObject(deviceManager)
                .environmentObject(bluetoothManager)
                .id(appLanguage.id)
        }
        .windowStyle(.hiddenTitleBar)
    }

    private var appLanguage: AppLanguage {
        AppLanguage(rawValue: appLanguageIdentifier) ?? .automatic
    }
}
