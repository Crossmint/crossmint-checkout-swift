//
//  LoggerProvider.swift
//  CrossmintCheckout
//
//  Created by Tomás Martins on 9/11/26.
//

import Foundation

protocol LoggerProvider: Sendable {
    nonisolated func debug(_ message: String, attributes: [String: Encodable]?)
    nonisolated func error(_ message: String, attributes: [String: Encodable]?)
    nonisolated func info(_ message: String, attributes: [String: Encodable]?)
    nonisolated func warning(_ message: String, attributes: [String: Encodable]?)
    nonisolated func flush() async
}

extension LoggerProvider {
    nonisolated func flush() { }
}
