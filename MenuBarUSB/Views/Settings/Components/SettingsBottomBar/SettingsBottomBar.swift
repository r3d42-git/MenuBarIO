//
//  SettingsBottomBar.swift
//  MenuBarUSB
//
//  Created by rafael on 17/04/26.
//

import SwiftUI

struct SettingsBottomBar: View {
    
    @Binding var currentWindow: AppWindow
    @Binding var resetSettingsPress: Int
    
    @AS(Key.settingsCategory) private var category: SettingsCategory = .system
    
    private func resetAppSettings() {
        Utils.App.deleteStorageData()
        resetSettingsPress = 0
        Utils.System.playSystemSound(named: "Bottle")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            Utils.App.restart()
        }
    }
    
    var body: some View {
        HStack {
            if category == .storage {
                Button("restore_default_settings") {
                    resetSettingsPress += 1
                    if resetSettingsPress == 5 {
                        resetAppSettings()
                    }
                }
                
                if resetSettingsPress > 0 {
                    Text("(\(resetSettingsPress)/5)")
                        .font(.footnote)
                }
            }
            
            Spacer()
            
            Button(action: {
                currentWindow = .devices
            }) {
                Label("back", systemImage: "arrow.uturn.backward")
            }
        }
    }
}
