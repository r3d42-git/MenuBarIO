//
//  SettingsSystemCategory.swift
//  PortGlance
//

import SwiftUI

struct SettingsSystemCategory: View {
    @Binding var activeRowID: String?

    @AS(Key.reduceTransparency) private var reduceTransparency = false
    @AS(Key.forceDarkMode) private var forceDarkMode = false
    @AS(Key.forceLightMode) private var forceLightMode = false

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            SystemBasicsSettings(activeRowID: $activeRowID)
            ToggleRow(
                label: "reduce_transparency",
                description: "reduce_transparency_description",
                binding: $reduceTransparency,
                activeRowID: $activeRowID,
                disabled: forceDarkMode || forceLightMode,
                onToggle: { _ in }
            )
            ToggleRow(
                label: "force_dark_mode",
                description: "force_dark_mode_description",
                binding: $forceDarkMode,
                activeRowID: $activeRowID,
                hasIncompatibility: forceLightMode,
                onToggle: { if $0 { forceLightMode = false } }
            )
            ToggleRow(
                label: "force_light_mode",
                description: "force_light_mode_description",
                binding: $forceLightMode,
                activeRowID: $activeRowID,
                hasIncompatibility: forceDarkMode,
                onToggle: { if $0 { forceDarkMode = false } }
            )
        }
    }
}
