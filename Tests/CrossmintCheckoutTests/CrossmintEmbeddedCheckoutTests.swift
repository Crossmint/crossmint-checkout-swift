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
        apiKey: "ck_test",
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
        apiKey: "ck_test",
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
        apiKey: "ck_test",
        orderId: "abc-123",
        clientSecret: "secret-456",
        environment: .staging
    )

    let url = try checkout.generateCheckoutUrl()
    #expect(url.contains("orderId=abc-123"))
    #expect(url.contains("clientSecret=secret-456"))
}

@MainActor
@Test func urlContainsApiKey() throws {
    let checkout = CrossmintEmbeddedCheckout(
        apiKey: "ck_production_abc123",
        orderId: "abc-123",
        clientSecret: "secret-456",
        environment: .production
    )

    let url = try checkout.generateCheckoutUrl()
    #expect(url.contains("apiKey=ck_production_abc123"))
}

@MainActor
@Test func emptyApiKeyThrows() throws {
    let checkout = CrossmintEmbeddedCheckout(
        apiKey: "",
        orderId: "abc-123",
        clientSecret: "secret-456",
        environment: .staging
    )

    #expect(throws: CheckoutError.self) {
        try checkout.generateCheckoutUrl()
    }
}

@MainActor
@Test func urlContainsSdkMetadata() throws {
    let checkout = CrossmintEmbeddedCheckout(apiKey: "ck_test", environment: .staging)

    let url = try checkout.generateCheckoutUrl()
    #expect(url.contains("sdkMetadata"))
    #expect(url.contains("checkout-swift"))
}

@MainActor
@Test func urlContainsPaymentConfig() throws {
    let checkout = CrossmintEmbeddedCheckout(
        apiKey: "ck_test",
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
        apiKey: "ck_test",
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
        apiKey: "ck_test",
        recipient: CheckoutRecipient(email: "test@test.com"),
        environment: .staging
    )

    #expect(throws: CheckoutError.self) {
        try checkout.generateCheckoutUrl()
    }
}

@MainActor
@Test func urlContainsAppearanceGlobalMessageRule() throws {
    let checkout = CrossmintEmbeddedCheckout(
        apiKey: "ck_test",
        appearance: CheckoutAppearance(
            rules: CheckoutAppearanceRules(
                globalMessage: CheckoutGlobalMessageRule(display: "visible")
            )
        ),
        environment: .staging
    )

    let url = try checkout.generateCheckoutUrl()
    #expect(url.contains("GlobalMessage"))
    #expect(url.contains("visible"))
}

@MainActor
@Test func identityVerificationHandlingExternalAddsQueryParam() throws {
    let checkout = CrossmintEmbeddedCheckout(
        apiKey: "ck_test",
        identityVerificationHandling: .external,
        environment: .staging
    )

    let url = try checkout.generateCheckoutUrl()
    #expect(url.contains("identityVerificationHandling=external"))
}

@MainActor
@Test func identityVerificationHandlingOmittedByDefault() throws {
    let checkout = CrossmintEmbeddedCheckout(apiKey: "ck_test", environment: .staging)

    let url = try checkout.generateCheckoutUrl()
    #expect(!url.contains("identityVerificationHandling"))
}
