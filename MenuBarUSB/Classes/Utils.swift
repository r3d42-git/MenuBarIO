//
//  Utils.swift
//  MenuBarUSB
//
//  Created by Rafael Neuwirth on 02/10/25.
//

import AppKit
import Foundation
import SwiftUI

final class Utils {
    final class System {
        static func openSysInfo() {
            let task = Process()
            task.launchPath = "/usr/bin/open"
            task.arguments = [
                "-b", "com.apple.SystemProfiler",
                "--args", "SPUSBDataType",
            ]
            try? task.run()
        }

        static func copyToClipboard(_ content: String) {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(content, forType: .string)
        }

        static func safeClipboardDeviceField(_ value: String) -> String {
            value.unicodeScalars.map { scalar in
                switch scalar.value {
                case 0x0000 ... 0x001F,
                     0x007F ... 0x009F,
                     0x061C,
                     0x200E ... 0x200F,
                     0x202A ... 0x202E,
                     0x2028 ... 0x2029,
                     0x2066 ... 0x2069:
                    return String(format: "\\u{%04X}", scalar.value)
                default:
                    return String(scalar)
                }
            }.joined()
        }

        static func playSystemSound(named sound: String, limit: TimeInterval = 8) {
            guard let audio = NSSound(named: NSSound.Name(sound)) else { return }

            audio.play()
            let stopTime = min(limit, audio.duration)

            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + stopTime) {
                audio.stop()
            }
        }

