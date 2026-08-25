//
//  LegacySettingsUSBCategory.swift
//  MenuBarUSB
//
//  Created by rafael on 17/04/26.
//

import SwiftUI

struct LegacySettingsUSBCategory: View {
    
    @Binding var activeRowID: UUID?
    
    @AS(Key.showPortMax) private var showPortMax = false
    @AS(Key.hideTechInfo) private var hideTechInfo = false
    @AS(Key.mouseHoverInfo) private var mouseHoverInfo = false
    
    var body: some View {
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
