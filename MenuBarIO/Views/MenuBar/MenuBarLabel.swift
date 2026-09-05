import AppKit
import SwiftUI

struct MenuBarLabel: View {
    @ObservedObject var deviceManager: USBDeviceManager
    @ObservedObject var bluetoothManager: BluetoothDeviceManager

    @AS(Key.showEthernet) private var showEthernet = false

    var body: some View {
        Image(nsImage: labelImage)
            .id(labelID)
            .accessibilityLabel(Text("MenuBarIO, USB \(deviceManager.count), Bluetooth \(bluetoothManager.count)"))
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
            if showEthernet && deviceManager.ethernetCableConnected {
                HStack(spacing: 7) {
                    Image(systemName: "network")
                    Image(systemName: "cable.connector")
                }
            } else {
                Image(systemName: "cable.connector")
            }
            countLabels
        }
        .fixedSize()
        .asImage()
    }

    private var standardLabelImage: NSImage {
        HStack(spacing: 5) {
            Image(systemName: "cable.connector")
            countLabels
        }
        .fixedSize()
        .asImage()
    }

    private var countLabels: some View {
        HStack(spacing: 5) {
            Text(DeviceCountFormatter.string(for: deviceManager.count))

            if let bluetoothImage = NSImage(named: NSImage.bluetoothTemplateName) {
                Image(nsImage: bluetoothImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14, height: 17)
            }

            Text(DeviceCountFormatter.string(for: bluetoothManager.count))
        }
    }

    private var labelID: String {
        [
            String(deviceManager.count),
            String(bluetoothManager.count),
            String(deviceManager.ethernetCableConnected),
            String(showEthernet),
        ].joined(separator: "-")
    }
}
