//
//  AppLanguage.swift
//  PortGlance
//

import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case automatic
    case english = "en"
    case german = "de"
    case spanish = "es"
    case french = "fr"
    case brazilianPortuguese = "pt-BR"
    case simplifiedChinese = "zh-Hans"
    case japanese = "ja"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .automatic: "app_language_automatic".localized
        case .english: "English"
        case .german: "Deutsch"
        case .spanish: "Español"
        case .french: "Français"
        case .brazilianPortuguese: "Português (Brasil)"
        case .simplifiedChinese: "中文（简体）"
        case .japanese: "日本語"
        }
    }

    var locale: Locale {
        self == .automatic ? .current : Locale(identifier: rawValue)
    }

    static func selected(in defaults: UserDefaults = .standard) -> AppLanguage {
        guard let identifier = defaults.string(forKey: StorageKeys.appLanguage),
            let language = AppLanguage(rawValue: identifier)
        else {
            return .automatic
        }
        return language
    }

    static var current: AppLanguage {
        selected()
    }

    func localizedString(for key: String, fallback: String? = nil, in mainBundle: Bundle = .main) -> String {
        let bundle: Bundle
        if self == .automatic {
            bundle = mainBundle
        } else if let path = mainBundle.path(forResource: rawValue, ofType: "lproj"),
            let languageBundle = Bundle(path: path)
        {
            bundle = languageBundle
        } else {
            bundle = mainBundle
        }

        return bundle.localizedString(forKey: key, value: fallback ?? key, table: nil)
    }
}
