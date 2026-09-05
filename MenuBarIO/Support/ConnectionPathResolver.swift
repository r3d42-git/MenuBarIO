import Foundation

/// Uses only already resolved physical port assignments and unique USB ancestry.
struct ConnectionPathResolver {
    let devices: [USBDevice]
    let hostPorts: [ThunderboltPort]
    let externalGroups: [ExternalThunderboltPortGroup]
    var localize: (String) -> String = { $0.localized }

    func path(to device: USBDevice) -> String? {
        components(to: device, visited: []).map { $0.joined(separator: " → ") }
    }

    func path(to port: ThunderboltPort) -> String? {
        if hostPorts.contains(where: { $0.id == port.id }) {
            return ([localize("this_mac"), portName(port)] + deviceName(port)).joined(separator: " → ")
        }
        let owners = externalGroups.filter { $0.ports.contains(where: { $0.id == port.id }) }
        guard owners.count == 1,
            let ownerPath = components(to: owners[0].owner, visited: [])
        else { return nil }
        return (ownerPath + [portName(port)] + deviceName(port)).joined(separator: " → ")
    }

    private func components(to device: USBDevice, visited: Set<String>) -> [String]? {
        guard !visited.contains(device.id) else { return nil }
        let visited = visited.union([device.id])
        let hostMatches = hostPorts.filter { $0.connectedDevice?.id == device.id }
        if hostMatches.count == 1 {
            return [localize("this_mac"), portName(hostMatches[0]), device.displayName]
        }
        guard hostMatches.isEmpty else { return nil }
        let externalMatches = externalGroups.flatMap { group in
            group.ports.filter { $0.connectedDevice?.id == device.id }.map { (group, $0) }
        }
        if externalMatches.count == 1 {
            let (group, port) = externalMatches[0]
            guard let ownerPath = components(to: group.owner, visited: visited) else { return nil }
            return ownerPath + [portName(port), device.displayName]
        }
        guard externalMatches.isEmpty else { return nil }
        if device.isInternal { return [localize("this_mac"), device.displayName] }
        if let location = device.parentHubLocationId {
            let parents = devices.filter { $0.isHub && $0.locationId == location }
            guard parents.count == 1,
                let parentPath = components(to: parents[0], visited: visited)
            else { return nil }
            // A USB hub's logical port number need not identify a labelled receptacle.
            return parentPath + [device.displayName]
        }
        return nil
    }

    private func portName(_ port: ThunderboltPort) -> String {
        "\(localize("thunderbolt_port")) \(port.connectorNumber)"
    }

    private func deviceName(_ port: ThunderboltPort) -> [String] {
        port.connectedDevice.map { [$0.displayName] } ?? []
    }
}
