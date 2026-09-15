//
//  EventLoggingTests.swift
//  CrossmintCheckoutTests
//
//  Created by Tomás Martins on 9/14/26.
//

import Foundation
import Testing
import WebKit
@testable import CrossmintCheckout

@MainActor
@Suite(.serialized)
final class EventLoggingTests {
    private let saved = Logger.checkout
    private let spy = MockLoggerProvider()

    init() {
        Logger.checkout = Logger(providers: [spy])
    }

    deinit {
        Logger.checkout = saved
    }

    private func makeCoordinator() -> HostedWebView.Coordinator {
        let host = HostedWebView(
            url: "https://staging.crossmint.com/sdk/unstable/identity-verification",
            navigationPolicy: .crossmintMainFrame(resolvedHost: "staging.crossmint.com"),
            logAttributes: ["surface": "identity-verification"]
        )
        return HostedWebView.Coordinator(host: host)
    }

    @Test(arguments: [
        (NSURLErrorNotConnectedToInternet, LogEvents.webviewLoadError, CheckoutLogLevel.error),
        (NSURLErrorCancelled, LogEvents.webviewLoadCancelled, .debug)
    ])
    func loadFailureLogsByErrorCode(code: Int, event: String, level: CheckoutLogLevel) {
        let failure = NSError(domain: NSURLErrorDomain, code: code)
        makeCoordinator().webView(WKWebView(), didFailProvisionalNavigation: nil, withError: failure)

        let entry = spy.entry(event)
        #expect(entry?.level == level)
        #expect(entry?.attributes?["errorCode"] == String(code))
        #expect(entry?.attributes?["surface"] == "identity-verification")
        #expect(spy.entries.count == 1)
    }

    @Test func loadSuccessLogsTheDuration() {
        let coordinator = makeCoordinator()
        let webView = WKWebView()
        coordinator.load("https://staging.crossmint.com/sdk/unstable/identity-verification", in: webView)
        coordinator.webView(webView, didFinish: nil)

        let entry = spy.entry(LogEvents.webviewLoadSuccess)
        #expect(entry?.level == .info)
        #expect(entry?.attributes?["durationMs"].flatMap(Int.init) != nil)
    }

    @Test func terminatedContentProcessLogsAnError() {
        makeCoordinator().webViewWebContentProcessDidTerminate(WKWebView())

        #expect(spy.entry(LogEvents.webviewProcessTerminated)?.level == .error)
    }

    @Test func orderUpdateLogsTheOrderSummary() {
        let checkout = CrossmintEmbeddedCheckout(apiKey: "ck_staging_test")
        checkout.handle(#"{"event":"order:updated","data":{"order":{"orderId":"o-2","phase":"payment","payment":{"status":"requires-kyc"}},"orderClientSecret":"cs"}}"#, BridgeResponder())
        checkout.handle(#"{"event":"order:updated","data":{"orderClientSecret":"cs"}}"#, BridgeResponder())

        #expect(spy.entry(LogEvents.orderUpdated)?.attributes == [
            "orderId": "o-2", "phase": "payment", "paymentStatus": "requires-kyc", "requiresKyc": "false", "hasClientSecret": "true"
        ])
        #expect(spy.entry(LogEvents.orderUpdatedEmpty)?.level == .warning)
    }

    @Test(arguments: [
        (#"{"event":"kyc:ready"}"#, LogEvents.identityReady, CheckoutLogLevel.info, "inquiryId", "inq-1"),
        (#"{"event":"kyc:completed","data":{"status":"verified"}}"#, LogEvents.identityCompleted, .info, "status", "verified"),
        (#"{"event":"kyc:cancelled"}"#, LogEvents.identityCancelled, .info, "inquiryId", "inq-1"),
        (#"{"event":"kyc:error","data":{"retriable":true,"reason":"provider-error","message":"boom"}}"#, LogEvents.identityError, .error, "reason", "provider-error")
    ])
    func identityEventsLog(raw: String, event: String, level: CheckoutLogLevel, key: String, value: String) {
        let credentials = IdentityVerificationCredentials(inquiryId: "inq-1")
        CrossmintIdentityVerification(apiKey: "ck_staging_test", credentials: credentials).handle(raw)

        let entry = spy.entry(event)
        #expect(entry?.level == level)
        #expect(entry?.attributes?[key] == value)
    }

    @Test func loadStartLogsHostAndPathWithoutQuery() {
        makeCoordinator().load("https://staging.crossmint.com/sdk/unstable/identity-verification?apiKey=ck_staging_secret", in: WKWebView())

        let entry = spy.entry(LogEvents.webviewLoadStart)
        #expect(entry?.level == .info)
        #expect(entry?.attributes?["host"] == "staging.crossmint.com")
        #expect(entry?.attributes?["path"] == "/sdk/unstable/identity-verification")
        #expect(entry?.attributes?.values.contains { $0.contains("apiKey") } == false)
    }

    @Test func undecodablePayloadLogsTheEventName() {
        #expect(CheckoutEvent(messageBody: #"{"event":"order:creation-failed","data":{"errorMessage":5}}"#) == nil)

        let entry = spy.entry(LogEvents.bridgeInboundDecodeError)
        #expect(entry?.level == .error)
        #expect(entry?.attributes?["event"] == "order:creation-failed")
    }

    @Test func controllerLogsPhaseAndKycTransitionsOnce() throws {
        let controller = CrossmintCheckoutController()
        let update = try orderUpdate(#"{"event":"order:updated","data":{"order":{"orderId":"o-1","phase":"payment","payment":{"status":"requires-kyc","preparation":{"kyc":{"provider":"persona","inquiryId":"inq-1","sessionToken":"tok"}}}}}}"#)

        controller.handle(update)
        controller.handle(update)

        #expect(spy.entries.filter { $0.message == LogEvents.orderPhaseChanged }.count == 1)
        #expect(spy.entries.filter { $0.message == LogEvents.orderKycRequired }.count == 1)
        #expect(spy.entry(LogEvents.orderPhaseChanged)?.attributes == ["orderId": "o-1", "from": "", "to": "payment"])
        #expect(spy.entry(LogEvents.orderKycRequired)?.attributes == ["orderId": "o-1", "inquiryId": "inq-1", "hasSessionToken": "true"])
    }

    @Test func replyWithoutWebViewLogsAWarning() {
        BridgeResponder().send(BridgeReply(event: "crypto:load.success", error: nil))

        let entry = spy.entry(LogEvents.bridgeOutboundDropped)
        #expect(entry?.level == .warning)
        #expect(entry?.attributes == ["event": "crypto:load.success", "reason": "no-web-view"])
    }
}
