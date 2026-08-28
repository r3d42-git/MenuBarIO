import SwiftUI

struct MainListDeviceList: View {
    @EnvironmentObject private var manager: USBDeviceManager
    @EnvironmentObject private var bluetoothManager: BluetoothDeviceManager

    @State private var hoveredDeviceID: String?
    @State private var expandedDeviceIDs: Set<String> = []

    @Binding var deviceGroupExpanded: Bool
    @Binding var hubGroupExpanded: Bool
    @Binding var internalGroupExpanded: Bool
    @Binding var bluetoothGroupExpanded: Bool

    @AS(Key.hideSecondaryInfo) private var hideSecondaryInfo = false
    @AS(Key.mouseHoverInfo) private var mouseHoverInfo = false
    @AS(Key.showPortMax) private var showPortMax = false
    @AS(Key.showScrollBar) private var showScrollBar = false
    @AS(Key.hideTechInfo) private var hideTechInfo = false
    @AS(Key.bigNames) private var bigNames = false

    var body: some View {
        let groups = manager.deviceGroups

        PowerSourceRow()

        ScrollView(showsIndicators: showScrollBar) {
            LazyVStack(alignment: .leading, spacing: 4) {
                usbGroup(
                    title: "usb_devices",
                    icon: .system("desktopcomputer"),
                    devices: groups.externalDevices,
                    isExpanded: $deviceGroupExpanded
                )

                bluetoothGroup

                usbGroup(
                    title: "internal_devices",
                    icon: .system("laptopcomputer"),
                    devices: groups.internalDevices,
                    isExpanded: $internalGroupExpanded
                )

                usbGroup(
                    title: "usb_hubs",
                    icon: .system("circle.grid.2x2"),
                    devices: groups.hubs,
                    isExpanded: $hubGroupExpanded
                )
            }
            .padding(.horizontal, 2)
        }
        .frame(maxHeight: 1_000)
        .onReceive(manager.$devices) { devices in
            expandedDeviceIDs.formIntersection(Set(devices.map(\.id)))
        }
    }

    @ViewBuilder
    private func usbGroup(
        title: LocalizedStringKey,
        icon: DeviceGroupIcon,
        devices: [USBDevice],
        isExpanded: Binding<Bool>
    ) -> some View {
        DeviceGroupHeader(
            title: title,
            icon: icon,
            count: devices.count,
            isExpanded: isExpanded
        )

        if isExpanded.wrappedValue {
            ForEach(devices) { device in
                let isHovered = hoveredDeviceID == device.id
                let forceDetails = expandedDeviceIDs.contains(device.id)

                USBDeviceRow(
                    device: device,
                    isHovered: isHovered,
                    showsSecondaryInfo: forceDetails
                        || !hideSecondaryInfo
                        || (mouseHoverInfo && isHovered),
                    showsTechnicalInfo: forceDetails
                        || !hideTechInfo
                        || (mouseHoverInfo && isHovered),
                    showsSpeed: showPortMax,
                    usesLargeName: bigNames,
                    onHover: { updateHoveredDevice(device.id, isHovering: $0) },
                    expandedDeviceIDs: $expandedDeviceIDs
                )
            }
        }
    }

    @ViewBuilder
    private var bluetoothGroup: some View {
        DeviceGroupHeader(
            title: "bluetooth_devices",
            icon: .bluetooth,
            count: bluetoothManager.count,
            isExpanded: $bluetoothGroupExpanded
        )

        if bluetoothGroupExpanded {
            ForEach(bluetoothManager.devices) { device in
                BluetoothDeviceRow(
                    device: device,
                    isHovered: hoveredDeviceID == device.id,
                    usesLargeName: bigNames,
                    onHover: { updateHoveredDevice(device.id, isHovering: $0) }
                )
            }
        }
    }

    private func updateHoveredDevice(_ id: String, isHovering: Bool) {
        if isHovering {
            hoveredDeviceID = id
        } else if hoveredDeviceID == id {
            hoveredDeviceID = nil
        }
    }
}
