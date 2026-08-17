//
//  BridgeEventParsingTests.swift
//  CrossmintCheckoutTests
//
//  Created by Tomás Martins on 8/17/26.
//

import Testing
@testable import CrossmintCheckout

private func identityEvent(_ raw: String) -> IdentityVerificationEvent? {
    guard let envelope = WebViewBridge.parse(raw) else { return nil }
    return IdentityVerificationEvent(envelope: envelope)
}

@MainActor
@Test func parsesHeightChangedFromIntAndDouble() throws {
    guard case .heightChanged(let intHeight)? = identityEvent(#"{"event":"ui:height.changed","data":{"height":660}}"#) else {
        Issue.record("expected heightChanged")
        return
    }
    #expect(intHeight == 660)

    guard case .heightChanged(let doubleHeight)? = identityEvent(#"{"event":"ui:height.changed","data":{"height":660.5}}"#) else {
        Issue.record("expected heightChanged")
        return
    }
    #expect(doubleHeight == 660.5)
}

@MainActor
@Test func ignoresHeightChangedWithoutNumericHeight() throws {
    #expect(identityEvent(#"{"event":"ui:height.changed","data":{}}"#) == nil)
    #expect(identityEvent(#"{"event":"ui:height.changed","data":{"height":"tall"}}"#) == nil)
}

@MainActor
@Test func parsesKycReady() throws {
    guard case .ready? = identityEvent(#"{"event":"kyc:ready","data":{}}"#) else {
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
        guard case .completed(let status)? = identityEvent(#"{"event":"kyc:completed","data":{"status":"\#(wire)"}}"#) else {
            Issue.record("expected completed for \(wire)")
            return
        }
        #expect(status == expected)
    }
}

@MainActor
@Test func unknownStatusFallsBackToUnknown() throws {
    guard case .completed(let status)? = identityEvent(#"{"event":"kyc:completed","data":{"status":"a-future-status"}}"#) else {
        Issue.record("expected completed")
        return
    }
    #expect(status == .unknown)
}

@MainActor
@Test func parsesKycCancelled() throws {
    guard case .cancelled? = identityEvent(#"{"event":"kyc:cancelled","data":{}}"#) else {
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
        guard case .failed(let error)? = identityEvent(raw) else {
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
    guard case .failed(let error)? = identityEvent(#"{"event":"kyc:error","data":{"retriable":false,"reason":"a-future-reason","message":"m"}}"#) else {
        Issue.record("expected failed")
        return
    }
    #expect(error.reason == .unknown)
    #expect(!error.retriable)
}

@MainActor
@Test func missingErrorFieldsUseSafeDefaults() throws {
    guard case .failed(let error)? = identityEvent(#"{"event":"kyc:error","data":{}}"#) else {
        Issue.record("expected failed")
        return
    }
    #expect(!error.retriable)
    #expect(error.reason == .unknown)
    #expect(error.message.isEmpty)
}

@MainActor
@Test func ignoresFrameReadyBareString() throws {
    #expect(WebViewBridge.parse("frame-ready") == nil)
}

@MainActor
@Test func ignoresConsoleEnvelope() throws {
    #expect(WebViewBridge.parse(#"{"type":"console.log","data":["hello"]}"#) == nil)
}

@MainActor
@Test func ignoresMalformedJsonAndNonStringBodies() throws {
    #expect(WebViewBridge.parse(#"{"event":"#) == nil)
    #expect(WebViewBridge.parse(42) == nil)
    #expect(WebViewBridge.parse(["event": "kyc:ready"]) == nil)
}

@MainActor
@Test func ignoresUnknownEvent() throws {
    #expect(identityEvent(#"{"event":"kyc:launched","data":{}}"#) == nil)
}

@MainActor
@Test func toleratesExtraKeys() throws {
    let raw = #"{"event":"kyc:completed","data":{"status":"verified","attempt":2},"origin":"page"}"#
    guard case .completed(let status)? = identityEvent(raw) else {
        Issue.record("expected completed")
        return
    }
    #expect(status == .verified)
}

@MainActor
@Test func missingDataDefaultsToEmpty() throws {
    let envelope = try #require(WebViewBridge.parse(#"{"event":"kyc:ready"}"#))
    #expect(envelope.data.isEmpty)
}

@MainActor
@Test func mapsCryptoEventsToCryptoRequests() throws {
    func checkoutEvent(_ raw: String) -> CheckoutEvent? {
        guard let envelope = WebViewBridge.parse(raw) else { return nil }
        return CheckoutEvent(envelope: envelope)
    }

    guard case .cryptoRequest(.load)? = checkoutEvent(#"{"event":"crypto:load","data":{}}"#) else {
        Issue.record("expected load")
        return
    }
    guard case .cryptoRequest(.connectWalletShow(true))? = checkoutEvent(#"{"event":"crypto:connect-wallet.show","data":{"show":true}}"#) else {
        Issue.record("expected connectWalletShow(true)")
        return
    }
    guard case .cryptoRequest(.connectWalletShow(false))? = checkoutEvent(#"{"event":"crypto:connect-wallet.show","data":{"show":false}}"#) else {
        Issue.record("expected connectWalletShow(false)")
        return
    }
    guard case .cryptoRequest(.sendTransaction)? = checkoutEvent(#"{"event":"crypto:send-transaction","data":{"chain":"base","serializedTransaction":"0x"}}"#) else {
        Issue.record("expected sendTransaction")
        return
    }
    guard case .cryptoRequest(.signMessage)? = checkoutEvent(#"{"event":"crypto:sign-message","data":{"message":"m"}}"#) else {
        Issue.record("expected signMessage")
        return
    }
}

@MainActor
@Test func dispatchScriptEscapesSingleQuotesAndNewlines() throws {
    let script = try WebViewBridge.dispatchScript(event: "crypto:load.success", data: ["error": "it's\nbroken"])
    #expect(script.contains("crypto:load.success"))
    #expect(script.contains(#"\'"#) || !script.contains("it's"))
    #expect(!script.contains("it's\nbroken"))
}
