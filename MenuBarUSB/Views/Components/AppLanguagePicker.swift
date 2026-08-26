//
//  AppLanguagePicker.swift
//  MenuBarUSB
//

import SwiftUI

struct AppLanguagePicker: View {
    @AS(Key.appLanguage) private var selectedLanguageIdentifier = AppLanguage.automatic.rawValue

    private var selectedLanguage: Binding<AppLanguage> {
        Binding(
            get: { AppLanguage(rawValue: selectedLanguageIdentifier) ?? .automatic },
            set: { selectedLanguageIdentifier = $0.rawValue }
        )
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("app_language".localized)
                Text("app_language_description".localized)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Picker("app_language".localized, selection: selectedLanguage) {
                ForEach(AppLanguage.allCases) { language in
                    Text(language.displayName).tag(language)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .accessibilityLabel(Text("app_language".localized))
        }
        .padding(.vertical, 7)
    }
}
