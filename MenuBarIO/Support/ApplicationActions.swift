import AppKit
import Foundation

enum ApplicationActions {
    static var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "N/A"
    }

    static var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "N/A"
    }

    static func exit() {
        NSApp.terminate(nil)
    }

    static func restart() {
        let process = Process()
        process.launchPath = "/usr/bin/open"
        process.arguments = ["-n", Bundle.main.bundlePath]

        guard (try? process.run()) != nil else { return }
        exit()
    }
}
