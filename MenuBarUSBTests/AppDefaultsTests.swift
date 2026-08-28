import XCTest

@testable import MenuBarUSB

final class AppDefaultsTests: XCTestCase {
    func testDeviceGroupsAreCollapsedByDefault() {
        withIsolatedDefaults { defaults in
            AppDefaults.register(in: defaults)

            XCTAssertFalse(defaults.bool(forKey: StorageKeys.bluetoothGroupExpanded))
            XCTAssertFalse(defaults.bool(forKey: StorageKeys.internalGroupExpanded))
        }
    }

    func testAppLanguageDefaultsToAutomatic() {
        withIsolatedDefaults { defaults in
            AppDefaults.register(in: defaults)

            XCTAssertEqual(AppLanguage.selected(in: defaults), .automatic)
        }
    }

    func testAppLanguageContainsOnlyBundledManualLanguages() {
        XCTAssertEqual(
            Set(AppLanguage.allCases.map(\.rawValue)),
            Set(["automatic", "en", "de", "es", "fr", "pt-BR", "zh-Hans", "ja"])
        )
    }

    func testCuratedDefaultsDoNotOverwriteExistingPreferences() {
        withIsolatedDefaults { defaults in
            AppDefaults.register(in: defaults)
            XCTAssertTrue(defaults.bool(forKey: StorageKeys.showPortMax))
            XCTAssertTrue(defaults.bool(forKey: StorageKeys.longList))
            XCTAssertFalse(defaults.bool(forKey: StorageKeys.showScrollBar))
            XCTAssertTrue(defaults.bool(forKey: StorageKeys.bigNames))
            XCTAssertTrue(defaults.bool(forKey: StorageKeys.showEthernet))

            defaults.set(false, forKey: StorageKeys.longList)
            AppDefaults.register(in: defaults)
            XCTAssertFalse(defaults.bool(forKey: StorageKeys.longList))
        }
    }
}
