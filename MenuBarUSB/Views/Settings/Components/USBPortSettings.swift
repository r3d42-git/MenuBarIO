import SwiftUI

struct USBPortSettings: View {
    @Binding var activeRowID: String?

    @AS(Key.showPortMax) private var showPortMax = false
    @AS(Key.hideTechInfo) private var hideTechInfo = false
    @AS(Key.mouseHoverInfo) private var mouseHoverInfo = false

    var body: some View {
        ToggleRow(
            label: "show_port_max",
            description: "show_port_max_description",
            binding: $showPortMax,
            activeRowID: $activeRowID,
            disabled: hideTechInfo && !mouseHoverInfo
        )
    }
}
