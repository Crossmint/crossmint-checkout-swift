//
//  BridgeReply.swift
//  CrossmintCheckout
//
//  Created by Tomás Martins on 8/20/26.
//

import Foundation

struct BridgeReply: Equatable, Encodable {
    let event: String
    let error: String?
    var rejected: Bool?
    var txId: String?
    var signature: String?

    // The event name goes next to this payload, not inside it.
    private enum CodingKeys: String, CodingKey {
        case error, rejected, txId, signature
    }
}
