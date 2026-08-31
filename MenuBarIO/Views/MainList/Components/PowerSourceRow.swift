import SwiftUI

struct PowerSourceRow: View {
    @EnvironmentObject private var manager: USBDeviceManager

    @AS(Key.powerSourceInfo) private var powerSourceInfo = false
    @AS(Key.powerSupplyAsCharger) private var powerSupplyAsCharger = false

    var body: some View {
        if powerSourceInfo,
            manager.chargeConnected,
            let percentage = manager.chargePercentage
        {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text((powerSupplyAsCharger ? "charger" : "power_supply").localized)
                        .font(.system(size: 18, weight: .semibold))

                    if !powerDetails.isEmpty {
                        Text(powerDetails)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: manager.batteryIsCharging ? "bolt.fill" : "battery.100percent")
                    .font(.system(size: 10))
                Text("\(percentage)%")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                .primary.opacity(0.07),
                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
            )
            .contextMenu {
                MainListDeviceListContextMenuCharger()
            }

            Divider()
        }
    }

    private var powerDetails: String {
        var parts: [String] = []

        if let watts = manager.chargingPowerWatts {
            parts.append(String(format: "charging_at_watts_format".localized, watts))
        }
        if let watts = manager.adapterPowerWatts {
            parts.append(String(format: "power_adapter_watts_format".localized, watts))
        }

        return parts.joined(separator: " · ")
    }
}
