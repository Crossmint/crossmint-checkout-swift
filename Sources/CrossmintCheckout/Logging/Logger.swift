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
        forward(message, attributes) { $0.debug($1, attributes: $2) }
    }

    func error(_ message: String, attributes: [String: Encodable]? = nil) {
        forward(message, attributes) { $0.error($1, attributes: $2) }
    }

    func info(_ message: String, attributes: [String: Encodable]? = nil) {
        forward(message, attributes) { $0.info($1, attributes: $2) }
    }

    func warning(_ message: String, attributes: [String: Encodable]? = nil) {
        forward(message, attributes) { $0.warning($1, attributes: $2) }
    }

    private func forward(
        _ message: String,
        _ attributes: [String: Encodable]?,
        to log: (LoggerProvider, String, [String: Encodable]?) -> Void
    ) {
        let message = CredentialScrubber.scrub(message)
        let attributes = CredentialScrubber.scrub(attributes)
        for provider in providers {
            log(provider, message, attributes)
        }
    }

    func flush() async {
        for provider in providers {
            await provider.flush()
        }
    }
}
