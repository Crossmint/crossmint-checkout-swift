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
        apiKey: "ck_staging_test",
        credentials: IdentityVerificationCredentials(inquiryId: "inq-123")
    )

    let url = try verification.generateVerificationUrl()
    #expect(url.contains("https://staging.crossmint.com/sdk/unstable/identity-verification"))
}

@MainActor
@Test func verificationUrlContainsProductionDomain() throws {
    let verification = CrossmintIdentityVerification(
        apiKey: "ck_production_test",
        credentials: IdentityVerificationCredentials(inquiryId: "inq-123")
    )

    let url = try verification.generateVerificationUrl()
    #expect(url.contains("https://www.crossmint.com/sdk/unstable/identity-verification"))
}

@MainActor
@Test func credentialsParamContainsProviderAndInquiryId() throws {
    let verification = CrossmintIdentityVerification(
        apiKey: "ck_staging_test",
        credentials: IdentityVerificationCredentials(inquiryId: "inq-123")
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
        apiKey: "ck_staging_test",
        credentials: IdentityVerificationCredentials(inquiryId: "inq-123"),
        locale: .esES
    )

    let url = try verification.generateVerificationUrl()
    #expect(url.contains("locale=es-ES"))
}

@MainActor
@Test func localeOmittedByDefault() throws {
    let verification = CrossmintIdentityVerification(
        apiKey: "ck_staging_test",
        credentials: IdentityVerificationCredentials(inquiryId: "inq-123")
    )

    let url = try verification.generateVerificationUrl()
    #expect(!url.contains("locale="))
}

@MainActor
@Test func verificationUrlContainsApiKeyAndSdkMetadata() throws {
    let verification = CrossmintIdentityVerification(
        apiKey: "ck_staging_abc",
        credentials: IdentityVerificationCredentials(inquiryId: "inq-123")
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
        credentials: IdentityVerificationCredentials(inquiryId: "inq-123")
    )

    #expect(throws: CheckoutError.missingAPIKey) {
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
        apiKey: "ck_staging_test",
        credentials: IdentityVerificationCredentials(inquiryId: "inq-123", sessionToken: "tok-1"),
        locale: .enUS
    )
    let first = try verification.generateVerificationUrl()
    for _ in 0..<20 {
        #expect(try verification.generateVerificationUrl() == first)
    }
}

@MainActor
@Test func credentialsIdentityIsTheInquiryId() throws {
    #expect(IdentityVerificationCredentials(inquiryId: "inq-123").id == "inq-123")
}

private func decodeCredentials(_ json: String) throws -> IdentityVerificationCredentials {
    try JSONDecoder().decode(IdentityVerificationCredentials.self, from: Data(json.utf8))
}

@MainActor
@Test func credentialsDecodeTheSessionShape() throws {
    let credentials = try decodeCredentials(#"{"verificationId":"ver-1","clientSecret":"cs-1","deviceSessionKey":"dsk-1"}"#)
    #expect(credentials == IdentityVerificationCredentials(verificationId: "ver-1", clientSecret: "cs-1", deviceSessionKey: "dsk-1"))
    #expect(credentials.id == "ver-1")
    #expect(credentials.inquiryId == nil)
    #expect(credentials.sessionToken == nil)
    #expect(credentials.provider == nil)
}

@MainActor
@Test func credentialsDecodeAnEmptyDeviceSessionKeyAsAbsent() throws {
    let credentials = try decodeCredentials(#"{"verificationId":"ver-1","clientSecret":"cs-1","deviceSessionKey":""}"#)
    #expect(credentials == IdentityVerificationCredentials(verificationId: "ver-1", clientSecret: "cs-1"))
    #expect(try decodeCredentials(#"{"verificationId":"ver-1","clientSecret":"cs-1","deviceSessionKey":5}"#)
        == IdentityVerificationCredentials(verificationId: "ver-1", clientSecret: "cs-1"))
}

@MainActor
@Test func credentialsDecodeThePersonaShapeUnchanged() throws {
    let credentials = try decodeCredentials(#"{"provider":"persona","inquiryId":"inq-1","sessionToken":""}"#)
    #expect(credentials == IdentityVerificationCredentials(inquiryId: "inq-1"))
    #expect(credentials.provider == "persona")
}

@MainActor
@Test func credentialsDecodePrefersACompleteSession() throws {
    #expect(try decodeCredentials(#"{"verificationId":"ver-1","clientSecret":"cs-1","provider":"persona","inquiryId":"inq-1"}"#)
        == IdentityVerificationCredentials(verificationId: "ver-1", clientSecret: "cs-1"))
}

@MainActor
@Test func credentialsDecodeFallsBackToPersonaForAnIncompleteSession() throws {
    #expect(try decodeCredentials(#"{"verificationId":"ver-1","clientSecret":"","provider":"persona","inquiryId":"inq-1"}"#)
        == IdentityVerificationCredentials(inquiryId: "inq-1"))
}

