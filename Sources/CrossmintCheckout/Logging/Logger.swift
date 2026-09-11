//
//  Logger.swift
//  CrossmintCheckout
//
//  Created by Tomás Martins on 9/11/26.
//

import Foundation

protocol LoggerProvider: Sendable {
    nonisolated func log(_ level: CheckoutLogLevel, _ message: String, attributes: [String: String]?)
}

final class LockedValue<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var stored: Value

    init(_ value: Value) {
        stored = value
    }

    var value: Value {
        get { lock.withLock { stored } }
        set { lock.withLock { stored = newValue } }
    }
}

struct Logger: Sendable {
    private static let levelBox = LockedValue(CheckoutLogLevel.error)

    static var level: CheckoutLogLevel {
        get { levelBox.value }
        set { levelBox.value = newValue }
    }

    static let checkout = Logger(category: "checkout")

    private let providers: [LoggerProvider]

    init(category: String) {
        self.init(providers: [OSLoggerProvider(category: category), DataDogLoggerProvider(service: category)])
    }

    init(providers: [LoggerProvider]) {
        self.providers = providers
    }

    func debug(_ message: String, attributes: [String: String]? = nil) {
        log(.debug, message, attributes)
    }

    func info(_ message: String, attributes: [String: String]? = nil) {
        log(.info, message, attributes)
    }

    func warning(_ message: String, attributes: [String: String]? = nil) {
        log(.warning, message, attributes)
    }

    func error(_ message: String, attributes: [String: String]? = nil) {
        log(.error, message, attributes)
    }

    private func log(_ level: CheckoutLogLevel, _ message: String, _ attributes: [String: String]?) {
        let message = CredentialScrubber.scrub(message)
        let attributes = attributes?.mapValues(CredentialScrubber.scrub)
        for provider in providers {
            provider.log(level, message, attributes: attributes)
        }
    }
}
