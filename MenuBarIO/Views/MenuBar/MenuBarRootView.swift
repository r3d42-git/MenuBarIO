import SwiftUI

struct MenuBarRootView: View {
    @Binding var currentWindow: AppWindow

    var body: some View {
        switch currentWindow {
        case .devices:
            MainListView(currentWindow: $currentWindow)
        case .settings:
            SettingsView(currentWindow: $currentWindow)
        }
    }
}
