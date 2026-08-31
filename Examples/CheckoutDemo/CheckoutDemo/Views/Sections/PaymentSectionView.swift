//
//  PaymentSectionView.swift
//  CheckoutDemo
//
//  Created by Tomás Martins on 8/31/26.
//

import SwiftUI

struct PaymentSectionView: View {
    @Environment(DemoStore.self) private var store

    var body: some View {
        @Bindable var store = store

        Form {
            Section {
                Toggle("Fiat", isOn: $store.options.fiatEnabled)
                    .accessibilityIdentifier("fiat-enabled-toggle")
                Toggle("Crypto", isOn: $store.options.cryptoEnabled)
                    .accessibilityIdentifier("crypto-enabled-toggle")
            } footer: {
                Text("The buyer needs at least one of these methods.")
            }

            Section("Allowed fiat methods") {
                Toggle("Card", isOn: $store.options.allowCard)
                    .accessibilityIdentifier("card-allowed-toggle")
                Toggle("Apple Pay", isOn: $store.options.allowApplePay)
                    .accessibilityIdentifier("apple-pay-allowed-toggle")
                Toggle("Google Pay", isOn: $store.options.allowGooglePay)
                    .accessibilityIdentifier("google-pay-allowed-toggle")
            }
            .disabled(!store.options.fiatEnabled)

            Section {
                Toggle(
                    "Handle identity verification externally",
                    isOn: $store.options.externalIdentityVerification
                )
                .accessibilityIdentifier("external-identity-verification-toggle")
            } header: {
                Text("Identity verification")
            } footer: {
                Text("The app presents CrossmintIdentityVerification instead of the step inside the checkout.")
            }
        }
    }
}

#Preview {
    NavigationStack {
        PaymentSectionView().environment(DemoStore())
    }
}
