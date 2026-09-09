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
    /// The provider verified the identity of the buyer.
    case verified
    /// The provider needs more time to review the inquiry.
    case pendingReview = "pending-review"
    /// A person at the provider must review the inquiry.
    case pendingManualReview = "pending-manual-review"
    /// The provider rejected the identity of the buyer.
    case declined
    /// The inquiry expired before the buyer finished it.
    case expired
    /// The verification did not complete.
    case failed
    /// A provider state this SDK version does not know.
    case unknown
}
