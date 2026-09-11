//
//  CredentialScrubberTests.swift
//  CrossmintCheckoutTests
//
//  Created by Tomás Martins on 9/11/26.
//

import Foundation
import Testing
@testable import CrossmintCheckout

private let JWT = "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ0ZXN0LWZpeHR1cmUifQ.notARealSignatureJustTestData01"
private let API_KEY = "ck_staging_notARealApiKeyJustTestData01"
private let CLIENT_SECRET = "cs_notARealClientSecretJustTestData01"
private let SESSION_TOKEN = "notARealSessionTokenJustTestData01"

struct CredentialScrubberTests {
    @Test func redactsOrderClientSecretFromOrderUpdate() {
        let message = """
        Web >> Native: {"event":"order:updated","data":{"order":{"orderId":"order-1","phase":"payment"},\
        "orderClientSecret":"\(CLIENT_SECRET)"}}
        """

        let scrubbed = CredentialScrubber.scrub(message)

        #expect(!scrubbed.contains(CLIENT_SECRET))
        #expect(scrubbed.contains("order:updated"))
        #expect(scrubbed.contains("order-1"))
    }

    @Test func redactsKycSessionToken() {
        let message = #"{"kyc":{"provider":"persona","inquiryId":"inq-1","sessionToken":"\#(SESSION_TOKEN)"}}"#

        let scrubbed = CredentialScrubber.scrub(message)

        #expect(!scrubbed.contains(SESSION_TOKEN))
        #expect(scrubbed.contains("inq-1"))
    }

    @Test func redactsQueryParametersFromHostedPageUrl() {
        let url = "https://staging.crossmint.com/sdk/2024-03-05/embedded-checkout?sdkMetadata=%7B%7D"
            + "&apiKey=\(API_KEY)&orderId=order-1&clientSecret=\(CLIENT_SECRET)"

        let scrubbed = CredentialScrubber.scrub(url)

        #expect(!scrubbed.contains(API_KEY))
        #expect(!scrubbed.contains(CLIENT_SECRET))
        #expect(scrubbed.contains("orderId=order-1"))
        #expect(scrubbed.contains("clientSecret=[REDACTED]"))
    }

    @Test func redactsEncodedCredentialsQueryParameter() {
        let url = "https://www.crossmint.com/sdk/unstable/identity-verification"
            + "?credentials=%7B%22sessionToken%22%3A%22\(SESSION_TOKEN)%22%7D&locale=en-US"

        let scrubbed = CredentialScrubber.scrub(url)

        #expect(!scrubbed.contains(SESSION_TOKEN))
        #expect(scrubbed.contains("locale=en-US"))
    }

    @Test func redactsEveryApiKeyPrefix() {
        let keys = [
            "ck_development_notARealApiKeyJustTestData01",
            "ck_staging_notARealApiKeyJustTestData01",
            "ck_production_notARealApiKeyJustTestData01",
            "sk_production_notARealApiKeyJustTestData01"
        ]

        for key in keys {
            #expect(!CredentialScrubber.scrub("key=\(key)").contains(key))
        }
    }

    @Test func redactsCredentialsOutsideJsonContainers() {
        let scrubbed = CredentialScrubber.scrub("refreshed token=\(JWT) using \(API_KEY)")

        #expect(scrubbed == "refreshed token=[REDACTED_JWT] using [REDACTED_API_KEY]")
    }

    @Test func leavesMessagesWithoutCredentialsIntact() {
        let message = #"Web >> Native: {"event":"kyc:completed","data":{"status":"approved"}}"#

        #expect(CredentialScrubber.scrub(message) == message)
    }

    @Test func scrubsStringAttributesReachingProviders() {
        let provider = MockLoggerProvider()
        let logger = Logger(testProviders: [provider])

        logger.error("load failed", attributes: ["context": "key \(API_KEY)"])

        #expect(provider.lastAttributes?["context"] as? String == "key [REDACTED_API_KEY]")
    }

    @Test func leavesNonStringAttributesUntouched() {
        let provider = MockLoggerProvider()
        let logger = Logger(testProviders: [provider])

        logger.debug("sending", attributes: ["attempt": 2])

        #expect(provider.lastAttributes?["attempt"] as? Int == 2)
    }

    @Test func compilesEveryPattern() {
        #expect(CredentialScrubber.patterns.count == 4)
    }

    @Test func scrubsEveryLogLevel() {
        let provider = MockLoggerProvider()
        let logger = Logger(testProviders: [provider])

        logger.debug(JWT)
        #expect(provider.lastMessage == "[REDACTED_JWT]")

        logger.info(JWT)
        #expect(provider.lastMessage == "[REDACTED_JWT]")

        logger.warning(JWT)
        #expect(provider.lastMessage == "[REDACTED_JWT]")

        logger.error(JWT)
        #expect(provider.lastMessage == "[REDACTED_JWT]")
    }
}
