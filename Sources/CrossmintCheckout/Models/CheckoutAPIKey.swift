//
//  CheckoutAPIKey.swift
//  CrossmintCheckout
//
//  Created by Tomás Martins on 9/8/26.
//

import Foundation

enum CheckoutAPIKey {
    static func validate(_ apiKey: String) throws {
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
        guard apiKey.hasPrefix("ck_") else {
            throw CheckoutError.invalidConfiguration(
                "apiKey must be a Crossmint client key (ck_<environment>_...)"
            )
        }
    }
}
