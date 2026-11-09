//
//  NavigationPolicyTests.swift
//  CrossmintCheckoutTests
//
//  Created by Tomás Martins on 8/17/26.
//

import Foundation
import Testing
@testable import CrossmintCheckout

private let IDENTITY_POLICY = NavigationPolicy.crossmintMainFrame(resolvedHost: "staging.crossmint.com")

private func url(_ string: String) throws -> URL {
    try #require(URL(string: string))
}

@MainActor
@Test func blocksUnsafeSchemes() throws {
    #expect(!IDENTITY_POLICY.allows(url: try url("javascript:alert(1)"), isMainFrame: true))
    #expect(!IDENTITY_POLICY.allows(url: try url("javascript:alert(1)"), isMainFrame: false))
    #expect(!IDENTITY_POLICY.allows(url: try url("file:///etc/passwd"), isMainFrame: true))
    #expect(!IDENTITY_POLICY.allows(url: try url("file:///etc/passwd"), isMainFrame: false))
}

@MainActor
@Test func mainFrameAllowedOnResolvedHostAndApexDomain() throws {
    #expect(IDENTITY_POLICY.allows(url: try url("https://staging.crossmint.com/sdk/unstable/identity-verification"), isMainFrame: true))
    #expect(IDENTITY_POLICY.allows(url: try url("https://crossmint.com/x"), isMainFrame: true))
}

@MainActor
@Test func mainFrameBlockedOnForeignHost() throws {
    #expect(!IDENTITY_POLICY.allows(url: try url("https://evil.example.com"), isMainFrame: true))
    #expect(!IDENTITY_POLICY.allows(url: try url("https://www.crossmint.com.evil.example.com"), isMainFrame: true))
}

@MainActor
@Test func mainFrameRequiresHttpScheme() throws {
    #expect(!IDENTITY_POLICY.allows(url: try url("ftp://staging.crossmint.com"), isMainFrame: true))
}

@MainActor
@Test func subFramesAllowedAnywhere() throws {
    #expect(IDENTITY_POLICY.allows(url: try url("https://inquiry.withpersona.com/verify"), isMainFrame: false))
}

@MainActor
@Test func checkoutPolicyBlocksForeignMainFramesButAllowsPaymentIframes() throws {
    let policy = NavigationPolicy.crossmintMainFrame(resolvedHost: "www.crossmint.com")
    #expect(!policy.allows(url: try url("https://pay.stripe.com/x"), isMainFrame: true))
    #expect(policy.allows(url: try url("https://pay.stripe.com/x"), isMainFrame: false))
    #expect(policy.allows(url: try url("https://www.crossmint.com/sdk/2024-03-05/embedded-checkout"), isMainFrame: true))
}

@MainActor
@Test func loadFailureGateFiresOnce() throws {
    var gate = LoadFailureGate()
    let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
    #expect(gate.reportOnce(for: error) != nil)
    #expect(gate.reportOnce(for: error) == nil)
    #expect(gate.reportOnce(forHTTPStatus: 500) == nil)
}

@MainActor
@Test func loadFailureGateIgnoresCancelledNavigation() throws {
    var gate = LoadFailureGate()
    let cancelled = NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled)
    #expect(gate.reportOnce(for: cancelled) == nil)
    #expect(gate.reportOnce(forHTTPStatus: 500) == "HTTP 500")
}

@MainActor
@Test func loadFailureGateIgnoresSuccessfulStatusCodes() throws {
    var gate = LoadFailureGate()
    #expect(gate.reportOnce(forHTTPStatus: 200) == nil)
    #expect(gate.reportOnce(forHTTPStatus: 302) == nil)
    #expect(gate.reportOnce(forHTTPStatus: 404) == "HTTP 404")
}

private let PAGE_URL = URL(string: "https://staging.crossmint.com/sdk/unstable/embedded-offramp?apiKey=ck_staging_x")!
private let PAGE_POLICY = NavigationPolicy.page(PAGE_URL)

@MainActor
@Test(arguments: [
    "https://staging.crossmint.com/sdk/unstable/embedded-offramp",
    "https://staging.crossmint.com/sdk/unstable/embedded-offramp?step=bank",
    "https://STAGING.crossmint.com/sdk/unstable/embedded-offramp"
])
func pagePolicyKeepsTheMainFrameOnThePageWhateverItsQuery(page: String) throws {
    #expect(PAGE_POLICY.decision(for: try url(page), targetIsMainFrame: true, linkActivated: false) == .allow)
}

