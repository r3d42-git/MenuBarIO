import XCTest

@testable import MenuBarIO

final class DiagnosticReportBuilderTests: XCTestCase {
    func testOverviewUsesDisplayOrderAndOmitsSensitiveIdentifiers() throws {
        let usbDevice = makeDevice(
            name: "Camera\u{202E}",
            vendor: "Example Vendor",
            serialNumber: "SECRET-SERIAL",
            locationId: 0x0110_0000,
            speedMbps: 480,
            portMaxSpeedMbps: 5_000
        )
        let hub = makeDevice(
            name: "IOUSBHostDevice",
            vendor: nil,
            serialNumber: "SECRET-HUB",
            locationId: 0x0120_0000,
            speedMbps: 12,
            portMaxSpeedMbps: 480,
            deviceClass: 9,
            isThunderboltTunneledUSB: true
        )
        let bluetooth = try XCTUnwrap(
            BluetoothDevice(
                snapshot: .init(
                    identifier: "AA:BB:CC:DD:EE:FF",
                    name: "Desk Mouse",
                    isConnected: true
                )
            )
        )
        let port = ThunderboltPort(
            id: "host-port-private-id",
            controllerID: 99,
            connectorNumber: 1,
            protocolVersion: 4,
            maximumSpeedMbps: 40_000,
            connectedDevice: nil
        )
        let dock = makeDevice(
            name: "Desk Dock",
            vendor: "Dock Vendor",
            serialNumber: "SECRET-DOCK",
            locationId: 0x0130_0000,
            speedMbps: 40_000,
            portMaxSpeedMbps: 40_000,
            transport: .thunderbolt,
            transportVersion: "Thunderbolt 3/4 / USB4"
        )
        let externalPort = ThunderboltPort(
            id: "external-port-private-id",
            controllerID: 100,
            connectorNumber: 1,
            protocolVersion: 32,
            maximumSpeedMbps: 40_000,
            connectedDevice: usbDevice
        )
        let snapshot = DiagnosticOverviewSnapshot(
            appVersion: "0.5.0",
            appBuild: "9",
            generatedAt: Date(timeIntervalSince1970: 0),
            operatingSystemVersion: "macOS 26.6",
            modelIdentifier: "Mac15,14",
            devices: [usbDevice, hub],
            thunderboltPorts: [port],
            externalThunderboltPortGroups: [
                ExternalThunderboltPortGroup(
                    owner: dock,
                    hostConnectorNumber: 1,
                    depth: 1,
                    ports: [externalPort]
                )
            ],
            bluetoothDevices: [bluetooth],
            deviceSourceStatus: .ready(lastUpdated: Date(timeIntervalSince1970: 0)),
            bluetoothSourceStatus: .ready(lastUpdated: Date(timeIntervalSince1970: 0)),
            powerSource: DiagnosticPowerSource(
                chargePercentage: nil,
                isCharging: false,
                chargingPowerWatts: nil,
                adapterPowerWatts: 100
            ),
            powerSourceConnectorNumber: 1
        )

        let report = DiagnosticReportBuilder(localize: reportLocalizer).overview(snapshot)

        XCTAssertTrue(report.hasPrefix("# MenuBarIO — hardware report\n"))
        XCTAssertTrue(report.contains("- **report version:** 0.5.0 (9)"))
        XCTAssertTrue(report.contains("- **operating system:** macOS 26.6"))
        XCTAssertTrue(report.contains("- **mac model:** Mac15,14"))
        XCTAssertTrue(report.contains("### Desk Dock"))
        XCTAssertTrue(report.contains("#### thunderbolt port 1 — Camera\\\\u{202E}"))
        XCTAssertTrue(report.contains("Example Vendor"))
        XCTAssertTrue(report.contains("480 Mbps"))
        XCTAssertTrue(report.contains("5.0 Gbps"))
        XCTAssertTrue(report.contains("40.0 Gbps"))
        XCTAssertTrue(report.contains("100 W"))
        XCTAssertTrue(report.contains("Desk Mouse"))
        XCTAssertTrue(report.contains("unknown usb hub assignment"))
        XCTAssertTrue(report.contains("_no devices found_"))
        XCTAssertTrue(report.hasSuffix("\n"))
        XCTAssertFalse(report.contains(" · "))

        XCTAssertFalse(report.contains("SECRET-SERIAL"))
        XCTAssertFalse(report.contains("SECRET-HUB"))
        XCTAssertFalse(report.contains("AA:BB:CC:DD:EE:FF"))
        XCTAssertFalse(report.contains(usbDevice.uniqueId))
        XCTAssertFalse(report.contains("host-port-private-id"))
        XCTAssertFalse(report.contains("external-port-private-id"))
        XCTAssertFalse(report.contains("controller id"))

        assertOrder(
            [
                "thunderbolt ports",
                "external thunderbolt ports",
                "usb devices",
                "bluetooth devices",
                "internal devices",
                "usb hubs",
            ],
            in: report
        )
    }

