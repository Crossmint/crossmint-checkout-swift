//
//  OfframpStatus.swift
//  CrossmintCheckout
//
//  Created by Angel Calderaro on 11/5/26.
//

import Foundation

/// The step of the offramp flow.
///
/// The value `unknown` shows a step this SDK version does not know.
public enum OfframpStatus: String, Sendable, Equatable {
    case loading
    case enteringAmount = "entering-amount"
    case selectingBank = "selecting-bank"
    case addingBank = "adding-bank"
    case verifyingIdentity = "verifying-identity"
    case identityInReview = "identity-in-review"
    case verifyingWallet = "verifying-wallet"
    case reviewing
    case awaitingSignature = "awaiting-signature"
    case confirmingDeposit = "confirming-deposit"
    case completed
    case payoutCompleted = "payout-completed"
    case payoutFailed = "payout-failed"
    case failed
    /// A step this SDK version does not know.
    case unknown
}

/// A move of the offramp flow to another step.
public struct OfframpStatusChange: Sendable, Equatable {
    /// The step the flow moved to.
    public let status: OfframpStatus
    /// The order of the withdrawal, once there is one. It can change during one withdrawal, so keep the latest.
    public let orderId: String?
}

/// A confirmed deposit. The bank payout can still be pending.
public struct OfframpCompletion: Sendable, Equatable {
    /// The order of the withdrawal.
    public let orderId: String
    /// The transaction identifier that the payer returned for the deposit.
    public let txId: String
}

extension OfframpCompletion: Decodable {}
