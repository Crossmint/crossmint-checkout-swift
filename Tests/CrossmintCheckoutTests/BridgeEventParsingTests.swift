//
//  BridgeEventParsingTests.swift
//  CrossmintCheckoutTests
//
//  Created by Tomás Martins on 8/17/26.
//

import Testing
@testable import CrossmintCheckout

@MainActor
@Test func parsesHeightChangedFromIntAndDouble() throws {
    guard case .heightChanged(let intHeight)? = IdentityVerificationEvent(messageBody: #"{"event":"ui:height.changed","data":{"height":660}}"#) else {
        Issue.record("expected heightChanged")
        return
    }
    #expect(intHeight == 660)

    guard case .heightChanged(let doubleHeight)? = IdentityVerificationEvent(messageBody: #"{"event":"ui:height.changed","data":{"height":660.5}}"#) else {
        Issue.record("expected heightChanged")
        return
    }
    #expect(doubleHeight == 660.5)
}

@MainActor
@Test func ignoresHeightChangedWithoutNumericHeight() throws {
    #expect(IdentityVerificationEvent(messageBody: #"{"event":"ui:height.changed","data":{}}"#) == nil)
    #expect(IdentityVerificationEvent(messageBody: #"{"event":"ui:height.changed","data":{"height":"tall"}}"#) == nil)
}

@MainActor
@Test func parsesKycReady() throws {
    guard case .ready? = IdentityVerificationEvent(messageBody: #"{"event":"kyc:ready","data":{}}"#) else {
        Issue.record("expected ready")
        return
    }
}

@MainActor
@Test func parsesKycReadyWithoutData() throws {
    guard case .ready? = IdentityVerificationEvent(messageBody: #"{"event":"kyc:ready"}"#) else {
        Issue.record("expected ready")
        return
    }
}

@MainActor
@Test func parsesKycCompletedEachStatus() throws {
    let statuses: [(String, IdentityVerificationStatus)] = [
        ("verified", .verified),
        ("pending-review", .pendingReview),
        ("pending-manual-review", .pendingManualReview),
        ("declined", .declined),
        ("expired", .expired),
        ("failed", .failed),
        ("unknown", .unknown)
    ]
    for (wire, expected) in statuses {
        guard case .completed(let status)? = IdentityVerificationEvent(messageBody: #"{"event":"kyc:completed","data":{"status":"\#(wire)"}}"#) else {
            Issue.record("expected completed for \(wire)")
            return
        }
        #expect(status == expected)
    }
}

@MainActor
@Test func unknownStatusFallsBackToUnknown() throws {
    guard case .completed(let status)? = IdentityVerificationEvent(messageBody: #"{"event":"kyc:completed","data":{"status":"a-future-status"}}"#) else {
        Issue.record("expected completed")
        return
    }
    #expect(status == .unknown)
}

@MainActor
@Test func parsesKycCancelled() throws {
    guard case .cancelled? = IdentityVerificationEvent(messageBody: #"{"event":"kyc:cancelled","data":{}}"#) else {
        Issue.record("expected cancelled")
        return
    }
}

@MainActor
@Test func parsesKycErrorEachReason() throws {
    let reasons: [(String, IdentityVerificationError.Reason)] = [
        ("widget-unavailable", .widgetUnavailable),
        ("invalid-configuration", .invalidConfiguration),
        ("invalid-credentials", .invalidCredentials),
        ("provider-error", .providerError),
        ("unknown", .unknown)
    ]
    for (wire, expected) in reasons {
        let raw = #"{"event":"kyc:error","data":{"retriable":true,"reason":"\#(wire)","message":"boom"}}"#
        guard case .failed(let error)? = IdentityVerificationEvent(messageBody: raw) else {
            Issue.record("expected failed for \(wire)")
            return
        }
        #expect(error.reason == expected)
        #expect(error.retriable)
        #expect(error.message == "boom")
    }
}

@MainActor
@Test func unknownReasonFallsBackToUnknown() throws {
    guard case .failed(let error)? = IdentityVerificationEvent(messageBody: #"{"event":"kyc:error","data":{"retriable":false,"reason":"a-future-reason","message":"m"}}"#) else {
        Issue.record("expected failed")
        return
    }
    #expect(error.reason == .unknown)
    #expect(!error.retriable)
}

@MainActor
@Test func missingErrorFieldsUseSafeDefaults() throws {
    guard case .failed(let error)? = IdentityVerificationEvent(messageBody: #"{"event":"kyc:error","data":{}}"#) else {
        Issue.record("expected failed")
        return
    }
    #expect(!error.retriable)
    #expect(error.reason == .unknown)
    #expect(error.message.isEmpty)
}

