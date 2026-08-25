//
//  LegacySettingsSystemCategory.swift
//  MenuBarUSB
//

import SwiftUI

struct LegacySettingsSystemCategory: View {
    @Binding var activeRowID: UUID?

    var body: some View {
        LaunchAtLoginToggle(activeRowID: $activeRowID)
    }
}
