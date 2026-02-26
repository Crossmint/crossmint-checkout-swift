//
//  CheckoutError.swift
//  CrossmintCheckout
//
//  Created by Robin Curbelo on 2/25/26.
//

import Foundation

public enum CheckoutError: Error, LocalizedError {
    case notImplemented(String)
    case invalidConfiguration(String)

    public var errorDescription: String? {
        switch self {
        case .notImplemented(let message):
            return message
        case .invalidConfiguration(let message):
            return message
        }
    }
}
