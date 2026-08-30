//
//  LegacySettingsHorizontalBottomBar.swift
//  PortGlance
//
//  Created by rafael on 17/04/26.
//

import SwiftUI

struct LegacySettingsHorizontalBottomBar: View {

    @State private var showDescription = false

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        HStack {
            ZStack(alignment: .bottomLeading) {
                if showDescription {
                    Text("legacy_settings_description")
                        .font(.caption)
                        .offset(y: -40)
                }

                Button {
                    showDescription.toggle()
                } label: {
                    Image(systemName: "info.circle")
                        .font(.title2)
                        .foregroundColor(.primary)
                        .padding(4)
                }
                .buttonStyle(.plain)
            }
            Spacer()
            Button("close") {
                dismiss()
            }
        }
    }
}
