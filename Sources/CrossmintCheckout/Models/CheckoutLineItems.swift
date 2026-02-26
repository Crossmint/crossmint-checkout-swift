//
//  CheckoutLineItems.swift
//  CrossmintCheckout
//
//  Created by Robin Curbelo on 2/25/26.
//

import Foundation

public struct CheckoutLineItems: Codable, Sendable {
    public let collectionLocator: String?
    public let tokenLocator: String?
    public let productLocator: String?
    public let callData: [String: AnyCodable]?
    public let executionParameters: [String: AnyCodable]?

    public init(
        collectionLocator: String? = nil,
        tokenLocator: String? = nil,
        productLocator: String? = nil,
        callData: [String: AnyCodable]? = nil,
        executionParameters: [String: AnyCodable]? = nil
    ) {
        self.collectionLocator = collectionLocator
        self.tokenLocator = tokenLocator
        self.productLocator = productLocator
        self.callData = callData
        self.executionParameters = executionParameters
    }
}
