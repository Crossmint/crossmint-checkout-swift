//
//  CrossmintEmbeddedCheckoutTests.swift
//  CrossmintCheckoutTests
//
//  Created by Robin Curbelo on 2/25/26.
//

import Testing
@testable import CrossmintCheckout

@MainActor
@Test func urlContainsStagingDomain() throws {
    let checkout = CrossmintEmbeddedCheckout(
        orderId: "test-order-id",
        clientSecret: "test-secret",
        environment: .staging
    )

    let url = try checkout.generateCheckoutUrl()
    #expect(url.contains("staging.crossmint.com"))
}

@MainActor
@Test func urlContainsProductionDomain() throws {
    let checkout = CrossmintEmbeddedCheckout(
        orderId: "test-order-id",
        clientSecret: "test-secret",
        environment: .production
    )

    let url = try checkout.generateCheckoutUrl()
    #expect(url.contains("www.crossmint.com"))
}

@MainActor
@Test func urlContainsOrderIdAndClientSecret() throws {
    let checkout = CrossmintEmbeddedCheckout(
        orderId: "abc-123",
        clientSecret: "secret-456",
        environment: .staging
    )

    let url = try checkout.generateCheckoutUrl()
    #expect(url.contains("orderId=abc-123"))
    #expect(url.contains("clientSecret=secret-456"))
}

@MainActor
@Test func urlContainsSdkMetadata() throws {
    let checkout = CrossmintEmbeddedCheckout(environment: .staging)

    let url = try checkout.generateCheckoutUrl()
    #expect(url.contains("sdkMetadata"))
    #expect(url.contains("checkout-swift"))
}

@MainActor
@Test func urlContainsPaymentConfig() throws {
    let checkout = CrossmintEmbeddedCheckout(
        payment: CheckoutPayment(
            crypto: CheckoutCryptoPayment(enabled: false),
            fiat: CheckoutFiatPayment(enabled: true)
        ),
        environment: .staging
    )

    let url = try checkout.generateCheckoutUrl()
    #expect(url.contains("payment="))
}

@MainActor
@Test func lineItemsThrowsNotImplemented() throws {
    let checkout = CrossmintEmbeddedCheckout(
        lineItems: CheckoutLineItems(tokenLocator: "test"),
        environment: .staging
    )

    #expect(throws: CheckoutError.self) {
        try checkout.generateCheckoutUrl()
    }
}

@MainActor
@Test func recipientThrowsNotImplemented() throws {
    let checkout = CrossmintEmbeddedCheckout(
        recipient: CheckoutRecipient(email: "test@test.com"),
        environment: .staging
    )

    #expect(throws: CheckoutError.self) {
        try checkout.generateCheckoutUrl()
    }
}
