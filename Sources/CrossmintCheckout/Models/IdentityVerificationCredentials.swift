//
//  IdentityVerificationCredentials.swift
//  CrossmintCheckout
//
//  Created by Tomás Martins on 8/17/26.
//

import Foundation

/// The credentials for one identity verification session.
///
/// An order that needs verification carries them in `payment.preparation.kyc`.
/// Read them from ``CrossmintCheckoutController/identityVerificationCredentials`` or from your backend's order response.
public struct IdentityVerificationCredentials: Codable, Sendable, Equatable, Identifiable {
    public let inquiryId: String
    public let sessionToken: String?

    /// The verification provider. Persona is the only supported provider.
    public var provider: String { "persona" }

    public var id: String { inquiryId }

    public init(inquiryId: String, sessionToken: String? = nil) {
        self.inquiryId = inquiryId
        self.sessionToken = Self.normalized(sessionToken)
    }

    enum CodingKeys: String, CodingKey {
        case provider
        case inquiryId
        case sessionToken
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let provider = try container.decode(String.self, forKey: .provider)
        guard provider == "persona" else {
            throw DecodingError.dataCorruptedError(
                forKey: .provider,
                in: container,
                debugDescription: "Unsupported identity verification provider: \(provider)"
            )
        }

        inquiryId = try container.decode(String.self, forKey: .inquiryId)
        sessionToken = Self.normalized(try container.decodeIfPresent(String.self, forKey: .sessionToken))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(provider, forKey: .provider)
        try container.encode(inquiryId, forKey: .inquiryId)
        try container.encodeIfPresent(sessionToken, forKey: .sessionToken)
    }

    private static func normalized(_ sessionToken: String?) -> String? {
        guard let sessionToken, !sessionToken.isEmpty else { return nil }
        return sessionToken
    }
}
