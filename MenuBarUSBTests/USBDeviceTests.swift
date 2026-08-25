import XCTest
@testable import MenuBarUSB

final class USBDeviceTests: XCTestCase {
    private enum LaunchAtLoginTestError: LocalizedError {
        case failed

        var errorDescription: String? {
            "Login item update failed"
        }
    }

    func testLaunchAtLoginUpdatePersistsRequestedValueOnSuccess() {
        let result = LaunchAtLoginUpdateResult.applying(
            requestedValue: true,
            currentValue: { false },
            operation: {}
        )

        XCTAssertEqual(result, LaunchAtLoginUpdateResult(persistedValue: true, errorMessage: nil))
    }

    func testLaunchAtLoginUpdateRestoresActualValueOnFailure() {
        let result = LaunchAtLoginUpdateResult.applying(
            requestedValue: true,
            currentValue: { false },
            operation: { throw LaunchAtLoginTestError.failed }
        )

        XCTAssertEqual(
            result,
            LaunchAtLoginUpdateResult(
                persistedValue: false,
                errorMessage: "Login item update failed"
            )
        )
    }

    func testSeriallessUSBDevicesRemainDistinctByLocation() {
        let first = USBDevice(
            name: "USB Device",
            vendor: "Example",
            vendorId: 0x1234,
            productId: 0x5678,
            serialNumber: nil,
            locationId: 0x0010_0000,
            speedMbps: nil,
            portMaxSpeedMbps: nil,
            usbVersionBCD: nil,
            isExternalStorage: nil
        )
        let second = USBDevice(
            name: "USB Device",
            vendor: "Example",
            vendorId: 0x1234,
            productId: 0x5678,
            serialNumber: nil,
            locationId: 0x0020_0000,
            speedMbps: nil,
            portMaxSpeedMbps: nil,
            usbVersionBCD: nil,
            isExternalStorage: nil
        )

        XCTAssertNotEqual(first.uniqueId, second.uniqueId)
    }

    func testHubClassificationOnlyAppliesToUSBClassNine() {
        let usbHub = USBDevice(
            name: "Hub",
            vendor: nil,
            vendorId: 0,
            productId: 0,
            serialNumber: nil,
            locationId: nil,
            speedMbps: nil,
            portMaxSpeedMbps: nil,
            usbVersionBCD: nil,
            isExternalStorage: nil,
            deviceClass: 9
        )
        let thunderboltDevice = USBDevice(
            name: "Dock",
            vendor: nil,
            vendorId: 0,
            productId: 0,
            serialNumber: nil,
            locationId: nil,
            speedMbps: 40_000,
            portMaxSpeedMbps: nil,
            usbVersionBCD: nil,
            isExternalStorage: nil,
            deviceClass: 9,
            transport: .thunderbolt
        )

        XCTAssertTrue(usbHub.isHub)
        XCTAssertFalse(thunderboltDevice.isHub)
    }

    func testThunderboltDescriptionUsesItsNegotiatedLinkSpeed() {
        let device = USBDevice(
            name: "SSD",
            vendor: "Example",
            vendorId: 0x1111,
            productId: 0x2222,
            serialNumber: nil,
            locationId: 1,
            speedMbps: 80_000,
            portMaxSpeedMbps: nil,
            usbVersionBCD: nil,
            isExternalStorage: nil,
            transport: .thunderbolt,
            transportVersion: "USB4 v2",
            transportIdentifier: "ABC"
        )

        XCTAssertEqual(device.connectionDescription, "Thunderbolt/USB4 — 80.0 Gbps")
        XCTAssertEqual(device.uniqueId, "thunderbolt-4369-8738-ABC")
    }

    func testThunderboltBillboardIsExplicitOptIn() {
        let regularUSBDevice = USBDevice(
            name: "USB Device",
            vendor: "Example",
            vendorId: 1,
            productId: 1,
            serialNumber: nil,
            locationId: nil,
            speedMbps: nil,
            portMaxSpeedMbps: nil,
            usbVersionBCD: nil,
            isExternalStorage: false
        )
        let billboard = USBDevice(
            name: "Thunderbolt4 Mini Dock",
            vendor: "Anker",
            vendorId: 0x291A,
            productId: 0x8358,
            serialNumber: "11AD1D0AB6073C0A31200B00",
            locationId: 0x0215_0000,
            speedMbps: 12,
            portMaxSpeedMbps: nil,
            usbVersionBCD: 0x0201,
            isExternalStorage: false,
            isThunderboltBillboard: true
        )

        XCTAssertFalse(regularUSBDevice.isThunderboltBillboard)
        XCTAssertTrue(billboard.isThunderboltBillboard)
    }

    func testClipboardDeviceFieldsEscapeControlAndBidiCharacters() {
        let rawValue = "USB\n\u{001B}[2J\u{202E}device\u{2028}\u{2066}"

        XCTAssertEqual(
            Utils.System.safeClipboardDeviceField(rawValue),
            "USB\\u{000A}\\u{001B}[2J\\u{202E}device\\u{2028}\\u{2066}"
        )
        XCTAssertEqual(Utils.System.safeClipboardDeviceField("USB Café 4"), "USB Café 4")
    }

