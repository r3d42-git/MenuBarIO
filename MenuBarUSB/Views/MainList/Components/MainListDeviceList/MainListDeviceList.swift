//
//  MainListDeviceList.swift
//  MenuBarUSB
//
//  Created by rafael on 19/04/26.
//

import SwiftUI

struct MainListDeviceList: View {
    
    @EnvironmentObject var manager: USBDeviceManager
    @State private var isHoveringDeviceId: String = ""
    @State private var isHoveringPowerSupply: Bool = false
    @State private var devicesShowingMore: [USBDeviceWrapper] = []
    
    @Binding var deviceGroupExpanded: Bool
    @Binding var hubGroupExpanded: Bool
    
    @AS(Key.powerSourceInfo) private var powerSourceInfo = false
    @AS(Key.powerSupplyAsCharger) private var powerSupplyAsCharger = false
    @AS(Key.hideSecondaryInfo) private var hideSecondaryInfo = false
    @AS(Key.mouseHoverInfo) private var mouseHoverInfo = false
    @AS(Key.showPortMax) private var showPortMax = false
    @AS(Key.showScrollBar) private var showScrollBar = false
    @AS(Key.hideTechInfo) private var hideTechInfo = false
    @AS(Key.bigNames) private var bigNames = false
    
    private var deviceGroupDevices: [USBDeviceWrapper] {
        manager.devices.filter { !$0.item.isHub }
    }

    private var hubGroupDevices: [USBDeviceWrapper] {
        manager.devices.filter { $0.item.isHub }
    }
    
    private func devicesShowingMoreHas(_ device: borrowing USBDevice) -> Bool {
        for dev in devicesShowingMore {
            if dev.item.id == device.id {
                return true
            }
        }
        return false
    }
    
    private var showChargingStatus: Bool {
        return powerSourceInfo && manager.chargeConnected && manager.chargePercentage != nil
    }
    
    private var powerSupplyLabel: String {
        powerSupplyAsCharger ? "charger".localized : "power_supply".localized
    }
    
    private func showSecondaryInfo(for device: borrowing USBDevice, charger _: Bool = false) -> Bool {
        if devicesShowingMoreHas(device) { return true }
        if !hideSecondaryInfo { return true }
        return mouseHoverInfo && isHoveringDeviceId == device.uniqueId
    }

    private var showBatteryPercentage: Bool {
        if !hideSecondaryInfo { return true }
        return isHoveringPowerSupply
    }

    private func showTechInfo(for device: borrowing USBDevice) -> Bool {
        if devicesShowingMoreHas(device) { return true }
        if !hideTechInfo { return true }
        return mouseHoverInfo && isHoveringDeviceId == device.uniqueId
    }

    private func deviceTitleView(_ name: String?) -> some View {
        Text(name ?? "usb_device".localized)
            .font(.system(size: bigNames ? 17 : 14, weight: .semibold))
            .foregroundColor(.primary)
            .lineLimit(1)
    }

    private func deviceIcon(for device: borrowing USBDevice) -> String {
        if device.isHub {
            return "circle.grid.2x2"
        }
        if device.isExternalStorage == true {
            return "externaldrive"
        }
        if device.transport == .thunderbolt {
            return "bolt.horizontal.circle"
        }
        return "cable.connector"
    }

    private func deviceDetail(for device: borrowing USBDevice) -> String {
        var detail: [String] = []

        if showSecondaryInfo(for: device), let vendor = device.vendor, !vendor.isEmpty {
            detail.append(vendor)
        }

        if showTechInfo(for: device) {
            detail.append(device.connectionDescription)
        }

        return detail.joined(separator: " · ")
    }

    private func deviceSpeed(for device: borrowing USBDevice) -> String? {
        guard showTechInfo(for: device), showPortMax else { return nil }
        guard let speedMbps = device.speedMbps ?? device.portMaxSpeedMbps else { return nil }
        return Utils.USB.prettyMbps(speedMbps)
    }

    private func groupHeader(
        title: String,
        icon: String,
        count: Int,
        isExpanded: Binding<Bool>
    ) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                isExpanded.wrappedValue.toggle()
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isExpanded.wrappedValue ? "chevron.down" : "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .frame(width: 12)

                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)

                Text(title)
                    .font(.subheadline.weight(.semibold))

                Spacer()

                Text("\(count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(.primary.opacity(0.07), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func connectedDeviceRows(
        _ devices: [USBDeviceWrapper]
    ) -> some View {
        ForEach(devices) { device in
            connectedDeviceRow(device)
        }
    }

    @ViewBuilder
    private func connectedDeviceRow(_ device: USBDeviceWrapper) -> some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(.primary.opacity(0.08))
                    .frame(width: 32, height: 32)
                Image(systemName: deviceIcon(for: device.item))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 3) {
                deviceTitleView(device.item.name)

                let detail = deviceDetail(for: device.item)
                if !detail.isEmpty {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 12)

            if let speed = deviceSpeed(for: device.item) {
                Text(speed)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            isHoveringDeviceId == device.item.uniqueId
                ? Color.primary.opacity(0.07)
                : Color.clear,
            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .onHover { hovering in
            if hovering {
                isHoveringDeviceId = device.item.uniqueId
            } else if isHoveringDeviceId == device.item.uniqueId {
                isHoveringDeviceId = ""
            }
        }
        .animation(.easeInOut(duration: 0.12), value: isHoveringDeviceId)
        .animation(.easeInOut(duration: 0.12), value: showSecondaryInfo(for: device.item))
        .animation(.easeInOut(duration: 0.12), value: showTechInfo(for: device.item))
        .contextMenu {
            MainListDeviceListContextMenuDevice(
                devicesShowingMore: $devicesShowingMore,
                device: device,
            )
        }

        Divider()
            .padding(.leading, 42)
    }
    
    
    var body: some View {
        if showChargingStatus {
            HStack {
                Group {
                    Text(powerSupplyLabel)
                        .font(.system(size: bigNames ? 18 : 12, weight: .semibold))
                    Spacer()
                    if showBatteryPercentage {
                        Image(systemName: manager.chargePercentage == 100 ? "battery.100percent" : "bolt.fill")
                            .font(.system(size: 10))
                        Text("\(manager.chargePercentage ?? 0)%")
                            .font(.system(size: 12, weight: .semibold))
                    }
                }
                .foregroundColor(.primary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(.primary.opacity(0.07), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .onHover { hovering in
                if mouseHoverInfo {
                    if hovering {
                        isHoveringPowerSupply = true
                    } else if isHoveringPowerSupply {
                        isHoveringPowerSupply = false
                    }
                }
            }
            .contextMenu {
                MainListDeviceListContextMenuCharger()
            }

            Divider()
        }
        ScrollView(showsIndicators: showScrollBar) {
            LazyVStack(alignment: .leading, spacing: 4) {
                groupHeader(
                    title: "usb_devices".localized,
                    icon: "desktopcomputer",
                    count: deviceGroupDevices.count,
                    isExpanded: $deviceGroupExpanded
                )

                if deviceGroupExpanded {
                    connectedDeviceRows(deviceGroupDevices)
                }

                groupHeader(
                    title: "usb_hubs".localized,
                    icon: "circle.grid.2x2",
                    count: hubGroupDevices.count,
                    isExpanded: $hubGroupExpanded
                )

                if hubGroupExpanded {
                    connectedDeviceRows(hubGroupDevices)
                }
            }
            .padding(.horizontal, 2)
        }
        .frame(maxHeight: 1000)
    }
}
