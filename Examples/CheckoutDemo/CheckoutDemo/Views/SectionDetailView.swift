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
            case .identity: IdentitySectionView(apiKey: apiKey)
            case .events: EventLogView()
            case nil:
                ContentUnavailableView(
                    "No section selected",
                    systemImage: "sidebar.left",
                    description: Text("Select a section in the sidebar to configure the checkout.")
                )
            }
        }
        .navigationTitle(section?.title ?? "Playground")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if showsCheckoutButton, SidebarSection.configuration.contains(where: { $0 == section }) {
                ToolbarItem(placement: .primaryAction) {
                    Button("Checkout", systemImage: "creditcard") {
                        isShowingCheckout = true
                    }
                    .accessibilityIdentifier("show-checkout-button")
                }
            }
        }
        .onChange(of: showsCheckoutButton) { _, newValue in
            if !newValue { isShowingCheckout = false }
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
