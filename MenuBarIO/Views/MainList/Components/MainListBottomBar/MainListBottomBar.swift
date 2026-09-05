//
//  MainListBottomBar.swift
//  MenuBarIO
//
//  Created by rafael on 19/04/26.
//

import SwiftUI

struct MainListBottomBar: View {

    @EnvironmentObject var manager: USBDeviceManager
    @EnvironmentObject private var bluetoothManager: BluetoothDeviceManager
    @EnvironmentObject private var refreshCoordinator: HardwareRefreshCoordinator
    @Environment(\.openWindow) private var openWindow

    @Binding var currentWindow: AppWindow
    @State private var exportFeedbackToken: UUID?

    private var isRefreshing: Bool {
        manager.sourceStatus.isRefreshing || bluetoothManager.sourceStatus.isRefreshing
    }

    private func goToSettings() {
        if #available(macOS 15.0, *) {
            currentWindow = .settings
        } else {
            openWindow(id: "legacy_settings")
        }
    }

    private func exportReport() {
        let generatedAt = Date()
        let powerSource: DiagnosticPowerSource? =
            manager.chargeConnected
            ? DiagnosticPowerSource(
                chargePercentage: manager.chargePercentage,
                isCharging: manager.batteryIsCharging,
                chargingPowerWatts: manager.chargingPowerWatts,
                adapterPowerWatts: manager.adapterPowerWatts
            )
            : nil
        let snapshot = DiagnosticOverviewSnapshot(
            appVersion: ApplicationActions.version,
            appBuild: ApplicationActions.build,
            generatedAt: generatedAt,
            operatingSystemVersion: ProcessInfo.processInfo.operatingSystemVersionString,
            modelIdentifier: SystemActions.modelIdentifier,
            devices: manager.devices,
            thunderboltPorts: manager.thunderboltPorts,
            externalThunderboltPortGroups: manager.externalThunderboltPortGroups,
            bluetoothDevices: bluetoothManager.devices,
            deviceSourceStatus: manager.sourceStatus,
            bluetoothSourceStatus: bluetoothManager.sourceStatus,
            powerSource: powerSource,
            powerSourceConnectorNumber: manager.powerSourceConnectorNumber
        )

        let markdown = DiagnosticReportBuilder().overview(snapshot)
        let suggestedFilename = MarkdownReportExporter.suggestedFilename(generatedAt: generatedAt)
        guard MarkdownReportExporter.export(markdown, suggestedFilename: suggestedFilename) != nil else {
            return
        }

        SystemActions.announceForAccessibility("report_saved".localized)

        let token = UUID()
        exportFeedbackToken = token
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if exportFeedbackToken == token {
                exportFeedbackToken = nil
            }
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Button {
                SystemActions.openSystemInformation()
            } label: {
                Image(systemName: "info.circle")
                    .help("open_profiler")
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("open_profiler"))

            Button(action: exportReport) {
                Image(systemName: exportFeedbackToken == nil ? "square.and.arrow.down" : "checkmark")
                    .help(exportFeedbackToken == nil ? "export_report" : "report_saved")
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(exportFeedbackToken == nil ? "export_report" : "report_saved"))

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
                    refreshCoordinator.refresh()
                } label: {
                    if isRefreshing {
                        ProgressView()
                            .controlSize(.small)
                            .frame(width: 14, height: 14)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .help("refresh")
                .accessibilityLabel(Text("refresh"))
                .keyboardShortcut("r")
                .disabled(isRefreshing)

                Button {
                    ApplicationActions.exit()
                } label: {
                    Image(systemName: "power")
                }
                .help("exit")
                .accessibilityLabel(Text("exit"))
                .contextMenu {
                    MainListBottomBarContextMenuExit()
                }
            }
            .controlGroupStyle(.navigation)
        }
    }
}
