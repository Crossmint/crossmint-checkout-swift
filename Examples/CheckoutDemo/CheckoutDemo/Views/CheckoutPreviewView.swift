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
    var showsOrderDetailsButton = false

    @Environment(DemoStore.self) private var store
    @StateObject private var controller = CrossmintCheckoutController()
    @State private var identityCredentials: IdentityVerificationCredentials?
    @State private var handledInquiryIDs: Set<String> = []
    @State private var isShowingOrderDetails = false

    var body: some View {
        Group {
            if let session = store.session {
                checkout(for: session)
                    .id(store.previewToken)
                    .ignoresSafeArea()
            } else {
                CheckoutPreviewEmptyState()
            }
        }
        .navigationTitle(store.session != nil ? "Preview" : "")
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            if showsOrderDetailsButton {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Order details", systemImage: "list.bullet.rectangle") {
                        isShowingOrderDetails = true
                    }
                    .disabled(store.session == nil)
                    .accessibilityIdentifier("show-order-details-button")
                }
            }
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
        .sheet(isPresented: $isShowingOrderDetails) {
            if let session = store.session {
                OrderDetailsSheet(session: session).environment(store)
            }
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
