//
//  ToggleRow.swift
//  PortGlance
//
//  Created by Rafael Neuwirth Swierczynski on 31/08/25.
//

import SwiftUI

struct ToggleRow: View {
    let label: String
    @Binding var binding: Bool
    var onToggle: (Bool) -> Void = { _ in }

    private var toggleBinding: Binding<Bool> {
        Binding(
            get: { binding },
            set: { newValue in
                binding = newValue
                onToggle(newValue)
            }
        )
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(label.localized)

            Spacer(minLength: 12)

            Toggle(label.localized, isOn: toggleBinding)
                .labelsHidden()
                .toggleStyle(.switch)
                .accessibilityLabel(Text(label.localized))
        }
        .padding(.vertical, 4)
    }
}
