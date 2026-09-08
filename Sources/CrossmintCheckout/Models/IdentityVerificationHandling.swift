//
//  IdentityVerificationHandling.swift
//  CrossmintCheckout
//
//  Created by Tomás Martins on 8/17/26.
//

import Foundation

/// The presentation mode for the identity verification (KYC) step of embedded checkout.
///
/// If you do not set a value, the checkout shows the step itself. If you set ``external``,
/// the checkout does not show the step. You must then show ``CrossmintIdentityVerification``
/// with the credentials of the order. If you do not, the buyer cannot finish.
public enum IdentityVerificationHandling: String, Sendable {
    /// Your app shows the identity verification step with ``CrossmintIdentityVerification``.
    case external
}
