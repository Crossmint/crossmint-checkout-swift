//
//  CheckoutOrder.swift
//  CrossmintCheckout
//
//  Created by Tomás Martins on 8/17/26.
//

import Foundation

/// An order as the embedded checkout page reports it.
public struct CheckoutOrder: Decodable, Sendable {
    public let orderId: String?
    public let phase: Phase?
    public let payment: Payment?

    let clientSecret: String?

    /// A stage in the life of an order.
    public enum Phase: String, Decodable, Sendable {
        case quote
        case payment
        case delivery
        case completed
    }

    /// The payment section of an order.
    ///
    /// The `status` value `requires-kyc` means the order waits on identity verification.
    public struct Payment: Decodable, Sendable {
        public let status: String?
        public let preparation: Preparation?
    }

    /// The payment preparation section of an order.
    public struct Preparation: Decodable, Sendable {
        public let kyc: IdentityVerificationCredentials?

        private enum CodingKeys: String, CodingKey {
            case kyc
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            kyc = try? container.decodeIfPresent(IdentityVerificationCredentials.self, forKey: .kyc)
        }
    }

    /// The credentials for the pending identity verification, when the order waits on one.
    public var identityVerificationCredentials: IdentityVerificationCredentials? {
        payment?.preparation?.kyc
    }

    private enum CodingKeys: String, CodingKey {
        case orderId
        case id
        case phase
        case payment
        case clientSecret
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        orderId = Self.string(.orderId, in: container) ?? Self.string(.id, in: container)
        phase = try? container.decodeIfPresent(Phase.self, forKey: .phase)
        payment = try? container.decodeIfPresent(Payment.self, forKey: .payment)
        clientSecret = Self.string(.clientSecret, in: container)
    }

    var looksLikeOrder: Bool {
        orderId != nil || phase != nil || payment != nil
    }

    private static func string(_ key: CodingKeys, in container: KeyedDecodingContainer<CodingKeys>) -> String? {
        try? container.decodeIfPresent(String.self, forKey: key)
    }
}
