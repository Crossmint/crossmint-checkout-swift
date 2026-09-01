//
//  CheckoutPreviewView.swift
//  CheckoutDemo
//
//  Created by Tomás Martins on 8/31/26.
//

import CrossmintCheckout
import SwiftUI

struct CheckoutPreviewView: View {
    let apiKey: String

    @Environment(DemoStore.self) private var store
    @StateObject private var controller = CrossmintCheckoutController()
    @State private var identityCredentials: IdentityVerificationCredentials?
    @State private var handledInquiryIDs: Set<String> = []

    var body: some View {
        Group {
            if let session = store.session {
                checkout(for: session)
                    .id(store.previewToken)
                    .ignoresSafeArea()
                    .safeAreaPadding()
            } else {
                CheckoutPreviewEmptyState()
            }
        }
        .navigationTitle(store.session != nil ? "Checkout" : "")
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Reload", systemImage: "arrow.clockwise") {
                    controller.clear()
                    handledInquiryIDs.removeAll()
                    store.reloadPreview()
                }
                .disabled(store.session == nil)
                .accessibilityIdentifier("reload-preview-button")
            }
        }
        .onReceive(controller.$order) { order in
            guard store.options.externalIdentityVerification,
                  let credentials = order?.identityVerificationCredentials,
                  !handledInquiryIDs.contains(credentials.inquiryId) else { return }
            handledInquiryIDs.insert(credentials.inquiryId)
            identityCredentials = credentials
        }
        .sheet(item: $identityCredentials) { credentials in
            IdentityVerificationSheet(apiKey: apiKey, credentials: credentials).environment(store)
        }
    }

    private func checkout(for session: OrderSession) -> some View {
        CrossmintEmbeddedCheckout(
            apiKey: apiKey,
            orderId: session.orderId,
            clientSecret: session.clientSecret,
            payment: store.options.payment,
            appearance: store.options.appearance,
            identityVerificationHandling: store.options.identityVerificationHandling,
            controller: controller
        )
        .onOrderUpdated { store.handleOrderUpdate($0) }
        .onOrderCreationFailed { store.handleOrderCreationFailure($0) }
        .accessibilityIdentifier("checkout-preview")
    }
}
