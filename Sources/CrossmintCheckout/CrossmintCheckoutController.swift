//
//  CrossmintCheckoutController.swift
//  CrossmintCheckout
//
//  Created by Tomás Martins on 8/17/26.
//

import Foundation
import Combine

/// The observable order state of one embedded checkout session.
///
/// Give an instance to ``CrossmintEmbeddedCheckout``. Observe the instance to react to order changes.
/// ``identityVerificationCredentials`` has a value when the order needs identity verification.
/// Call ``clear()`` before you use one controller for a new checkout session.
@MainActor
public final class CrossmintCheckoutController: ObservableObject {
    /// The order in its latest state.
    ///
    /// The value is `nil` before the first order update.
    @Published public private(set) var order: CheckoutOrder?
    /// The secret that authorizes reads of the order.
    ///
    /// The checkout page sends the secret with the first order update. Later updates can omit
    /// it, and the controller keeps the last secret it received.
    @Published public private(set) var orderClientSecret: String?

    /// The credentials for the pending identity verification.
    ///
    /// The value is `nil` when the order does not wait on identity verification.
    public var identityVerificationCredentials: IdentityVerificationCredentials? {
        order?.identityVerificationCredentials
    }

    /// Creates a controller with no order.
    public init() {}

    /// Removes the stored order state.
    public func clear() {
        Logger.checkout.debug(LogEvents.controllerCleared, attributes: ["orderId": order?.orderId ?? ""])
        order = nil
        orderClientSecret = nil
    }

    func handle(_ update: CheckoutOrderUpdate) {
        if let updatedOrder = update.order {
            logTransitions(from: order, to: updatedOrder)
            order = updatedOrder
        }
        if let secret = update.orderClientSecret {
            orderClientSecret = secret
        }
    }

    private func logTransitions(from previous: CheckoutOrder?, to next: CheckoutOrder) {
        let orderId = next.orderId ?? previous?.orderId ?? ""
        if let phase = next.phase, phase != previous?.phase {
            Logger.checkout.info(LogEvents.orderPhaseChanged, attributes: [
                "orderId": orderId,
                "from": previous?.phase?.rawValue ?? "",
                "to": phase.rawValue
            ])
        }
        if let credentials = next.identityVerificationCredentials,
           credentials != previous?.identityVerificationCredentials {
            Logger.checkout.info(LogEvents.orderKycRequired, attributes: [
                "orderId": orderId,
                "inquiryId": credentials.inquiryId,
                "hasSessionToken": String(credentials.sessionToken != nil)
            ])
        }
    }
}
