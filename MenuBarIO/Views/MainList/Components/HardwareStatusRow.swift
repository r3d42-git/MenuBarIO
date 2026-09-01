import SwiftUI

struct HardwareStatusRow: View {
    @EnvironmentObject private var manager: USBDeviceManager
    @EnvironmentObject private var bluetoothManager: BluetoothDeviceManager

    var body: some View {
        if !messages.isEmpty {
            VStack(alignment: .leading, spacing: 5) {
                ForEach(messages, id: \.self) { message in
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Image(systemName: "exclamationmark.triangle")
                        Text(message)
                    }
                }
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                .primary.opacity(0.05),
                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
            )
        }
    }

    private var messages: [String] {
        var messages: [String] = []

        switch manager.sourceStatus {
        case .stale:
            messages.append("hardware_data_stale".localized)
        case .unavailable:
            messages.append("hardware_data_unavailable".localized)
        case .ready, .refreshing:
            break
        }

        switch bluetoothManager.sourceStatus {
        case .stale:
            messages.append("bluetooth_data_stale".localized)
        case .unavailable(.bluetoothPoweredOff):
            messages.append("bluetooth_off".localized)
        case .unavailable:
            messages.append("bluetooth_unavailable".localized)
        case .ready, .refreshing:
            break
        }

        return messages
    }
}
