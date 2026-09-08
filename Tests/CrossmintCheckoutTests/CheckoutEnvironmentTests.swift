//
//  CheckoutEnvironmentTests.swift
//  CrossmintCheckoutTests
//
//  Created by Tomás Martins on 9/8/26.
//

import Testing
@testable import CrossmintCheckout

@Test func clientKeySelectsItsEnvironment() throws {
    #expect(try CheckoutEnvironment(apiKey: "ck_staging_test") == .staging)
    #expect(try CheckoutEnvironment(apiKey: "ck_development_test") == .staging)
    #expect(try CheckoutEnvironment(apiKey: "ck_production_test") == .production)
}

@Test func emptyKeyIsRejected() {
    #expect(throws: CheckoutError.missingAPIKey) {
        try CheckoutEnvironment(apiKey: "")
    }
}

@Test func legacyServerKeyIsRejected() {
    #expect(throws: CheckoutError.legacyAPIKey) {
        try CheckoutEnvironment(apiKey: "sk_live_test")
    }
}

@Test func serverKeyIsRejected() {
    #expect(throws: CheckoutError.serverAPIKey) {
        try CheckoutEnvironment(apiKey: "sk_staging_test")
    }
}

@Test func keyWithoutClientPrefixIsRejected() {
    #expect(throws: CheckoutError.malformedAPIKey) {
        try CheckoutEnvironment(apiKey: "not-a-crossmint-key")
    }
}

@Test func unknownEnvironmentIsRejected() {
    #expect(throws: CheckoutError.malformedAPIKey) {
        try CheckoutEnvironment(apiKey: "ck_sandbox_test")
    }
}

@MainActor
@Test func checkoutRejectsServerKey() {
    let checkout = CrossmintEmbeddedCheckout(
        apiKey: "sk_production_test",
        orderId: "test-order-id",
        clientSecret: "test-secret"
    )

    #expect(throws: CheckoutError.serverAPIKey) {
        try checkout.generateCheckoutUrl()
    }
}

@MainActor
@Test
@available(*, deprecated, message: "Covers the deprecated environment overload")
func checkoutRejectsServerKeyWithExplicitEnvironment() {
    let checkout = CrossmintEmbeddedCheckout(apiKey: "sk_production_test", environment: .production)

    #expect(throws: CheckoutError.serverAPIKey) {
        try checkout.generateCheckoutUrl()
    }
}

@MainActor
@Test func identityVerificationRejectsServerKey() {
    let verification = CrossmintIdentityVerification(
        apiKey: "sk_staging_test",
        credentials: IdentityVerificationCredentials(inquiryId: "inq-123")
    )

    #expect(throws: CheckoutError.serverAPIKey) {
        try verification.generateVerificationUrl()
    }
}
