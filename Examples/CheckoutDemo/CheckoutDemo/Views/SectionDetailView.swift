//
//  SectionDetailView.swift
//  CheckoutDemo
//
//  Created by Tomás Martins on 8/31/26.
//

import SwiftUI

struct SectionDetailView: View {
    let section: SidebarSection?
    let apiKey: String
    let showsCheckoutButton: Bool

    @Environment(DemoStore.self) private var store
    @State private var isShowingCheckout = false

    var body: some View {
        Group {
            switch section {
            case .order: OrderSectionView()
            case .payment: PaymentSectionView()
            case .appearance: AppearanceSectionView()
            case .elements: ElementsSectionView()
            case .events: EventLogView()
            case .settings: SettingsSectionView()
            case nil:
                ContentUnavailableView(
                    "Pick a section",
                    systemImage: "sidebar.left",
                    description: Text("Choose what to configure from the sidebar.")
                )
            }
        }
        .navigationTitle(section?.title ?? "Playground")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if showsCheckoutButton, section != .events, section != .settings {
                ToolbarItem(placement: .primaryAction) {
                    Button("Checkout", systemImage: "creditcard") {
                        isShowingCheckout = true
                    }
                    .accessibilityIdentifier("show-checkout-button")
                }
            }
        }
        .sheet(isPresented: $isShowingCheckout) {
            NavigationStack {
                CheckoutPreviewView(apiKey: apiKey)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { isShowingCheckout = false }
                                .accessibilityIdentifier("close-checkout-button")
                        }
                    }
            }
            .environment(store)
        }
    }
}
