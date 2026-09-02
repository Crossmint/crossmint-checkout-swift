//
//  IdentityVerificationSheet.swift
//  CheckoutDemo
//
//  Created by Tomás Martins on 8/31/26.
//

import CrossmintCheckout
import SwiftUI

struct IdentityVerificationSheet: View {
    let apiKey: String
    let credentials: IdentityVerificationCredentials
    var locale: CheckoutLocale?

    @Environment(DemoStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            CrossmintIdentityVerification(
                apiKey: apiKey,
                credentials: credentials,
                locale: locale
            )
            .onReady {
                store.handleIdentityVerificationReady()
            }
            .onComplete { status in
                store.handleIdentityVerification(status: status)
                dismiss()
            }
            .onError { error in
                store.handleIdentityVerification(error: error)
            }
            .onCancel {
                store.handleIdentityVerificationCancelled()
                dismiss()
            }
            .ignoresSafeArea()
            .navigationTitle("Identity verification")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    CloseButton { dismiss() }
                        .accessibilityIdentifier("close-identity-verification-button")
                }
            }
        }
    }
}