    func testExternalNumericValuesAreValidated() {
        XCTAssertEqual(Utils.USB.chargePercentage(currentCapacity: 50, maximumCapacity: 100), 50)
        XCTAssertEqual(Utils.USB.chargePercentage(currentCapacity: 150, maximumCapacity: 100), 100)
        XCTAssertNil(Utils.USB.chargePercentage(currentCapacity: -1, maximumCapacity: 100))
        XCTAssertNil(Utils.USB.chargePercentage(currentCapacity: 50, maximumCapacity: 0))

        XCTAssertEqual(Utils.USB.megabitsPerSecond(fromBitsPerSecond: 5_000_000_000), 5_000)
        XCTAssertNil(Utils.USB.megabitsPerSecond(fromBitsPerSecond: .nan))
        XCTAssertNil(Utils.USB.megabitsPerSecond(fromBitsPerSecond: .infinity))
        XCTAssertNil(Utils.USB.megabitsPerSecond(fromBitsPerSecond: -1))
        XCTAssertNil(Utils.USB.megabitsPerSecond(fromBitsPerSecond: .greatestFiniteMagnitude))

        XCTAssertEqual(Utils.USB.thunderboltMegabitsPerSecond(fromLinkBandwidth: 800), 80_000)
        XCTAssertNil(Utils.USB.thunderboltMegabitsPerSecond(fromLinkBandwidth: Int.max))
    }

    func testRefreshCoordinatorCoalescesBurstsAndPublishesOnlyTheLatestGeneration() throws {
        var coordinator = DeviceRefreshCoordinator()

        let firstGeneration = try XCTUnwrap(coordinator.requestRefresh())
        XCTAssertNil(coordinator.requestRefresh())
        XCTAssertFalse(coordinator.isCurrent(firstGeneration))

        let secondGeneration = firstGeneration + 1
        XCTAssertEqual(coordinator.completeRefresh(firstGeneration), .refresh(secondGeneration))
        XCTAssertTrue(coordinator.isCurrent(secondGeneration))
        XCTAssertEqual(coordinator.completeRefresh(secondGeneration), .publish)

        XCTAssertEqual(coordinator.requestRefresh(), secondGeneration + 1)
    }

    func testUSBDiscoveryIncludesHostAndLegacyDeviceClasses() {
        XCTAssertEqual(
            Set(USBDeviceManager.usbDeviceClassNames),
            Set(["IOUSBHostDevice", "IOUSBDevice"])
        )
    }

    func testLegacyHardwareSoundDataIsRemoved() throws {
        let suiteName = "MenuBarUSBTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            return XCTFail("Could not create isolated defaults suite")
        }
        defer { defaults.removePersistentDomain(forName: suiteName) }

        ["soundDevices", "customHardwareSounds", "hardwareSound", "playHardwareSound"].forEach {
            defaults.set("legacy-value", forKey: $0)
        }

        let appSupport = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let soundDirectory = appSupport
            .appendingPathComponent("local.menubarusb.tests", isDirectory: true)
            .appendingPathComponent("Sounds", isDirectory: true)
        try FileManager.default.createDirectory(at: soundDirectory, withIntermediateDirectories: true)
        try Data("legacy sound".utf8).write(to: soundDirectory.appendingPathComponent("sound.mp3"))
        defer { try? FileManager.default.removeItem(at: appSupport) }

        Utils.App.removeLegacyHardwareSoundData(
            defaults: defaults,
            bundleIdentifier: "local.menubarusb.tests",
            applicationSupportDirectory: appSupport
        )

        XCTAssertFalse(FileManager.default.fileExists(atPath: soundDirectory.path))
        ["soundDevices", "customHardwareSounds", "hardwareSound", "playHardwareSound"].forEach {
            XCTAssertNil(defaults.object(forKey: $0))
        }
    }

    func testLegacyDonationPreferenceIsRemoved() {
        let suiteName = "MenuBarUSBTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            return XCTFail("Could not create isolated defaults suite")
        }
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set(true, forKey: "hideDonate")
        Utils.App.removeLegacyDonationData(defaults: defaults)

        XCTAssertNil(defaults.object(forKey: "hideDonate"))
    }

    func testLegacyAutomaticUpdatePreferenceIsRemoved() {
        let suiteName = "MenuBarUSBTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            return XCTFail("Could not create isolated defaults suite")
        }
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set(true, forKey: "newVersionNotification")
        Utils.App.removeLegacyAutomaticUpdateData(defaults: defaults)

        XCTAssertNil(defaults.object(forKey: "newVersionNotification"))
    }

    func testLegacyEthernetTrafficPreferencesAreRemoved() {
        let suiteName = "MenuBarUSBTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            return XCTFail("Could not create isolated defaults suite")
        }
        defer { defaults.removePersistentDomain(forName: suiteName) }

        ["internetMonitoring", "trafficButton", "disableTrafficButtonLabel", "fastMonitor"].forEach {
            defaults.set(true, forKey: $0)
        }
        Utils.App.removeLegacyEthernetTrafficData(defaults: defaults)

        ["internetMonitoring", "trafficButton", "disableTrafficButtonLabel", "fastMonitor"].forEach {
            XCTAssertNil(defaults.object(forKey: $0))
        }
    }

    func testCuratedInitialDefaultsDoNotOverwriteExistingPreferences() {
        let suiteName = "MenuBarUSBTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            return XCTFail("Could not create isolated defaults suite")
        }
        defer { defaults.removePersistentDomain(forName: suiteName) }

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

    func testRemovedFeatureDataIsCleared() {
        let suiteName = "MenuBarUSBTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            return XCTFail("Could not create isolated defaults suite")
        }
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let removedKeys = [
            "storedDevices", "inheritedDevices", "connectionLogs",
            "showNotifications", "searchEngine", "storeConnectionLogs",
            "listToolBar", "forceEnglish",
            "renamedDevices", "camouflagedDevices", "pinnedDevices",
        ]
        removedKeys.forEach { defaults.set("legacy-value", forKey: $0) }

        Utils.App.removeRemovedFeatureData(defaults: defaults)

        removedKeys.forEach { XCTAssertNil(defaults.object(forKey: $0)) }
    }
}
