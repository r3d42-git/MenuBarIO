import Foundation

//
//  StorageKeys.swift
//  MenuBarIO
//
//  Created by Rafael Neuwirth Swierczynski on 30/08/25.
//

enum StorageKeys {
    static let launchAtLogin = "launchAtLogin"
    static let deviceGroupExpanded = "deviceGroupExpanded"
    static let hubGroupExpanded = "hubGroupExpanded"
    static let internalGroupExpanded = "internalGroupExpanded"
    static let bluetoothGroupExpanded = "bluetoothGroupExpanded"
    static let thunderboltPortGroupExpanded = "thunderboltPortGroupExpanded"
    static let externalThunderboltPortGroupExpanded = "externalThunderboltPortGroupExpanded"
    static let powerSourceInfo = "powerSourceInfo"
    static let powerSupplyAsCharger = "powerSupplyAsCharger"
    static let appAppearance = "appAppearance"
    static let showEthernet = "showEthernet"
    static let windowWidth = "windowWidth"
    static let appLanguage = "appLanguage"
}

enum AppDefaults {
    /// Product defaults chosen from the reviewed local profile. Registering
    /// defaults never overwrites an existing user's choices.
    static let values: [String: Any] = [
        StorageKeys.showEthernet: true,
        StorageKeys.internalGroupExpanded: false,
        StorageKeys.bluetoothGroupExpanded: false,
        StorageKeys.thunderboltPortGroupExpanded: false,
        StorageKeys.externalThunderboltPortGroupExpanded: false,
        StorageKeys.appAppearance: AppAppearance.system.rawValue,
        StorageKeys.appLanguage: AppLanguage.automatic.rawValue,
    ]

    static func register(in defaults: UserDefaults = .standard) {
        defaults.register(defaults: values)
    }
}
