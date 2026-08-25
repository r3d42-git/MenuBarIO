//
//  LegacySettingsSystemCategory.swift
//  MenuBarUSB
//

import ServiceManagement
import SwiftUI

struct LegacySettingsSystemCategory: View {
    @Binding var activeRowID: UUID?

    @AS(Key.launchAtLogin) private var launchAtLogin = false

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
        ToggleRow(
            label: "open_on_startup",
            description: "open_on_startup_description",
            binding: $launchAtLogin,
            activeRowID: $activeRowID,
            incompatibilities: nil,
            onToggle: { toggleLoginItem(enabled: $0) }
        )
    }
}
