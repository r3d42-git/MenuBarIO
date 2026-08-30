//
//  LegacySettingsHorizontalTopBar.swift
//  PortGlance
//
//  Created by rafael on 17/04/26.
//

import SwiftUI

struct LegacySettingsHorizontalTopBar: View {

    var body: some View {
        let version = ProcessInfo.processInfo.operatingSystemVersion

        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("PortGlance")
                    .font(.title2)
                    .bold()
                Text(
                    String(
                        format: "version".localized,
                        "\(ApplicationActions.version) - OS \(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
                    )
                )
                .font(.footnote)
                .foregroundColor(.secondary)
            }
            Spacer()

        }
    }
}
