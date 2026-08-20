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
        self == .production ? "www.crossmint.com" : "staging.crossmint.com"
    }
}
