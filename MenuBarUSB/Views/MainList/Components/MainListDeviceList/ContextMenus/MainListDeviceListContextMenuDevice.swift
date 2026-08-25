//
//  MainListDeviceListContextMenuDevice.swift
//  MenuBarUSB
//
//  Created by rafael on 25/04/26.
//

import SwiftUI

struct MainListDeviceListContextMenuDevice: View {
    
    @Binding var devicesShowingMore: [USBDeviceWrapper]
    
    var device: USBDeviceWrapper
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
    
    private func deviceId(_ device: borrowing USBDevice) -> String {
        return device.hardwareIdentifier
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
        Button {
            Utils.System.copyToClipboard(compactStringInformation(device.item))
        } label: {
            Label("copy", systemImage: "square.on.square")
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

    }
}
