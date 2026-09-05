import AppKit
import SwiftUI

struct BluetoothDeviceRow: View {
    let device: BluetoothDevice
    let isHovered: Bool
    let onHover: (Bool) -> Void

    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(.primary.opacity(0.08))
                        .frame(width: 32, height: 32)
                        .accessibilityHidden(true)
                    deviceIcon.accessibilityHidden(true)
                }

                Text(device.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Spacer(minLength: 12)

                if let level = device.batteryLevel {
                    Label("\(level)%", systemImage: batteryIcon(level))
                        .font(.caption.weight(.medium))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .accessibilityLabel(Text("\("battery_level".localized): \(level)%"))
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                isHovered ? Color.primary.opacity(0.07) : Color.clear,
                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
            )
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .onHover(perform: onHover)
            .animation(.easeInOut(duration: 0.12), value: isHovered)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint(Text("open_device_details"))
        .contextMenu {
            Button {
                SystemActions.copyToClipboard(
                    DiagnosticReportBuilder().bluetoothDeviceDetails(device)
                )
            } label: {
                Label("copy", systemImage: "square.on.square")
            }
        }

        Divider()
            .padding(.leading, 42)
    }

    private func batteryIcon(_ level: Int) -> String {
        switch level {
        case 0..<10: "battery.0percent"
        case 10..<38: "battery.25percent"
        case 38..<63: "battery.50percent"
        case 63..<88: "battery.75percent"
        default: "battery.100percent"
        }
    }

    @ViewBuilder
    private var deviceIcon: some View {
        switch device.icon {
        case .system(let symbolName):
            Image(systemName: symbolName)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.secondary)
        case .bluetoothTemplate:
            if let image = NSImage(named: NSImage.bluetoothTemplateName) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12, height: 15)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