@MainActor
@Test func ignoresFrameReadyBareString() throws {
    #expect(IdentityVerificationEvent(messageBody: "frame-ready") == nil)
    #expect(CheckoutEvent(messageBody: "frame-ready") == nil)
}

@MainActor
@Test func ignoresConsoleEnvelope() throws {
    #expect(IdentityVerificationEvent(messageBody: #"{"type":"console.log","data":["hello"]}"#) == nil)
    #expect(CheckoutEvent(messageBody: #"{"type":"console.log","data":["hello"]}"#) == nil)
}

@MainActor
@Test func ignoresMalformedJsonAndNonStringBodies() throws {
    #expect(IdentityVerificationEvent(messageBody: #"{"event":"#) == nil)
    #expect(IdentityVerificationEvent(messageBody: 42) == nil)
    #expect(IdentityVerificationEvent(messageBody: ["event": "kyc:ready"]) == nil)
}

@MainActor
@Test func ignoresUnknownEvent() throws {
    #expect(IdentityVerificationEvent(messageBody: #"{"event":"kyc:launched","data":{}}"#) == nil)
    #expect(CheckoutEvent(messageBody: #"{"event":"kyc:launched","data":{}}"#) == nil)
}

@MainActor
@Test func toleratesExtraKeys() throws {
    let raw = #"{"event":"kyc:completed","data":{"status":"verified","attempt":2},"origin":"page"}"#
    guard case .completed(let status)? = IdentityVerificationEvent(messageBody: raw) else {
        Issue.record("expected completed")
        return
    }
    #expect(status == .verified)
}

@MainActor
@Test func mapsCryptoEventsToCryptoRequests() throws {
    guard case .cryptoRequest(.load)? = CheckoutEvent(messageBody: #"{"event":"crypto:load","data":{}}"#) else {
        Issue.record("expected load")
        return
    }
    guard case .cryptoRequest(.connectWalletShow(true))? = CheckoutEvent(messageBody: #"{"event":"crypto:connect-wallet.show","data":{"show":true}}"#) else {
        Issue.record("expected connectWalletShow(true)")
        return
    }
    guard case .cryptoRequest(.connectWalletShow(false))? = CheckoutEvent(messageBody: #"{"event":"crypto:connect-wallet.show","data":{"show":false}}"#) else {
        Issue.record("expected connectWalletShow(false)")
        return
    }
    guard case .cryptoRequest(.sendTransaction)? = CheckoutEvent(messageBody: #"{"event":"crypto:send-transaction","data":{"chain":"base","serializedTransaction":"0x"}}"#) else {
        Issue.record("expected sendTransaction")
        return
    }
    guard case .cryptoRequest(.signMessage)? = CheckoutEvent(messageBody: #"{"event":"crypto:sign-message","data":{"message":"m"}}"#) else {
        Issue.record("expected signMessage")
        return
    }
}

@MainActor
@Test func noPayerRepliesMatchThePageEventMap() throws {
    #expect(CryptoRequest.load.noPayerReply == BridgeReply(event: "crypto:load.success", error: nil))
    #expect(CryptoRequest.connectWalletShow(false).noPayerReply == nil)
    #expect(CryptoRequest.connectWalletShow(true).noPayerReply == BridgeReply(event: "crypto:connect-wallet.failed", error: "No payer configured"))
    #expect(CryptoRequest.sendTransaction.noPayerReply == BridgeReply(event: "crypto:send-transaction:failed", error: "No payer configured"))
    #expect(CryptoRequest.signMessage.noPayerReply == BridgeReply(event: "crypto:sign-message:failed", error: "No payer configured"))
}

@MainActor
@Test func replyScriptEmbedsValidJson() throws {
    let script = try #require(BridgeResponder.script(for: BridgeReply(event: "crypto:load.success", error: nil)))
    #expect(script.contains(#"{"data":{},"event":"crypto:load.success"}"#))
    #expect(script.contains("JSON.stringify(message)"))
}

@MainActor
@Test func replyScriptEscapesErrorTextThroughJsonEncoding() throws {
    let script = try #require(BridgeResponder.script(for: BridgeReply(event: "crypto:sign-message:failed", error: "it's\nbroken")))
    #expect(!script.contains("it's\nbroken"))
    #expect(script.contains(#"it's\nbroken"#))
}
