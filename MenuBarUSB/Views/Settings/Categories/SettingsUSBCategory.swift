//
//  SettingsUSBCategory.swift
//  MenuBarUSB
//
//  Created by rafael on 17/04/26.
//

import SwiftUI

struct SettingsUSBCategory: View {

    @Binding var activeRowID: String?
    @EnvironmentObject private var manager: USBDeviceManager

    @AS(Key.powerSourceInfo) private var powerSourceInfo = false

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            if SystemActions.isMacBook {
                ToggleRow(
                    label: "show_charger",
                    description: "show_charger_description",
                    binding: $powerSourceInfo,
                    activeRowID: $activeRowID,
                    onToggle: { manager.setPowerSourceInfoEnabled($0) }
                )
            }
            USBPortSettings(activeRowID: $activeRowID)
        }
    }
}
