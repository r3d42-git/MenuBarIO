//
//  LegacySettingsHorizontalTopBar.swift
//  MenuBarUSB
//
//  Created by rafael on 17/04/26.
//

import SwiftUI

struct LegacySettingsHorizontalTopBar: View {
    
    var body: some View {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("MenuBarUSB-TB")
                    .font(.title2)
                    .bold()
                Text(
                    String(
                        format: NSLocalizedString("version", comment: "APP VERSION"),
                        "\(Utils.App.appVersion) - OS \(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
                    )
                )
                .font(.footnote)
                .foregroundColor(.secondary)
            }
            Spacer()

        }
    }
}
