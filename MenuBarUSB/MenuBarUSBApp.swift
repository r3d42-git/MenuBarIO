//
//  MenuBarUSBApp.swift
//  MenuBarUSB
//
//  Created by Rafael Neuwirth on 28/08/25.
//

import AppKit
import ServiceManagement
import SwiftUI

@main
struct MenuBarUSBApp: App {
    @StateObject private var manager: USBDeviceManager
    @StateObject private var bluetoothManager: BluetoothDeviceManager
    @State private var currentWindow: AppWindow = .devices
    
    @AS(Key.reduceTransparency) private var isReduceTransparencyOn = false
    @AS(Key.forceDarkMode) private var forceDarkMode = false
    @AS(Key.forceLightMode) private var forceLightMode = false
    @AS(Key.hideCount) private var hideCount = false
    @AS(Key.powerSourceInfo) private var powerSourceInfo = false
    @AS(Key.hideMenubarIcon) private var hideMenubarIcon = false
    @AS(Key.macBarIcon) private var macBarIcon: String = "cable.connector"
    @AS(Key.showEthernet) private var showEthernet = false
    @AS(Key.appLanguage) private var appLanguageIdentifier = AppLanguage.automatic.rawValue

    init() {
        let isRunningTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil ||
            NSClassFromString("XCTestCase") != nil
        _manager = StateObject(wrappedValue: USBDeviceManager(monitoringEnabled: !isRunningTests))
        _bluetoothManager = StateObject(wrappedValue: BluetoothDeviceManager(monitoringEnabled: !isRunningTests))

        AppDefaults.register()
        Utils.App.removeLegacyHardwareSoundData()
        Utils.App.removeLegacyDonationData()
        Utils.App.removeLegacyAutomaticUpdateData()
        Utils.App.removeLegacyEthernetTrafficData()
        Utils.App.removeRemovedFeatureData()
    }

    private func bluetoothMenuSymbol(_ image: NSImage) -> some View {
        Image(nsImage: image)
            .resizable()
            .scaledToFit()
            .frame(width: 14, height: 17)
    }
    
    private var modernMenuLabelImage: NSImage {
        HStack(spacing: 5) {
            // Keep the original macOS 15 Ethernet-link image unchanged.
            let ethernetAndUSBImage = HStack(spacing: 7) {
                Image("ETHERNET")
                Image(systemName: macBarIcon)
            }
            .asImage()

            if !hideMenubarIcon {
                if showEthernet && manager.ethernetCableConnected {
                    Image(nsImage: ethernetAndUSBImage)
                } else {
                    Image(systemName: macBarIcon)
                }
            }
            if !hideCount {
                Text(NumberConverter(manager.count).converted)
            }
            if !hideMenubarIcon,
               let bluetoothImage = NSImage(named: NSImage.bluetoothTemplateName) {
                bluetoothMenuSymbol(bluetoothImage)
            }
            if !hideCount {
                Text(NumberConverter(bluetoothManager.count).converted)
            }
        }
        .fixedSize()
        .asImage()
    }

    private var legacyMenuLabelImage: NSImage {
        HStack(spacing: 5) {
            if !hideMenubarIcon {
                Image(systemName: macBarIcon)
            }
            if !hideCount {
                Text(NumberConverter(manager.count).converted)
            }
            if !hideMenubarIcon,
               let bluetoothImage = NSImage(named: NSImage.bluetoothTemplateName) {
                bluetoothMenuSymbol(bluetoothImage)
            }
            if !hideCount {
                Text(NumberConverter(bluetoothManager.count).converted)
            }
        }
        .fixedSize()
        .asImage()
    }

    private var menuLabelImage: NSImage {
        if #available(macOS 15.0, *) {
            modernMenuLabelImage
        } else {
            legacyMenuLabelImage
        }
    }

    private var menuLabelID: String {
        [
            String(manager.count),
            String(bluetoothManager.count),
            String(manager.ethernetCableConnected),
            String(showEthernet),
            macBarIcon,
            String(hideMenubarIcon),
            String(hideCount),
            appLanguageIdentifier
        ].joined(separator: "-")
    }

    private var appLanguage: AppLanguage {
        AppLanguage(rawValue: appLanguageIdentifier) ?? .automatic
    }

    private var menuLabel: some View {
        Image(nsImage: menuLabelImage)
            .id(menuLabelID)
    }
    
    // Default menubar view
    private func view<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .appBackground(isReduceTransparencyOn)
            .colorSchemeForce(light: forceLightMode, dark: forceDarkMode)
            .environment(\.locale, appLanguage.locale)
            .environmentObject(manager)
            .environmentObject(bluetoothManager)
            .id(appLanguage.id)
    }
    
    // Auxiliary function for views in separate windows
    @SceneBuilder
    private func appWindow<Content: View>(
        _ title: String,
        id: String,
        @ViewBuilder content: () -> Content
    ) -> some Scene {
        Window(title, id: id) {
            content()
                .colorSchemeForce(light: false, dark: true)
                .environment(\.locale, appLanguage.locale)
                .environmentObject(manager)
                .environmentObject(bluetoothManager)
                .id(appLanguage.id)
        }
    }
    
    // Auxiliary function for views in separate windows
    @SceneBuilder
    private var windowScenes: some Scene {
        appWindow("settings", id: "legacy_settings") {
            LegacySettingsView()
        }
        
    }
    
    @ViewBuilder
    private var mainContent: some View {
        switch currentWindow {
        case .devices:
            view { MainListView(currentWindow: $currentWindow) }
        case .settings:
            view { SettingsView(currentWindow: $currentWindow) }
        }
    }
    
    var body: some Scene {
        MenuBarExtra {
            mainContent
        } label: {
            menuLabel
        }
        .menuBarExtraStyle(.window)
        
        windowScenes
            .windowStyle(.hiddenTitleBar)
    }
}
