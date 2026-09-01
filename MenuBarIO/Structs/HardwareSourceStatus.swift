import Foundation

enum HardwareSourceUnavailableReason: Equatable {
    case discoveryFailed
    case bluetoothPoweredOff
    case bluetoothUnavailable
}

enum HardwareSourceStatus: Equatable {
    case ready(lastUpdated: Date)
    case refreshing(lastUpdated: Date?)
    case stale(lastUpdated: Date)
    case unavailable(HardwareSourceUnavailableReason)

    var isRefreshing: Bool {
        if case .refreshing = self {
            return true
        }
        return false
    }

    var lastUpdated: Date? {
        switch self {
        case .ready(let lastUpdated), .stale(let lastUpdated):
            return lastUpdated
        case .refreshing(let lastUpdated):
            return lastUpdated
        case .unavailable:
            return nil
        }
    }
}
