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
@Test func blocksUnsafeSchemesInEveryPolicy() throws {
    for policy in [NavigationPolicy.permissive, IDENTITY_POLICY] {
        #expect(!policy.allows(url: try url("javascript:alert(1)"), isMainFrame: true))
        #expect(!policy.allows(url: try url("javascript:alert(1)"), isMainFrame: false))
        #expect(!policy.allows(url: try url("file:///etc/passwd"), isMainFrame: true))
        #expect(!policy.allows(url: try url("file:///etc/passwd"), isMainFrame: false))
    }
}

@MainActor
@Test func permissivePolicyAllowsForeignHosts() throws {
    #expect(NavigationPolicy.permissive.allows(url: try url("https://pay.stripe.com/x"), isMainFrame: true))
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
@Test func loadFailureGateFiresOnce() throws {
    var gate = LoadFailureGate()
    let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
    #expect(gate.message(for: error) != nil)
    #expect(gate.message(for: error) == nil)
    #expect(gate.message(forHTTPStatus: 500) == nil)
}

@MainActor
@Test func loadFailureGateIgnoresCancelledNavigation() throws {
    var gate = LoadFailureGate()
    let cancelled = NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled)
    #expect(gate.message(for: cancelled) == nil)
    #expect(gate.message(forHTTPStatus: 500) == "HTTP 500")
}

@MainActor
@Test func loadFailureGateIgnoresSuccessfulStatusCodes() throws {
    var gate = LoadFailureGate()
    #expect(gate.message(forHTTPStatus: 200) == nil)
    #expect(gate.message(forHTTPStatus: 302) == nil)
    #expect(gate.message(forHTTPStatus: 404) == "HTTP 404")
}
