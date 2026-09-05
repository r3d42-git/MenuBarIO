import SwiftUI

struct SettingsOptions: View {
    @EnvironmentObject private var manager: USBDeviceManager

    @AS(Key.powerSourceInfo) private var powerSourceInfo = false
    @AS(Key.showEthernet) private var showEthernet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SystemBasicsSettings()

            AppearancePicker()

            if SystemActions.isMacBook {
                ToggleRow(
                    label: "show_charger",
                    binding: $powerSourceInfo,
                    onToggle: { manager.setPowerSourceInfoEnabled($0) }
                )
            }

            ToggleRow(
                label: "ethernet_connected_icon",
                binding: $showEthernet,
                onToggle: { manager.setEthernetIndicatorEnabled($0) }
            )

            if #available(macOS 27, *) {
                HStack(spacing: 5) {
                    Image(systemName: "info.circle")
                    Text("golden_gate_ethernet_message")
                }
                .foregroundStyle(.gray)
                .font(.footnote)
            }

            WindowWidthControl(title: "window_width")
        }
    }
}
