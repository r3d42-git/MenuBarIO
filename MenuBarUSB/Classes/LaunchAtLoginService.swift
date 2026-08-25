//
//  LaunchAtLoginService.swift
//  MenuBarUSB
//

import ServiceManagement

struct LaunchAtLoginUpdateResult: Equatable {
    let persistedValue: Bool
    let errorMessage: String?

    static func applying(
        requestedValue: Bool,
        currentValue: () -> Bool,
        operation: () throws -> Void
    ) -> Self {
        do {
            try operation()
            return Self(persistedValue: requestedValue, errorMessage: nil)
        } catch {
            return Self(
                persistedValue: currentValue(),
                errorMessage: error.localizedDescription
            )
        }
    }
}

enum LaunchAtLoginService {
    static func update(enabled: Bool) -> LaunchAtLoginUpdateResult {
        LaunchAtLoginUpdateResult.applying(
            requestedValue: enabled,
            currentValue: { SMAppService.mainApp.status == .enabled }
        ) {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        }
    }
}
