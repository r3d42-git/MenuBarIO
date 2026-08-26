//
//  LegacySettingsSystemCategory.swift
//  MenuBarUSB
//

import SwiftUI

struct LegacySettingsSystemCategory: View {
    @Binding var activeRowID: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            LaunchAtLoginToggle(activeRowID: $activeRowID)
            AppLanguagePicker()
        }
    }
}
