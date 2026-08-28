import SwiftUI

struct SystemBasicsSettings: View {
    @Binding var activeRowID: String?

    var body: some View {
        LaunchAtLoginToggle(activeRowID: $activeRowID)
        AppLanguagePicker()
    }
}
