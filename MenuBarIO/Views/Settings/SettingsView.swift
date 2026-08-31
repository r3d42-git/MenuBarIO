//
//  SettingsView.swift
//  MenuBarIO
//
//  Created by Rafael Neuwirth on 28/08/25.
//

import SwiftUI

struct SettingsView: View {
    @Binding var currentWindow: AppWindow

    @AS(Key.windowWidth) private var windowWidth: WindowWidth = .normal

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 2) {
                Text("MenuBarIO")
                    .font(.title2)
                    .bold()
                Text("product_subtitle")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(
                    String(
                        format: "version".localized,
                        ApplicationActions.version
                    )
                )
                .font(.footnote)
                .foregroundColor(.secondary)
            }

            ContentFittingScrollView {
                SettingsOptions()
                    .padding(.horizontal, 1)
            }

            SettingsBottomBar(currentWindow: $currentWindow)
        }
        .padding(10)
        .frame(minWidth: CGFloat(windowWidth.rawValue))
    }
}
