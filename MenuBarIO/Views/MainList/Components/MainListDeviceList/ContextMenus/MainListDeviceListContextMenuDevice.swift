//
//  MainListDeviceListContextMenuDevice.swift
//  MenuBarIO
//
//  Created by rafael on 25/04/26.
//

import SwiftUI

struct MainListDeviceListContextMenuDevice: View {
    let device: USBDevice

    var body: some View {
        Button {
            SystemActions.copyToClipboard(DiagnosticReportBuilder().usbDeviceDetails(device))
        } label: {
            Label("copy", systemImage: "square.on.square")
        }
    }
}
