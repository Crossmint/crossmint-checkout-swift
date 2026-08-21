//
//  IdentityVerificationError.swift
//  CrossmintCheckout
//
//  Created by Tomás Martins on 8/17/26.
//

import Foundation

/// An error from the identity verification flow.
///
/// When `retriable` is false, the flow is dead. The user cannot finish it.
public struct IdentityVerificationError: Error, LocalizedError, Sendable, Equatable {
    public enum Reason: String, Sendable, Equatable {
        case widgetUnavailable = "widget-unavailable"
        case invalidConfiguration = "invalid-configuration"
        case invalidCredentials = "invalid-credentials"
        case providerError = "provider-error"
        case unknown
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
