import AppKit
import Foundation

enum SystemActions {
    static func openSystemInformation() {
        let process = Process()
        process.launchPath = "/usr/bin/open"
        process.arguments = [
            "-b", "com.apple.SystemProfiler",
            "--args", "SPUSBDataType",
        ]
        try? process.run()
    }

    static func copyToClipboard(_ content: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(content, forType: .string)
    }

    static func sanitizedDeviceField(_ value: String) -> String {
        value.unicodeScalars.map { scalar in
            switch scalar.value {
            case 0x0000...0x001F,
                0x007F...0x009F,
                0x061C,
                0x200E...0x200F,
                0x2028...0x2029,
                0x202A...0x202E,
                0x2066...0x2069:
                return String(format: "\\u{%04X}", scalar.value)
            default:
                return String(scalar)
            }
        }.joined()
    }

    static var isMacBook: Bool {
        var size = 0
        guard sysctlbyname("hw.model", nil, &size, nil, 0) == 0 else { return false }

        var model = [CChar](repeating: 0, count: size)
        guard sysctlbyname("hw.model", &model, &size, nil, 0) == 0 else { return false }

        let identifier = String(cString: model).lowercased()
        let desktopPrefixes = ["imac", "macmini", "macstudio", "macpro"]
        return identifier.hasPrefix("mac")
            && !desktopPrefixes.contains(where: identifier.hasPrefix)
    }
}
