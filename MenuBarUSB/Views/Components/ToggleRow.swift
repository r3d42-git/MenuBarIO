//
//  ToggleRow.swift
//  MenuBarUSB
//
//  Created by Rafael Neuwirth Swierczynski on 31/08/25.
//

import SwiftUI

struct ToggleRow: View {
    let label: String
    let description: String
    @Binding var binding: Bool
    @Binding var activeRowID: String?
    var hasIncompatibility = false
    var disabled: Bool = false
    var onToggle: (Bool) -> Void = { _ in }

    @State private var showIncompatibilityMessage = false
    @State private var showDescription = false

    @State private var warningHoverProgress: Double = 0
    @State private var warningTimer: Timer?

    private var id: String { label }

    private func startWarningHoverProgress() {
        let duration: TimeInterval = 1.5
        let step: TimeInterval = 0.05
        var elapsed: TimeInterval = 0

        warningHoverProgress = 0
        warningTimer?.invalidate()
        warningTimer = Timer.scheduledTimer(withTimeInterval: step, repeats: true) { timer in
            elapsed += step
            let percent = min(elapsed / duration, 1.0)
            warningHoverProgress = percent
            if percent >= 1 {
                withAnimation(.easeInOut(duration: 0.25)) {
                    activeRowID = id
                    showIncompatibilityMessage = true
                    showDescription = false
                }
                timer.invalidate()
            }
        }
    }

    private func cancelWarningHover() {
        warningTimer?.invalidate()
        warningHoverProgress = 0
    }

    private func toggleDescription() {
        let newState = !(activeRowID == id && showDescription)
        activeRowID = newState ? id : nil
        showDescription = newState
        showIncompatibilityMessage = false
    }

    private func toggleWarningMessage() {
        warningTimer?.invalidate()
        warningHoverProgress = 0
        withAnimation(.easeInOut(duration: 0.25)) {
            let newState = !(activeRowID == id && showIncompatibilityMessage)
            activeRowID = newState ? id : nil
            showIncompatibilityMessage = newState
            showDescription = false
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Toggle(
                    label.localized,
                    isOn: Binding(
                        get: { binding },
                        set: { newValue in
                            binding = newValue
                            onToggle(newValue)
                            if !newValue && activeRowID == id {
                                activeRowID = nil
                            }
                        }
                    )
                )
                .toggleStyle(.checkbox)
                .disabled(disabled)

                Button(action: toggleDescription) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(AssetColors.info)
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(description.localized))

                if hasIncompatibility {
                    ZStack {
                        Button(action: toggleWarningMessage) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(AssetColors.warning)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text("warning_incompatible_options"))
                        .onHover { inside in
                            if inside && !showIncompatibilityMessage {
                                startWarningHoverProgress()
                            } else {
                                cancelWarningHover()
                            }
                        }

                        if warningHoverProgress > 0 && warningHoverProgress < 1 {
                            Circle()
                                .trim(from: 0, to: warningHoverProgress)
                                .stroke(AssetColors.warning, lineWidth: 2)
                                .rotationEffect(.degrees(-90))
                                .animation(.linear, value: warningHoverProgress)
                        }
                    }
                    .frame(width: 22, height: 22)
                }

                Spacer()
            }

            if activeRowID == id && showDescription {
                Text(description.localized)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if activeRowID == id && showIncompatibilityMessage {
                Text("warning_incompatible_options")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .padding(8)
                    .background(
                        AssetColors.warning
                            .opacity(0.4)
                            .cornerRadius(8)
                    )
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 1)
        .animation(.easeInOut(duration: 0.25), value: showIncompatibilityMessage)
        .onDisappear {
            warningTimer?.invalidate()
        }
    }
}
