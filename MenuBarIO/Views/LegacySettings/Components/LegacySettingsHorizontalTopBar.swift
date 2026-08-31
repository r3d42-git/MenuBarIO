//
//  LegacySettingsHorizontalTopBar.swift
//  MenuBarIO
//
//  Created by rafael on 17/04/26.
//

import SwiftUI

struct LegacySettingsHorizontalTopBar: View {

    var body: some View {
        let version = ProcessInfo.processInfo.operatingSystemVersion

        HStack {
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
