//
//  SettingsEthernetCategory.swift
//  MenuBarUSB
//
//  Created by rafael on 17/04/26.
//

import SwiftUI

struct SettingsEthernetCategory: View {

    @EnvironmentObject var manager: USBDeviceManager

    @Binding var activeRowID: String?

    @AS(Key.showEthernet) private var showEthernet = false
    @AS(Key.hideMenubarIcon) private var hideMenubarIcon = false

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            ToggleRow(
                label: "ethernet_connected_icon",
                description: "ethernet_connected_icon_description",
                binding: $showEthernet,
                activeRowID: $activeRowID,
                disabled: hideMenubarIcon,
                onToggle: { _ in
                    manager.refresh()
                }
            )

            if #available(macOS 27, *) {
                HStack(spacing: 5) {
                    Image(systemName: "info.circle")
                    Text("golden_gate_ethernet_message")
                }
                .foregroundStyle(.gray)
                .font(.footnote)
            }

        }
    }
}
