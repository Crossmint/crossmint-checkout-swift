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

    init?(apiKey: String) {
        let tokens = apiKey.split(separator: "_")
        guard tokens.count >= 3, tokens[0] == "ck" || tokens[0] == "sk" else { return nil }
        switch tokens[1] {
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
