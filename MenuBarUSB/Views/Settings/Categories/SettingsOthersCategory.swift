//
//  SettingsOthersCategory.swift
//  MenuBarUSB
//
//  Created by rafael on 17/04/26.
//

import SwiftUI

struct SettingsOthersCategory: View {
    
    @Binding var activeRowID: UUID?

    @AS(Key.profilerButton) private var profilerButton = false
    @AS(Key.windowWidth) private var windowWidth: WindowWidth = .normal
    
    private func setWindowWidth(increase: Bool) {
        let order: [WindowWidth] = [.normal, .big, .veryBig, .huge]
        guard let index = order.firstIndex(of: windowWidth) else { return }
        
        let nextIndex = index + (increase ? 1 : -1)
        if order.indices.contains(nextIndex) {
            windowWidth = order[nextIndex]
        }
    }
    
    private var windowWidthLabel: String {
        var width = ""
        switch windowWidth {
        case .normal:
            width = "window_size_normal"
        case .big:
            width = "window_size_big"
        case .veryBig:
            width = "window_size_verybig"
        case .huge:
            width = "window_size_huge"
        }
        return width.localized
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            ToggleRow(
                label: "profiler_shortcut",
                description: "profiler_shortcut_description",
                binding: $profilerButton,
                activeRowID: $activeRowID,
                incompatibilities: nil,
                onToggle: { _ in }
            )
            
            HStack {
                
                Text("window_width")
                
                Button {
                    setWindowWidth(increase: false)
                } label: {
                    Image(systemName: "minus")
                        .frame(width: 14, height: 14)
                }
                .disabled(windowWidth == .normal)
                
                Button {
                    setWindowWidth(increase: true)
                } label: {
                    Image(systemName: "plus")
                        .frame(width: 14, height: 14)
                }
                .disabled(windowWidth == .huge)
                
                Text(windowWidthLabel)
                    .font(.footnote)
            }
            .padding(.vertical, 7)
        }
    }
}
