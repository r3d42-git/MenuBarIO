//
//  SettingsBottomBar.swift
//  MenuBarUSB
//
//  Created by rafael on 17/04/26.
//

import SwiftUI

struct SettingsBottomBar: View {
    
    @Binding var currentWindow: AppWindow
    
    var body: some View {
        HStack {
            Spacer()
            
            Button(action: {
                currentWindow = .devices
            }) {
                Label("back", systemImage: "arrow.uturn.backward")
            }
        }
    }
}
