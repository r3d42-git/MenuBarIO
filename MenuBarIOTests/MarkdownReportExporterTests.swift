import Foundation
import XCTest

@testable import MenuBarIO

final class MarkdownReportExporterTests: XCTestCase {
    func testSuggestedFilenameIsMarkdownAndFileSystemSafe() {
        let filename = MarkdownReportExporter.suggestedFilename(
            generatedAt: Date(timeIntervalSince1970: 0)
        )

        XCTAssertEqual(filename, "MenuBarIO-Hardware-Report-1970-01-01T000000Z.md")
        XCTAssertFalse(filename.contains(":"))
        XCTAssertFalse(filename.contains("/"))
    }

    func testWriteCreatesUTF8MarkdownFile() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let url = directory.appendingPathComponent("report.md")
        let markdown = "# MenuBarIO\n\n- USB: 1\n"

        try MarkdownReportExporter.write(markdown, to: url)

        XCTAssertEqual(try String(contentsOf: url, encoding: .utf8), markdown)
    }
}
