struct USBDeviceGroups: Equatable {
    let externalDevices: [USBDevice]
    let internalDevices: [USBDevice]
    let hubs: [USBDevice]

    init(devices: [USBDevice]) {
        externalDevices = devices.filter(\.countsTowardUSBDeviceTotal)
        internalDevices = devices.filter { $0.isInternal && !$0.isHub }
        hubs = devices.filter(\.isHub)
    }
}
