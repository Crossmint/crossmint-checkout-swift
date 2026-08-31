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

    @Environment(DemoStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            CrossmintIdentityVerification(apiKey: apiKey, credentials: credentials)
                .onComplete { status in
                    store.handleIdentityVerification(status: status)
                    dismiss()
                }
                .onError { error in
                    store.handleIdentityVerification(error: error)
                }
                .onCancel {
                    dismiss()
                }
                .navigationTitle("Identity verification")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { dismiss() }
                            .accessibilityIdentifier("close-identity-verification-button")
                    }
                }
        }
    }
}
