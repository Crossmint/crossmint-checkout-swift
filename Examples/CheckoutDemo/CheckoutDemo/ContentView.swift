//
//  ContentView.swift
//  CheckoutDemo
//
//  Created by Robin Curbelo on 2/25/26.
//

import SwiftUI
import CrossmintCheckout

struct ContentView: View {
    var body: some View {
        CrossmintEmbeddedCheckout(
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
            environment: .staging
        )
    }
}
