import AppKit
import Foundation
import UniformTypeIdentifiers

enum MarkdownReportExporter {
    static func suggestedFilename(generatedAt: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let timestamp = formatter.string(from: generatedAt).replacingOccurrences(of: ":", with: "")
        return "MenuBarIO-Hardware-Report-\(timestamp).md"
    }

    static func write(_ markdown: String, to url: URL) throws {
        try markdown.write(to: url, atomically: true, encoding: .utf8)
    }

    @MainActor
    static func export(_ markdown: String, suggestedFilename: String) -> URL? {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType(filenameExtension: "md") ?? .plainText]
        panel.allowsOtherFileTypes = false
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false
        panel.nameFieldStringValue = suggestedFilename
        panel.title = "export_report".localized

        guard panel.runModal() == .OK, let url = panel.url else { return nil }

        do {
            try write(markdown, to: url)
            return url
        } catch {
            NSApp.presentError(error)
            return nil
        }
    }
}
