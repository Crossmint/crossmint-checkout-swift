//
//  MockLoggerProvider.swift
//  CrossmintCheckoutTests
//
//  Created by Tomás Martins on 9/11/26.
//

import Foundation
import Testing
@testable import CrossmintCheckout

final class MockLoggerProvider: LoggerProvider, @unchecked Sendable {
    struct Entry: Equatable {
        let level: CheckoutLogLevel
        let message: String
        let attributes: [String: String]?
    }

    private let lock = NSLock()
    private var stored: [Entry] = []
    // Logger.checkout is global, so tests running in parallel log into this spy too.
    private let owner = Test.current?.id

    var entries: [Entry] { lock.withLock { stored } }

    var calls: [CheckoutLogLevel] { entries.map(\.level) }
    var lastMessage: String? { entries.last?.message }
    var lastAttributes: [String: String]? { entries.last?.attributes }

    func log(_ level: CheckoutLogLevel, _ message: String, attributes: [String: String]?) {
        guard Test.current?.id == owner else { return }
        lock.withLock { stored.append(Entry(level: level, message: message, attributes: attributes)) }
    }

    func entry(_ message: String) -> Entry? {
        entries.first { $0.message == message }
    }
}
