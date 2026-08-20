//
//  BridgeDecoding.swift
//  CrossmintCheckout
//
//  Created by Tomás Martins on 8/20/26.
//

import Foundation

enum BridgeDecoding {
    private struct Named: Decodable {
        let event: String
    }

    private struct Envelope<Payload: Decodable>: Decodable {
        let data: Payload?
    }

    static func eventName(of messageBody: Any) -> (name: String, message: Data)? {
        guard
            let string = messageBody as? String,
            let message = string.data(using: .utf8),
            let named = try? JSONDecoder().decode(Named.self, from: message)
        else { return nil }
        return (named.event, message)
    }

    static func payload<Payload: Decodable>(_ type: Payload.Type, from message: Data) -> Payload? {
        try? JSONDecoder().decode(Envelope<Payload>.self, from: message).data
    }
}
