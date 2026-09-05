import SwiftUI

struct ThunderboltPortOwnerHeader: View {
    let group: ExternalThunderboltPortGroup

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "bolt.horizontal.circle")
                .accessibilityHidden(true)
                .font(.system(size: 11, weight: .semibold))
                .frame(width: 14)
                .foregroundStyle(.secondary)

            Text(group.owner.displayNameWithVendor)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Spacer()

            Text("\(group.ports.count)")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 10)
        .padding(.top, 7)
        .padding(.bottom, 1)
    }
}
