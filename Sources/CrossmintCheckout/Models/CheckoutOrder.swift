//
//  CheckoutOrder.swift
//  CrossmintCheckout
//
//  Created by Tomás Martins on 8/17/26.
//

import Foundation

/// An order as reported by the embedded checkout page.
///
/// The full payload is kept in ``raw`` because the backend's order schema evolves faster than any
/// client-side mirror (`payment.status` values like `requires-kyc` postdate the published types).
/// The typed accessors read the fields this SDK knows about.
public struct CheckoutOrder: Codable, Sendable {
    public let raw: [String: AnyCodable]

    public init(raw: [String: AnyCodable]) {
        self.raw = raw
    }

    public var orderId: String? {
        string("orderId") ?? string("id")
    }

    public var phase: String? {
        string("phase")
    }

    /// Open-ended: values include `requires-kyc`, which the merchant reacts to when taking over
    /// the verification step.
    public var paymentStatus: String? {
        dictionary("payment")?["status"]?.value as? String
    }

    /// Credentials from `payment.preparation.kyc`, when the order is waiting on identity verification.
    public var identityVerificationCredentials: IdentityVerificationCredentials? {
        guard
            let payment = dictionary("payment"),
            let preparation = payment["preparation"]?.value as? [String: AnyCodable],
            let kyc = preparation["kyc"]?.value as? [String: AnyCodable],
            kyc["provider"]?.value as? String == "persona",
            let inquiryId = kyc["inquiryId"]?.value as? String,
            !inquiryId.isEmpty
        else { return nil }

        return IdentityVerificationCredentials(
            inquiryId: inquiryId,
            sessionToken: kyc["sessionToken"]?.value as? String
        )
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        raw = try container.decode([String: AnyCodable].self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(raw)
    }

    private func string(_ key: String) -> String? {
        raw[key]?.value as? String
    }

    private func dictionary(_ key: String) -> [String: AnyCodable]? {
        raw[key]?.value as? [String: AnyCodable]
    }
}

/// Payload of an `order:updated` event: the order plus the client secret that authorizes reading it.
public struct CheckoutOrderUpdate: Sendable {
    public let order: CheckoutOrder?
    public let orderClientSecret: String?

    init(data: [String: AnyCodable]) {
        let orderDictionary = data["order"]?.value as? [String: AnyCodable]

        // The page nests the order under "order", but be lenient with a flattened payload
        // that itself looks like an order.
        let resolvedOrder: [String: AnyCodable]?
        if let orderDictionary {
            resolvedOrder = orderDictionary
        } else if ["id", "orderId", "status", "phase"].contains(where: { data[$0] != nil }) {
            resolvedOrder = data
        } else {
            resolvedOrder = nil
        }

        order = resolvedOrder.map(CheckoutOrder.init(raw:))
        orderClientSecret = (data["orderClientSecret"]?.value as? String)
            ?? (data["clientSecret"]?.value as? String)
            ?? (resolvedOrder?["clientSecret"]?.value as? String)
    }
}
