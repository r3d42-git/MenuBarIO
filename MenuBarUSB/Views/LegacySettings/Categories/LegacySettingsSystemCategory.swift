//
//  LegacySettingsSystemCategory.swift
//  MenuBarUSB
//

import ServiceManagement
import SwiftUI

struct LegacySettingsSystemCategory: View {
    @Binding var activeRowID: UUID?

    @AS(Key.launchAtLogin) private var launchAtLogin = false
    @AS(Key.showNotifications) private var showNotifications = false
    @AS(Key.disableNotifCooldown) private var disableNotifCooldown = false

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
        ToggleRow(
            label: "show_notification",
            description: "show_notification_description",
            binding: $showNotifications,
            activeRowID: $activeRowID,
            incompatibilities: nil,
            onToggle: { enabled in
                if enabled {
                    Utils.System.requestNotificationPermission()
                } else {
                    disableNotifCooldown = false
                }
            }
        )
        ToggleRow(
            label: "disable_notification_cooldown",
            description: "disable_notification_cooldown_description",
            binding: $disableNotifCooldown,
            activeRowID: $activeRowID,
            incompatibilities: nil,
            disabled: !showNotifications,
            onToggle: { _ in }
        )
    }
}
