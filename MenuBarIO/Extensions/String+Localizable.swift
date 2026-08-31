//
//  String+Localizable.swift
//  MenuBarIO
//
//  Created by Rafael Neuwirth Swierczynski on 17/11/25.
//

import Foundation

extension String {
    var localized: String {
        AppLanguage.current.localizedString(for: self)
    }
}
