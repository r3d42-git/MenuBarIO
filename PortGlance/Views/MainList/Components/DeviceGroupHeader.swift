import AppKit
import SwiftUI

enum DeviceGroupIcon {
    case system(String)
    case bluetooth
}

struct DeviceGroupHeader: View {
    let title: LocalizedStringKey
    let icon: DeviceGroupIcon
    let count: Int
    @Binding var isExpanded: Bool

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                isExpanded.toggle()
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .frame(width: 12)

                groupIcon
                    .frame(width: 14, height: 15)
                    .foregroundStyle(.secondary)

                Text(title)
                    .font(.subheadline.weight(.semibold))

                Spacer()

                Text("\(count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                .primary.opacity(0.07),
                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var groupIcon: some View {
        switch icon {
        case .system(let name):
            Image(systemName: name)
                .font(.system(size: 13, weight: .semibold))
        case .bluetooth:
            if let image = NSImage(named: NSImage.bluetoothTemplateName) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
            }
        }
    }
}
