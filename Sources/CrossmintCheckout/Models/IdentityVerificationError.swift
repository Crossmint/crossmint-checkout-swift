//
//  IdentityVerificationError.swift
//  CrossmintCheckout
//
//  Created by Tomás Martins on 8/17/26.
//

import Foundation

/// An error from the identity verification flow.
///
/// When `retriable` is false, the flow cannot continue. The buyer cannot finish it.
public struct IdentityVerificationError: Error, LocalizedError, Sendable, Equatable {
    /// The cause of the error.
    public enum Reason: String, Sendable, Equatable {
        /// The verification UI did not load.
        case widgetUnavailable = "widget-unavailable"
        /// The API key or another setting is not valid.
        case invalidConfiguration = "invalid-configuration"
        /// The provider rejected the credentials.
        case invalidCredentials = "invalid-credentials"
        /// The provider reported an error.
        case providerError = "provider-error"
        /// A cause this SDK version does not know.
        case unknown
    }

    /// Set `true` when a new attempt can work.
    public let retriable: Bool
    /// The cause of the error.
    public let reason: Reason
    /// The text that describes the error. The text is for developers, not for the buyer.
    public let message: String

    public var errorDescription: String? { message }

    /// Creates an error.
    public init(retriable: Bool, reason: Reason, message: String) {
        self.retriable = retriable
        self.reason = reason
        self.message = message
    }
}
