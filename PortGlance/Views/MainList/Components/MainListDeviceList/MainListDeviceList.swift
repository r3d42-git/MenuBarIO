import SwiftUI

struct MainListDeviceList: View {
    @EnvironmentObject private var manager: USBDeviceManager
    @EnvironmentObject private var bluetoothManager: BluetoothDeviceManager

    @State private var hoveredDeviceID: String?

    @Binding var deviceGroupExpanded: Bool
    @Binding var hubGroupExpanded: Bool
    @Binding var internalGroupExpanded: Bool
    @Binding var bluetoothGroupExpanded: Bool
    @Binding var thunderboltPortGroupExpanded: Bool
    @Binding var externalThunderboltPortGroupExpanded: Bool

    var body: some View {
        let groups = manager.deviceGroups

        PowerSourceRow()

        ContentFittingScrollView {
            VStack(alignment: .leading, spacing: 4) {
                thunderboltPortGroup

                externalThunderboltPortGroup

                usbGroup(
                    title: "usb_devices",
                    icon: .system("desktopcomputer"),
                    devices: groups.usbDevices,
                    isExpanded: $deviceGroupExpanded
                )

                bluetoothGroup

                usbGroup(
                    title: "internal_devices",
                    icon: .system("laptopcomputer"),
                    devices: groups.internalDevices,
                    isExpanded: $internalGroupExpanded
                )

                hubGroup(groups: groups)
            }
            .padding(.horizontal, 2)
        }
    }

    @ViewBuilder
    private var externalThunderboltPortGroup: some View {
        DeviceGroupHeader(
            title: "external_thunderbolt_ports",
            icon: .system("bolt.horizontal.circle.fill"),
            count: manager.externalThunderboltPortCount,
            isExpanded: $externalThunderboltPortGroupExpanded
        )

        if externalThunderboltPortGroupExpanded {
            ForEach(manager.externalThunderboltPortGroups) { group in
                ThunderboltPortOwnerHeader(group: group)

                ForEach(group.ports) { port in
                    ThunderboltPortRow(port: port)
                }
            }
        }
    }

    @ViewBuilder
    private var thunderboltPortGroup: some View {
        DeviceGroupHeader(
            title: "thunderbolt_ports",
            icon: .system("bolt.horizontal.circle"),
            count: manager.thunderboltPorts.count,
            isExpanded: $thunderboltPortGroupExpanded
        )

        if thunderboltPortGroupExpanded {
            ForEach(manager.thunderboltPorts) { port in
                ThunderboltPortRow(
                    port: port,
                    isPowerSourceConnected:
                        port.connectedDevice == nil
                        && manager.powerSourceConnectorNumber == port.connectorNumber,
                    powerSourceWatts: manager.adapterPowerWatts
                )
            }
        }
    }

    @ViewBuilder
    private func hubGroup(groups: USBDeviceGroups) -> some View {
        DeviceGroupHeader(
            title: "usb_hubs",
            icon: .system("circle.grid.2x2"),
            count: groups.hubs.count,
            isExpanded: $hubGroupExpanded
        )

        if hubGroupExpanded {
            ForEach(groups.hubGroups) { group in
                USBHubOwnerHeader(group: group)

                ForEach(group.devices) { device in
                    let isHovered = hoveredDeviceID == device.id

                    USBDeviceRow(
                        device: device,
                        isHovered: isHovered,
                        onHover: { updateHoveredDevice(device.id, isHovering: $0) }
                    )
                }
            }
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
