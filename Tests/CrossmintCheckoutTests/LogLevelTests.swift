//
//  LogLevelTests.swift
//  CrossmintCheckoutTests
//
//  Created by Tomás Martins on 9/11/26.
//

import Foundation
import Testing
@testable import CrossmintCheckout

private final class LevelRespectingSpy: LoggerProvider, @unchecked Sendable {
    var calls: [CheckoutLogLevel] = []

    func log(_ level: CheckoutLogLevel, _ message: String, attributes: [String: Encodable]?) {
        guard Logger.level.rawValue <= level.rawValue else { return }
        calls.append(level)
    }
}

@Suite(.serialized)
struct LogLevelTests {
    @Test func silentIsAboveError() {
        #expect(CheckoutLogLevel.silent.rawValue > CheckoutLogLevel.error.rawValue)
    }

    @Test func remoteProvidersReceiveEveryLevel() {
        let saved = Logger.level
        defer { Logger.level = saved }

        Logger.level = .silent
        let spy = MockLoggerProvider()
        let logger = Logger(testProviders: [spy])

        logger.debug("d")
        logger.info("i")
        logger.warning("w")
        logger.error("e")

        #expect(spy.calls == [.debug, .info, .warning, .error])
    }

    @Test func consoleProvidersRespectLevel() {
        let saved = Logger.level
        defer { Logger.level = saved }

        Logger.level = .error
        let spy = LevelRespectingSpy()
        let logger = Logger(testProviders: [spy])

        logger.debug("d")
        logger.info("i")
        logger.warning("w")
        logger.error("e")

        #expect(spy.calls == [.error])
    }

    @MainActor
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

    @Test func consoleProvidersEmitNothingWhenSilent() {
        let saved = Logger.level
        defer { Logger.level = saved }

        Logger.level = .silent
        let spy = LevelRespectingSpy()
        let logger = Logger(testProviders: [spy])

        logger.debug("d")
        logger.info("i")
        logger.warning("w")
        logger.error("e")

        #expect(spy.calls.isEmpty)
    }
}
