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
                Text((powerSupplyAsCharger ? "charger" : "power_supply").localized)
                    .font(.system(size: 18, weight: .semibold))

                Spacer()

                Image(systemName: percentage == 100 ? "battery.100percent" : "bolt.fill")
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
}
