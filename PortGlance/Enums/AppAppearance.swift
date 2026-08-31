import Foundation

enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var localizedNameKey: String {
        switch self {
        case .system: "appearance_system"
        case .light: "appearance_light"
        case .dark: "appearance_dark"
        }
    }

    static func selected(in defaults: UserDefaults = .standard) -> AppAppearance {
        guard let value = defaults.string(forKey: StorageKeys.appAppearance),
            let appearance = AppAppearance(rawValue: value)
        else {
            return .system
        }
        return appearance
    }
}
