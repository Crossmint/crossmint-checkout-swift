//
//  CheckoutError.swift
//  CrossmintCheckout
//
//  Created by Robin Curbelo on 2/25/26.
//

import Foundation

public enum CheckoutError: Error, LocalizedError, Equatable {
    case notImplemented(String)
    case invalidConfiguration(String)
    case missingAPIKey
    case legacyAPIKey
    case serverAPIKey
    case malformedAPIKey

    public var errorDescription: String? {
        switch self {
        case .notImplemented(let message), .invalidConfiguration(let message):
            message
        case .missingAPIKey:
            "apiKey is required"
        case .legacyAPIKey:
            "Old API key format detected. Create a new API key in the Crossmint console."
        case .serverAPIKey:
            "Disallowed API key. You passed a server API key, but a client API key is required."
        case .malformedAPIKey:
            "apiKey must be a Crossmint client key (ck_<environment>_...)"
        }
    }
}
