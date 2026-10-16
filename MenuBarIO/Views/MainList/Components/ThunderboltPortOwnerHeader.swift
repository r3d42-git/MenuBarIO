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

            VStack(alignment: .leading, spacing: 3) {
                Text(group.owner.displayNameWithVendor)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                if group.activeDisplayOutputCount > 0 {
                    Text("\("active_displayport_outputs".localized): \(group.activeDisplayOutputCount)")
                        .font(.caption2)
                        .help("displayport_connector_unknown".localized)
                }
            }
            .foregroundStyle(.secondary)

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
