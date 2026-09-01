import Foundation

struct DiagnosticPowerSource: Equatable {
    let chargePercentage: Int?
    let isCharging: Bool
    let chargingPowerWatts: Int?
    let adapterPowerWatts: Int?
}

struct DiagnosticOverviewSnapshot: Equatable {
    let appVersion: String
    let appBuild: String
    let generatedAt: Date
    let operatingSystemVersion: String
    let modelIdentifier: String?
    let devices: [USBDevice]
    let thunderboltPorts: [ThunderboltPort]
    let externalThunderboltPortGroups: [ExternalThunderboltPortGroup]
    let bluetoothDevices: [BluetoothDevice]
    let deviceSourceStatus: HardwareSourceStatus
    let bluetoothSourceStatus: HardwareSourceStatus
    let powerSource: DiagnosticPowerSource?
    let powerSourceConnectorNumber: Int?
}

struct DiagnosticReportBuilder {
    typealias Localize = (String) -> String

    private let localize: Localize

    init(localize: @escaping Localize = { $0.localized }) {
        self.localize = localize
    }

    func overview(_ snapshot: DiagnosticOverviewSnapshot) -> String {
        let groups = USBDeviceGroups(
            devices: snapshot.devices,
            thunderboltPorts: snapshot.thunderboltPorts,
            externalThunderboltPortGroups: snapshot.externalThunderboltPortGroups
        )
        let connectedDeviceCount = groups.countedExternalDeviceCount + snapshot.bluetoothDevices.count

        var lines = [
            "# MenuBarIO — \(markdownText(localize("hardware_report")))",
            "",
            fieldLine("report_version", "\(snapshot.appVersion) (\(snapshot.appBuild))"),
            fieldLine("generated_at", Self.timestampFormatter.string(from: snapshot.generatedAt)),
            fieldLine("operating_system", snapshot.operatingSystemVersion),
        ]
        if let modelIdentifier = snapshot.modelIdentifier, !modelIdentifier.isEmpty {
            lines.append(fieldLine("mac_model", modelIdentifier))
        }
        lines.append(fieldLine("connected_devices", String(connectedDeviceCount)))

        let statusMessages = [
            sourceStatusMessage(snapshot.deviceSourceStatus),
            bluetoothStatusMessage(snapshot.bluetoothSourceStatus),
        ].compactMap { $0 }
        if !statusMessages.isEmpty {
            lines.append("")
            lines.append(
                contentsOf: statusMessages.map {
                    "> **\(fieldLabel("status")):** \(markdownText($0))"
                })
        }

        if let powerSource = snapshot.powerSource {
            appendSection(title: localize("power_supply"), count: nil, to: &lines)
            if let chargePercentage = powerSource.chargePercentage {
                lines.append(fieldLine("charge_level", "\(chargePercentage)%"))
            }
            if powerSource.isCharging, let chargingPowerWatts = powerSource.chargingPowerWatts {
                lines.append(fieldLine("charging_power", "\(chargingPowerWatts) W"))
            }
            if let adapterPowerWatts = powerSource.adapterPowerWatts {
                lines.append(fieldLine("adapter_power", "\(adapterPowerWatts) W"))
            }
        }

        appendSection(
            title: localize("thunderbolt_ports"),
            count: snapshot.thunderboltPorts.count,
            to: &lines
        )
        if snapshot.thunderboltPorts.isEmpty {
            appendEmptyState(to: &lines)
        } else {
            for port in snapshot.thunderboltPorts {
                appendPort(
                    port,
                    headingLevel: 3,
                    isPowerSourceConnected:
                        port.connectedDevice == nil
                        && snapshot.powerSourceConnectorNumber == port.connectorNumber,
                    powerSourceWatts: snapshot.powerSource?.adapterPowerWatts,
                    to: &lines
                )
            }
        }

        let externalPortCount = snapshot.externalThunderboltPortGroups.reduce(0) {
            $0 + $1.ports.count
        }
        appendSection(
            title: localize("external_thunderbolt_ports"),
            count: externalPortCount,
            to: &lines
        )
        if snapshot.externalThunderboltPortGroups.isEmpty {
            appendEmptyState(to: &lines)
        }
        for group in snapshot.externalThunderboltPortGroups {
            lines.append("### \(markdownText(group.owner.displayName))")
            lines.append("")
            if let vendor = group.owner.vendor, !vendor.isEmpty {
                lines.append(fieldLine("vendor", vendor))
                lines.append("")
            }
            for port in group.ports {
                appendPort(port, headingLevel: 4, to: &lines)
            }
        }

        appendSection(
            title: localize("usb_devices"),
            count: groups.usbDevices.count,
            to: &lines
        )
        if groups.usbDevices.isEmpty {
            appendEmptyState(to: &lines)
        } else {
            for device in groups.usbDevices {
                appendDevice(device, headingLevel: 3, to: &lines)
            }
        }

        appendSection(
            title: localize("bluetooth_devices"),
            count: snapshot.bluetoothDevices.count,
            to: &lines
        )
        if snapshot.bluetoothDevices.isEmpty {
            appendEmptyState(to: &lines)
        } else {
            lines.append(
                contentsOf: snapshot.bluetoothDevices.map {
                    "- \(markdownText($0.name))"
                })
        }

        appendSection(
            title: localize("internal_devices"),
            count: groups.internalDevices.count,
            to: &lines
        )
        if groups.internalDevices.isEmpty {
            appendEmptyState(to: &lines)
        } else {
            for device in groups.internalDevices {
                appendDevice(device, headingLevel: 3, to: &lines)
            }
        }

        appendSection(
            title: localize("usb_hubs"),
            count: groups.hubs.count,
            to: &lines
        )
        if groups.hubs.isEmpty {
            appendEmptyState(to: &lines)
        }
        for group in groups.hubGroups {
            lines.append("### \(markdownText(hubOwnerDescription(group.owner)))")
            lines.append("")
            for device in group.devices {
                appendDevice(device, headingLevel: 4, to: &lines)
            }
        }

        while lines.last == "" {
            lines.removeLast()
        }
        return lines.joined(separator: "\n") + "\n"
    }

