import Foundation

struct ThunderboltPort: Identifiable, Equatable, Hashable {
    let id: String
    let controllerID: Int
    let connectorNumber: Int
    let protocolVersion: Int?
    let maximumSpeedMbps: Int?
    let connectedDevice: USBDevice?

    init(
        id: String,
        controllerID: Int,
        connectorNumber: Int,
        protocolVersion: Int?,
        maximumSpeedMbps: Int?,
        connectedDevice: USBDevice?
    ) {
        self.id = id
        self.controllerID = controllerID
        self.connectorNumber = connectorNumber
        self.protocolVersion = protocolVersion
        self.maximumSpeedMbps = maximumSpeedMbps
        self.connectedDevice = connectedDevice
    }

    var protocolDescription: String {
        if let connectedDevice, connectedDevice.transport == .usb {
            return connectedDevice.connectionDescription
        }
        if let connectedProtocol = connectedDevice?.transportVersion,
            !connectedProtocol.isEmpty
        {
            return connectedProtocol
        }
        return USBFormatting.thunderboltProtocolLabel(for: protocolVersion)
    }

    var negotiatedSpeedMbps: Int? {
        connectedDevice?.speedMbps
    }

    /// A USB occupant uses its USB companion port capability, not the native TB link limit.
    var connectionMaximumSpeedMbps: Int? {
        connectedDevice?.transport == .usb ? connectedDevice?.portMaxSpeedMbps : standardMaximumSpeedMbps
    }

    /// USB4 v2's asymmetric boost is not the normal bidirectional link rate.
    var standardMaximumSpeedMbps: Int? {
        bandwidthBoostSpeedMbps == nil ? maximumSpeedMbps : 80_000
    }

    var bandwidthBoostSpeedMbps: Int? {
        protocolVersion == 64 && maximumSpeedMbps == 120_000 ? 120_000 : nil
    }
}

struct ExternalThunderboltPortGroup: Identifiable, Equatable, Hashable {
    let owner: USBDevice
    let hostConnectorNumber: Int
    let depth: Int
    let ports: [ThunderboltPort]

    var id: String {
        owner.id
    }
}
