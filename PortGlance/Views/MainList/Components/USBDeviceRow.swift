import SwiftUI

struct USBDeviceRow: View {
    let device: USBDevice
    let isHovered: Bool
    let onHover: (Bool) -> Void

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(.primary.opacity(0.08))
                    .frame(width: 32, height: 32)
                Image(systemName: iconName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(device.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                if !detail.isEmpty {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 12)

            if let speed {
                Text(speed)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .lineLimit(1)
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
        .contextMenu {
            MainListDeviceListContextMenuDevice(device: device)
        }

        Divider()
            .padding(.leading, 42)
    }

    private var iconName: String {
        if device.isHub { return "circle.grid.2x2" }
        if device.isExternalStorage == true { return "externaldrive" }
        if device.transport == .thunderbolt { return "bolt.horizontal.circle" }
        return "cable.connector"
    }

    private var detail: String {
        var parts: [String] = []
        if let vendor = device.vendor, !vendor.isEmpty {
            parts.append(vendor)
        }
        if !device.connectionDescription.isEmpty {
            parts.append(device.connectionDescription)
        }
        return parts.joined(separator: " · ")
    }

    private var speed: String? {
        guard let speed = device.speedMbps else {
            return nil
        }
        return USBFormatting.transferRate(speed)
    }
}
