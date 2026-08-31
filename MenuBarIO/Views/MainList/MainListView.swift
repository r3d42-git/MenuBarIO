//
//  MainListView.swift
//  MenuBarIO
//
//  Created by Rafael Neuwirth on 28/08/25.
//

import SwiftUI

struct MainListView: View {

    @EnvironmentObject var manager: USBDeviceManager
    @EnvironmentObject var bluetoothManager: BluetoothDeviceManager

    @Binding var currentWindow: AppWindow

    @AS(Key.windowWidth) private var windowWidth: WindowWidth = .normal
    @AS(Key.deviceGroupExpanded) private var deviceGroupExpanded = true
    @AS(Key.hubGroupExpanded) private var hubGroupExpanded = false
    @AS(Key.internalGroupExpanded) private var internalGroupExpanded = false
    @AS(Key.bluetoothGroupExpanded) private var bluetoothGroupExpanded = false
    @AS(Key.thunderboltPortGroupExpanded) private var thunderboltPortGroupExpanded = false
    @AS(Key.externalThunderboltPortGroupExpanded) private var externalThunderboltPortGroupExpanded = false

    private var isTrulyEmpty: Bool {
        manager.devices.isEmpty
            && bluetoothManager.devices.isEmpty
            && manager.thunderboltPorts.isEmpty
    }

    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(.tint.opacity(0.16))
                    .frame(width: 30, height: 30)
                Image(systemName: "cable.connector")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.tint)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("MenuBarIO")
                    .font(.headline)
                Text("connected_devices")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 6) {
                Circle()
                    .fill(.blue)
                    .frame(width: 6, height: 6)
                Text("\(manager.count + bluetoothManager.count)")
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(.primary.opacity(0.07), in: Capsule())
            .accessibilityLabel(Text("\(manager.count + bluetoothManager.count) \("connected_devices".localized)"))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            VStack(alignment: .leading, spacing: 6) {
                if isTrulyEmpty {
                    MainListEmptyListMessage()
                } else {
                    MainListDeviceList(
                        deviceGroupExpanded: $deviceGroupExpanded,
                        hubGroupExpanded: $hubGroupExpanded,
                        internalGroupExpanded: $internalGroupExpanded,
                        bluetoothGroupExpanded: $bluetoothGroupExpanded,
                        thunderboltPortGroupExpanded: $thunderboltPortGroupExpanded,
                        externalThunderboltPortGroupExpanded: $externalThunderboltPortGroupExpanded
                    )
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 7)

            Divider()

            MainListBottomBar(currentWindow: $currentWindow)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        }
        .frame(width: CGFloat(windowWidth.rawValue))
    }
}
