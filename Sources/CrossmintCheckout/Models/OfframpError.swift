//
//  OfframpError.swift
//  CrossmintCheckout
//
//  Created by Angel Calderaro on 11/5/26.
//

import Foundation

/// An error from the offramp flow.
///
/// When `retriable` is false, the session cannot continue. Remove the view.
public struct OfframpError: Error, LocalizedError, Sendable, Equatable {
    /// The cause of the error.
    public enum Reason: String, Sendable, Equatable {
        case invalidCredentials = "invalid-credentials"
        case invalidConfiguration = "invalid-configuration"
        case sessionSpent = "session-spent"
        case identityVerificationRequired = "identity-verification-required"
        case identityVerificationFailed = "identity-verification-failed"
        case walletOwnershipRequired = "wallet-ownership-required"
        case bankNotSupported = "bank-not-supported"
        case bankNotVerified = "bank-not-verified"
        case bankHolderMismatch = "bank-holder-mismatch"
        case amountTooLow = "amount-too-low"
        case amountTooHigh = "amount-too-high"
        case exactPayoutUnsupported = "exact-payout-unsupported"
        case insufficientFunds = "insufficient-funds"
        case walletRejected = "wallet-rejected"
        case payoutFailed = "payout-failed"
        case providerError = "provider-error"
        /// A cause this SDK version does not know.
        case unknown
    }

    /// A Boolean value that shows whether a new attempt can work.
    public let retriable: Bool
    /// The cause of the error.
    public let reason: Reason
    /// The text that describes the error.
    ///
    /// The text is for developers, not for the user.
    public let message: String

    public var errorDescription: String? { message }

    /// Creates an error.
    public init(retriable: Bool, reason: Reason, message: String) {
        self.retriable = retriable
        self.reason = reason
        self.message = message
    }

    // A 4xx means the embed itself is wrong; a 5xx or a connection failure may pass on retry.
    init(loadFailure message: String, statusCode: Int?) {
        let retriable = (statusCode ?? 500) >= 500
        self.init(retriable: retriable, reason: retriable ? .providerError : .invalidConfiguration, message: message)
    }
}
