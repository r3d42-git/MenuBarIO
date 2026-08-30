//
//  MainListBottomBar.swift
//  PortGlance
//
//  Created by rafael on 19/04/26.
//

import SwiftUI

struct MainListBottomBar: View {

    @EnvironmentObject var manager: USBDeviceManager
    @Environment(\.openWindow) private var openWindow

    @Binding var currentWindow: AppWindow

    @AS(Key.profilerButton) private var profilerButton = false

    private func goToSettings() {
        if #available(macOS 15.0, *) {
            currentWindow = .settings
        } else {
            openWindow(id: "legacy_settings")
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            if profilerButton {
                Button {
                    SystemActions.openSystemInformation()
                } label: {
                    Image(systemName: "info.circle")
                        .help("open_profiler")
                        .contextMenu {
                            MainListBottomBarContextMenuProfiler()
                        }
                }
                .buttonStyle(.plain)
            }

            Button {
                goToSettings()
            } label: {
                Label("settings", systemImage: "gearshape")
                    .font(.subheadline.weight(.medium))
            }
            .buttonStyle(.plain)

            Spacer()

            ControlGroup {
                Button {
                    manager.refresh()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help("refresh")

                Button {
                    ApplicationActions.exit()
                } label: {
                    Image(systemName: "power")
                }
                .help("exit")
                .contextMenu {
                    MainListBottomBarContextMenuExit()
                }
            }
            .controlGroupStyle(.navigation)
        }
    }
}
