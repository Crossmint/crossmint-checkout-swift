//
//  CheckoutPayment.swift
//  CrossmintCheckout
//
//  Created by Robin Curbelo on 2/25/26.
//

import Foundation

/// The settings for payment with crypto.
public struct CheckoutCryptoPayment: Codable, Sendable {
    /// Set `true` to let the buyer pay with crypto.
    public let enabled: Bool
    /// The blockchain the checkout selects first, for example `"base"` or `"solana"`.
    public let defaultChain: String?
    /// The currency the checkout selects first, for example `"usdc"`.
    public let defaultCurrency: String?

    /// Creates the crypto payment settings. Pass `nil` for a value to keep the checkout default.
    public init(enabled: Bool, defaultChain: String? = nil, defaultCurrency: String? = nil) {
        self.enabled = enabled
        self.defaultChain = defaultChain
        self.defaultCurrency = defaultCurrency
    }
}

/// The fiat payment methods the checkout offers.
///
/// Every method is on by default. Set a method to `false` to remove it from the checkout.
public struct CheckoutAllowedMethods: Codable, Sendable {
    /// Set `false` to remove Google Pay.
    public let googlePay: Bool?
    /// Set `false` to remove Apple Pay.
    public let applePay: Bool?
    /// Set `false` to remove card payment.
    public let card: Bool?

    /// Creates the allowed methods. Every method is on unless you set it to `false`.
    public init(googlePay: Bool? = true, applePay: Bool? = true, card: Bool? = true) {
        self.googlePay = googlePay
        self.applePay = applePay
        self.card = card
    }
}

/// The settings for payment with fiat currency.
public struct CheckoutFiatPayment: Codable, Sendable {
    /// Set `true` to let the buyer pay with fiat currency.
    public let enabled: Bool
    /// The currency the checkout selects first, for example `"usd"` or `"eur"`.
    public let defaultCurrency: String?
    /// The fiat payment methods the checkout offers. Pass `nil` to offer all of them.
    public let allowedMethods: CheckoutAllowedMethods?

    /// Creates the fiat payment settings. Pass `nil` for a value to keep the checkout default.
    public init(
        enabled: Bool,
        defaultCurrency: String? = nil,
        allowedMethods: CheckoutAllowedMethods? = nil
    ) {
        self.enabled = enabled
        self.defaultCurrency = defaultCurrency
        self.allowedMethods = allowedMethods
    }
}

/// The payment settings for ``CrossmintEmbeddedCheckout``.
///
/// Turn on at least one of ``crypto`` and ``fiat``. The checkout shows a tab for each method
/// that is on.
public struct CheckoutPayment: Codable, Sendable {
    /// A payment method.
    public enum Method: String, Codable, Sendable {
        /// Payment with crypto.
        case crypto
        /// Payment with fiat currency.
        case fiat
    }

    /// The settings for payment with crypto.
    public let crypto: CheckoutCryptoPayment
    /// The settings for payment with fiat currency.
    public let fiat: CheckoutFiatPayment
    /// The email address that receives the receipt. Pass `nil` to let the buyer enter one.
    public let receiptEmail: String?
    /// The payment method the checkout selects first. Pass `nil` to let the checkout choose.
    public let defaultMethod: Method?

    /// Creates the payment settings.
    public init(
        crypto: CheckoutCryptoPayment,
        fiat: CheckoutFiatPayment,
        receiptEmail: String? = nil,
        defaultMethod: Method? = nil
    ) {
        self.crypto = crypto
        self.fiat = fiat
        self.receiptEmail = receiptEmail
        self.defaultMethod = defaultMethod
    }
}
