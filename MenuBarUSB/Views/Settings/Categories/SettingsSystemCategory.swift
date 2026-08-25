//
//  SettingsSystemCategory.swift
//  MenuBarUSB
//

import ServiceManagement
import SwiftUI

struct SettingsSystemCategory: View {
    @Binding var activeRowID: UUID?

    @AS(Key.launchAtLogin) private var launchAtLogin = false
    @AS(Key.reduceTransparency) private var reduceTransparency = false
    @AS(Key.forceDarkMode) private var forceDarkMode = false
    @AS(Key.forceLightMode) private var forceLightMode = false

    private func toggleLoginItem(enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Error:", error)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            ToggleRow(
                label: "open_on_startup",
                description: "open_on_startup_description",
                binding: $launchAtLogin,
                activeRowID: $activeRowID,
                incompatibilities: nil,
                onToggle: { toggleLoginItem(enabled: $0) }
            )
            ToggleRow(
                label: "reduce_transparency",
                description: "reduce_transparency_description",
                binding: $reduceTransparency,
                activeRowID: $activeRowID,
                incompatibilities: nil,
                disabled: forceDarkMode || forceLightMode,
                onToggle: { _ in }
            )
            ToggleRow(
                label: "force_dark_mode",
                description: "force_dark_mode_description",
                binding: $forceDarkMode,
                activeRowID: $activeRowID,
                incompatibilities: [forceLightMode],
                onToggle: { if $0 { forceLightMode = false } }
            )
            ToggleRow(
                label: "force_light_mode",
                description: "force_light_mode_description",
                binding: $forceLightMode,
                activeRowID: $activeRowID,
                incompatibilities: [forceDarkMode],
                onToggle: { if $0 { forceDarkMode = false } }
            )
        }
    }
}
