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
    @Test func redactsSecretsInsideBridgeJson() {
        let message = """
        {"event":"order:updated","data":{"order":{"orderId":"order-1","payment":{"preparation":{"kyc":\
        {"inquiryId":"inq-1","sessionToken":"\(SESSION_TOKEN)"}}}},"orderClientSecret":"\(CLIENT_SECRET)"}}
        """

        let scrubbed = CredentialScrubber.scrub(message)

        #expect(!scrubbed.contains(CLIENT_SECRET))
        #expect(!scrubbed.contains(SESSION_TOKEN))
        #expect(scrubbed.contains("order-1"))
        #expect(scrubbed.contains("inq-1"))
    }

    @Test func redactsQueryParametersFromHostedPageUrls() {
        let url = "https://staging.crossmint.com/sdk/2024-03-05/embedded-checkout?orderId=order-1"
            + "&apiKey=\(API_KEY)&clientSecret=\(CLIENT_SECRET)"
            + "&credentials=%7B%22sessionToken%22%3A%22\(SESSION_TOKEN)%22%7D&locale=en-US"

        let scrubbed = CredentialScrubber.scrub(url)

        #expect(!scrubbed.contains(API_KEY))
        #expect(!scrubbed.contains(CLIENT_SECRET))
        #expect(!scrubbed.contains(SESSION_TOKEN))
        #expect(scrubbed.contains("orderId=order-1"))
        #expect(scrubbed.contains("locale=en-US"))
    }

    @Test(arguments: [
        "ck_development_notARealApiKeyJustTestData01",
        "ck_staging_notARealApiKeyJustTestData01",
        "ck_production_notARealApiKeyJustTestData01",
        "sk_production_notARealApiKeyJustTestData01"
    ])
    func redactsEveryApiKeyPrefix(key: String) {
        #expect(!CredentialScrubber.scrub("key=\(key)").contains(key))
    }

    @Test func redactsCredentialsOutsideJsonContainers() {
        let scrubbed = CredentialScrubber.scrub("refreshed token=\(JWT) using \(API_KEY)")

        #expect(scrubbed == "refreshed token=[REDACTED_JWT] using [REDACTED_API_KEY]")
    }

    @Test func leavesMessagesWithoutCredentialsIntact() {
        let message = #"{"event":"kyc:completed","data":{"status":"approved"}}"#

        #expect(CredentialScrubber.scrub(message) == message)
    }

    @Test func scrubsMessageAndAttributesReachingProviders() {
        let provider = MockLoggerProvider()
        let logger = Logger(providers: [provider])

        logger.error("load failed for \(API_KEY)", attributes: ["context": "key \(API_KEY)"])

        #expect(provider.lastMessage == "load failed for [REDACTED_API_KEY]")
        #expect(provider.lastAttributes?["context"] == "key [REDACTED_API_KEY]")
    }

    @Test func compilesEveryPattern() {
        #expect(CredentialScrubber.patterns.count == 4)
    }
}
