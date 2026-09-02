//
//  AppearanceSectionView.swift
//  CheckoutDemo
//
//  Created by Tomás Martins on 8/31/26.
//

import SwiftUI

struct AppearanceSectionView: View {
    @Environment(DemoStore.self) private var store

    var body: some View {
        @Bindable var store = store

        Form {
            Section {
                ColorField(label: "Background", hex: $store.options.colors.backgroundPrimary)
                ColorField(label: "Primary text", hex: $store.options.colors.textPrimary)
                ColorField(label: "Secondary text", hex: $store.options.colors.textSecondary)
                ColorField(label: "Border", hex: $store.options.colors.borderPrimary)
                ColorField(label: "Accent", hex: $store.options.colors.accent)
                ColorField(label: "Danger", hex: $store.options.colors.danger)
                ColorField(label: "Warning", hex: $store.options.colors.warning)
            } header: {
                Text("Colors")
            } footer: {
                Text("Type a hex value with or without the leading #, or leave a field empty to keep the checkout default.")
            }

            Section {
                Toggle("Custom border radius", isOn: borderRadiusEnabled)
                    .accessibilityIdentifier("border-radius-toggle")

                if let radius = store.options.borderRadius {
                    LabeledContent("Border radius") {
                        Text("\(Int(radius))px")
                            .font(.callout.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    Slider(
                        value: borderRadiusValue,
                        in: 0...24,
                        step: 1
                    )
                    .accessibilityIdentifier("border-radius-slider")
                    .accessibilityValue("\(Int(radius)) pixels")
                }
            } header: {
                Text("Shape")
            } footer: {
                Text("The radius applies to inputs, tabs and the primary button.")
            }

            Section {
                Button("Reset appearance", role: .destructive) {
                    store.options.colors = AppearanceColors()
                    store.options.borderRadius = nil
                }
                .disabled(store.options.colors.isEmpty && store.options.borderRadius == nil)
                .accessibilityIdentifier("reset-appearance-button")
            }
        }
    }

    private var borderRadiusEnabled: Binding<Bool> {
        Binding(
            get: { store.options.borderRadius != nil },
            set: { store.options.borderRadius = $0 ? 8 : nil }
        )
    }

    private var borderRadiusValue: Binding<Double> {
        Binding(
            get: { store.options.borderRadius ?? 8 },
            set: { store.options.borderRadius = $0 }
        )
    }
}

#Preview {
    NavigationStack {
        AppearanceSectionView().environment(DemoStore())
    }
}
