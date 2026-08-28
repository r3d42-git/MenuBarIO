import SwiftUI

struct LegacySettingsView: View {
    @State private var activeRowID: String?
    @State private var showSystemOptions = true
    @State private var showInterfaceOptions = false
    @State private var showUSBOptions = false
    @State private var showOtherOptions = false

    var body: some View {
        ZStack {
            Image(systemName: "gear")
                .font(.system(size: 350))
                .opacity(0.03)

            VStack(alignment: .leading, spacing: 20) {
                LegacySettingsHorizontalTopBar()
                Divider()

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        section(
                            "system_category",
                            image: "gearshape",
                            isExpanded: $showSystemOptions
                        ) {
                            SystemBasicsSettings(activeRowID: $activeRowID)
                        }

                        section(
                            "ui_category",
                            image: "rectangle.3.group",
                            isExpanded: $showInterfaceOptions
                        ) {
                            SettingsInterfaceCategory(activeRowID: $activeRowID)
                            WindowWidthControl(title: "list_width")
                        }

                        section(
                            "usb_category",
                            image: "cable.connector",
                            isExpanded: $showUSBOptions
                        ) {
                            USBPortSettings(activeRowID: $activeRowID)
                        }

                        section(
                            "others_category",
                            image: "ellipsis.circle",
                            isExpanded: $showOtherOptions
                        ) {
                            MenuBarVisibilitySettings(activeRowID: $activeRowID)
                        }
                    }
                }

                LegacySettingsHorizontalBottomBar()
            }
        }
        .padding(10)
        .frame(minWidth: 700, minHeight: 580)
    }

    private func section<Content: View>(
        _ label: LocalizedStringKey,
        image: String,
        isExpanded: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        DisclosureGroup(isExpanded: isExpanded) {
            content()
                .padding(.top, 8)
                .padding(.leading, 2)
        } label: {
            Label(label, systemImage: image)
                .font(.headline)
        }
        .padding(10)
        .background(Color.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    }
}
