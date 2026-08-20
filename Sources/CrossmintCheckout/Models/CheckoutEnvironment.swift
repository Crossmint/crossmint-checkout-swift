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

    var crossmintHost: String {
        switch self {
        case .staging: "staging.crossmint.com"
        case .production: "www.crossmint.com"
        }
    }
}
