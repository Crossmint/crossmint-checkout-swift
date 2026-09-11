//
//  UnsafeSendableAttributes.swift
//  CrossmintCheckout
//
//  Created by Tomás Martins on 9/11/26.
//

import Foundation

struct UnsafeSendableAttributes: @unchecked Sendable {
    let value: [String: Encodable]?
}
