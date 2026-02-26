//
//  CheckoutPayment.swift
//  CrossmintCheckout
//
//  Created by Robin Curbelo on 2/25/26.
//

import Foundation

public struct CheckoutCryptoPayment: Codable, Sendable {
    public let enabled: Bool
    public let defaultChain: String?
    public let defaultCurrency: String?

    public init(enabled: Bool, defaultChain: String? = nil, defaultCurrency: String? = nil) {
        self.enabled = enabled
        self.defaultChain = defaultChain
        self.defaultCurrency = defaultCurrency
    }
}

public struct CheckoutAllowedMethods: Codable, Sendable {
    public let googlePay: Bool?
    public let applePay: Bool?
    public let card: Bool?

    public init(googlePay: Bool? = true, applePay: Bool? = true, card: Bool? = true) {
        self.googlePay = googlePay
        self.applePay = applePay
        self.card = card
    }
}

public struct CheckoutFiatPayment: Codable, Sendable {
    public let enabled: Bool
    public let defaultCurrency: String?
    public let allowedMethods: CheckoutAllowedMethods?

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

public struct CheckoutPayment: Codable, Sendable {
    public enum Method: String, Codable, Sendable {
        case crypto
        case fiat
    }

    public let crypto: CheckoutCryptoPayment
    public let fiat: CheckoutFiatPayment
    public let receiptEmail: String?
    public let defaultMethod: Method?

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
