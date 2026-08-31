import AppKit
import SwiftUI

struct ContentFittingScrollView<Content: View>: View {
    @State private var contentHeight: CGFloat = 1

    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            content
                .background {
                    GeometryReader { geometry in
                        Color.clear.preference(
                            key: ContentHeightPreferenceKey.self,
                            value: geometry.size.height
                        )
                    }
                }
        }
        .frame(height: min(contentHeight, maximumHeight))
        .animation(.easeInOut(duration: 0.15), value: contentHeight)
        .onPreferenceChange(ContentHeightPreferenceKey.self) { height in
            contentHeight = max(1, height)
        }
    }

    private var maximumHeight: CGFloat {
        let visibleScreenHeight = NSScreen.main?.visibleFrame.height ?? 720
        return max(120, visibleScreenHeight - 180)
    }
}

private struct ContentHeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 1

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
