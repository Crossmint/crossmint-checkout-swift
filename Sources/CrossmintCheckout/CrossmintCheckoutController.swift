//
//  CrossmintCheckoutController.swift
//  CrossmintCheckout
//
//  Created by Tomás Martins on 8/17/26.
//

import Foundation
import Combine

/// Observable order state for one embedded checkout session.
///
/// Give an instance to ``CrossmintEmbeddedCheckout`` and observe it to react to order changes.
/// When the order needs identity verification, ``identityVerificationCredentials`` becomes available.
/// Call ``clear()`` before you use one controller for a new checkout session.
@MainActor
public final class CrossmintCheckoutController: ObservableObject {
    @Published public private(set) var order: CheckoutOrder?
    @Published public private(set) var orderClientSecret: String?

    /// The credentials for the pending identity verification, when the order waits on one.
    public var identityVerificationCredentials: IdentityVerificationCredentials? {
        order?.identityVerificationCredentials
    }

    public init() {}

    /// Removes the stored order state.
    public func clear() {
        order = nil
        orderClientSecret = nil
    }

    func handle(_ update: CheckoutOrderUpdate) {
        if let updatedOrder = update.order {
            order = updatedOrder
        }
        if let secret = update.orderClientSecret {
            orderClientSecret = secret
        }
    }
}
