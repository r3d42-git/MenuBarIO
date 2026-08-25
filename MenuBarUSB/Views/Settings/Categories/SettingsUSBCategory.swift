//
//  SettingsUSBCategory.swift
//  MenuBarUSB
//
//  Created by rafael on 17/04/26.
//

import SwiftUI

struct SettingsUSBCategory: View {
    
    @Binding var activeRowID: UUID?
    @EnvironmentObject private var manager: USBDeviceManager
    
    @AS(Key.powerSourceInfo) private var powerSourceInfo = false
    @AS(Key.showPortMax) private var showPortMax = false
    @AS(Key.hideTechInfo) private var hideTechInfo = false
    @AS(Key.mouseHoverInfo) private var mouseHoverInfo = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            if Utils.System.isMacbook {
                ToggleRow(
                    label: "show_charger",
                    description: "show_charger_description",
                    binding: $powerSourceInfo,
                    activeRowID: $activeRowID,
                    incompatibilities: nil,
                    onToggle: { manager.setPowerSourceInfoEnabled($0) }
                )
            }
            ToggleRow(
                label: "show_port_max",
                description: "show_port_max_description",
                binding: $showPortMax,
                activeRowID: $activeRowID,
                incompatibilities: nil,
                disabled: hideTechInfo && !mouseHoverInfo,
                onToggle: { _ in }
            )
        }
    }
}
