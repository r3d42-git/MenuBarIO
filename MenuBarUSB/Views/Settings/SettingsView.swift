//
//  SettingsView.swift
//  MenuBarUSB
//
//  Created by Rafael Neuwirth on 28/08/25.
//

import AppKit
import ServiceManagement
import SwiftUI

struct SettingsView: View {
    
    @Environment(\.openURL) var openURL
    @Environment(\.openWindow) private var openWindow
    @Binding var currentWindow: AppWindow
    
    @State private var activeRowID: UUID? = nil
    
    @State private var resetSettingsPress: Int = 0
    
    @AS(Key.settingsCategory) private var category: SettingsCategory = .system
    @AS(Key.reduceTransparency) private var reduceTransparency = false
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("MenuBarUSB-TB")
                        .font(.title2)
                        .bold()
                    Text(
                        String(
                            format: NSLocalizedString("version", comment: "APP VERSION"),
                            Utils.App.appVersion
                        )
                    )
                    .font(.footnote)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                SettingsHorizontalTopBar()
            }
            
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Spacer()
                    CategoryButton(category: .system, label: "system_category", image: "settings_general", binding: $category)
                    CategoryButton(category: .icon, label: "icon_category", image: "settings_icon", binding: $category)
                    CategoryButton(category: .interface, label: "ui_category", image: "settings_interface", binding: $category)
                    CategoryButton(category: .usb, label: "usb_category", image: "settings_info", binding: $category)
                    CategoryButton(category: .contextMenu, label: "context_menu_category", image: "settings_contextmenu", binding: $category)
                    CategoryButton(category: .ethernet, label: "ethernet_category", image: "settings_ethernet", binding: $category)
                    CategoryButton(category: .heritage, label: "heritage_category", image: "settings_heritage", binding: $category)
                    // CategoryButton(category: .automation, label: "automation_category", image: "settings_automation", binding: $category)
                    CategoryButton(category: .others, label: "others_category", image: "settings_others", binding: $category) {
                        resetSettingsPress = 0
                    }
                    CategoryButton(category: .storage, label: "storage_category", image: "settings_storage", binding: $category)
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(5)
                
                Text(LocalizedStringKey(category.rawValue))
                    .font(.title)
                    .padding(.vertical, 10)
                
                if category == .system {
                    SettingsSystemCategory(activeRowID: $activeRowID)
                }
                
                if category == .icon {
                    SettingsIconCategory(activeRowID: $activeRowID)
                }
                
                if category == .interface {
                    SettingsInterfaceCategory(activeRowID: $activeRowID)
                }
                
                if category == .usb {
                    SettingsUSBCategory(currentWindow: $currentWindow, activeRowID: $activeRowID)
                }
                
                if category == .contextMenu {
                    SettingsContextMenuCategory(activeRowID: $activeRowID)
                }
                
                if category == .ethernet {
                    SettingsEthernetCategory(activeRowID: $activeRowID)
                }
                
                if category == .heritage {
                    SettingsHeritageCategory(currentWindow: $currentWindow, activeRowID: $activeRowID)
                }
                
                if category == .others {
                    SettingsOthersCategory(activeRowID: $activeRowID)
                }
                
                if category == .storage {
                    SettingsStorageCategory()
                }
            }
            
            Spacer()
            
            SettingsBottomBar(currentWindow: $currentWindow, resetSettingsPress: $resetSettingsPress)
        }
        .padding(10)
        .frame(minWidth: WindowWidth.value, minHeight: 600)
        .appBackground(reduceTransparency)
    }
}
