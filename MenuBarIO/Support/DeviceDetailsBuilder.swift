import Foundation

struct DeviceDetailField: Identifiable {
    let label: String
    let value: String
    var id: String { label }
}

struct DeviceDetailContent {
    let title: String
    let fields: [DeviceDetailField]
    let technicalFields: [DeviceDetailField]
    let notes: [String]
    let copyText: String
}

struct DeviceDetailsBuilder {
    let paths: ConnectionPathResolver

    func usb(_ device: USBDevice) -> DeviceDetailContent {
        let displayOutputCount = activeDisplayOutputCount(for: device)
        return DeviceDetailContent(
            title: device.displayName,
            fields: deviceFields(device) + [pathField(paths.path(to: device))]
                + (displayOutputCount > 0
                    ? [.init(label: "active_displayport_outputs", value: "\(displayOutputCount)")] : []),
            technicalFields: technicalFields(device),
            notes: ["link_speed_explanation"] + (displayOutputCount > 0 ? ["displayport_connector_unknown"] : []),
            copyText: withPath(
                DiagnosticReportBuilder().usbDeviceDetails(device)
                    + displayOutputCopy(count: displayOutputCount),
                paths.path(to: device))
        )
    }

    func port(_ port: ThunderboltPort, powerConnected: Bool, powerWatts: Int?) -> DeviceDetailContent {
        let displayOutputCount = activeDisplayOutputCount(for: port.connectedDevice)
        var fields: [DeviceDetailField] = []
        if let device = port.connectedDevice {
            fields = deviceFields(device).filter { $0.label != "port_max" }
        } else {
            fields.append(
                .init(label: "status", value: (powerConnected ? "power_supply" : port.unoccupiedStatusKey).localized))
            fields.append(.init(label: "protocol", value: port.protocolDescription))
            if powerConnected, let powerWatts {
                fields.append(.init(label: "adapter_power", value: "\(powerWatts) W"))
            }
        }
        if let maximum = port.connectionMaximumSpeedMbps {
            fields.append(.init(label: "port_max", value: USBFormatting.transferRate(maximum)))
        }
        if port.connectedDevice?.transport != .usb, let boost = port.bandwidthBoostSpeedMbps {
            fields.append(.init(label: "bandwidth_boost", value: USBFormatting.transferRate(boost)))
        }
        if displayOutputCount > 0 {
            fields.append(.init(label: "active_displayport_outputs", value: "\(displayOutputCount)"))
        }
        fields.append(pathField(paths.path(to: port)))
        return DeviceDetailContent(
            title: "\("thunderbolt_port".localized) \(port.connectorNumber) · "
                + (port.connectedDevice?.displayName
                    ?? (powerConnected ? "power_supply" : port.unoccupiedStatusKey).localized),
            fields: fields,
            technicalFields: port.connectedDevice.map(technicalFields) ?? [],
            notes: ["link_speed_explanation"]
                + (port.hasUnresolvedDisplayConnection || displayOutputCount > 0
                    ? ["displayport_connector_unknown"] : [])
                + (port.bandwidthBoostSpeedMbps == nil || port.connectedDevice?.transport == .usb
                    ? [] : ["bandwidth_boost_explanation"]),
            copyText: withPath(
                DiagnosticReportBuilder().thunderboltPortDetails(
                    port, isPowerSourceConnected: powerConnected, powerSourceWatts: powerWatts
                ) + displayOutputCopy(count: displayOutputCount), paths.path(to: port)
            )
        )
    }

    func bluetooth(_ device: BluetoothDevice) -> DeviceDetailContent {
        var fields = [DeviceDetailField(label: "protocol", value: "Bluetooth")]
        if let level = device.batteryLevel {
            fields.append(.init(label: "battery_level", value: "\(level)%"))
        }
        return DeviceDetailContent(
            title: device.name,
            fields: fields,
            technicalFields: device.address.map { [.init(label: "bluetooth_address", value: $0)] } ?? [],
            notes: [],
            copyText: DiagnosticReportBuilder().bluetoothDeviceDetails(device)
        )
    }

    private func activeDisplayOutputCount(for device: USBDevice?) -> Int {
        guard let device else { return 0 }
        return paths.externalGroups.first { $0.owner.id == device.id }?.activeDisplayOutputCount ?? 0
    }

    private func displayOutputCopy(count: Int) -> String {
        guard count > 0 else { return "" }
        return "\n\("active_displayport_outputs".localized): \(count)\n\("displayport_connector_unknown".localized)"
    }

    private func deviceFields(_ device: USBDevice) -> [DeviceDetailField] {
        var fields: [DeviceDetailField] = []
        if let vendor = device.vendor, !vendor.isEmpty {
            fields.append(.init(label: "vendor", value: vendor))
        }
        let protocolName =
            device.transport == .usb
            ? device.speedMbps.map(USBFormatting.speedTierLabel) ?? device.transport.displayName
            : device.transportVersion ?? device.transport.displayName
        fields.append(.init(label: "protocol", value: protocolName))
        fields.append(
            .init(
                label: "negotiated_speed",
                value: device.speedMbps.map(USBFormatting.transferRate) ?? "unknown_speed".localized))
        if let maximum = device.portMaxSpeedMbps {
            fields.append(.init(label: "port_max", value: USBFormatting.transferRate(maximum)))
        }
        return fields
    }

    private func technicalFields(_ device: USBDevice) -> [DeviceDetailField] {
        var fields = [DeviceDetailField(label: "hardware_identifier", value: device.hardwareIdentifier)]
        if let serial = device.serialNumber, !serial.isEmpty {
            fields.append(.init(label: "serial_number", value: serial))
        }
        if let version = USBFormatting.usbVersionLabel(from: device.usbVersionBCD) {
            fields.append(.init(label: "usb_version", value: version))
        }
        return fields
    }

    private func pathField(_ path: String?) -> DeviceDetailField {
        .init(label: "connection_path", value: path ?? "connection_path_unknown".localized)
    }

    private func withPath(_ text: String, _ path: String?) -> String {
        guard let path else { return text }
        return text + "\n\("connection_path".localized): \(SystemActions.sanitizedDeviceField(path))"
    }
}
