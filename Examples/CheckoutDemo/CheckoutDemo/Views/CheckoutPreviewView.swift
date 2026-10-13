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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay {
            if let credentials = store.previewIdentityCredentials {
                identityVerification(for: credentials)
                    .background(Color(.systemBackground))
            }
        }
        .navigationTitle(navigationTitle)
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            if showsOrderDetailsButton, store.previewIdentityCredentials == nil {
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
                .disabled(store.session == nil && store.previewIdentityCredentials == nil)
                .accessibilityIdentifier("reload-preview-button")
            }
        }
        .onReceive(controller.$order) { order in
            guard store.options.externalIdentityVerification,
                  let credentials = order?.identityVerificationCredentials,
                  !handledInquiryIDs.contains(credentials.inquiryId) else { return }
            handledInquiryIDs.insert(credentials.inquiryId)
            store.previewIdentityCredentials = credentials
        }
        .sheet(isPresented: $isShowingOrderDetails) {
            if let session = store.session {
                OrderDetailsSheet(session: session).environment(store)
            }
        }
    }

    private var navigationTitle: String {
        store.session != nil || store.previewIdentityCredentials != nil ? "Preview" : ""
    }

    private func identityVerification(
        for credentials: IdentityVerificationCredentials
    ) -> some View {
        CrossmintIdentityVerification(
            apiKey: apiKey,
            credentials: credentials,
            locale: store.identityLocale
        )
        .onReady { store.handleIdentityVerificationReady() }
        .onComplete { status in
            store.handleIdentityVerification(status: status)
            store.previewIdentityCredentials = nil
        }
        .onCancel {
            store.handleIdentityVerificationCancelled()
            store.previewIdentityCredentials = nil
        }
        .onError { error in
            store.handleIdentityVerification(error: error)
        }
        .accessibilityIdentifier("identity-verification-preview")
        .id(store.previewToken)
        .safeAreaPadding()
        .ignoresSafeArea()
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
