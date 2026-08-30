import SwiftUI

struct MenuBarVisibilitySettings: View {
    @Binding var activeRowID: String?

    @AS(Key.hideMenubarIcon) private var hideMenubarIcon = false
    @AS(Key.hideCount) private var hideCount = false

    var body: some View {
        ToggleRow(
            label: "hide_menubar_icon",
            description: "hide_menubar_icon_description",
            binding: $hideMenubarIcon,
            activeRowID: $activeRowID,
            disabled: hideCount,
            onToggle: { _ in hideCount = false }
        )
        ToggleRow(
            label: "hide_count",
            description: "hide_count_description",
            binding: $hideCount,
            activeRowID: $activeRowID,
            disabled: hideMenubarIcon,
            onToggle: { _ in hideMenubarIcon = false }
        )
    }
}
