//
//  MockLoggerProvider.swift
//  CrossmintCheckoutTests
//
//  Created by Tomás Martins on 9/11/26.
//

import Foundation
@testable import CrossmintCheckout

final class MockLoggerProvider: LoggerProvider, @unchecked Sendable {
    var calls: [CheckoutLogLevel] = []
    var lastMessage: String?
    var lastAttributes: [String: String]?

    func log(_ level: CheckoutLogLevel, _ message: String, attributes: [String: String]?) {
        calls.append(level)
        lastMessage = message
        lastAttributes = attributes
    }
}
