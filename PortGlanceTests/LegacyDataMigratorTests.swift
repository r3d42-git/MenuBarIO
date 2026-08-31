import Foundation
import XCTest

@testable import PortGlance

final class LegacyDataMigratorTests: XCTestCase {
    func testRemovesRetiredPreferencesAndSoundDirectory() throws {
        try withIsolatedDefaults { defaults in
            let retiredKeys = [
                "soundDevices", "hideDonate", "newVersionNotification",
                "internetMonitoring", "storedDevices", "inheritedDevices",
                "connectionLogs", "forceEnglish", "renamedDevices", "pinnedDevices",
            ]
            for key in retiredKeys {
                defaults.set("legacy-value", forKey: key)
            }

            let applicationSupport = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString, isDirectory: true)
            let soundDirectory =
                applicationSupport
                .appendingPathComponent("local.portglance.tests", isDirectory: true)
                .appendingPathComponent("Sounds", isDirectory: true)
            try FileManager.default.createDirectory(
                at: soundDirectory,
                withIntermediateDirectories: true
            )
            try Data("legacy sound".utf8).write(
                to: soundDirectory.appendingPathComponent("sound.mp3")
            )
            defer { try? FileManager.default.removeItem(at: applicationSupport) }

            LegacyDataMigrator.runIfNeeded(
                defaults: defaults,
                bundleIdentifier: "local.portglance.tests",
                applicationSupportDirectory: applicationSupport
            )

            for key in retiredKeys {
                XCTAssertNil(defaults.object(forKey: key))
            }
            XCTAssertFalse(FileManager.default.fileExists(atPath: soundDirectory.path))
        }
    }

    func testRunsOnlyOnce() {
        withIsolatedDefaults { defaults in
            LegacyDataMigrator.runIfNeeded(defaults: defaults)
            defaults.set(true, forKey: "hideDonate")

            LegacyDataMigrator.runIfNeeded(defaults: defaults)

            XCTAssertTrue(defaults.bool(forKey: "hideDonate"))
        }
    }

    func testMigratesLegacyAppearancePreference() {
        withIsolatedDefaults { defaults in
            defaults.set(1, forKey: "legacyDataMigrationVersion")
            defaults.set(true, forKey: "forceDarkMode")

            LegacyDataMigrator.runIfNeeded(defaults: defaults)

            XCTAssertEqual(AppAppearance.selected(in: defaults), .dark)
            XCTAssertNil(defaults.object(forKey: "forceDarkMode"))
            XCTAssertNil(defaults.object(forKey: "forceLightMode"))
        }
    }

    func testLegacyLightAppearanceKeepsItsFormerPriority() {
        withIsolatedDefaults { defaults in
            defaults.set(1, forKey: "legacyDataMigrationVersion")
            defaults.set(true, forKey: "forceDarkMode")
            defaults.set(true, forKey: "forceLightMode")

            LegacyDataMigrator.runIfNeeded(defaults: defaults)

            XCTAssertEqual(AppAppearance.selected(in: defaults), .light)
        }
    }

    func testRemovesRetiredTransparencyPreference() {
        withIsolatedDefaults { defaults in
            defaults.set(2, forKey: "legacyDataMigrationVersion")
            defaults.set(true, forKey: "reduceTransparency")

            LegacyDataMigrator.runIfNeeded(defaults: defaults)

            XCTAssertNil(defaults.object(forKey: "reduceTransparency"))
        }
    }

    func testRemovesRetiredMinimalSettingsPreferencesAfterDevelopmentMigration() {
        withIsolatedDefaults { defaults in
            let retiredKeys = [
                "showPortMax", "longList", "hideTechInfo", "reduceTransparency",
                "forceDarkMode", "forceLightMode", "hideSecondaryInfo", "hideCount",
                "numberRepresentation", "macBarIcon", "hideMenubarIcon", "mouseHoverInfo",
                "profilerButton", "showScrollBar", "bigNames",
            ]
            defaults.set(3, forKey: "legacyDataMigrationVersion")
            for key in retiredKeys {
                defaults.set("retired", forKey: key)
            }

            LegacyDataMigrator.runIfNeeded(defaults: defaults)

            for key in retiredKeys {
                XCTAssertNil(defaults.object(forKey: key), "Expected retired key \(key) to be removed")
            }
        }
    }
}