    func usbDeviceDetails(_ device: USBDevice) -> String {
        var parts: [String] = []

        if !device.name.isEmpty {
            parts.append(sanitize(device.name))
        } else {
            parts.append(localize("usb_device"))
        }

        if let vendor = device.vendor, !vendor.isEmpty {
            parts.append(sanitize(vendor))
        }

        parts.append(sanitize(device.uniqueId))
        parts.append(device.hardwareIdentifier)

        if let usbVer = device.usbVersionBCD {
            if let usbVersion = USBFormatting.usbVersionLabel(from: usbVer) {
                parts.append("\(localize("usb_version")) \(usbVersion)")
            } else {
                parts.append("\(localize("usb_version")) 0x\(String(format: "%04X", usbVer))")
            }
        }

        if let serial = device.serialNumber, !serial.isEmpty {
            parts.append("\(localize("serial_number")) \(sanitize(serial))")
        }

        if let portMax = device.portMaxSpeedMbps {
            parts.append("\(localize("port_max")) \(USBFormatting.transferRate(portMax))")
        }

        return parts.joined(separator: "\n")
    }

    func bluetoothDeviceDetails(_ device: BluetoothDevice) -> String {
        var parts = [sanitize(device.name), "Bluetooth"]
        if let address = device.address {
            parts.append("\(localize("bluetooth_address")) \(sanitize(address))")
        }
        return parts.joined(separator: "\n")
    }

    func thunderboltPortDetails(
        _ port: ThunderboltPort,
        isPowerSourceConnected: Bool = false,
        powerSourceWatts: Int? = nil
    ) -> String {
        var parts = [
            "\(localize("thunderbolt_port")) \(port.connectorNumber)",
            "\(localize("controller_id")) \(port.controllerID)",
        ]

        if let device = port.connectedDevice {
            parts.append(port.protocolDescription)
            if let speed = port.negotiatedSpeedMbps {
                parts.append("\(localize("negotiated_speed")) \(USBFormatting.transferRate(speed))")
            }
            if let maximum = port.maximumSpeedMbps {
                parts.append("\(localize("port_max")) \(USBFormatting.transferRate(maximum))")
            }
            parts.append(usbDeviceDetails(device))
        } else if isPowerSourceConnected {
            parts.append(localize("power_supply"))
            if let powerSourceWatts {
                parts.append(String(format: localize("power_adapter_watts_format"), powerSourceWatts))
            }
            if let maximum = port.maximumSpeedMbps {
                parts.append("\(localize("port_max")) \(USBFormatting.transferRate(maximum))")
            }
        } else {
            parts.append(localize("port_free"))
            if let maximum = port.maximumSpeedMbps {
                parts.append("\(localize("port_max")) \(USBFormatting.transferRate(maximum))")
            }
        }

        return parts.joined(separator: "\n")
    }

    private func sourceStatusMessage(_ status: HardwareSourceStatus) -> String? {
        switch status {
        case .stale:
            return localize("hardware_data_stale")
        case .unavailable:
            return localize("hardware_data_unavailable")
        case .ready, .refreshing:
            return nil
        }
    }

    private func bluetoothStatusMessage(_ status: HardwareSourceStatus) -> String? {
        switch status {
        case .stale:
            return localize("bluetooth_data_stale")
        case .unavailable(.bluetoothPoweredOff):
            return localize("bluetooth_off")
        case .unavailable:
            return localize("bluetooth_unavailable")
        case .ready, .refreshing:
            return nil
        }
    }

