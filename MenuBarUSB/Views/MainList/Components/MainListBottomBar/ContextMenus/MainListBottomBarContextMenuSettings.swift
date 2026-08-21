//
//  MainListBottomBarContextMenuSettings.swift
//  MenuBarUSB
//
//  Created by rafael on 25/04/26.
//

import SwiftUI

struct MainListBottomBarContextMenuSettings: View {
    
    @EnvironmentObject var manager: USBDeviceManager
    @Environment(\.openWindow) private var openWindow
    
    @AS(Key.listToolBar) private var listToolBar = false
    @AS(Key.storeDevices) private var storeDevices = false
    
    private var isTrulyEmpty: Bool {
        let hasConnectedDevices = !manager.devices.isEmpty
        let storedCount: Int = CSM.Stored.filteredDevices(manager.devices).count

        if !hasConnectedDevices && storeDevices == false {
            return true
        }

        if !hasConnectedDevices && storedCount == 0 {
            return true
        }

        return false
    }
    
    var body: some View {
        Button {
            listToolBar.toggle()
        } label: {
            Label(listToolBar ? "hide_toolbar" : "show_toolbar", systemImage: "menubar.arrow.up.rectangle")
        }
        .disabled(isTrulyEmpty)
        Divider()
        Button {
            Utils.System.openSysInfo()
        } label: {
            Label("open_profiler", systemImage: "info.circle")
        }
        if #available(macOS 15.0, *) {
            Button {
                openWindow(id: "legacy_settings")
            } label: {
                Label("open_legacy_settings", systemImage: "gearshape")
            }
        }

    }
}
