//
//  CheckoutEvent.swift
//  CrossmintCheckout
//
//  Created by Tomás Martins on 8/17/26.
//

import Foundation

enum CheckoutEvent {
    case orderUpdated(CheckoutOrderUpdate)
    case orderCreationFailed(String)
    case cryptoRequest(CryptoRequest)

    private enum Name: String {
        case orderUpdated = "order:updated"
        case orderCreationFailed = "order:creation-failed"
        case cryptoLoad = "crypto:load"
        case cryptoConnectWalletShow = "crypto:connect-wallet.show"
        case cryptoSendTransaction = "crypto:send-transaction"
        case cryptoSignMessage = "crypto:sign-message"
    }

    private struct FailurePayload: Decodable {
        let errorMessage: String
    }

    private struct ShowPayload: Decodable {
        let show: Bool?
    }

    init?(messageBody: Any) {
        guard
            let (name, message) = BridgeDecoding.eventName(of: messageBody),
            let event = Name(rawValue: name)
        else { return nil }

        switch event {
        case .orderUpdated:
            guard let update = BridgeDecoding.payload(CheckoutOrderUpdate.self, from: message) else { return nil }
            self = .orderUpdated(update)
        case .orderCreationFailed:
            guard let payload = BridgeDecoding.payload(FailurePayload.self, from: message) else { return nil }
            self = .orderCreationFailed(payload.errorMessage)
        case .cryptoLoad:
            self = .cryptoRequest(.load)
        case .cryptoConnectWalletShow:
            let payload = BridgeDecoding.payload(ShowPayload.self, from: message)
            self = .cryptoRequest(.connectWalletShow(payload?.show ?? true))
        case .cryptoSendTransaction:
            self = .cryptoRequest(.sendTransaction)
        case .cryptoSignMessage:
            self = .cryptoRequest(.signMessage)
        }
    }
}
