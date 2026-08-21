//
//  IdentityVerificationEvent.swift
//  CrossmintCheckout
//
//  Created by Tomás Martins on 8/17/26.
//

import Foundation

enum IdentityVerificationEvent {
    case ready
    case completed(IdentityVerificationStatus)
    case cancelled
    case failed(IdentityVerificationError)

    private enum Name: String {
        case ready = "kyc:ready"
        case completed = "kyc:completed"
        case cancelled = "kyc:cancelled"
        case error = "kyc:error"
    }

    private struct CompletedPayload: Decodable {
        let status: String?
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
        case .ready:
            self = .ready
        case .completed:
            let payload = BridgeDecoding.payload(CompletedPayload.self, from: message)
            self = .completed(IdentityVerificationStatus(rawValue: payload?.status ?? "") ?? .unknown)
        case .cancelled:
            self = .cancelled
        case .error:
            let payload = BridgeDecoding.payload(ErrorPayload.self, from: message)
            self = .failed(IdentityVerificationError(
                retriable: payload?.retriable ?? false,
                reason: IdentityVerificationError.Reason(rawValue: payload?.reason ?? "") ?? .unknown,
                message: payload?.message ?? ""
            ))
        }
    }
}
