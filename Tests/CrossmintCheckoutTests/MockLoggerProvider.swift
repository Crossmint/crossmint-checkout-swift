//
//  MockLoggerProvider.swift
//  CrossmintCheckoutTests
//
//  Created by Tomás Martins on 9/11/26.
//

import Foundation
@testable import CrossmintCheckout

final class MockLoggerProvider: LoggerProvider, @unchecked Sendable {
    var calls: [String] = []
    var lastMessage: String?
    var lastAttributes: [String: Encodable]?

    func debug(_ message: String, attributes: [String: Encodable]?) {
        record("debug", message, attributes)
    }

    func info(_ message: String, attributes: [String: Encodable]?) {
        record("info", message, attributes)
    }

    func warning(_ message: String, attributes: [String: Encodable]?) {
        record("warning", message, attributes)
    }

    func error(_ message: String, attributes: [String: Encodable]?) {
        record("error", message, attributes)
    }

    private func record(_ level: String, _ message: String, _ attributes: [String: Encodable]?) {
        calls.append(level)
        lastMessage = message
        lastAttributes = attributes
    }
}
