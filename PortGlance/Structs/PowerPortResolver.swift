import Foundation

struct PowerPortControllerRecord: Equatable {
    let routerID: Int
    let address: Int
}

struct PowerPortContractRecord: Equatable {
    let loserReason: Int
    let powerDeliveryState: Int
    let maximumPowerMilliwatts: Int
    let fetStatus: Int

    var isSupplyingPower: Bool {
        loserReason == 0
            && powerDeliveryState > 0
            && maximumPowerMilliwatts > 0
            && fetStatus != 0
    }
}

struct PowerPortThunderboltConnectorRecord: Equatable {
    let routerID: Int
    let connectorNumber: Int
    let hostPortNumber: Int
}

enum PowerPortResolver {
    static func connectorNumber(
        contracts: [PowerPortContractRecord],
        controllers: [PowerPortControllerRecord],
        thunderboltConnectors: [PowerPortThunderboltConnectorRecord]
    ) -> Int? {
        let sortedControllers = controllers.sorted {
            $0.routerID < $1.routerID
                || ($0.routerID == $1.routerID && $0.address < $1.address)
        }
        guard contracts.count == sortedControllers.count,
            Set(sortedControllers.map { "\($0.routerID):\($0.address)" }).count
                == sortedControllers.count
        else {
            return nil
        }

        let supplyingIndices = contracts.indices.filter {
            contracts[$0].isSupplyingPower
        }
        guard supplyingIndices.count == 1 else { return nil }

        let controller = sortedControllers[supplyingIndices[0]]
        let controllerAddresses =
            sortedControllers
            .filter { $0.routerID == controller.routerID }
            .map(\.address)
        guard controllerAddresses == Array(0..<controllerAddresses.count) else {
            return nil
        }

        var firstHostPortByConnector: [Int: Int] = [:]
        for connector in thunderboltConnectors
        where connector.routerID == controller.routerID {
            firstHostPortByConnector[connector.connectorNumber] = min(
                firstHostPortByConnector[connector.connectorNumber] ?? Int.max,
                connector.hostPortNumber
            )
        }

        let connectorNumbers =
            firstHostPortByConnector
            .sorted {
                $0.value < $1.value
                    || ($0.value == $1.value && $0.key < $1.key)
            }
            .map(\.key)
        guard connectorNumbers.count == controllerAddresses.count,
            connectorNumbers.indices.contains(controller.address)
        else {
            return nil
        }

        return connectorNumbers[controller.address]
    }
}
