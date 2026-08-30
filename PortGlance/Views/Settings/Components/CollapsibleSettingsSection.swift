import SwiftUI

struct CollapsibleSettingsSection<Content: View>: View {
    let label: LocalizedStringKey
    let systemImage: String
    @Binding var isExpanded: Bool
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .frame(width: 12)

                    Image(systemName: systemImage)
                        .font(.system(size: 14, weight: .medium))
                        .frame(width: 16, height: 16)

                    Text(label)
                        .font(.headline)

                    Spacer()
                }
                .contentShape(Rectangle())
                .padding(.horizontal, 12)
                .frame(minHeight: 46)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)

            if isExpanded {
                content()
                    .padding(.top, 8)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
            }
        }
        .background(Color.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    }
}
