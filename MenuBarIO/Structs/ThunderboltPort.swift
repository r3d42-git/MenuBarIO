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
