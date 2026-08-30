//
//  MainListDeviceListContextMenuDevice.swift
//  PortGlance
//
//  Created by rafael on 25/04/26.
//

import SwiftUI

struct MainListDeviceListContextMenuDevice: View {

    @Binding var expandedDeviceIDs: Set<String>

    let device: USBDevice
    @AS(Key.mouseHoverInfo) private var mouseHoverInfo = false
    @AS(Key.hideTechInfo) private var hideTechInfo = false

    private func compactStringInformation(_ device: USBDevice) -> String {
        var parts: [String] = []

        if !device.name.isEmpty {
            parts.append(SystemActions.sanitizedDeviceField(device.name))
        } else {
            parts.append("usb_device".localized)
        }

        if let vendor = device.vendor, !vendor.isEmpty {
            parts.append(SystemActions.sanitizedDeviceField(vendor))
        }

        parts.append(SystemActions.sanitizedDeviceField(device.uniqueId))

        parts.append(device.hardwareIdentifier)

        if let usbVer = device.usbVersionBCD {
            if let usbVersion = USBFormatting.usbVersionLabel(from: usbVer) {
                parts.append("\("usb_version".localized) \(usbVersion)")
            } else {
                parts.append("\("usb_version".localized) 0x\(String(format: "%04X", usbVer))")
            }
        }

        if let serial = device.serialNumber, !serial.isEmpty {
            parts.append("\("serial_number".localized) \(SystemActions.sanitizedDeviceField(serial))")
        }

        if let portMax = device.portMaxSpeedMbps {
            parts.append("\("port_max".localized) \(USBFormatting.transferRate(portMax))")
        }

        return parts.joined(separator: "\n")
    }

    var body: some View {
        Button {
            SystemActions.copyToClipboard(compactStringInformation(device))
        } label: {
            Label("copy", systemImage: "square.on.square")
        }
        if !mouseHoverInfo && hideTechInfo {
            Divider()
            if !expandedDeviceIDs.contains(device.id) {
                Button {
                    expandedDeviceIDs.insert(device.id)
                } label: {
                    Label("show_more", systemImage: "line.3.horizontal")
                }
            } else {
                Button {
                    expandedDeviceIDs.remove(device.id)
                } label: {
                    Label("show_less", systemImage: "ellipsis")
                }
            }
        }

    }
}
