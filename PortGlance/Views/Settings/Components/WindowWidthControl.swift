import SwiftUI

struct WindowWidthControl: View {
    let title: LocalizedStringKey
    @AS(Key.windowWidth) private var windowWidth: WindowWidth = .normal

    var body: some View {
        HStack {
            Text(title)

            Button {
                if let smaller = windowWidth.smaller {
                    windowWidth = smaller
                }
            } label: {
                Image(systemName: "minus")
                    .frame(width: 14, height: 14)
            }
            .disabled(windowWidth.smaller == nil)

            Button {
                if let larger = windowWidth.larger {
                    windowWidth = larger
                }
            } label: {
                Image(systemName: "plus")
                    .frame(width: 14, height: 14)
            }
            .disabled(windowWidth.larger == nil)

            Text(windowWidth.localizedNameKey.localized)
                .font(.footnote)
        }
        .padding(.vertical, 7)
    }
}
