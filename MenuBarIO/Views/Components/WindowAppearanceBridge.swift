import AppKit
import SwiftUI

struct WindowAppearanceBridge: NSViewRepresentable {
    let appearance: AppAppearance

    func makeNSView(context: Context) -> WindowAppearanceView {
        let view = WindowAppearanceView()
        view.appAppearance = appearance
        return view
    }

    func updateNSView(_ nsView: WindowAppearanceView, context: Context) {
        nsView.appAppearance = appearance
    }
}

@MainActor
final class WindowAppearanceView: NSView {
    var appAppearance: AppAppearance = .system {
        didSet { applyAppearance() }
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        applyAppearance()
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }

    private func applyAppearance() {
        window?.appearance = appAppearance.nsAppearance
    }
}

extension AppAppearance {
    var nsAppearance: NSAppearance? {
        switch self {
        case .system: nil
        case .light: NSAppearance(named: .aqua)
        case .dark: NSAppearance(named: .darkAqua)
        }
    }
}
