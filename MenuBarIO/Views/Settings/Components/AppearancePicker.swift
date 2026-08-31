import SwiftUI

struct AppearancePicker: View {
    @AS(Key.appAppearance) private var appearance: AppAppearance = .system

    var body: some View {
        HStack(spacing: 12) {
            Text("appearance")

            Spacer(minLength: 8)

            Picker("appearance", selection: $appearance) {
                ForEach(AppAppearance.allCases) { option in
                    Text(option.localizedNameKey.localized)
                        .tag(option)
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .frame(width: 220)
            .accessibilityLabel(Text("appearance"))
        }
        .padding(.vertical, 7)
    }
}
