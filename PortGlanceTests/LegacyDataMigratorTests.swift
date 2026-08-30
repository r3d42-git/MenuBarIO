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
}
