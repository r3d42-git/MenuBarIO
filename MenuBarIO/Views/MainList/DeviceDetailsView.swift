import SwiftUI

struct DeviceDetailsView: View {
    @EnvironmentObject private var manager: USBDeviceManager
    @EnvironmentObject private var bluetoothManager: BluetoothDeviceManager
    @EnvironmentObject private var refreshCoordinator: HardwareRefreshCoordinator
    let selection: DeviceDetailSelection
    let onBack: () -> Void
    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button(action: onBack) { Label("back", systemImage: "chevron.left") }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Text("device_details").font(.headline)
            }
            .buttonStyle(.plain)
            .padding(14)
            Divider()
            HardwareStatusRow()
            if let content {
                ContentFittingScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(content.title)
                            .font(.title3.weight(.semibold))
                            .fixedSize(horizontal: false, vertical: true)
                            .textSelection(.enabled)
                        fields(content.fields)
                        if !content.technicalFields.isEmpty {
                            DisclosureGroup("technical_identifiers") {
                                fields(content.technicalFields).padding(.top, 8)
                            }
                        }
                        ForEach(content.notes, id: \.self) { key in
                            Text(key.localized)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(14)
                }
                Divider()
                HStack {
                    Button {
                        SystemActions.copyToClipboard(content.copyText)
                        copied = true
                        SystemActions.announceForAccessibility("details_copied".localized)
                    } label: {
                        Label(
                            copied ? "details_copied" : "copy", systemImage: copied ? "checkmark" : "square.on.square")
                    }
                    .keyboardShortcut("c")
                    Spacer()
                    refreshButton
                }
                .padding(14)
            } else {
                Text("device_no_longer_available")
                    .foregroundStyle(.secondary)
                    .padding(20)
                refreshButton.padding(14)
            }
        }
        .onChange(of: content?.copyText) { _ in copied = false }
        .task(id: copied) {
            guard copied else { return }
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            if !Task.isCancelled { copied = false }
        }
    }

    private var refreshButton: some View {
        Button {
            refreshCoordinator.refresh()
        } label: {
            Label("refresh", systemImage: "arrow.clockwise")
        }
        .keyboardShortcut("r")
        .disabled(manager.sourceStatus.isRefreshing || bluetoothManager.sourceStatus.isRefreshing)
    }

    private func fields(_ fields: [DeviceDetailField]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(fields) { field in
                VStack(alignment: .leading, spacing: 3) {
                    Text(field.label.localized.trimmingCharacters(in: CharacterSet(charactersIn: ":")))
                        .font(.caption).foregroundStyle(.secondary)
                    Text(field.value)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }

    private var content: DeviceDetailContent? {
        let builder = DeviceDetailsBuilder(
            paths: ConnectionPathResolver(
                devices: manager.devices, hostPorts: manager.thunderboltPorts,
                externalGroups: manager.externalThunderboltPortGroups
            ))
        switch selection {
        case .usb(let id):
            return manager.devices.first { $0.id == id }.map(builder.usb)
        case .bluetooth(let id):
            return bluetoothManager.devices.first { $0.id == id }.map(builder.bluetooth)
        case .port(let id):
            let hostPort = manager.thunderboltPorts.first { $0.id == id }
            guard
                let port = hostPort
                    ?? manager.externalThunderboltPortGroups.flatMap(\.ports).first(where: { $0.id == id })
            else { return nil }
            return builder.port(
                port,
                powerConnected: hostPort != nil && port.connectedDevice == nil
                    && manager.powerSourceConnectorNumber == port.connectorNumber,
                powerWatts: manager.adapterPowerWatts
            )
        }
    }
}
