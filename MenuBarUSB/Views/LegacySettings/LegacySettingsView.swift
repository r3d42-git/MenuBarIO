//
//  LegacySettingsView.swift
//  MenuBarUSB
//
//  Created by Rafael Neuwirth on 28/08/25.
//

import AppKit
import ServiceManagement
import SwiftUI

struct LegacySettingsView: View {
    
    @Environment(\.openWindow) private var openWindow
    @EnvironmentObject var manager: USBDeviceManager

    @State private var showMessage: Bool = false

    @State private var activeRowID: UUID? = nil

    @State private var showSystemOptions = true
    @State private var showInterfaceOptions = false
    @State private var showUsbOptions = false
    @State private var showOthersOptions = false

    private func section<Content: View>(
        _ label: LocalizedStringKey,
        image: String,
        isExpanded: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        DisclosureGroup(isExpanded: isExpanded) {
            content()
                .padding(.top, 8)
                .padding(.leading, 2)
        } label: {
            Label(label, systemImage: image)
                .font(.headline)
        }
        .padding(10)
        .background(Color.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    }

    var body: some View {

        ZStack {
            
            Image(systemName: "gear")
                .font(.system(size: 350))
                .opacity(0.03)
            
            VStack(alignment: .leading, spacing: 20) {
                LegacySettingsHorizontalTopBar()

                Divider()

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        section(
                            "system_category",
                            image: "gearshape",
                            isExpanded: $showSystemOptions
                        ) {
                            LegacySettingsSystemCategory(activeRowID: $activeRowID)
                        }

                        section(
                            "ui_category",
                            image: "rectangle.3.group",
                            isExpanded: $showInterfaceOptions
                        ) {
                            LegacySettingsInterfaceCategory(activeRowID: $activeRowID)
                        }

                        section(
                            "usb_category",
                            image: "cable.connector",
                            isExpanded: $showUsbOptions
                        ) {
                            LegacySettingsUSBCategory(activeRowID: $activeRowID)
                        }

                        section(
                            "others_category",
                            image: "ellipsis.circle",
                            isExpanded: $showOthersOptions
                        ) {
                            LegacySettingsOthersCategory(activeRowID: $activeRowID)
                        }

                    }
                }

                LegacySettingsHorizontalBottomBar()
            }
        }
        .padding(10)
        .frame(minWidth: 700, minHeight: 580)
    }
}
