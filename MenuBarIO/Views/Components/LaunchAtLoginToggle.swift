//
//  LaunchAtLoginToggle.swift
//  MenuBarIO
//

import SwiftUI

struct LaunchAtLoginToggle: View {
    @AS(Key.launchAtLogin) private var launchAtLogin = false
    @State private var errorMessage: String?

    private func updateLoginItem(enabled: Bool) {
        let result = LaunchAtLoginService.update(enabled: enabled)
        launchAtLogin = result.persistedValue
        errorMessage = result.errorMessage
    }

    var body: some View {
        ToggleRow(
            label: "open_on_startup",
            binding: $launchAtLogin,
            onToggle: updateLoginItem
        )
        .alert(
            "alert".localized,
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button("close".localized, role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
    }
}
