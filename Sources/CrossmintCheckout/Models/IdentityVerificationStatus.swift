//
//  IdentityVerificationStatus.swift
//  CrossmintCheckout
//
//  Created by Tomás Martins on 8/17/26.
//

import Foundation

/// The outcome of an identity verification.
///
/// The value `unknown` shows a provider state this SDK version does not know. It is never a success.
public enum IdentityVerificationStatus: String, Sendable, Equatable {
    case verified
    case pendingReview = "pending-review"
    case pendingManualReview = "pending-manual-review"
    case declined
    case expired
    case failed
    case unknown
}
