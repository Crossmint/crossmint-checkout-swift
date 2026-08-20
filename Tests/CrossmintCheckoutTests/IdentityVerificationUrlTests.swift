//
//  IdentityVerificationUrlTests.swift
//  CrossmintCheckoutTests
//
//  Created by Tomás Martins on 8/17/26.
//

import Foundation
import Testing
@testable import CrossmintCheckout

@MainActor
@Test func verificationUrlContainsStagingDomain() throws {
    let verification = CrossmintIdentityVerification(
        apiKey: "ck_test",
        credentials: IdentityVerificationCredentials(inquiryId: "inq-123"),
        environment: .staging
    )

    let url = try verification.generateVerificationUrl()
    #expect(url.contains("https://staging.crossmint.com/sdk/unstable/identity-verification"))
}

@MainActor
@Test func verificationUrlContainsProductionDomain() throws {
    let verification = CrossmintIdentityVerification(
        apiKey: "ck_test",
        credentials: IdentityVerificationCredentials(inquiryId: "inq-123"),
        environment: .production
    )

    let url = try verification.generateVerificationUrl()
    #expect(url.contains("https://www.crossmint.com/sdk/unstable/identity-verification"))
}

@MainActor
@Test func credentialsParamContainsProviderAndInquiryId() throws {
    let verification = CrossmintIdentityVerification(
        apiKey: "ck_test",
        credentials: IdentityVerificationCredentials(inquiryId: "inq-123"),
        environment: .staging
    )

    let url = try verification.generateVerificationUrl()
    #expect(url.contains("credentials="))
    #expect(url.contains("persona"))
    #expect(url.contains("inq-123"))
}

@MainActor
@Test func sessionTokenIncludedWhenPresent() throws {
    let json = try IdentityVerificationCredentials(inquiryId: "inq-123", sessionToken: "tok-456").toJSON()
    #expect(json.contains("\"sessionToken\":\"tok-456\""))
}

@MainActor
@Test func sessionTokenOmittedWhenNil() throws {
    let json = try IdentityVerificationCredentials(inquiryId: "inq-123").toJSON()
    #expect(!json.contains("sessionToken"))
}

@MainActor
@Test func sessionTokenOmittedWhenEmpty() throws {
    let json = try IdentityVerificationCredentials(inquiryId: "inq-123", sessionToken: "").toJSON()
    #expect(!json.contains("sessionToken"))
}

@MainActor
@Test func localeIncludedWhenSet() throws {
    let verification = CrossmintIdentityVerification(
        apiKey: "ck_test",
        credentials: IdentityVerificationCredentials(inquiryId: "inq-123"),
        locale: .esES,
        environment: .staging
    )

    let url = try verification.generateVerificationUrl()
    #expect(url.contains("locale=es-ES"))
}

@MainActor
@Test func localeOmittedByDefault() throws {
    let verification = CrossmintIdentityVerification(
        apiKey: "ck_test",
        credentials: IdentityVerificationCredentials(inquiryId: "inq-123"),
        environment: .staging
    )

    let url = try verification.generateVerificationUrl()
    #expect(!url.contains("locale="))
}

@MainActor
@Test func verificationUrlContainsApiKeyAndSdkMetadata() throws {
    let verification = CrossmintIdentityVerification(
        apiKey: "ck_staging_abc",
        credentials: IdentityVerificationCredentials(inquiryId: "inq-123"),
        environment: .staging
    )

    let url = try verification.generateVerificationUrl()
    #expect(url.contains("apiKey=ck_staging_abc"))
    #expect(url.contains("sdkMetadata"))
    #expect(url.contains("checkout-swift"))
}

@MainActor
@Test func verificationEmptyApiKeyThrows() throws {
    let verification = CrossmintIdentityVerification(
        apiKey: "",
        credentials: IdentityVerificationCredentials(inquiryId: "inq-123"),
        environment: .staging
    )

    #expect(throws: CheckoutError.self) {
        try verification.generateVerificationUrl()
    }
}

@MainActor
@Test func credentialsDecodeRejectsUnknownProvider() throws {
    let json = Data(#"{"provider":"other","inquiryId":"inq-123"}"#.utf8)
    #expect(throws: DecodingError.self) {
        try JSONDecoder().decode(IdentityVerificationCredentials.self, from: json)
    }
}

@MainActor
@Test func credentialsDecodeIgnoresEnvironmentIdAndUnknownKeys() throws {
    let json = Data(#"{"provider":"persona","inquiryId":"inq-123","sessionToken":"tok-1","environmentId":null,"future":42}"#.utf8)
    let credentials = try JSONDecoder().decode(IdentityVerificationCredentials.self, from: json)
    #expect(credentials.inquiryId == "inq-123")
    #expect(credentials.sessionToken == "tok-1")
}

@MainActor
@Test func verificationUrlIsStableAcrossGenerations() throws {
    let verification = CrossmintIdentityVerification(
        apiKey: "ck_test",
        credentials: IdentityVerificationCredentials(inquiryId: "inq-123", sessionToken: "tok-1"),
        locale: .enUS,
        environment: .staging
    )
    let first = try verification.generateVerificationUrl()
    for _ in 0..<20 {
        #expect(try verification.generateVerificationUrl() == first)
    }
}
