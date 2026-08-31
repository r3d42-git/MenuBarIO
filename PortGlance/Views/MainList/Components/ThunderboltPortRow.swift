import SwiftUI

struct ThunderboltPortRow: View {
    let port: ThunderboltPort

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(.primary.opacity(0.08))
                    .frame(width: 32, height: 32)
                Image(systemName: "bolt.horizontal.circle")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
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

        Divider()
            .padding(.leading, 42)
    }

    private var portName: String {
        "\("thunderbolt_port".localized) \(port.connectorNumber)"
    }

    private var title: String {
        guard let device = port.connectedDevice else {
            return "\(portName) · \("port_free".localized)"
        }
        return "\(portName) · \(device.name)"
    }

    private var detail: String {
        var parts: [String] = []
        if let vendor = port.connectedDevice?.vendor, !vendor.isEmpty {
            parts.append(vendor)
        }
        parts.append(port.protocolDescription)
        return parts.joined(separator: " · ")
    }

    private var speed: String? {
        if let speed = port.negotiatedSpeedMbps {
            return USBFormatting.transferRate(speed)
        }
        if let maximum = port.maximumSpeedMbps {
            return "\("up_to".localized) \(USBFormatting.transferRate(maximum))"
        }
        return nil
    }
}
