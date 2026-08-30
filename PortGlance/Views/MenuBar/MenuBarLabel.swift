import AppKit
import SwiftUI

struct MenuBarLabel: View {
    @ObservedObject var deviceManager: USBDeviceManager
    @ObservedObject var bluetoothManager: BluetoothDeviceManager

    @AS(Key.hideCount) private var hideCount = false
    @AS(Key.hideMenubarIcon) private var hideMenubarIcon = false
    @AS(Key.macBarIcon) private var iconName = "cable.connector"
    @AS(Key.numberRepresentation) private var numberRepresentation: NumberRepresentation = .base10
    @AS(Key.showEthernet) private var showEthernet = false
    @AS(Key.appLanguage) private var appLanguageIdentifier = AppLanguage.automatic.rawValue

    var body: some View {
        Image(nsImage: labelImage)
            .id(labelID)
    }

    private var labelImage: NSImage {
        if #available(macOS 15.0, *) {
            modernLabelImage
        } else {
            standardLabelImage
        }
    }

    private var modernLabelImage: NSImage {
        HStack(spacing: 5) {
            if !hideMenubarIcon {
                if showEthernet && deviceManager.ethernetCableConnected {
                    HStack(spacing: 7) {
                        Image(systemName: "network")
                        Image(systemName: iconName)
                    }
                } else {
                    Image(systemName: iconName)
                }
            }
            countLabels
        }
        .fixedSize()
        .asImage()
    }

    private var standardLabelImage: NSImage {
        HStack(spacing: 5) {
            if !hideMenubarIcon {
                Image(systemName: iconName)
            }
            countLabels
        }
        .fixedSize()
        .asImage()
    }

    @ViewBuilder
    private var countLabels: some View {
        if !hideCount {
            Text(formattedCount(deviceManager.count))
        }
        if !hideMenubarIcon,
            let bluetoothImage = NSImage(named: NSImage.bluetoothTemplateName)
        {
            Image(nsImage: bluetoothImage)
                .resizable()
                .scaledToFit()
                .frame(width: 14, height: 17)
        }
        if !hideCount {
            Text(formattedCount(bluetoothManager.count))
        }
    }

    private func formattedCount(_ count: Int) -> String {
        DeviceCountFormatter.string(for: count, representation: numberRepresentation)
    }

    private var labelID: String {
        [
            String(deviceManager.count),
            String(bluetoothManager.count),
            String(deviceManager.ethernetCableConnected),
            String(showEthernet),
            iconName,
            String(hideMenubarIcon),
            String(hideCount),
            numberRepresentation.rawValue,
            appLanguageIdentifier,
        ].joined(separator: "-")
    }
}
