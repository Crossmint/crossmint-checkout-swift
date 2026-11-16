//
//  BridgeResponderTests.swift
//  CrossmintCheckoutTests
//
//  Created by Angel Calderaro on 11/5/26.
//

import Foundation
import Testing
@testable import CrossmintCheckout

private let SEND = "crypto:send-transaction"

private func success(_ txId: String) -> BridgeReply {
    BridgeReply(event: "\(SEND):success", error: nil, txId: txId)
}

@MainActor
private func makeResponder() -> (BridgeResponder, () -> [String]) {
    let responder = BridgeResponder()
    var scripts: [String] = []
    responder.runScript = { scripts.append($0) }
    return (responder, { scripts })
}

@MainActor
@Test func answerRunsTheReplyScriptOnce() async {
    let (responder, scripts) = makeResponder()

    await responder.answer(SEND) { success("0xhash") }?.value

    #expect(scripts().count == 1)
    #expect(scripts().first?.contains(#"{"data":{"txId":"0xhash"},"event":"crypto:send-transaction:success"}"#) == true)
}

@MainActor
@Test func answerIgnoresARequestOfAKindAlreadyInFlight() async {
    let (responder, scripts) = makeResponder()
    var resume: CheckedContinuation<Void, Never>?
    var calls = 0

    let first = responder.answer(SEND) {
        calls += 1
        await withCheckedContinuation { resume = $0 }
        return success("0xfirst")
    }
    while resume == nil { await Task.yield() }
    let second = responder.answer(SEND) {
        calls += 1
        return success("0xsecond")
    }
    await responder.answer("crypto:sign-message") { BridgeReply(event: "crypto:sign-message:success", error: nil, signature: "0xsig") }?.value
    resume?.resume()
    await first?.value

    #expect(second == nil)
    #expect(calls == 1)
    #expect(scripts().count == 2)
    #expect(scripts().last?.contains("0xfirst") == true)
}

@MainActor
@Test func answerDropsTheReplyToADocumentTheWebViewNoLongerShows() async {
    let (responder, scripts) = makeResponder()
    var resumeOld: CheckedContinuation<Void, Never>?

    let old = responder.answer(SEND) {
        await withCheckedContinuation { resumeOld = $0 }
        return success("0xold")
    }
    while resumeOld == nil { await Task.yield() }
    responder.forgetPendingRequests()
    await responder.answer(SEND) { success("0xnew") }?.value
    resumeOld?.resume()
    await old?.value

    #expect(scripts().count == 1)
    #expect(scripts().first?.contains("0xnew") == true)
}

@MainActor
@Test func answerTakesTheNextRequestAfterThePageMissesAReply() async {
    let responder = BridgeResponder()
    var attempts = 0
    responder.runScript = { _ in
        attempts += 1
        if attempts == 1 { throw URLError(.cancelled) }
    }

    await responder.answer(SEND) { success("0xhash") }?.value
    await responder.answer(SEND) { success("0xhash") }?.value

    #expect(attempts == 2)
}

@MainActor
@Test func replyScriptCarriesTheFailureFields() throws {
    let script = try #require(BridgeResponder.script(for: BridgeReply(event: "\(SEND):failed", error: "no", rejected: true)))
    #expect(script.contains(#"{"data":{"error":"no","rejected":true},"event":"crypto:send-transaction:failed"}"#))
}
