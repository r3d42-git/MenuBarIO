//
//  SettingsView.swift
//  MenuBarUSB
//
//  Created by Rafael Neuwirth on 28/08/25.
//

import SwiftUI

struct SettingsView: View {
    @Binding var currentWindow: AppWindow
    @State private var activeRowID: UUID? = nil
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

    private func section<Content: View>(
        _ category: SettingsCategory,
        label: LocalizedStringKey,
        image: String,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        let isExpanded = expandedBinding(for: category)

        return VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.wrappedValue.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .rotationEffect(.degrees(isExpanded.wrappedValue ? 90 : 0))
                        .frame(width: 12)

                    Image(image)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)

                    Text(label)
                        .font(.headline)

                    Spacer()
                }
                .contentShape(Rectangle())
                .padding(.horizontal, 12)
                .frame(minHeight: 46)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)

            if isExpanded.wrappedValue {
                content()
                    .padding(.top, 8)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
            }
        }
        .background(Color.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 2) {
                Text("MenuBarUSB-TB")
                    .font(.title2)
                    .bold()
                Text(
                    String(
                        format: "version".localized,
                        Utils.App.appVersion
                    )
                )
                .font(.footnote)
                .foregroundColor(.secondary)
            }

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    section(.system, label: "system_category", image: "settings_general") {
                        SettingsSystemCategory(activeRowID: $activeRowID)
                    }

                    section(.icon, label: "icon_category", image: "settings_icon") {
                        SettingsIconCategory(activeRowID: $activeRowID)
                    }

                    section(.interface, label: "ui_category", image: "settings_interface") {
                        SettingsInterfaceCategory(activeRowID: $activeRowID)
                    }

                    section(.usb, label: "usb_category", image: "settings_info") {
                        SettingsUSBCategory(activeRowID: $activeRowID)
                    }

                    section(.ethernet, label: "ethernet_category", image: "settings_ethernet") {
                        SettingsEthernetCategory(activeRowID: $activeRowID)
                    }

                    section(.others, label: "others_category", image: "settings_others") {
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
