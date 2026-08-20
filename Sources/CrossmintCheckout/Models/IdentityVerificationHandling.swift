//
//  IdentityVerificationHandling.swift
//  CrossmintCheckout
//
//  Created by Tomás Martins on 8/17/26.
//

import Foundation

/// Controls who shows the identity verification (KYC) step of embedded checkout.
///
/// Do not set it and checkout shows the step itself. Set `external` and checkout shows nothing for that step.
/// You must then show ``CrossmintIdentityVerification`` with the order's credentials, or the buyer cannot finish.
public enum IdentityVerificationHandling: String, Sendable {
    case external
}
