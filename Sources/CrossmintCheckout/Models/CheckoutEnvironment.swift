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

    init(apiKey: String) throws {
        guard !apiKey.isEmpty else {
            throw CheckoutError.invalidConfiguration("apiKey is required")
        }
        if apiKey.hasPrefix("sk_live") || apiKey.hasPrefix("sk_test") {
            throw CheckoutError.invalidConfiguration(
                "Old API key format detected. Create a new API key in the Crossmint console."
            )
        }
        if apiKey.hasPrefix("sk_") {
            throw CheckoutError.invalidConfiguration(
                "Disallowed API key. You passed a server API key, but a client API key is required."
            )
        }
        let tokens = apiKey.split(separator: "_")
        guard tokens.count >= 3, tokens[0] == "ck", let environment = Self(token: tokens[1]) else {
            throw CheckoutError.invalidConfiguration("apiKey must be a Crossmint client key (ck_<environment>_...)")
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
