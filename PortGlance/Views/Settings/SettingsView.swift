//
//  SettingsView.swift
//  PortGlance
//
//  Created by Rafael Neuwirth on 28/08/25.
//

import SwiftUI

struct SettingsView: View {
    @Binding var currentWindow: AppWindow
    @State private var activeRowID: String?
    @State private var expandedCategories: Set<SettingsCategory> = [.system]

    @AS(Key.reduceTransparency) private var reduceTransparency = false
    @AS(Key.windowWidth) private var windowWidth: WindowWidth = .normal

    private func expandedBinding(for category: SettingsCategory) -> Binding<Bool> {
        Binding(
            get: {
                expandedCategories.contains(category)
            },
            set: { isExpanded in
                if isExpanded {
                    expandedCategories.insert(category)
                } else {
                    expandedCategories.remove(category)
                }
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 2) {
                Text("PortGlance")
                    .font(.title2)
                    .bold()
                Text(
                    String(
                        format: "version".localized,
                        ApplicationActions.version
                    )
                )
                .font(.footnote)
                .foregroundColor(.secondary)
            }

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    CollapsibleSettingsSection(
                        label: "system_category",
                        systemImage: "gearshape",
                        isExpanded: expandedBinding(for: .system)
                    ) {
                        SettingsSystemCategory(activeRowID: $activeRowID)
                    }

                    CollapsibleSettingsSection(
                        label: "icon_category",
                        systemImage: "menubar.rectangle",
                        isExpanded: expandedBinding(for: .icon)
                    ) {
                        SettingsIconCategory(activeRowID: $activeRowID)
                    }

                    CollapsibleSettingsSection(
                        label: "ui_category",
                        systemImage: "rectangle.3.group",
                        isExpanded: expandedBinding(for: .interface)
                    ) {
                        SettingsInterfaceCategory(activeRowID: $activeRowID)
                    }

                    CollapsibleSettingsSection(
                        label: "usb_category",
                        systemImage: "cable.connector",
                        isExpanded: expandedBinding(for: .usb)
                    ) {
                        SettingsUSBCategory(activeRowID: $activeRowID)
                    }

                    CollapsibleSettingsSection(
                        label: "ethernet_category",
                        systemImage: "network",
                        isExpanded: expandedBinding(for: .ethernet)
                    ) {
                        SettingsEthernetCategory(activeRowID: $activeRowID)
                    }

                    CollapsibleSettingsSection(
                        label: "others_category",
                        systemImage: "ellipsis.circle",
                        isExpanded: expandedBinding(for: .others)
                    ) {
                        SettingsOthersCategory(activeRowID: $activeRowID)
                    }

                }
                .padding(.horizontal, 1)
            }

            SettingsBottomBar(currentWindow: $currentWindow)
        }
        .padding(10)
        .frame(minWidth: CGFloat(windowWidth.rawValue), minHeight: 600)
        .appBackground(reduceTransparency)
    }
}
