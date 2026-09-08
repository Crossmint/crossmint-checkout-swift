//
//  CheckoutEnvironmentTests.swift
//  CrossmintCheckoutTests
//
//  Created by Tomás Martins on 9/8/26.
//

import Testing
@testable import CrossmintCheckout

@Test func clientKeyPassesValidation() throws {
    _ = try CheckoutEnvironment(apiKey: "ck_staging_test")
}

@Test func serverKeyIsRejected() {
    let error = #expect(throws: CheckoutError.self) {
        _ = try CheckoutEnvironment(apiKey: "sk_staging_test")
    }
    #expect(error?.errorDescription?.contains("server API key") == true)
}

@Test func oldFormatServerKeyIsRejected() {
    let error = #expect(throws: CheckoutError.self) {
        _ = try CheckoutEnvironment(apiKey: "sk_live_test")
    }
    #expect(error?.errorDescription?.contains("Old API key format") == true)
}

@Test func keyWithoutClientPrefixIsRejected() {
    #expect(throws: CheckoutError.self) {
        _ = try CheckoutEnvironment(apiKey: "not-a-crossmint-key")
    }
}

@MainActor
@Test func checkoutRejectsServerKey() {
    let checkout = CrossmintEmbeddedCheckout(
        apiKey: "sk_production_test",
        orderId: "test-order-id",
        clientSecret: "test-secret"
    )

    let error = #expect(throws: CheckoutError.self) {
        try checkout.generateCheckoutUrl()
    }
    #expect(error?.errorDescription?.contains("server API key") == true)
}

@MainActor
@Test
@available(*, deprecated, message: "Covers the deprecated environment overload")
func checkoutRejectsServerKeyWithExplicitEnvironment() {
    let checkout = CrossmintEmbeddedCheckout(apiKey: "sk_production_test", environment: .production)

    #expect(throws: CheckoutError.self) {
        try checkout.generateCheckoutUrl()
    }
}

@MainActor
@Test func identityVerificationRejectsServerKey() {
    let verification = CrossmintIdentityVerification(
        apiKey: "sk_staging_test",
        credentials: IdentityVerificationCredentials(inquiryId: "inq-123")
    )

    let error = #expect(throws: CheckoutError.self) {
        try verification.generateVerificationUrl()
    }
    #expect(error?.errorDescription?.contains("server API key") == true)
}
