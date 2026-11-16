//
//  OfframpEvent.swift
//  CrossmintCheckout
//
//  Created by Angel Calderaro on 11/5/26.
//

import Foundation

enum OfframpEvent: Equatable {
    case heightChanged(CGFloat)
    case ready
    case statusChanged(OfframpStatusChange)
    case completed(OfframpCompletion)
    case cancelled
    case failed(OfframpError)
    case sendTransaction(OfframpTransaction)
    case signMessage(OfframpMessage)

    enum Name: String {
        case heightChanged = "ui:height.changed"
        case ready = "offramp:ready"
        case status = "offramp:status"
        case completed = "offramp:completed"
        case cancelled = "offramp:cancelled"
        case error = "offramp:error"
        case sendTransaction = "crypto:send-transaction"
        case signMessage = "crypto:sign-message"
    }

    private struct HeightPayload: Decodable {
        let height: CGFloat
    }

    private struct StatusPayload: Decodable {
        let status: String?
        let orderId: String?
    }

    private struct ErrorPayload: Decodable {
        let retriable: Bool?
        let reason: String?
        let message: String?
    }

    init?(messageBody: Any) {
        guard
            let (name, message) = BridgeDecoding.eventName(of: messageBody),
            let event = Name(rawValue: name)
        else { return nil }

        switch event {
        case .heightChanged:
            guard let height = BridgeDecoding.payload(HeightPayload.self, from: message, event: name)?.height,
                  height > 0
            else { return nil }
            self = .heightChanged(height)
        case .ready:
            self = .ready
        case .status:
            let payload = BridgeDecoding.payload(StatusPayload.self, from: message, event: name)
            self = .statusChanged(OfframpStatusChange(
                status: OfframpStatus(rawValue: payload?.status ?? "") ?? .unknown,
                orderId: payload?.orderId
            ))
        case .completed:
            guard let completion = BridgeDecoding.payload(OfframpCompletion.self, from: message, event: name) else { return nil }
            self = .completed(completion)
        case .cancelled:
            self = .cancelled
        case .error:
            let payload = BridgeDecoding.payload(ErrorPayload.self, from: message, event: name)
            self = .failed(OfframpError(
                retriable: payload?.retriable ?? false,
                reason: OfframpError.Reason(rawValue: payload?.reason ?? "") ?? .unknown,
                message: payload?.message ?? ""
            ))
        case .sendTransaction:
            guard let transaction = BridgeDecoding.payload(OfframpTransaction.self, from: message, event: name) else { return nil }
            self = .sendTransaction(transaction)
        case .signMessage:
            guard let request = BridgeDecoding.payload(OfframpMessage.self, from: message, event: name) else { return nil }
            self = .signMessage(request)
        }
    }
}
