//
//  LogLevelTests.swift
//  CrossmintCheckoutTests
//
//  Created by Tomás Martins on 9/11/26.
//

import Foundation
import Testing
@testable import CrossmintCheckout

@MainActor
@Suite(.serialized)
struct LogLevelTests {
    @Test func remoteProvidersReceiveEveryLevel() {
        let saved = Logger.level
        defer { Logger.level = saved }

        Logger.level = .silent
        let spy = MockLoggerProvider()
        let logger = Logger(providers: [spy])
        logger.debug("d")
        logger.info("i")
        logger.warning("w")
        logger.error("e")

        #expect(spy.calls == [.debug, .info, .warning, .error])
    }

    @Test(arguments: [
        (CheckoutLogLevel.warning, [CheckoutLogLevel.warning, .error]),
        (.error, [.error]),
        (.silent, [])
    ])
    func consoleThresholdIncludesLevelsAtOrAbove(threshold: CheckoutLogLevel, expected: [CheckoutLogLevel]) {
        let included = [CheckoutLogLevel.debug, .info, .warning, .error].filter(threshold.includes)

        #expect(included == expected)
    }

    @Test func viewInitializersSetTheConsoleLevel() {
        let saved = Logger.level
        defer { Logger.level = saved }

        _ = CrossmintEmbeddedCheckout(apiKey: "ck_staging_test", orderId: "order-1", consoleLogLevel: .debug)
        #expect(Logger.level == .debug)

        let credentials = IdentityVerificationCredentials(inquiryId: "inq-1", sessionToken: "tok-1")
        _ = CrossmintIdentityVerification(apiKey: "ck_staging_test", credentials: credentials, consoleLogLevel: .silent)
        #expect(Logger.level == .silent)

        _ = CrossmintEmbeddedCheckout(apiKey: "ck_staging_test", orderId: "order-1")
        #expect(Logger.level == .error)
    }
}
