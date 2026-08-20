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
        navigationPolicy: .permissive,
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
        navigationPolicy: .permissive,
        onLoadFailure: { messages.append($0) }
    )
    let coordinator = HostedWebView.Coordinator(host: host)
    let webView = WKWebView()
    coordinator.webView(webView, didFailProvisionalNavigation: nil, withError: NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled))
    #expect(messages.isEmpty)
}
