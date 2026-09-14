//
//  CryptoRequest.swift
//  CrossmintCheckout
//
//  Created by Tomás Martins on 8/17/26.
//

import Foundation

enum CryptoRequest: Equatable {
    case load
    case connectWalletShow(Bool)
    case sendTransaction
    case signMessage

    var noPayerReply: BridgeReply? {
        switch self {
        case .load:
            BridgeReply(event: "crypto:load.success", error: nil)
        case .connectWalletShow(false):
            nil
        case .connectWalletShow(true):
            BridgeReply(event: "crypto:connect-wallet.failed", error: "No payer configured")
        case .sendTransaction:
            BridgeReply(event: "crypto:send-transaction:failed", error: "No payer configured")
        case .signMessage:
            BridgeReply(event: "crypto:sign-message:failed", error: "No payer configured")
        }
    }
}
