import SwiftUI

extension View {
    @ViewBuilder
    func appColorScheme(_ appearance: AppAppearance) -> some View {
        switch appearance {
        case .system:
            background(WindowAppearanceBridge(appearance: appearance))
        case .light:
            environment(\.colorScheme, .light)
                .background(WindowAppearanceBridge(appearance: appearance))
        case .dark:
            environment(\.colorScheme, .dark)
                .background(WindowAppearanceBridge(appearance: appearance))
        }
    }
}