    private func appendSection(
        title: String,
        count: Int?,
        to lines: inout [String]
    ) {
        lines.append("")
        let countSuffix = count.map { " (\($0))" } ?? ""
        lines.append("## \(markdownText(title))\(countSuffix)")
        lines.append("")
    }

    private func appendPort(
        _ port: ThunderboltPort,
        headingLevel: Int,
        isPowerSourceConnected: Bool = false,
        powerSourceWatts: Int? = nil,
        to lines: inout [String]
    ) {
        let heading = String(repeating: "#", count: headingLevel)
        let portTitle: String
        if let device = port.connectedDevice {
            portTitle = device.displayName
        } else if isPowerSourceConnected {
            portTitle = localize("power_supply")
        } else {
            portTitle = localize("port_free")
        }

        lines.append(
            "\(heading) \(markdownText(localize("thunderbolt_port"))) \(port.connectorNumber) — \(markdownText(portTitle))"
        )
        lines.append("")

        if let device = port.connectedDevice {
            if let vendor = device.vendor, !vendor.isEmpty {
                lines.append(fieldLine("vendor", vendor))
            }
            lines.append(fieldLine("protocol", port.protocolDescription))
            if let speed = port.negotiatedSpeedMbps {
                lines.append(fieldLine("negotiated_speed", USBFormatting.transferRate(speed)))
            }
            if let maximum = port.maximumSpeedMbps {
                lines.append(fieldLine("port_max", USBFormatting.transferRate(maximum)))
            }
        } else if isPowerSourceConnected {
            lines.append(fieldLine("protocol", port.protocolDescription))
            if let powerSourceWatts {
                lines.append(fieldLine("adapter_power", "\(powerSourceWatts) W"))
            }
            if let maximum = port.maximumSpeedMbps {
                lines.append(fieldLine("port_max", USBFormatting.transferRate(maximum)))
            }
        } else {
            lines.append(fieldLine("protocol", port.protocolDescription))
            if let maximum = port.maximumSpeedMbps {
                lines.append(fieldLine("port_max", USBFormatting.transferRate(maximum)))
            }
        }
        lines.append("")
    }

    private func appendDevice(
        _ device: USBDevice,
        headingLevel: Int,
        to lines: inout [String]
    ) {
        let heading = String(repeating: "#", count: headingLevel)
        lines.append("\(heading) \(markdownText(device.displayName))")
        lines.append("")

        if let vendor = device.vendor, !vendor.isEmpty {
            lines.append(fieldLine("vendor", vendor))
        }
        lines.append(fieldLine("protocol", deviceProtocolDescription(device)))
        if let speed = device.speedMbps {
            lines.append(fieldLine("negotiated_speed", USBFormatting.transferRate(speed)))
        }
        if let portMaximum = device.portMaxSpeedMbps {
            lines.append(fieldLine("port_max", USBFormatting.transferRate(portMaximum)))
        }
        lines.append("")
    }

    private func deviceProtocolDescription(_ device: USBDevice) -> String {
        if let transportVersion = device.transportVersion, !transportVersion.isEmpty {
            return transportVersion
        }
        if let speed = device.speedMbps {
            return USBFormatting.speedTierLabel(for: speed)
        }
        if let usbVersion = USBFormatting.usbVersionLabel(from: device.usbVersionBCD) {
            return usbVersion
        }
        return device.transport.displayName
    }

    private func appendEmptyState(to lines: inout [String]) {
        lines.append("_\(markdownText(localize("no_devices_found")))_")
    }

    private func hubOwnerDescription(_ owner: USBHubOwner) -> String {
        switch owner {
        case .thisMac:
            return localize("this_mac")
        case .thunderboltDevice(_, let displayName, _):
            return displayName
        case .direct:
            return localize("direct_usb_hubs")
        case .unknown:
            return localize("unknown_usb_hub_assignment")
        }
    }

    private func sanitize(_ value: String) -> String {
        SystemActions.sanitizedDeviceField(value)
    }

    private func fieldLine(_ key: String, _ value: String) -> String {
        "- **\(fieldLabel(key)):** \(markdownText(value))"
    }

    private func fieldLabel(_ key: String) -> String {
        localize(key).trimmingCharacters(
            in: CharacterSet.whitespacesAndNewlines.union(
                CharacterSet(charactersIn: ":")
            ))
    }

    private func markdownText(_ value: String) -> String {
        let specialCharacters = CharacterSet(charactersIn: "\\`*_[]<>#|")
        return sanitize(value).unicodeScalars.map { scalar in
            specialCharacters.contains(scalar) ? "\\\(scalar)" : String(scalar)
        }.joined()
    }

    private static let timestampFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}
