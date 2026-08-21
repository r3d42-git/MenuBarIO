//
//  MainListDeviceListContextMenuDevice.swift
//  MenuBarUSB
//
//  Created by rafael on 25/04/26.
//

import SwiftUI

struct MainListDeviceListContextMenuDevice: View {
    
    @EnvironmentObject var manager: USBDeviceManager
    @Environment(\.openURL) var openURL
    
    @Binding var inputText: String
    @Binding var isRenamingDeviceId: String
    @Binding var devicesShowingMore: [USBDeviceWrapper]
    
    var device: USBDeviceWrapper
    var sortedDevices: [USBDeviceWrapper]
    var searchOnWeb: (String) -> Void
    
    @AS(Key.disableContextMenuHeritage) private var disableContextMenuHeritage = false
    @AS(Key.disableContextMenuSearch) private var disableContextMenuSearch = false
    @AS(Key.contextMenuCopyAll) private var contextMenuCopyAll = false
    @AS(Key.mouseHoverInfo) private var mouseHoverInfo = false
    @AS(Key.hideTechInfo) private var hideTechInfo = false
    
    private func devicesShowingMoreDoesNotHave(_ device: borrowing USBDevice) -> Bool {
        for dev in devicesShowingMore {
            if dev.item.id == device.id {
                return false
            }
        }
        return true
    }
    
    var uniqueId: String {
       return device.item.uniqueId
    }
    
    private func deviceId(_ device: borrowing USBDevice) -> String {
        return device.hardwareIdentifier
    }
    
    private func showRestoreName(for deviceId: String) -> Bool {
        let renamed = CSM.Renamed.devices.first { $0.deviceId == deviceId }
        return renamed != nil
    }
    
    private func copyTextLabelView(_ text: String) -> some View {
        let copy = "copy".localized
        let item = "\(text)".localized
        let label = "\(copy): \(item)"
        return Label(label, systemImage: "square.on.square")
    }
    
    private func isPinned(_ id: String) -> Bool {
        return CSM.Pin[id] != nil
    }
    
    private func compactStringInformation(_ device: borrowing USBDevice) -> String {
        var parts: [String] = []

        if !device.name.isEmpty {
            parts.append(device.name)
        } else {
            parts.append("usb_device".localized)
        }

        if let vendor = device.vendor, !vendor.isEmpty {
            parts.append(vendor)
        }

        parts.append(device.uniqueId)

        parts.append(deviceId(device))

        if let usbVer = device.usbVersionBCD {
            if let usbVersion = Utils.USB.usbVersionLabel(from: usbVer) {
                parts.append("\("usb_version".localized) \(usbVersion)")
            } else {
                parts.append("\("usb_version".localized) 0x\(String(format: "%04X", usbVer))")
            }
        }

        if let serial = device.serialNumber, !serial.isEmpty {
            parts.append("\("serial_number".localized) \(serial)")
        }

        if let portMax = device.portMaxSpeedMbps {
            let portStr = portMax >= 1000
                ? String(format: "%.1f Gbps", Double(portMax) / 1000.0)
                : "\(portMax) Mbps"
            parts.append("\("port_max".localized) \(portStr)")
        }

        return parts.joined(separator: "\n")
    }
    
    var body: some View {
        if contextMenuCopyAll {
            Menu {
                Button {
                    Utils.System.copyToClipboard(compactStringInformation(device.item))
                } label: {
                    Label("copy_all_properties", systemImage: "square.on.square")
                }

                Divider()

                Button {
                    Utils.System.copyToClipboard(device.item.name)
                } label: {
                    copyTextLabelView(device.item.name)
                }

                if device.item.vendor != nil {
                    Button {
                        Utils.System.copyToClipboard(device.item.vendor ?? "?")
                    } label: {
                        copyTextLabelView(device.item.vendor ?? "?")
                    }
                }

                Button {
                    Utils.System.copyToClipboard(deviceId(device.item))
                } label: {
                    copyTextLabelView(deviceId(device.item))
                }

                if device.item.serialNumber != nil {
                    Button {
                        Utils.System.copyToClipboard(device.item.serialNumber ?? "SN")
                    } label: {
                        copyTextLabelView(device.item.serialNumber ?? "SN")
                    }
                }
            } label: {
                Label("copy", systemImage: "square.on.square")
            }

        } else {
            Button {
                Utils.System.copyToClipboard(compactStringInformation(device.item))
            } label: {
                Label("copy", systemImage: "square.on.square")
            }
        }
        Divider()
        Button {
            if isPinned(uniqueId) {
                CSM.Pin.remove(withId: uniqueId)
            } else {
                CSM.Pin.add(withId: uniqueId)
            }
            manager.refresh()
        } label: {
            let label = isPinned(uniqueId) ? "unpin" : "pin"
            let icon = isPinned(uniqueId) ? "pin.slash" : "pin"
            Label(label.localized, systemImage: icon)
        }
        Button {
            CSM.Camouflaged.add(withId: uniqueId)
            manager.refresh()
        } label: {
            Label("hide", systemImage: "eye.slash")
        }
        .disabled(CSM.Heritage.devices.contains { $0.inheritsFrom == uniqueId })

        Button {
            inputText = ""
            isRenamingDeviceId = uniqueId
        } label: {
            Label("rename", systemImage: "pencil.and.scribble")
        }

        if showRestoreName(for: uniqueId) {
            Button {
                CSM.Renamed.remove(withId: uniqueId)
                manager.refresh()
            } label: {
                Label("restore_name", systemImage: "eraser.line.dashed")
            }
        }

        if !mouseHoverInfo && hideTechInfo {
            Divider()
            if devicesShowingMoreDoesNotHave(device.item) {
                Button {
                    devicesShowingMore.append(device)
                } label: {
                    Label("show_more", systemImage: "line.3.horizontal")
                }
            } else {
                Button {
                    devicesShowingMore.removeAll { $0 == device }
                } label: {
                    Label("show_less", systemImage: "ellipsis")
                }
            }
        }

        if !disableContextMenuHeritage {
            Divider()

            Menu {
                Button {
                    CSM.Heritage.remove(withId: uniqueId)
                    manager.refresh()
                } label: {
                    Label("kill_inheritance", systemImage: "trash")
                }
                .disabled(CSM.Heritage[uniqueId] == nil)

                Divider()

                Menu {
                    ForEach(sortedDevices.filter { $0.item.isHub == device.item.isHub }) { d in
                        Button {
                            CSM.Heritage.add(withId: d.item.uniqueId, inheritsFrom: uniqueId)
                            manager.refresh()
                        } label: {
                            Text(CSM.Renamed[d.item.uniqueId]?.name ?? d.item.name)
                        }
                    }
                } label: {
                    Label("new_heir", systemImage: "plus.square")
                }
            } label: {
                Label("heritage", systemImage: "app.connected.to.app.below.fill")
            }
        }

        if !disableContextMenuSearch {
            Divider()

            Menu {
                Button {
                    searchOnWeb(device.item.name)
                } label: {
                    Label("search_name", systemImage: "globe")
                }

                Button {
                    searchOnWeb(device.item.hardwareIdentifier)
                } label: {
                    Label("search_id", systemImage: "globe")
                }

                Button {
                    searchOnWeb(device.item.serialNumber!)
                } label: {
                    Label("search_sn", systemImage: "globe")
                }
                .disabled(device.item.serialNumber == nil)
            } label: {
                Label("search", systemImage: "globe")
            }
        }
    }
}
