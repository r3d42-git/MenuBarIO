import SwiftUI

struct USBHubOwnerHeader: View {
    let group: USBHubGroup

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: iconName)
                .font(.system(size: 11, weight: .semibold))
                .frame(width: 14)
                .foregroundStyle(.secondary)

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Spacer()

            Text("\(group.devices.count)")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 10)
        .padding(.top, 7)
        .padding(.bottom, 1)
    }

    private var title: String {
        switch group.owner {
        case .thisMac:
            return "this_mac".localized
        case .thunderboltDevice(_, let displayName, _):
            return displayName
        case .direct:
            return "direct_usb_hubs".localized
        case .unknown:
            return "unknown_usb_hub_assignment".localized
        }
    }

    private var iconName: String {
        switch group.owner {
        case .thisMac:
            return "desktopcomputer"
        case .thunderboltDevice:
            return "bolt.horizontal.circle"
        case .direct:
            return "cable.connector"
        case .unknown:
            return "questionmark.circle"
        }
    }
}
