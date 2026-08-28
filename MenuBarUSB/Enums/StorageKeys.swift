import Foundation

//
//  StorageKeys.swift
//  MenuBarUSB
//
//  Created by Rafael Neuwirth Swierczynski on 30/08/25.
//

enum StorageKeys {
    static let launchAtLogin = "launchAtLogin"
    static let showPortMax = "showPortMax"
    static let longList = "longList"
    static let deviceGroupExpanded = "deviceGroupExpanded"
    static let hubGroupExpanded = "hubGroupExpanded"
    static let internalGroupExpanded = "internalGroupExpanded"
    static let bluetoothGroupExpanded = "bluetoothGroupExpanded"
    static let hideTechInfo = "hideTechInfo"
    static let powerSourceInfo = "powerSourceInfo"
    static let reduceTransparency = "reduceTransparency"
    static let powerSupplyAsCharger = "powerSupplyAsCharger"
    static let forceDarkMode = "forceDarkMode"
    static let forceLightMode = "forceLightMode"
    static let hideSecondaryInfo = "hideSecondaryInfo"
    static let hideCount = "hideCount"
    static let numberRepresentation = "numberRepresentation"
    static let macBarIcon = "macBarIcon"
    static let hideMenubarIcon = "hideMenubarIcon"
    static let mouseHoverInfo = "mouseHoverInfo"
    static let profilerButton = "profilerButton"
    static let showEthernet = "showEthernet"
    static let windowWidth = "windowWidth"
    static let showScrollBar = "showScrollBar"
    static let bigNames = "bigNames"
    static let appLanguage = "appLanguage"
}

enum AppDefaults {
    /// Product defaults chosen from the reviewed local profile. Registering
    /// defaults never overwrites an existing user's choices.
    static let values: [String: Any] = [
        StorageKeys.showPortMax: true,
        StorageKeys.longList: true,
        StorageKeys.showScrollBar: false,
        StorageKeys.bigNames: true,
        StorageKeys.showEthernet: true,
        StorageKeys.internalGroupExpanded: false,
        StorageKeys.bluetoothGroupExpanded: false,
        StorageKeys.appLanguage: AppLanguage.automatic.rawValue,
    ]

    static func register(in defaults: UserDefaults = .standard) {
        defaults.register(defaults: values)
    }
}
