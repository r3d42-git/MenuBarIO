//
//  SettingsOthersCategory.swift
//  PortGlance
//
//  Created by rafael on 17/04/26.
//

import SwiftUI

struct SettingsOthersCategory: View {

    @Binding var activeRowID: String?

    @AS(Key.profilerButton) private var profilerButton = false

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            ToggleRow(
                label: "profiler_shortcut",
                description: "profiler_shortcut_description",
                binding: $profilerButton,
                activeRowID: $activeRowID
            )
            WindowWidthControl(title: "window_width")
        }
    }
}
