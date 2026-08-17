//
//  BridgeEvents.swift
//  CrossmintCheckout
//
//  Created by Tomás Martins on 8/17/26.
//

import Foundation

/// Events the identity verification page sends. The page never receives anything.
enum IdentityVerificationEvent {
    case heightChanged(Double)
    case ready
    case completed(IdentityVerificationStatus)
    case cancelled
    case failed(IdentityVerificationError)

    init?(envelope: BridgeEnvelope) {
        switch envelope.event {
        case "ui:height.changed":
            guard let height = envelope.data.doubleValue("height") else { return nil }
            self = .heightChanged(height)
        case "kyc:ready":
            self = .ready
        case "kyc:completed":
            let wireValue = envelope.data["status"]?.value as? String ?? ""
            self = .completed(IdentityVerificationStatus(wireValue: wireValue))
        case "kyc:cancelled":
            self = .cancelled
        case "kyc:error":
            self = .failed(IdentityVerificationError(
                retriable: envelope.data["retriable"]?.value as? Bool ?? false,
                reason: .init(wireValue: envelope.data["reason"]?.value as? String ?? ""),
                message: envelope.data["message"]?.value as? String ?? ""
            ))
        default:
            return nil
        }
    }
}

/// Requests the checkout page makes of a native crypto payer. This SDK has no payer support,
/// so each one is answered with the page's no-payer reply instead of being left hanging.
enum CryptoRequest {
    case load
    case connectWalletShow(Bool)
    case sendTransaction
    case signMessage
}

/// Events the embedded checkout page sends that this SDK acts on.
enum CheckoutEvent {
    case orderUpdated(CheckoutOrderUpdate)
    case orderCreationFailed(String)
    case cryptoRequest(CryptoRequest)

    init?(envelope: BridgeEnvelope) {
        switch envelope.event {
        case "order:updated":
            self = .orderUpdated(CheckoutOrderUpdate(data: envelope.data))
        case "order:creation-failed":
            guard let message = envelope.data["errorMessage"]?.value as? String else { return nil }
            self = .orderCreationFailed(message)
        case "crypto:load":
            self = .cryptoRequest(.load)
        case "crypto:connect-wallet.show":
            self = .cryptoRequest(.connectWalletShow(envelope.data["show"]?.value as? Bool ?? true))
        case "crypto:send-transaction":
            self = .cryptoRequest(.sendTransaction)
        case "crypto:sign-message":
            self = .cryptoRequest(.signMessage)
        default:
            return nil
        }
    }
}

extension [String: AnyCodable] {
    // AnyCodable decodes whole JSON numbers as Int, fractional ones as Double.
    func doubleValue(_ key: String) -> Double? {
        switch self[key]?.value {
        case let double as Double: double
        case let int as Int: Double(int)
        default: nil
        }
    }
}