    func testExplicitDeviceDetailsRetainTechnicalIdentifiers() throws {
        let usbDevice = makeDevice(
            name: "Camera",
            vendor: "Vendor",
            serialNumber: "SERIAL-123",
            locationId: 0x0100_0000,
            speedMbps: 480,
            portMaxSpeedMbps: 5_000
        )
        let bluetooth = try XCTUnwrap(
            BluetoothDevice(
                snapshot: .init(
                    identifier: "AA:BB",
                    name: "Mouse",
                    isConnected: true
                )
            )
        )
        let builder = DiagnosticReportBuilder(localize: { $0 })

        XCTAssertTrue(builder.usbDeviceDetails(usbDevice).contains("SERIAL-123"))
        XCTAssertTrue(builder.usbDeviceDetails(usbDevice).contains(usbDevice.uniqueId))
        XCTAssertTrue(builder.bluetoothDeviceDetails(bluetooth).contains("AA:BB"))
    }

    func testOverviewIncludesStaleAndPoweredOffStatus() {
        let snapshot = DiagnosticOverviewSnapshot(
            appVersion: "1",
            appBuild: "1",
            generatedAt: Date(timeIntervalSince1970: 0),
            operatingSystemVersion: "macOS",
            modelIdentifier: nil,
            devices: [],
            thunderboltPorts: [],
            externalThunderboltPortGroups: [],
            bluetoothDevices: [],
            deviceSourceStatus: .stale(lastUpdated: Date(timeIntervalSince1970: 0)),
            bluetoothSourceStatus: .unavailable(.bluetoothPoweredOff),
            powerSource: nil,
            powerSourceConnectorNumber: nil
        )

        let report = DiagnosticReportBuilder(localize: reportLocalizer).overview(snapshot)

        XCTAssertTrue(report.contains("hardware data stale"))
        XCTAssertTrue(report.contains("bluetooth off"))
    }

    private func makeDevice(
        name: String,
        vendor: String?,
        serialNumber: String?,
        locationId: UInt32,
        speedMbps: Int,
        portMaxSpeedMbps: Int,
        deviceClass: Int? = nil,
        isThunderboltTunneledUSB: Bool = false,
        transport: ConnectionTransport = .usb,
        transportVersion: String? = nil
    ) -> USBDevice {
        USBDevice(
            name: name,
            vendor: vendor,
            vendorId: 0x1234,
            productId: 0x5678,
            serialNumber: serialNumber,
            locationId: locationId,
            speedMbps: speedMbps,
            portMaxSpeedMbps: portMaxSpeedMbps,
            usbVersionBCD: 0x0200,
            isExternalStorage: false,
            deviceClass: deviceClass,
            transport: transport,
            transportVersion: transportVersion,
            isThunderboltTunneledUSB: isThunderboltTunneledUSB
        )
    }

    private func reportLocalizer(_ key: String) -> String {
        if key == "power_adapter_watts_format" {
            return "%d W adapter"
        }
        return key.replacingOccurrences(of: "_", with: " ")
    }

    private func assertOrder(
        _ values: [String],
        in text: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        var previousLocation = text.startIndex
        for value in values {
            guard let range = text.range(of: value, range: previousLocation..<text.endIndex) else {
                XCTFail("Missing ordered value: \(value)", file: file, line: line)
                return
            }
            previousLocation = range.upperBound
        }
    }
}