@MainActor
@Test(arguments: [
    #"{}"#,
    #"{"verificationId":"ver-1"}"#,
    #"{"verificationId":"ver-1","clientSecret":""}"#,
    #"{"verificationId":"","clientSecret":"cs-1"}"#,
    #"{"verificationId":1,"clientSecret":"cs-1"}"#,
    #"{"provider":"persona"}"#
])
func credentialsDecodeRejectsIncompleteShapes(json: String) {
    #expect(throws: DecodingError.self) {
        try decodeCredentials(json)
    }
}

@MainActor
@Test func credentialsEncodeEachShapeForTheHostedPage() throws {
    #expect(try IdentityVerificationCredentials(inquiryId: "inq-1", sessionToken: "tok-1").toJSON()
        == #"{"inquiryId":"inq-1","provider":"persona","sessionToken":"tok-1"}"#)
    #expect(try IdentityVerificationCredentials(verificationId: "ver-1", clientSecret: "cs-1", deviceSessionKey: "dsk-1").toJSON()
        == #"{"clientSecret":"cs-1","deviceSessionKey":"dsk-1","verificationId":"ver-1"}"#)
    #expect(try IdentityVerificationCredentials(verificationId: "ver-1", clientSecret: "cs-1", deviceSessionKey: "").toJSON()
        == #"{"clientSecret":"cs-1","verificationId":"ver-1"}"#)
}

@MainActor
@Test func verificationUrlCarriesSessionCredentials() throws {
    let verification = CrossmintIdentityVerification(
        apiKey: "ck_staging_test",
        credentials: IdentityVerificationCredentials(verificationId: "ver-1", clientSecret: "cs-1")
    )

    let components = try #require(URLComponents(string: try verification.generateVerificationUrl()))
    let credentials = components.queryItems?.first { $0.name == "credentials" }?.value
    #expect(credentials == #"{"clientSecret":"cs-1","verificationId":"ver-1"}"#)
}

@MainActor
@Test func sessionCredentialsCompareEveryField() throws {
    let credentials = IdentityVerificationCredentials(verificationId: "ver-1", clientSecret: "cs-1")
    let rotated = IdentityVerificationCredentials(verificationId: "ver-1", clientSecret: "cs-2")

    #expect(rotated.id == credentials.id)
    #expect(rotated != credentials)
    #expect(IdentityVerificationCredentials(verificationId: "ver-1", clientSecret: "cs-1", deviceSessionKey: "dsk-1") != credentials)
    #expect(IdentityVerificationCredentials(inquiryId: "ver-1") != credentials)
}

@MainActor
@Test func developmentKeyCollapsesToStaging() throws {
    let verification = CrossmintIdentityVerification(
        apiKey: "ck_development_test",
        credentials: IdentityVerificationCredentials(inquiryId: "inq-123")
    )
    let url = try verification.generateVerificationUrl()
    #expect(url.contains("https://staging.crossmint.com/"))
}

@MainActor
@Test func malformedApiKeyThrows() throws {
    let verification = CrossmintIdentityVerification(
        apiKey: "not-a-crossmint-key",
        credentials: IdentityVerificationCredentials(inquiryId: "inq-123")
    )
    #expect(throws: CheckoutError.malformedAPIKey) {
        try verification.generateVerificationUrl()
    }
}
