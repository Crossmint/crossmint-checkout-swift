//
//  IdentityVerification.swift
//  CrossmintCheckout
//
//  Created by Tomás Martins on 8/17/26.
//

import Foundation

/// Credentials for an identity verification session, read from an order's `payment.preparation.kyc`.
///
/// When taking over the verification step with ``IdentityVerificationHandling/external``, obtain them
/// from ``CrossmintCheckoutController/identityVerificationCredentials`` or from your backend's order response.
public struct IdentityVerificationCredentials: Codable, Sendable, Equatable {
    public let inquiryId: String
    public let sessionToken: String?

    /// The verification provider. Fixed: Persona is the only supported provider.
    public var provider: String { "persona" }

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

    // An empty session token on the wire earns a non-retriable invalid-configuration
    // error from the hosted page, so it is treated as absent.
    private static func normalized(_ sessionToken: String?) -> String? {
        guard let sessionToken, !sessionToken.isEmpty else { return nil }
        return sessionToken
    }
}

/// Provider-agnostic verification outcome. `unknown` is an unrecognized provider state, never a success.
public enum IdentityVerificationStatus: String, Sendable, Equatable {
    case verified
    case pendingReview = "pending-review"
    case pendingManualReview = "pending-manual-review"
    case declined
    case expired
    case failed
    case unknown

    init(wireValue: String) {
        self = Self(rawValue: wireValue) ?? .unknown
    }
}

/// `retriable: false` means the flow is dead and the user cannot finish it.
public struct IdentityVerificationError: Error, LocalizedError, Sendable, Equatable {
    public enum Reason: String, Sendable, Equatable {
        case widgetUnavailable = "widget-unavailable"
        case invalidConfiguration = "invalid-configuration"
        case invalidCredentials = "invalid-credentials"
        case providerError = "provider-error"
        case unknown

        init(wireValue: String) {
            self = Self(rawValue: wireValue) ?? .unknown
        }
    }

    public let retriable: Bool
    public let reason: Reason
    public let message: String

    public var errorDescription: String? { message }

    public init(retriable: Bool, reason: Reason, message: String) {
        self.retriable = retriable
        self.reason = reason
        self.message = message
    }
}

/// Who renders the identity verification (KYC) step of embedded checkout.
///
/// Omitted: checkout renders it inline itself. `external`: checkout renders nothing for the KYC step
/// and you must present ``CrossmintIdentityVerification`` with the order's credentials, or the buyer
/// cannot finish.
public enum IdentityVerificationHandling: String, Sendable {
    case external
}

/// Locales accepted by Crossmint's hosted pages. An unsupported value is rejected by the page,
/// so the set is closed.
public enum CheckoutLocale: String, Sendable, CaseIterable {
    case enUS = "en-US"
    case esES = "es-ES"
    case frFR = "fr-FR"
    case itIT = "it-IT"
    case koKR = "ko-KR"
    case ptPT = "pt-PT"
    case jaJP = "ja-JP"
    case zhCN = "zh-CN"
    case zhTW = "zh-TW"
    case deDE = "de-DE"
    case ruRU = "ru-RU"
    case trTR = "tr-TR"
    case ukUA = "uk-UA"
    case thTH = "th-TH"
    case viVN = "vi-VN"
}
