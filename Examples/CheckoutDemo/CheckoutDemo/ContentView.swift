//
//  ContentView.swift
//  CheckoutDemo
//
//  Created by Robin Curbelo on 2/25/26.
//

import SwiftUI
import CrossmintCheckout

struct ContentView: View {
    @StateObject private var controller = CrossmintCheckoutController()
    @State private var kycCredentials: IdentityVerificationCredentials?

    var body: some View {
        CrossmintEmbeddedCheckout(
            apiKey: "ck_production_...",
            orderId: "your-order-id",
            clientSecret: "your-client-secret",
            payment: CheckoutPayment(
                crypto: CheckoutCryptoPayment(enabled: false),
                fiat: CheckoutFiatPayment(
                    enabled: true,
                    allowedMethods: CheckoutAllowedMethods(
                        googlePay: false,
                        applePay: true,
                        card: false
                    )
                )
            ),
            appearance: CheckoutAppearance(
                rules: CheckoutAppearanceRules(
                    destinationInput: CheckoutDestinationInputRule(display: "hidden"),
                    receiptEmailInput: CheckoutReceiptEmailInputRule(display: "hidden")
                )
            ),
            identityVerificationHandling: .external,
            controller: controller
        )
        .onReceive(controller.$order) { order in
            kycCredentials = order?.identityVerificationCredentials
        }
        .sheet(item: $kycCredentials) { credentials in
            CrossmintIdentityVerification(
                apiKey: "ck_production_...",
                credentials: credentials
            )
            .onComplete { status in print("Identity verification finished: \(status)") }
            .onError { error in print("Identity verification error: \(error.message)") }
        }
    }
}
