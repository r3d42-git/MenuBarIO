//
//  MainListView.swift
//  MenuBarUSB
//
//  Created by Rafael Neuwirth on 28/08/25.
//

import SwiftUI

struct MainListView: View {
    
    @EnvironmentObject var manager: USBDeviceManager
    
    @Binding var currentWindow: AppWindow
    
    @AS(Key.longList) private var longList = false
    @AS(Key.hideTechInfo) private var hideTechInfo = false
    @AS(Key.windowWidth) private var windowWidth: WindowWidth = .normal
    @AS(Key.deviceGroupExpanded) private var deviceGroupExpanded = true
    @AS(Key.hubGroupExpanded) private var hubGroupExpanded = false
    
    private var windowHeight: CGFloat? {
        if isTrulyEmpty {
            return nil
        }
        let baseValue: CGFloat = 120
        let rowHeight: CGFloat = hideTechInfo ? 48 : 68

        // The header and bottom bar live outside this scrollable device area.
        // Device rows stay comfortably readable until scrolling becomes useful.
        let total = manager.devices.count

        let sum: CGFloat = baseValue + (CGFloat(total) * rowHeight)
        var max: CGFloat = 420
        if longList {
            max = 640
        }
        return sum >= max ? max : sum
    }
    
    private var isTrulyEmpty: Bool {
        manager.devices.isEmpty
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
                Text("MenuBarUSB-TB")
                    .font(.headline)
                Text("usb_devices")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 6) {
                Circle()
                    .fill(.blue)
                    .frame(width: 6, height: 6)
                Text("\(manager.devices.count)")
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(.primary.opacity(0.07), in: Capsule())
            .accessibilityLabel(Text("\(manager.devices.count) \("usb_devices".localized)"))
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
                        hubGroupExpanded: $hubGroupExpanded
                    )
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
            .frame(height: windowHeight)

            Divider()

            MainListBottomBar(currentWindow: $currentWindow)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        }
        .frame(width: CGFloat(windowWidth.rawValue))
        .background(.regularMaterial)
    }
}
