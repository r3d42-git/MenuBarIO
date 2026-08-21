//
//  MainListView.swift
//  MenuBarUSB
//
//  Created by Rafael Neuwirth on 28/08/25.
//

import SwiftUI

struct MainListView: View {
    
    @EnvironmentObject var manager: USBDeviceManager
    
    @State private var isRenamingDeviceId: String = ""
    @Binding var currentWindow: AppWindow
    
    @AS(Key.longList) private var longList = false
    @AS(Key.hideTechInfo) private var hideTechInfo = false
    @AS(Key.storeDevices) private var storeDevices = false
    @AS(Key.listToolBar) private var listToolBar = false
    @AS(Key.windowWidth) private var windowWidth: WindowWidth = .normal
    @AS(Key.deviceGroupExpanded) private var deviceGroupExpanded = true
    @AS(Key.hubGroupExpanded) private var hubGroupExpanded = false
    
    private var windowHeight: CGFloat? {
        if isTrulyEmpty {
            return nil
        }
        let baseValue: CGFloat = 200
        var multiplier: CGFloat = 26
        if longList {
            multiplier += 15
        }
        if hideTechInfo {
            multiplier -= 12
        }
        
        // The status counter excludes hubs, but popup sizing must account for all
        // currently visible entries (including the expandable hub group).
        var total = manager.devices.count
        if storeDevices {
            total += CSM.Stored.filteredDevices(manager.devices).count
        }
        
        var sum: CGFloat = baseValue + (CGFloat(total) * multiplier)
        var max: CGFloat = 380
        if longList {
            max += 315
        }
        if listToolBar {
            max += 40
            sum += 40
        }
        return sum >= max ? max : sum
    }
    
    private var isRenaming: Bool {
        return isRenamingDeviceId != ""
    }
    
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
    
    private var showToolbar: Bool {
        return listToolBar && !isTrulyEmpty
    }
    
    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 6) {
                if showToolbar {
                    MainListToolbar()
                }
                
                if isTrulyEmpty {
                    MainListEmptyListMessage()
                } else {
                    MainListDeviceList(
                        isRenamingDeviceId: $isRenamingDeviceId,
                        deviceGroupExpanded: $deviceGroupExpanded,
                        hubGroupExpanded: $hubGroupExpanded
                    )
                }
            }
            .padding(3)
            .frame(width: WindowWidth.value, height: windowHeight)
            
            MainListBottomBar(currentWindow: $currentWindow)
                .padding(10)
                .disabled(isRenaming)
        }
    }
}
