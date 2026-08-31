import SwiftUI

struct LegacySettingsView: View {
    var body: some View {
        ZStack {
            Image(systemName: "gear")
                .font(.system(size: 350))
                .opacity(0.03)

            VStack(alignment: .leading, spacing: 20) {
                LegacySettingsHorizontalTopBar()
                Divider()

                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        SystemBasicsSettings()
                        WindowWidthControl(title: "list_width")
                    }
                    .padding(.horizontal, 2)
                }

                LegacySettingsHorizontalBottomBar()
            }
        }
        .padding(10)
        .frame(minWidth: 700, minHeight: 580)
    }
}
