//
//  SettingsIconCategory.swift
//  PortGlance
//
//  Created by rafael on 17/04/26.
//

import SwiftUI

struct SettingsIconCategory: View {

    @EnvironmentObject var manager: USBDeviceManager

    @Binding var activeRowID: String?

    @AS(Key.hideMenubarIcon) private var hideMenubarIcon = false
    @AS(Key.hideCount) private var hideCount = false
    @AS(Key.macBarIcon) private var macBarIcon: String = "cable.connector"
    @AS(Key.numberRepresentation) private var numberRepresentation: NumberRepresentation = .base10

    private let icons: [String] = [
        "cable.connector",
        "app.connected.to.app.below.fill",
        "rectangle.connected.to.line.below",
        "mediastick",
        "sdcard",
        "sdcard.fill",
        "bolt.ring.closed",
        "bolt",
        "bolt.fill",
        "wrench.and.screwdriver",
        "wrench.and.screwdriver.fill",
        "externaldrive.connected.to.line.below",
        "externaldrive.connected.to.line.below.fill",
        "powerplug.portrait",
        "powerplug.portrait.fill",
        "powercord",
        "powercord.fill",
        "cat.fill",
        "dog.fill",
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            MenuBarVisibilitySettings(activeRowID: $activeRowID)

            HStack(spacing: 12) {
                if !hideMenubarIcon {
                    Text("icon")
                    Image(systemName: macBarIcon)
                }
                if !hideCount {
                    Text("numerical_representation")
                    Text(DeviceCountFormatter.string(for: manager.count, representation: numberRepresentation))
                        .fontWeight(.bold)
                }
                Spacer()
            }

            HStack {
                Menu {
                    ForEach(icons, id: \.self) { item in
                        Button {
                            macBarIcon = item
                        } label: {
                            HStack {
                                Image(systemName: item)
                                if !hideCount {
                                    Text(
                                        DeviceCountFormatter.string(
                                            for: manager.count,
                                            representation: numberRepresentation
                                        )
                                    )
                                }
                            }
                        }
                    }
                } label: {
                    Label("icon", systemImage: macBarIcon)
                        .background(
                            RoundedRectangle(cornerRadius: 6).stroke(
                                Color.gray.opacity(0.3)))
                }
                .disabled(hideMenubarIcon)

                Menu(LocalizedStringKey(numberRepresentation.rawValue)) {
                    ForEach(NumberRepresentation.allCases) { item in
                        Button {
                            numberRepresentation = item
                        } label: {
                            Text(LocalizedStringKey(item.rawValue))
                        }
                    }
                }
                .disabled(hideCount)
                .help("numerical_representation")
            }

        }
    }
}
