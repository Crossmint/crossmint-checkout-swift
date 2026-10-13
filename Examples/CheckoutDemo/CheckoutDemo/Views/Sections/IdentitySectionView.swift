//
//  IdentitySectionView.swift
//  CheckoutDemo
//
//  Created by Tomás Martins on 8/31/26.
//

import CrossmintCheckout
import SwiftUI

struct IdentitySectionView: View {
    let apiKey: String

    @Environment(DemoStore.self) private var store

    var body: some View {
        @Bindable var store = store

        Form {
            Section {
                Toggle(
                    "Present verification in the app",
                    isOn: $store.options.externalIdentityVerification
                )
                .accessibilityIdentifier("external-identity-verification-toggle")
            } footer: {
                Text("The checkout leaves out its verification step. When an order needs one, the app presents the verification screen itself.")
            }

            if let credentials = store.identityVerificationCredentials {
                Section {
                    CopyableRow(
                        label: "Verification ID",
                        value: credentials.inquiryId,
                        accessibilityID: "order-inquiry-id-label"
                    )
                    Button("Use the order's credentials") {
                        store.adoptOrderIdentityCredentials()
                    }
                    .accessibilityIdentifier("adopt-order-credentials-button")
                } header: {
                    Text("From the active order")
                }
            }

            Section {
                TextField("Verification ID", text: $store.identityInquiryId)
                    .font(.callout.monospaced())
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .accessibilityIdentifier("identity-inquiry-id-input")

                TextField("Session token (optional)", text: $store.identitySessionToken)
                    .font(.callout.monospaced())
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .accessibilityIdentifier("identity-session-token-input")
            } header: {
                Text("Credentials")
            } footer: {
                Text("A verification ID comes from an order that needs an identity check. Create one in the Order section with an unverified email.")
            }

            Section {
                Picker("Locale", selection: $store.identityLocale) {
                    Text("Default").tag(CheckoutLocale?.none)
                    ForEach(CheckoutLocale.allCases, id: \.self) { locale in
                        Text(locale.rawValue).tag(CheckoutLocale?.some(locale))
                    }
                }
                .accessibilityIdentifier("identity-locale-picker")
            }

            Section {
                Button("Open identity verification", systemImage: "person.text.rectangle") {
                    store.previewIdentityCredentials = store.manualIdentityCredentials
                }
                .disabled(store.manualIdentityCredentials == nil)
                .accessibilityIdentifier("open-identity-verification-button")
            } footer: {
                Text("The verification opens in the preview, in place of the checkout. On staging, you can finish it with the form data alone. No camera or document scan is necessary.")
            }
        }
    }
}

#Preview {
    NavigationStack {
        IdentitySectionView(apiKey: "ck_staging_example").environment(DemoStore(configuration: DemoConfiguration()))
    }
}
