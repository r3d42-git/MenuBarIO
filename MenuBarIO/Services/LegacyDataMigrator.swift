import Foundation

enum LegacyDataMigrator {
    private static let migrationVersionKey = "legacyDataMigrationVersion"
    private static let currentMigrationVersion = 4
    private static let appearanceMigrationVersion = 2
    private static let retiredSettingsMigrationVersion = 4
    private static let forceDarkModeKey = "forceDarkMode"
    private static let forceLightModeKey = "forceLightMode"

    private static let retiredSettingsKeys = [
        "showPortMax", "longList", "hideTechInfo", "reduceTransparency",
        "forceDarkMode", "forceLightMode", "hideSecondaryInfo", "hideCount",
        "numberRepresentation", "macBarIcon", "hideMenubarIcon", "mouseHoverInfo",
        "profilerButton", "showScrollBar", "bigNames",
    ]

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
        let storedMigrationVersion = defaults.integer(forKey: migrationVersionKey)
        guard storedMigrationVersion < currentMigrationVersion else {
            return
        }

        if storedMigrationVersion < 1 {
            for key in retiredPreferenceKeys {
                defaults.removeObject(forKey: key)
            }
            removeLegacySoundDirectory(
                bundleIdentifier: bundleIdentifier,
                applicationSupportDirectory: applicationSupportDirectory,
                fileManager: fileManager
            )
        }

        if storedMigrationVersion < appearanceMigrationVersion {
            migrateAppearance(in: defaults)
        }

        if storedMigrationVersion < retiredSettingsMigrationVersion {
            for key in retiredSettingsKeys {
                defaults.removeObject(forKey: key)
            }
        }

        defaults.set(currentMigrationVersion, forKey: migrationVersionKey)
    }

    private static func migrateAppearance(in defaults: UserDefaults) {
        let hasLegacyAppearance =
            defaults.object(forKey: forceDarkModeKey) != nil
            || defaults.object(forKey: forceLightModeKey) != nil
        guard hasLegacyAppearance else { return }

        let appearance: AppAppearance
        if defaults.bool(forKey: forceLightModeKey) {
            appearance = .light
        } else if defaults.bool(forKey: forceDarkModeKey) {
            appearance = .dark
        } else {
            appearance = .system
        }
        defaults.set(appearance.rawValue, forKey: StorageKeys.appAppearance)

        defaults.removeObject(forKey: forceDarkModeKey)
        defaults.removeObject(forKey: forceLightModeKey)
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
