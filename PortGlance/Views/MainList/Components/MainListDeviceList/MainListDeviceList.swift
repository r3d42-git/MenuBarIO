import SwiftUI

struct MainListDeviceList: View {
    @EnvironmentObject private var manager: USBDeviceManager
    @EnvironmentObject private var bluetoothManager: BluetoothDeviceManager

    @State private var hoveredDeviceID: String?

    @Binding var deviceGroupExpanded: Bool
    @Binding var hubGroupExpanded: Bool
    @Binding var internalGroupExpanded: Bool
    @Binding var bluetoothGroupExpanded: Bool

    var body: some View {
        let groups = manager.deviceGroups

        PowerSourceRow()

        ContentFittingScrollView {
            VStack(alignment: .leading, spacing: 4) {
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

                USBDeviceRow(
                    device: device,
                    isHovered: isHovered,
                    onHover: { updateHoveredDevice(device.id, isHovering: $0) }
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