        static var isMacbook: Bool {
            var size = 0

            if sysctlbyname("hw.model", nil, &size, nil, 0) != 0 {
                return false
            }

            var model = [CChar](repeating: 0, count: size)
            if sysctlbyname("hw.model", &model, &size, nil, 0) != 0 {
                return false
            }

            let identifier = String(cString: model)
            let lower = identifier.lowercased()

            let desktopPrefixes = ["imac", "macmini", "macstudio", "macpro"]

            if desktopPrefixes.contains(where: { lower.hasPrefix($0) }) {
                return false
            }

            return lower.hasPrefix("mac")
        }

    }

    final class App {
        static var appVersion: String {
            Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "N/A"
        }

        static func exit() {
            NSApp.terminate(nil)
        }

        static func restart() {
            let task = Process()
            task.launchPath = "/usr/bin/open"
            task.arguments = ["-n", Bundle.main.bundlePath]
            task.launch()
            Utils.App.exit()
        }

        static func removeLegacyHardwareSoundData(
            defaults: UserDefaults = .standard,
            bundleIdentifier: String? = Bundle.main.bundleIdentifier,
            applicationSupportDirectory: URL? = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first,
            fileManager: FileManager = .default
        ) {
            [
                "soundDevices",
                "customHardwareSounds",
                "hardwareSound",
                "playHardwareSound",
            ].forEach(defaults.removeObject(forKey:))

            guard let bundleIdentifier, let applicationSupportDirectory else { return }
            let legacySounds = applicationSupportDirectory
                .appendingPathComponent(bundleIdentifier, isDirectory: true)
                .appendingPathComponent("Sounds", isDirectory: true)
            try? fileManager.removeItem(at: legacySounds)
        }

        static func removeLegacyDonationData(defaults: UserDefaults = .standard) {
            defaults.removeObject(forKey: "hideDonate")
        }

        static func removeLegacyAutomaticUpdateData(defaults: UserDefaults = .standard) {
            defaults.removeObject(forKey: "newVersionNotification")
        }

        static func removeLegacyEthernetTrafficData(defaults: UserDefaults = .standard) {
            [
                "internetMonitoring",
                "trafficButton",
                "disableTrafficButtonLabel",
                "fastMonitor",
            ].forEach(defaults.removeObject(forKey:))
        }

        static func removeRemovedFeatureData(defaults: UserDefaults = .standard) {
            [
                "storedDevices", "inheritedDevices", "connectionLogs",
                "showNotifications", "disableNotifCooldown",
                "disableInheritanceLayout", "increasedIndentationGap",
                "hideUpdate", "noTextButtons", "disableContextMenuSearch",
                "disableContextMenuHeritage", "searchEngine", "storeConnectionLogs",
                "disableHaptic", "contextMenuCopyAll", "indexIndicator",
                "listToolBar", "storeDevices", "storedIndicator", "hidePinIndicator",
                "forceEnglish", "renamedIndicator", "camouflagedIndicator",
                "renamedDevices", "camouflagedDevices", "pinnedDevices",
            ].forEach(defaults.removeObject(forKey:))
        }

    }

    final class USB {
        static func chargePercentage(currentCapacity: Int, maximumCapacity: Int) -> Int? {
            guard currentCapacity >= 0, maximumCapacity > 0 else { return nil }

            let percentage = (Double(currentCapacity) / Double(maximumCapacity)) * 100
            guard percentage.isFinite else { return nil }

            return Int(min(max(percentage, 0), 100))
        }

        static func megabitsPerSecond(fromBitsPerSecond bitsPerSecond: Double) -> Int? {
            guard bitsPerSecond.isFinite, bitsPerSecond > 0 else { return nil }

            let megabitsPerSecond = bitsPerSecond / 1_000_000
            guard megabitsPerSecond >= 1, megabitsPerSecond < Double(Int.max) else { return nil }

            return Int(megabitsPerSecond)
        }

        static func thunderboltMegabitsPerSecond(fromLinkBandwidth linkBandwidth: Int) -> Int? {
            guard linkBandwidth > 0 else { return nil }

            let (megabitsPerSecond, overflow) = linkBandwidth.multipliedReportingOverflow(by: 100)
            return overflow ? nil : megabitsPerSecond
        }

        static func usbVersionLabel(from bcd: Int?) -> String? {
            guard let bcd = bcd else { return nil }

            let major = (bcd >> 8) & 0xFF
            let minorHigh = (bcd >> 4) & 0x0F
            let minorLow = bcd & 0x0F
            let minor = minorHigh * 10 + minorLow

            func format(_ label: String) -> String {
                return "\(label) (0x\(String(format: "%04X", bcd)))"
            }

            switch major {
            case 1:
                if bcd == 0x0100 { return format("USB 1.0") }
                if bcd == 0x0110 { return format("USB 1.1") }
                return format("USB 1.\(minor)")

            case 2:
                return format("USB \(major).\(minor)")

            case 3:
                if bcd >= 0x0320 {
                    return format("USB 3.2")
                } else if bcd >= 0x0310 {
                    return format("USB 3.1")
                } else {
                    return format("USB 3.0")
                }

            case 4:
                if bcd >= 0x0420 {
                    return format("USB4 2.0")
                } else {
                    return format("USB4")
                }

            default:
                let versionString = minor == 0 ? "\(major)" : "\(major).\(minor)"
                return format("USB \(versionString)")
            }
        }

        static func speedTierLabel(for mbps: Int) -> String {
            switch mbps {
            case 1, 2: return "USB 1.0 \("low_speed".localized) (1.5 Mbps)"
            case 12: return "USB 1.1 \("full_speed".localized) (12 Mbps)"
            case 480: return "USB 2.0 \("high_speed".localized) (480 Mbps)"
            case 5000: return "USB 3.0 / 3.1 Gen1 / 3.2 Gen1x1 (5 Gbps)"
            case 10000: return "USB 3.1 Gen2 / 3.2 Gen2x1 (10 Gbps)"
            case 20000: return "USB 3.2 Gen2x2 / USB4 Gen2x2 (20 Gbps)"
            case 40000: return "USB4 Gen3x2 / Thunderbolt 3/4 (40 Gbps)"
            case 80000: return "USB4 v2 Gen4x2 / Thunderbolt 5 (80 Gbps)"
            default:
                if mbps >= 1000 { return String(format: "%.1f Gbps", Double(mbps) / 1000.0) }
                return "\(mbps) Mbps"
            }
        }

        static func prettyMbps(_ mbps: Int) -> String {
            mbps >= 1000 ? String(format: "%.1f Gbps", Double(mbps) / 1000.0) : "\(mbps) Mbps"
        }
    }

}
