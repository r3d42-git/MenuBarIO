import Foundation

struct ThunderboltPort: Identifiable, Equatable, Hashable {
    let id: String
    let controllerID: Int
    let connectorNumber: Int
    let protocolVersion: Int?
    let maximumSpeedMbps: Int?
    let connectedDevice: USBDevice?
    let hasUnresolvedDisplayConnection: Bool

    init(
        id: String,
        controllerID: Int,
        connectorNumber: Int,
        protocolVersion: Int?,
        maximumSpeedMbps: Int?,
        connectedDevice: USBDevice?,
        hasUnresolvedDisplayConnection: Bool = false
    ) {
        self.id = id
        self.controllerID = controllerID
        self.connectorNumber = connectorNumber
        self.protocolVersion = protocolVersion
        self.maximumSpeedMbps = maximumSpeedMbps
        self.connectedDevice = connectedDevice
        self.hasUnresolvedDisplayConnection = connectedDevice == nil && hasUnresolvedDisplayConnection
    }

    var unoccupiedStatusKey: String {
        hasUnresolvedDisplayConnection ? "port_occupancy_unknown" : "port_free"
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
    let activeDisplayOutputCount: Int

    init(
        owner: USBDevice, hostConnectorNumber: Int, depth: Int,
        ports: [ThunderboltPort], activeDisplayOutputCount: Int = 0
    ) {
        self.owner = owner
        self.hostConnectorNumber = hostConnectorNumber
        self.depth = depth
        self.activeDisplayOutputCount = max(0, activeDisplayOutputCount)
        // DP OUT adapters can be switched between physical connectors. Do not
        // infer an exact socket from their adapter number or static DROM preference.
        self.ports = ports.map { port in
            ThunderboltPort(
                id: port.id, controllerID: port.controllerID,
                connectorNumber: port.connectorNumber, protocolVersion: port.protocolVersion,
                maximumSpeedMbps: port.maximumSpeedMbps, connectedDevice: port.connectedDevice,
                hasUnresolvedDisplayConnection: activeDisplayOutputCount > 0
            )
        }
    }

    var id: String {
        owner.id
    }
}

/// Evidence for an established output tunnel, not a physical connector assignment.
enum DisplayPortConnectionEvidence {
    static func isActiveOutput(
        adapterType: Int?, dpState: Int?, hpdState: Bool?, establishedLaneCount: Int?,
        hasTunnel: Bool
    ) -> Bool {
        adapterType == 917_762 && dpState == 2 && hpdState == true
            && (establishedLaneCount ?? 0) > 0 && hasTunnel
    }
}
