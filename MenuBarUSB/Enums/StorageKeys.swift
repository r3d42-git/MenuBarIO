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
    static let hideTechInfo = "hideTechInfo"
    static let renamedDevices = "renamedDevices"
    static let storedDevices = "storedDevices"
    static let inheritedDevices = "inheritedDevices"
    static let camouflagedDevices = "camouflagedDevices"
    static let pinnedDevices = "pinnedDevices"
    static let connectionLogs = "connectionLogs"
    static let renamedIndicator = "renamedIndicator"
    static let camouflagedIndicator = "camouflagedIndicator"
    static let showNotifications = "showNotifications"
    static let powerSourceInfo = "powerSourceInfo"
    static let reduceTransparency = "reduceTransparency"
    static let disableNotifCooldown = "disableNotifCooldown"
    static let disableInheritanceLayout = "disableInheritanceLayout"
    static let powerSupplyAsCharger = "powerSupplyAsCharger"
    static let forceDarkMode = "forceDarkMode"
    static let forceLightMode = "forceLightMode"
    static let increasedIndentationGap = "increasedIndentationGap"
    static let hideSecondaryInfo = "hideSecondaryInfo"
    static let hideUpdate = "hideUpdate"
    static let noTextButtons = "noTextButtons"
    static let hideCount = "hideCount"
    static let numberRepresentation = "numberRepresentation"
    static let macBarIcon = "macBarIcon"
    static let hideMenubarIcon = "hideMenubarIcon"
    static let switchSides = "switchSides"
    static let mouseHoverInfo = "mouseHoverInfo"
    static let profilerButton = "profilerButton"
    static let disableContextMenuSearch = "disableContextMenuSearch"
    static let disableContextMenuHeritage = "disableContextMenuHeritage"
    static let searchEngine = "searchEngine"
    static let showEthernet = "showEthernet"
    static let windowWidth = "windowWidth"
    static let storeConnectionLogs = "storeConnectionLogs";
    static let toolbarClockOff = "toolbarClockOff"
    static let disableHaptic = "disableHaptic"
    static let contextMenuCopyAll = "contextMenuCopyAll"
    static let settingsCategory = "settingsCategory"
    static let showScrollBar = "showScrollBar"
    static let indexIndicator = "indexIndicator"
    static let listToolBar = "listToolBar"
    static let storeDevices = "storeDevices"
    static let storedIndicator = "storedIndicator"
    static let bigNames = "bigNames"
    static let hidePinIndicator = "hidePinIndicator"
    static let forceEnglish = "forceEnglish"
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
        StorageKeys.storeConnectionLogs: false,
    ]

    static func register(in defaults: UserDefaults = .standard) {
        defaults.register(defaults: values)
    }
}
