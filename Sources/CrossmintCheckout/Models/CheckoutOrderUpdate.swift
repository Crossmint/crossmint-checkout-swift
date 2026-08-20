//
//  CheckoutOrderUpdate.swift
//  CrossmintCheckout
//
//  Created by Tomás Martins on 8/17/26.
//

import Foundation

/// The payload of one `order:updated` event from the checkout page.
///
/// The `orderClientSecret` authorizes reads of the order. A later update can omit it.
public struct CheckoutOrderUpdate: Decodable, Sendable {
    public let order: CheckoutOrder?
    public let orderClientSecret: String?

    private enum CodingKeys: String, CodingKey {
        case order
        case orderClientSecret
        case clientSecret
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let nested = try? container.decodeIfPresent(CheckoutOrder.self, forKey: .order)
        let flattened = (try? CheckoutOrder(from: decoder)).flatMap { $0.looksLikeOrder ? $0 : nil }
        let resolved = nested ?? flattened
        order = resolved

        let direct = try? container.decodeIfPresent(String.self, forKey: .orderClientSecret)
        let alternate = try? container.decodeIfPresent(String.self, forKey: .clientSecret)
        orderClientSecret = direct ?? alternate ?? resolved?.clientSecret
    }
}
