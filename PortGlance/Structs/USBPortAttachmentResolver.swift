import Foundation

struct ThunderboltUSBPortMapEntry: Equatable {
    let connectorNumber: Int
    let usbHubPortNumbers: Set<Int>

    static func entries(from data: Data?) -> [ThunderboltUSBPortMapEntry] {
        guard let data else { return [] }

        let bytes = Array(data)
        var entries: [ThunderboltUSBPortMapEntry] = []

        // IOKit exposes the Thunderbolt DROM USB port map as three-byte
        // records: the user-facing connector ordinal followed by its USB 2
        // and USB 3 companion-hub locations. A zero companion means that the
        // USB socket is not one of the router's Thunderbolt-capable ports.
        for offset in stride(from: 0, to: bytes.count - 2, by: 3) {
            let connectorNumber = Int(bytes[offset])
            let hubPortNumbers = Set(
                bytes[(offset + 1)...(offset + 2)].compactMap { rawValue -> Int? in
                    guard rawValue != 0 else { return nil }
                    let portNumber = Int(rawValue & 0x0F)
                    return portNumber > 0 ? portNumber : nil
                }
            )

            guard connectorNumber > 0, !hubPortNumbers.isEmpty else { continue }
            entries.append(
                ThunderboltUSBPortMapEntry(
                    connectorNumber: connectorNumber,
                    usbHubPortNumbers: hubPortNumbers
                )
            )
        }

        return entries
    }
}

enum USBPortAttachmentResolver {
    static func attachingUSBDevices(
        to ports: [ThunderboltPort],
        ownerID: String,
        controllerID: Int?,
        hostConnectorNumber: Int,
        portMap: [ThunderboltUSBPortMapEntry],
        usbDevices: [USBDevice]
    ) -> [ThunderboltPort] {
        // A native host-port attachment proves which Mac-side controller owns
        // this router. Intel systems that omit that relationship keep their
        // USB functions in the residual USB list instead of receiving a guess.
        guard hostConnectorNumber != Int.max,
            let controllerID,
            !portMap.isEmpty
        else {
            return ports
        }

        let candidateHubs = usbDevices.filter { device in
            device.isHub
                && !device.isInternal
                && device.usbControllerID == controllerID
        }
        let hasTunnelEvidence = candidateHubs.contains { hub in
            hub.thunderboltOwnerID == ownerID || hub.isThunderboltTunneledUSB
        }
        guard hasTunnelEvidence else { return ports }

        let candidateHubLocations = Set(candidateHubs.compactMap(\.locationId))
        let candidates = usbDevices.filter { device in
            device.countsTowardUSBDeviceTotal
                && device.transport == .usb
                && !device.isThunderboltBillboard
                && device.usbControllerID == controllerID
                && device.parentHubLocationId.map(candidateHubLocations.contains) == true
                && device.parentHubPortNumber != nil
        }

        return ports.map { port in
            guard port.connectedDevice == nil,
                let mapping = portMap.first(where: {
                    $0.connectorNumber == port.connectorNumber
                })
            else {
                return port
            }

            let matchingDevices = candidates.filter { device in
                guard let hubPortNumber = device.parentHubPortNumber else { return false }
                return mapping.usbHubPortNumbers.contains(hubPortNumber)
            }

            // A physical multi-protocol connector can expose one active USB
            // device. More than one candidate means the registry evidence is
            // ambiguous, so preserve the free port plus residual USB entries.
            guard matchingDevices.count == 1, let device = matchingDevices.first else {
                return port
            }

            return ThunderboltPort(
                id: port.id,
                controllerID: port.controllerID,
                connectorNumber: port.connectorNumber,
                protocolVersion: port.protocolVersion,
                maximumSpeedMbps: port.maximumSpeedMbps,
                connectedDevice: device
            )
        }
    }
}
