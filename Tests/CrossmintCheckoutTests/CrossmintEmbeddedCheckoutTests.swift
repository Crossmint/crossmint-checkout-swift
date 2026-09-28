//
//  CrossmintEmbeddedCheckoutTests.swift
//  CrossmintCheckoutTests
//
//  Created by Robin Curbelo on 2/25/26.
//

import SwiftUI
import Testing
import UIKit
@testable import CrossmintCheckout

@MainActor
@Test func urlContainsStagingDomain() throws {
    let checkout = CrossmintEmbeddedCheckout(
        apiKey: "ck_staging_test",
        orderId: "test-order-id",
        clientSecret: "test-secret"
    )

    let url = try checkout.generateCheckoutUrl()
    #expect(url.contains("staging.crossmint.com"))
}

@MainActor
@Test func urlContainsProductionDomain() throws {
    let checkout = CrossmintEmbeddedCheckout(
        apiKey: "ck_production_test",
        orderId: "test-order-id",
        clientSecret: "test-secret"
    )

    let url = try checkout.generateCheckoutUrl()
    #expect(url.contains("www.crossmint.com"))
}

@MainActor
@Test func checkoutDevelopmentKeyCollapsesToStaging() throws {
    let checkout = CrossmintEmbeddedCheckout(apiKey: "ck_development_test")

    let url = try checkout.generateCheckoutUrl()
    #expect(url.contains("https://staging.crossmint.com/"))
}

@MainActor
@Test func checkoutMalformedApiKeyThrows() throws {
    let checkout = CrossmintEmbeddedCheckout(apiKey: "not-a-crossmint-key")

    #expect(throws: CheckoutError.malformedAPIKey) {
        try checkout.generateCheckoutUrl()
    }
}

@MainActor
@Test func urlContainsOrderIdAndClientSecret() throws {
    let checkout = CrossmintEmbeddedCheckout(
        apiKey: "ck_staging_test",
        orderId: "abc-123",
        clientSecret: "secret-456"
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
        clientSecret: "secret-456"
    )

    let url = try checkout.generateCheckoutUrl()
    #expect(url.contains("apiKey=ck_production_abc123"))
}

@MainActor
@Test func emptyApiKeyThrows() throws {
    let checkout = CrossmintEmbeddedCheckout(
        apiKey: "",
        orderId: "abc-123",
        clientSecret: "secret-456"
    )

    #expect(throws: CheckoutError.missingAPIKey) {
        try checkout.generateCheckoutUrl()
    }
}

@MainActor
@Test func urlContainsSdkMetadata() throws {
    let checkout = CrossmintEmbeddedCheckout(apiKey: "ck_staging_test")

    let url = try checkout.generateCheckoutUrl()
    #expect(url.contains("sdkMetadata"))
    #expect(url.contains("checkout-swift"))
}

@MainActor
@Test func urlContainsPaymentConfig() throws {
    let checkout = CrossmintEmbeddedCheckout(
        apiKey: "ck_staging_test",
        payment: CheckoutPayment(
            crypto: CheckoutCryptoPayment(enabled: false),
            fiat: CheckoutFiatPayment(enabled: true)
        )
    )

    let url = try checkout.generateCheckoutUrl()
    #expect(url.contains("payment="))
}

@MainActor
@Test func lineItemsThrowsNotImplemented() throws {
    let checkout = CrossmintEmbeddedCheckout(
        apiKey: "ck_staging_test",
        lineItems: CheckoutLineItems(tokenLocator: "test")
    )

    #expect(throws: CheckoutError.self) {
        try checkout.generateCheckoutUrl()
    }
}

@MainActor
@Test func recipientThrowsNotImplemented() throws {
    let checkout = CrossmintEmbeddedCheckout(
        apiKey: "ck_staging_test",
        recipient: CheckoutRecipient(email: "test@test.com")
    )

    #expect(throws: CheckoutError.self) {
        try checkout.generateCheckoutUrl()
    }
}

@MainActor
@Test func urlContainsAppearanceGlobalMessageRule() throws {
    let checkout = CrossmintEmbeddedCheckout(
        apiKey: "ck_staging_test",
        appearance: CheckoutAppearance(
            rules: CheckoutAppearanceRules(
                globalMessage: CheckoutGlobalMessageRule(isHidden: false)
            )
        )
    )

    let url = try checkout.generateCheckoutUrl()
    #expect(url.contains("GlobalMessage"))
    #expect(url.contains("visible"))
}

@MainActor
@Test(arguments: [(ColorScheme.light, "#000000"), (.dark, "#FFFFFF")])
func urlResolvesDynamicColorsForTheColorScheme(colorScheme: ColorScheme, expected: String) throws {
    let dynamic = UIColor { $0.userInterfaceStyle == .dark ? .white : .black }
    let checkout = CrossmintEmbeddedCheckout(
        apiKey: "ck_staging_test",
        appearance: CheckoutAppearance(
            variables: CheckoutAppearanceVariables(
                colors: CheckoutVariablesColorStyle(textPrimary: .uiColor(dynamic), accent: .color(Color(dynamic)))
            )
        )
    )

    let url = try checkout.generateCheckoutUrl(colorScheme: colorScheme)
    let appearance = URLComponents(string: url)?.queryItems?.first { $0.name == "appearance" }?.value

    #expect(appearance == "{\"variables\":{\"colors\":{\"accent\":\"\(expected)\",\"textPrimary\":\"\(expected)\"}}}")
}

@MainActor
@Test func identityVerificationHandlingExternalAddsQueryParam() throws {
    let checkout = CrossmintEmbeddedCheckout(
        apiKey: "ck_staging_test",
        identityVerificationHandling: .external
    )

    let url = try checkout.generateCheckoutUrl()
    #expect(url.contains("identityVerificationHandling=external"))
}

@MainActor
@Test func identityVerificationHandlingOmittedByDefault() throws {
    let checkout = CrossmintEmbeddedCheckout(apiKey: "ck_staging_test")

    let url = try checkout.generateCheckoutUrl()
    #expect(!url.contains("identityVerificationHandling"))
}

@MainActor
@Test
@available(*, deprecated, message: "Covers the deprecated environment overload")
func explicitEnvironmentOverridesTheKey() throws {
    let checkout = CrossmintEmbeddedCheckout(
        apiKey: "ck_production_test",
        environment: .staging
    )

    let url = try checkout.generateCheckoutUrl()
    #expect(url.contains("staging.crossmint.com"))
}
