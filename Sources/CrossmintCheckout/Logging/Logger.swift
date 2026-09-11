//
//  Logger.swift
//  CrossmintCheckout
//
//  Created by Tomás Martins on 9/11/26.
//

import Foundation

struct Logger: Sendable {
    private let providers: [LoggerProvider]
    nonisolated(unsafe) static var level: CheckoutLogLevel = .error

    static let checkout = Logger(category: "checkout")
    static let web = Logger(category: "web")

    init(category: String) {
        providers = [
            OSLoggerProvider(category: category),
            DataDogLoggerProvider(service: category, clientToken: DataDogConfig.clientToken)
        ]
    }

    init(testProviders: [LoggerProvider]) {
        self.providers = testProviders
    }

    func debug(_ message: String, attributes: [String: Encodable]? = nil) {
        log(.debug, message, attributes)
    }

    func info(_ message: String, attributes: [String: Encodable]? = nil) {
        log(.info, message, attributes)
    }

    func warning(_ message: String, attributes: [String: Encodable]? = nil) {
        log(.warning, message, attributes)
    }

    func error(_ message: String, attributes: [String: Encodable]? = nil) {
        log(.error, message, attributes)
    }

    private func log(_ level: CheckoutLogLevel, _ message: String, _ attributes: [String: Encodable]?) {
        let message = CredentialScrubber.scrub(message)
        let attributes = CredentialScrubber.scrub(attributes)
        for provider in providers {
            provider.log(level, message, attributes: attributes)
        }
    }

    func flush() async {
        for provider in providers {
            await provider.flush()
        }
    }
}
