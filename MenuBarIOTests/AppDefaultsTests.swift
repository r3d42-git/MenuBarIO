import XCTest

@testable import MenuBarIO

final class AppDefaultsTests: XCTestCase {
    func testDeviceGroupsAreCollapsedByDefault() {
        withIsolatedDefaults { defaults in
            AppDefaults.register(in: defaults)

            XCTAssertFalse(defaults.bool(forKey: StorageKeys.bluetoothGroupExpanded))
            XCTAssertFalse(defaults.bool(forKey: StorageKeys.internalGroupExpanded))
            XCTAssertFalse(defaults.bool(forKey: StorageKeys.thunderboltPortGroupExpanded))
            XCTAssertFalse(defaults.bool(forKey: StorageKeys.externalThunderboltPortGroupExpanded))
        }
    }

    func testAppLanguageDefaultsToAutomatic() {
        withIsolatedDefaults { defaults in
            AppDefaults.register(in: defaults)

            XCTAssertEqual(AppLanguage.selected(in: defaults), .automatic)
        }
    }

    func testAppearanceDefaultsToSystem() {
        withIsolatedDefaults { defaults in
            AppDefaults.register(in: defaults)

            XCTAssertEqual(AppAppearance.selected(in: defaults), .system)
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
            XCTAssertTrue(defaults.bool(forKey: StorageKeys.showEthernet))

            defaults.set(false, forKey: StorageKeys.showEthernet)
            AppDefaults.register(in: defaults)
            XCTAssertFalse(defaults.bool(forKey: StorageKeys.showEthernet))
        }
    }
}
