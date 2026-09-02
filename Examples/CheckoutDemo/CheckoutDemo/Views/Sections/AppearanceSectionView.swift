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

        List {
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

            RadiusSection(
                label: "Primary button",
                radius: $store.options.radii.primaryButton,
                isInitiallyExpanded: true
            )
            RadiusSection(label: "Input", radius: $store.options.radii.input)
            RadiusSection(label: "Tab", radius: $store.options.radii.tab)

            Section {
                Button("Reset appearance", role: .destructive) {
                    store.options.colors = AppearanceColors()
                    store.options.radii = AppearanceRadii()
                }
                .disabled(store.options.colors.isEmpty && store.options.radii.isEmpty)
                .accessibilityIdentifier("reset-appearance-button")
            }
        }
        .listStyle(.sidebar)
    }

}

#Preview {
    NavigationStack {
        AppearanceSectionView().environment(DemoStore())
    }
}
