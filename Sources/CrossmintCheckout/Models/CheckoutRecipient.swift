//
//  CheckoutRecipient.swift
//  CrossmintCheckout
//
//  Created by Robin Curbelo on 2/25/26.
//

import Foundation

public struct CheckoutRecipient: Codable, Sendable {
    public let walletAddress: String?
    public let email: String?

    public init(walletAddress: String? = nil, email: String? = nil) {
        self.walletAddress = walletAddress
        self.email = email
    }
}
