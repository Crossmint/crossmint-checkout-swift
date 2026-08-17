//
//  CrossmintCheckoutController.swift
//  CrossmintCheckout
//
//  Created by Tomás Martins on 8/17/26.
//

import Foundation
import Combine

/// Observable order state for an embedded checkout session.
///
/// Pass an instance to ``CrossmintEmbeddedCheckout`` and observe it to react to order changes —
/// most notably ``identityVerificationCredentials`` appearing when the order requires KYC and you
/// render the step yourself via ``IdentityVerificationHandling/external``.
///
/// Reusing a controller across checkout sessions requires ``clear()`` first.
@MainActor
public final class CrossmintCheckoutController: ObservableObject {
    @Published public private(set) var order: CheckoutOrder?
    @Published public private(set) var orderClientSecret: String?

    /// Credentials for the pending identity verification, when the order is waiting on one.
    public var identityVerificationCredentials: IdentityVerificationCredentials? {
        order?.identityVerificationCredentials
    }

    public init() {}

    public func clear() {
        order = nil
        orderClientSecret = nil
    }

    func handle(_ update: CheckoutOrderUpdate) {
        if let updatedOrder = update.order {
            order = updatedOrder
        }
        // Later updates may omit the secret; the stored one stays valid.
        if let secret = update.orderClientSecret {
            orderClientSecret = secret
        }
    }
}
