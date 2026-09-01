import AppKit
import SwiftUI

struct BluetoothDeviceRow: View {
    let device: BluetoothDevice
    let isHovered: Bool
    let onHover: (Bool) -> Void

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(.primary.opacity(0.08))
                    .frame(width: 32, height: 32)
                deviceIcon
            }

            Text(device.name)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(1)

            Spacer(minLength: 12)
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
