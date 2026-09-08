//
//  CheckoutEnvironment.swift
//  CrossmintCheckout
//
//  Created by Robin Curbelo on 2/25/26.
//

import Foundation

/// The Crossmint environment the SDK talks to.
public enum CheckoutEnvironment: Sendable {
    case staging
    case production

    init(apiKey: String) throws(CheckoutError) {
        guard !apiKey.isEmpty else {
            throw .missingAPIKey
        }
        if apiKey.hasPrefix("sk_live") || apiKey.hasPrefix("sk_test") {
            throw .legacyAPIKey
        }
        if apiKey.hasPrefix("sk_") {
            throw .serverAPIKey
        }
        let tokens = apiKey.split(separator: "_")
        guard tokens.count >= 3, tokens[0] == "ck", let environment = Self(token: tokens[1]) else {
            throw .malformedAPIKey
        }
        self = environment
    }

    private init?(token: Substring) {
        switch token {
        case "production":
            self = .production
        case "staging", "development":
            self = .staging
        default:
            return nil
        }
    }

    var crossmintHost: String {
        switch self {
        case .staging: "staging.crossmint.com"
        case .production: "www.crossmint.com"
        }
    }
}