@MainActor
@Test(arguments: [
    "https://evil.example/sdk/unstable/embedded-offramp",
    "https://staging.crossmint.com/sdk/2024-03-05/embedded-checkout",
    "http://staging.crossmint.com/sdk/unstable/embedded-offramp",
    "https://staging.crossmint.com:8443/sdk/unstable/embedded-offramp",
    "https://user@staging.crossmint.com/sdk/unstable/embedded-offramp"
])
func pagePolicyBlocksOtherMainFramePagesTheUserDidNotTap(other: String) throws {
    #expect(PAGE_POLICY.decision(for: try url(other), targetIsMainFrame: true, linkActivated: false) == .cancel)
}

@MainActor
@Test(arguments: [
    ("https://terms.example/x", true),
    ("http://terms.example/x", true),
    ("mailto:help@terms.example", false),
    ("javascript:alert(1)", false),
    ("file:///etc/passwd", false)
])
func pagePolicyOpensWebLinksTheUserTapsInTheBrowser(link: String, opens: Bool) throws {
    let link = try url(link)
    #expect(PAGE_POLICY.decision(for: link, targetIsMainFrame: true, linkActivated: true) == (opens ? .openExternally(link) : .cancel))
}

@MainActor
@Test(arguments: [("https://terms.example/x", true), ("javascript:alert(1)", false)])
func pagePolicyOpensWebLinksForANewWindowInTheBrowser(link: String, opens: Bool) throws {
    let link = try url(link)
    #expect(PAGE_POLICY.decision(for: link, targetIsMainFrame: nil, linkActivated: false) == (opens ? .openExternally(link) : .cancel))
}

@MainActor
@Test(arguments: [("https://withpersona.com/verify", true), ("javascript:alert(1)", false), ("file:///etc/passwd", false)])
func pagePolicyAllowsFramesInsideThePageExceptUnsafeSchemes(frame: String, allowed: Bool) throws {
    #expect(PAGE_POLICY.decision(for: try url(frame), targetIsMainFrame: false, linkActivated: false) == (allowed ? .allow : .cancel))
}

@MainActor
@Test func crossmintPolicyNeverOpensANewWindowInTheBrowser() throws {
    #expect(IDENTITY_POLICY.decision(for: try url("https://terms.example/x"), targetIsMainFrame: nil, linkActivated: true) == .cancel)
    #expect(IDENTITY_POLICY.decision(for: try url("https://staging.crossmint.com/x"), targetIsMainFrame: nil, linkActivated: false) == .allow)
}

@MainActor
@Test func pagePolicyTrustsMessagesOnlyFromThePage() throws {
    #expect(PAGE_POLICY.trustsMessages(from: try url("https://staging.crossmint.com/sdk/unstable/embedded-offramp?a=1")))
    #expect(!PAGE_POLICY.trustsMessages(from: try url("https://evil.example/sdk/unstable/embedded-offramp")))
    #expect(!PAGE_POLICY.trustsMessages(from: try url("http://staging.crossmint.com/sdk/unstable/embedded-offramp")))
    #expect(!PAGE_POLICY.trustsMessages(from: try url("https://staging.crossmint.com/sdk/unstable/identity-verification")))
    #expect(!PAGE_POLICY.trustsMessages(from: nil))
    #expect(IDENTITY_POLICY.trustsMessages(from: nil))
}

@MainActor
@Test(arguments: [
    (PAGE_URL.absoluteString, true, true),
    (PAGE_URL.absoluteString, false, false),
    ("https://evil.example/sdk/unstable/embedded-offramp", true, false)
])
func onlyMainFrameMessagesFromThePageReachTheView(frame: String, isMainFrame: Bool, delivered: Bool) {
    var received: [String] = []
    let host = HostedWebView(
        url: PAGE_URL.absoluteString,
        navigationPolicy: PAGE_POLICY,
        onMessage: { body, _ in received.append(body as? String ?? "") }
    )
    let message = #"{"event":"offramp:ready","data":{}}"#

    HostedWebView.Coordinator(host: host).receive(message, frameURL: URL(string: frame), isMainFrame: isMainFrame)

    #expect(received == (delivered ? [message] : []))
}
