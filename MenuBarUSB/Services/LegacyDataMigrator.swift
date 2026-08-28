import Foundation

enum LegacyDataMigrator {
    private static let migrationVersionKey = "legacyDataMigrationVersion"
    private static let currentMigrationVersion = 1

    private static let retiredPreferenceKeys = [
        "soundDevices", "customHardwareSounds", "hardwareSound", "playHardwareSound",
        "hideDonate",
        "newVersionNotification",
        "internetMonitoring", "trafficButton", "disableTrafficButtonLabel", "fastMonitor",
        "storedDevices", "inheritedDevices", "connectionLogs",
        "showNotifications", "disableNotifCooldown",
        "disableInheritanceLayout", "increasedIndentationGap",
        "hideUpdate", "noTextButtons", "disableContextMenuSearch",
        "disableContextMenuHeritage", "searchEngine", "storeConnectionLogs",
        "disableHaptic", "contextMenuCopyAll", "indexIndicator",
        "listToolBar", "storeDevices", "storedIndicator", "hidePinIndicator",
        "forceEnglish", "renamedIndicator", "camouflagedIndicator",
        "renamedDevices", "camouflagedDevices", "pinnedDevices",
    ]

    static func runIfNeeded(
        defaults: UserDefaults = .standard,
        bundleIdentifier: String? = Bundle.main.bundleIdentifier,
        applicationSupportDirectory: URL? = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first,
        fileManager: FileManager = .default
    ) {
        guard defaults.integer(forKey: migrationVersionKey) < currentMigrationVersion else {
            return
        }

        for key in retiredPreferenceKeys {
            defaults.removeObject(forKey: key)
        }
        removeLegacySoundDirectory(
            bundleIdentifier: bundleIdentifier,
            applicationSupportDirectory: applicationSupportDirectory,
            fileManager: fileManager
        )
        defaults.set(currentMigrationVersion, forKey: migrationVersionKey)
    }

    private static func removeLegacySoundDirectory(
        bundleIdentifier: String?,
        applicationSupportDirectory: URL?,
        fileManager: FileManager
    ) {
        guard let bundleIdentifier, let applicationSupportDirectory else { return }

        let directory =
            applicationSupportDirectory
            .appendingPathComponent(bundleIdentifier, isDirectory: true)
            .appendingPathComponent("Sounds", isDirectory: true)
        try? fileManager.removeItem(at: directory)
    }
}
