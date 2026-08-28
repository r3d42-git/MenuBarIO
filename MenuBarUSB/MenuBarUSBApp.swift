import SwiftUI

@main
struct MenuBarUSBApp: App {
    @StateObject private var deviceManager: USBDeviceManager
    @StateObject private var bluetoothManager: BluetoothDeviceManager
    @State private var currentWindow: AppWindow = .devices

    @AS(Key.reduceTransparency) private var reduceTransparency = false
    @AS(Key.forceDarkMode) private var forceDarkMode = false
    @AS(Key.forceLightMode) private var forceLightMode = false
    @AS(Key.appLanguage) private var appLanguageIdentifier = AppLanguage.automatic.rawValue

    init() {
        AppDefaults.register()
        LegacyDataMigrator.runIfNeeded()

        let isRunningTests =
            ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
            || NSClassFromString("XCTestCase") != nil
        _deviceManager = StateObject(
            wrappedValue: USBDeviceManager(monitoringEnabled: !isRunningTests)
        )
        _bluetoothManager = StateObject(
            wrappedValue: BluetoothDeviceManager(monitoringEnabled: !isRunningTests)
        )
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarRootView(currentWindow: $currentWindow)
                .appBackground(reduceTransparency)
                .colorSchemeForce(light: forceLightMode, dark: forceDarkMode)
                .environment(\.locale, appLanguage.locale)
                .environmentObject(deviceManager)
                .environmentObject(bluetoothManager)
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
                .colorSchemeForce(light: false, dark: true)
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
