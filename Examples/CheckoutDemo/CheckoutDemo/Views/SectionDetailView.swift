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
    @Binding var isShowingCheckout: Bool
    @Binding var checkoutDetent: PresentationDetent

    @Environment(DemoStore.self) private var store

    var body: some View {
        Group {
            switch section {
            case .order: OrderSectionView()
            case .payment: PaymentSectionView()
            case .appearance: AppearanceSectionView()
            case .fields: FieldsSectionView()
            case .identity: IdentitySectionView(apiKey: apiKey)
            case .events: EventLogView()
            case nil:
                ContentUnavailableView(
                    "Nothing selected",
                    systemImage: "sidebar.left",
                    description: Text("Choose a section in the sidebar to set up the checkout.")
                )
            }
        }
        .navigationTitle(section?.title ?? "Playground")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if showsCheckoutButton, section?.configuresCheckout == true {
                ToolbarItem(placement: .primaryAction) {
                    Button("Checkout", systemImage: "play.fill") {
                        store.previewIdentityCredentials = nil
                        checkoutDetent = .large
                        isShowingCheckout = true
                    }
                    .disabled(store.session == nil)
                    .accessibilityIdentifier("show-checkout-button")
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }
            }
        }
    }
}
