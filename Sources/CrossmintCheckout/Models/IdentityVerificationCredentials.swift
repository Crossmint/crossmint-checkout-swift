//
//  IdentityVerificationCredentials.swift
//  CrossmintCheckout
//
//  Created by Tomás Martins on 8/17/26.
//

import Foundation

/// The credentials for one identity verification session.
///
/// An order that needs verification includes them in `payment.preparation.kyc`.
/// Read the credentials from ``CrossmintCheckoutController/identityVerificationCredentials``.
/// You can also read them from the order response of your backend.
///
/// The order picks the shape: a Persona inquiry, or a Crossmint verification session.
/// Pass the credentials through as they come.
public struct IdentityVerificationCredentials: Codable, Sendable, Equatable, Identifiable {
    private enum Shape: Equatable, Sendable {
        case persona(inquiryId: String, sessionToken: String?)
        case session(verificationId: String, clientSecret: String, deviceSessionKey: String?)
    }

    private let shape: Shape

    /// The identifier of the verification inquiry at Persona.
    ///
    /// The value is `nil` for a Crossmint verification session.
    public var inquiryId: String? {
        guard case .persona(let inquiryId, _) = shape else { return nil }
        return inquiryId
    }

    /// The token that resumes a Persona inquiry the buyer started before.
    ///
    /// The value is `nil` for a new inquiry and for a Crossmint verification session.
    public var sessionToken: String? {
        guard case .persona(_, let sessionToken) = shape else { return nil }
        return sessionToken
    }

    /// The verification provider, `"persona"` for a Persona inquiry.
    ///
    /// The value is `nil` for a Crossmint verification session.
    public var provider: String? {
        guard case .persona = shape else { return nil }
        return "persona"
    }

    /// The stable identity of the credentials: the inquiry identifier for Persona,
    /// or the verification identifier for a Crossmint verification session.
    public var id: String {
        switch shape {
        case .persona(let inquiryId, _): inquiryId
        case .session(let verificationId, _, _): verificationId
        }
    }

    var logAttributes: [String: String] {
        ["credentialsId": id, "credentialsShape": provider ?? "session"]
    }

    /// Creates the credentials for a Persona inquiry.
    ///
    /// An empty `sessionToken` becomes `nil`.
    public init(inquiryId: String, sessionToken: String? = nil) {
        shape = .persona(inquiryId: inquiryId, sessionToken: Self.normalized(sessionToken))
    }

    /// Creates the credentials for a Crossmint verification session.
    ///
    /// An empty `deviceSessionKey` becomes `nil`.
    public init(verificationId: String, clientSecret: String, deviceSessionKey: String? = nil) {
        shape = .session(
            verificationId: verificationId,
            clientSecret: clientSecret,
            deviceSessionKey: Self.normalized(deviceSessionKey)
        )
    }

    enum CodingKeys: String, CodingKey {
        case provider
        case inquiryId
        case sessionToken
        case verificationId
        case clientSecret
        case deviceSessionKey
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let verificationId = Self.normalized(try? container.decodeIfPresent(String.self, forKey: .verificationId)),
           let clientSecret = Self.normalized(try? container.decodeIfPresent(String.self, forKey: .clientSecret)) {
            self.init(
                verificationId: verificationId,
                clientSecret: clientSecret,
                deviceSessionKey: try container.decodeIfPresent(String.self, forKey: .deviceSessionKey)
            )
            return
        }

        let provider = try container.decode(String.self, forKey: .provider)
        guard provider == "persona" else {
            throw DecodingError.dataCorruptedError(
                forKey: .provider,
                in: container,
                debugDescription: "Unsupported identity verification provider: \(provider)"
            )
        }

        self.init(
            inquiryId: try container.decode(String.self, forKey: .inquiryId),
            sessionToken: try container.decodeIfPresent(String.self, forKey: .sessionToken)
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch shape {
        case .persona(let inquiryId, let sessionToken):
            try container.encode("persona", forKey: .provider)
            try container.encode(inquiryId, forKey: .inquiryId)
            try container.encodeIfPresent(sessionToken, forKey: .sessionToken)
        case .session(let verificationId, let clientSecret, let deviceSessionKey):
            try container.encode(verificationId, forKey: .verificationId)
            try container.encode(clientSecret, forKey: .clientSecret)
            try container.encodeIfPresent(deviceSessionKey, forKey: .deviceSessionKey)
        }
    }

    private static func normalized(_ value: String?) -> String? {
        guard let value, !value.isEmpty else { return nil }
        return value
    }
}
