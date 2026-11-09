//
//  HostedWebViewTests.swift
//  CrossmintCheckoutTests
//
//  Created by Tomás Martins on 8/20/26.
//

import Foundation
import Testing
import WebKit
@testable import CrossmintCheckout

@MainActor
@Test func loadFailureReachesTheCallbackOnce() throws {
    var messages: [String] = []
    let host = HostedWebView(
        url: "https://staging.crossmint.com/sdk/unstable/identity-verification",
        navigationPolicy: .crossmintMainFrame(resolvedHost: "staging.crossmint.com"),
        onLoadFailure: { messages.append($0) }
    )
    let coordinator = HostedWebView.Coordinator(host: host)
    let webView = WKWebView()
    let failure = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
    coordinator.webView(webView, didFailProvisionalNavigation: nil, withError: failure)
    coordinator.webView(webView, didFail: nil, withError: failure)
    #expect(messages == [failure.localizedDescription])
}

@MainActor
@Test func cancelledNavigationDoesNotReachTheCallback() throws {
    var messages: [String] = []
    let host = HostedWebView(
        url: "https://staging.crossmint.com/sdk/unstable/identity-verification",
        navigationPolicy: .crossmintMainFrame(resolvedHost: "staging.crossmint.com"),
        onLoadFailure: { messages.append($0) }
    )
    let coordinator = HostedWebView.Coordinator(host: host)
    let webView = WKWebView()
    coordinator.webView(webView, didFailProvisionalNavigation: nil, withError: NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled))
    #expect(messages.isEmpty)
}

@MainActor
private let IDENTITY_HOST = HostedWebView(
    url: "https://staging.crossmint.com/sdk/unstable/identity-verification",
    navigationPolicy: .crossmintMainFrame(resolvedHost: "staging.crossmint.com"),
    allowsMediaCapture: true
)

@MainActor
@Test(arguments: ["staging.crossmint.com", "crossmint.com", "withpersona.com", "inquiry.withpersona.com", "INQUIRY.WithPersona.com"])
func cameraGrantedToCrossmintAndPersona(host: String) {
    #expect(IDENTITY_HOST.mediaCaptureDecision(for: .camera, originProtocol: "https", originHost: host) == .grant)
}

@MainActor
@Test(arguments: ["evil.example.com", "notwithpersona.com", "withpersona.com.evil.example.com", "www.crossmint.com", ""])
func cameraPromptedForOtherHosts(host: String) {
    #expect(IDENTITY_HOST.mediaCaptureDecision(for: .camera, originProtocol: "https", originHost: host) == .prompt)
}

@MainActor
@Test func cameraPromptedForInsecureOrigin() {
    #expect(IDENTITY_HOST.mediaCaptureDecision(for: .camera, originProtocol: "http", originHost: "inquiry.withpersona.com") == .prompt)
}

@MainActor
@Test func microphonePromptedForTrustedHost() {
    #expect(IDENTITY_HOST.mediaCaptureDecision(for: .microphone, originProtocol: "https", originHost: "inquiry.withpersona.com") == .prompt)
    #expect(IDENTITY_HOST.mediaCaptureDecision(for: .cameraAndMicrophone, originProtocol: "https", originHost: "inquiry.withpersona.com") == .prompt)
}

@MainActor
@Test func cameraPromptedWhenMediaCaptureIsOff() {
    let checkout = HostedWebView(
        url: "https://www.crossmint.com/sdk/2024-03-05/embedded-checkout",
        navigationPolicy: .crossmintMainFrame(resolvedHost: "www.crossmint.com")
    )
    #expect(checkout.mediaCaptureDecision(for: .camera, originProtocol: "https", originHost: "www.crossmint.com") == .prompt)
}
