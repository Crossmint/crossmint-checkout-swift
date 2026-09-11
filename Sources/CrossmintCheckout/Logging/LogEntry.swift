//
//  LogEntry.swift
//  CrossmintCheckout
//
//  Created by Tomás Martins on 9/11/26.
//

import Foundation

struct LogEntry {
    let level: CheckoutLogLevel
    let message: String
    let timestamp: String
    let context: [String: Encodable]
}
