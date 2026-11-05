//
//  EmbeddedOfframpTests.swift
//  CrossmintCheckoutTests
//
//  Created by Angel Calderaro on 11/5/26.
//

import Foundation
import Testing
@testable import CrossmintCheckout

private let CREDENTIALS = EmbeddedOfframpCredentials(sessionId: "ses-1", clientSecret: "cs-secret")
private let TRANSACTION = #"{"event":"crypto:send-transaction","data":{"serializedTransaction":"0xtx","chain":"base-sepolia","payerAddress":"0xpayer"}}"#
private let SIGN_MESSAGE = #"{"event":"crypto:sign-message","data":{"message":"Sign in","chain":"base-sepolia","payerAddress":"0xpayer"}}"#

struct WalletFailure: LocalizedError, Sendable {
    let errorDescription: String?
}

enum PayerOutcome: Sendable {
    case returns(String)
    case fails(any Error & Sendable)

    func value() throws -> String {
        switch self {
        case .returns(let value): value
        case .fails(let error): throw error
        }
    }
}

private func failed(_ request: String, _ error: String, rejected: Bool) -> BridgeReply {
    BridgeReply(event: "\(request):failed", error: error, rejected: rejected)
}

private let TX_OUTCOMES: [(PayerOutcome, BridgeReply)] = [
    (.returns("0xhash"), BridgeReply(event: "crypto:send-transaction:success", error: nil, txId: "0xhash")),
    (.returns(""), failed("crypto:send-transaction", "The wallet returned no transaction id", rejected: false)),
    (.fails(OfframpSignatureRejectedError(message: "no")), failed("crypto:send-transaction", "no", rejected: true)),
    (.fails(WalletFailure(errorDescription: "lost")), failed("crypto:send-transaction", "lost", rejected: false))
]

private let MESSAGE_OUTCOMES: [(PayerOutcome, BridgeReply)] = [
    (.returns("0xsig"), BridgeReply(event: "crypto:sign-message:success", error: nil, signature: "0xsig")),
    (.returns(""), failed("crypto:sign-message", "The wallet returned no signature", rejected: false)),
    (.fails(OfframpSignatureRejectedError(message: "no")), failed("crypto:sign-message", "no", rejected: true)),
    (.fails(WalletFailure(errorDescription: "locked")), failed("crypto:sign-message", "locked", rejected: false))
]

@MainActor
private func makeOfframp(
    apiKey: String = "ck_staging_test",
    credentials: EmbeddedOfframpCredentials = CREDENTIALS,
    payer: EmbeddedOfframpPayer = EmbeddedOfframpPayer(signAndSendTransaction: { _ in "0xhash" }),
    appearance: CheckoutAppearance? = nil,
    locale: CheckoutLocale? = nil,
    fill: Bool = false
) -> CrossmintEmbeddedOfframp {
    CrossmintEmbeddedOfframp(
        apiKey: apiKey,
        credentials: credentials,
        payer: payer,
        appearance: appearance,
        locale: locale,
        fill: fill
    )
}

// Reads a query parameter the way the page does, with URLSearchParams.
private func searchParam(_ name: String, in url: URL) throws -> String? {
    let items = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false)?.percentEncodedQueryItems)
    return items.first { $0.name == name }?.value?.replacingOccurrences(of: "+", with: " ").removingPercentEncoding
}

@MainActor
private func replies(of offramp: CrossmintEmbeddedOfframp, to request: String) async throws -> [BridgeReply] {
    let responder = BridgeResponder()
    var scripts: [String] = []
    responder.runScript = { scripts.append($0) }
    await offramp.handle(request, responder)?.value
    return try scripts.map { script in
        let line = try #require(script.components(separatedBy: "const message = ").last?.components(separatedBy: ";\n").first)
        return try JSONDecoder().decode(DecodedReply.self, from: Data(line.utf8)).reply
    }
}

private struct DecodedReply: Decodable {
    let event: String
    let data: Payload

    struct Payload: Decodable {
        let error: String?
        let rejected: Bool?
        let txId: String?
        let signature: String?
    }

    var reply: BridgeReply {
        BridgeReply(event: event, error: data.error, rejected: data.rejected, txId: data.txId, signature: data.signature)
    }
}

// MARK: - Page URL

@MainActor
@Test(arguments: [("ck_staging_x", "staging.crossmint.com"), ("ck_production_x", "www.crossmint.com"), ("ck_development_x", "staging.crossmint.com")])
func offrampUrlPointsAtTheEnvironmentOfTheKey(key: String, host: String) throws {
    let url = try makeOfframp(apiKey: key).generatePageUrl()

    #expect(url.scheme == "https")
    #expect(url.host == host)
    #expect(url.path == "/sdk/unstable/embedded-offramp")
    #expect(try searchParam("apiKey", in: url) == key)
    #expect(try searchParam("sdkMetadata", in: url)?.contains("checkout-swift") == true)
    #expect(try searchParam("credentials", in: url) == #"{"clientSecret":"cs-secret","sessionId":"ses-1"}"#)
}

@MainActor
@Test func offrampUrlKeepsReservedCharactersForTheQueryParserOfThePage() throws {
    let credentials = EmbeddedOfframpCredentials(sessionId: "a+b&c=d", clientSecret: "e/f#g?h i")
    let appearance = CheckoutAppearance(fonts: [.cssURL(try #require(URL(string: "https://fonts.googleapis.com/css2?family=Open+Sans")))])

    let url = try makeOfframp(credentials: credentials, appearance: appearance).generatePageUrl()

    let sent = try JSONDecoder().decode(
        EmbeddedOfframpCredentials.self, from: Data(try #require(try searchParam("credentials", in: url)).utf8)
    )
    #expect(sent == credentials)
    #expect(try searchParam("appearance", in: url)?.contains("family=Open+Sans") == true)
}

@MainActor
@Test(arguments: [true, false])
func offrampUrlAnnouncesMessageSigningOnlyForAPayerThatSignsMessages(signs: Bool) throws {
    let payer = EmbeddedOfframpPayer(
        signAndSendTransaction: { _ in "" },
        signMessage: signs ? { @MainActor _ in "" } : nil
    )

    let url = try makeOfframp(payer: payer).generatePageUrl()

    #expect(try searchParam("canSignMessage", in: url) == (signs ? "true" : nil))
}

@MainActor
@Test(arguments: [true, false])
func offrampUrlAsksThePageToFillOnlyWhenFilling(fill: Bool) throws {
    let url = try makeOfframp(fill: fill).generatePageUrl()

    #expect(try searchParam("fill", in: url) == (fill ? "true" : nil))
}

@MainActor
@Test func offrampUrlCarriesTheLocaleOnlyWhenSet() throws {
    #expect(try searchParam("locale", in: try makeOfframp(locale: .ptPT).generatePageUrl()) == "pt-PT")
    #expect(try searchParam("locale", in: try makeOfframp().generatePageUrl()) == nil)
}

@MainActor
@Test func offrampUrlResolvesAppearanceColorsForTheColorSchemeAtLoad() throws {
    let appearance = CheckoutAppearance(variables: CheckoutAppearanceVariables(
        colors: CheckoutVariablesColorStyle(textPrimary: .uiColor(.label))
    ))
    let offramp = makeOfframp(appearance: appearance)

    let light = try searchParam("appearance", in: try offramp.generatePageUrl(colorScheme: .light))
    let dark = try searchParam("appearance", in: try offramp.generatePageUrl(colorScheme: .dark))

    #expect(light?.contains("textPrimary") == true)
    #expect(light != dark)
}

@MainActor
@Test func offrampUrlRejectsAServerKey() {
    #expect(throws: CheckoutError.serverAPIKey) {
        try makeOfframp(apiKey: "sk_staging_test").generatePageUrl()
    }
}

// MARK: - Payer replies

@MainActor
@Test(arguments: TX_OUTCOMES)
func offrampRepliesToADepositWithThePayerOutcome(outcome: PayerOutcome, expected: BridgeReply) async throws {
    let offramp = makeOfframp(payer: EmbeddedOfframpPayer(signAndSendTransaction: { _ in try outcome.value() }))

    #expect(try await replies(of: offramp, to: TRANSACTION) == [expected])
}

@MainActor
@Test(arguments: MESSAGE_OUTCOMES)
func offrampRepliesToAnOwnershipProofWithThePayerOutcome(outcome: PayerOutcome, expected: BridgeReply) async throws {
    let offramp = makeOfframp(payer: EmbeddedOfframpPayer(
        signAndSendTransaction: { _ in "" },
        signMessage: { _ in try outcome.value() }
    ))

    #expect(try await replies(of: offramp, to: SIGN_MESSAGE) == [expected])
}

@MainActor
@Test func offrampRefusesAnOwnershipProofWhenThePayerCannotSignMessages() async throws {
    #expect(try await replies(of: makeOfframp(), to: SIGN_MESSAGE) == [
        failed("crypto:sign-message", "This payer cannot sign messages", rejected: false)
    ])
}

@MainActor
@Test func offrampHandsThePayerTheRequestOfThePage() async throws {
    var received: [OfframpTransaction] = []
    let offramp = makeOfframp(payer: EmbeddedOfframpPayer(signAndSendTransaction: { transaction in
        received.append(transaction)
        return "0xhash"
    }))

    _ = try await replies(of: offramp, to: TRANSACTION)

    #expect(received == [OfframpTransaction(serializedTransaction: "0xtx", chain: "base-sepolia", payerAddress: "0xpayer")])
}

@MainActor
@Test func offrampSendsOneDepositAtATime() async throws {
    var calls = 0
    var resume: CheckedContinuation<String, Never>?
    let offramp = makeOfframp(payer: EmbeddedOfframpPayer(signAndSendTransaction: { _ in
        calls += 1
        return await withCheckedContinuation { resume = $0 }
    }))
    let responder = BridgeResponder()
    var scripts: [String] = []
    responder.runScript = { scripts.append($0) }

    let first = offramp.handle(TRANSACTION, responder)
    while resume == nil { await Task.yield() }
    #expect(offramp.handle(TRANSACTION, responder) == nil)
    resume?.resume(returning: "0xhash")
    await first?.value

    #expect(calls == 1)
    #expect(scripts.count == 1)
}

// MARK: - Page events

@MainActor
@Test func offrampHandsThePageEventsToTheHandlers() {
    var log: [String] = []
    let offramp = makeOfframp()
        .onReady { log.append("ready") }
        .onStatusChange { log.append("status \($0.status.rawValue) \($0.orderId ?? "-")") }
        .onComplete { log.append("completed \($0.orderId) \($0.txId)") }
        .onCancel { log.append("cancelled") }
        .onError { log.append("error \($0.reason.rawValue) \($0.retriable) \($0.message)") }

    for raw in [
        #"{"event":"offramp:ready","data":{}}"#,
        #"{"event":"offramp:status","data":{"status":"reviewing","orderId":"o-1"}}"#,
        #"{"event":"offramp:completed","data":{"orderId":"o-1","txId":"0xhash"}}"#,
        #"{"event":"offramp:cancelled","data":{}}"#,
        #"{"event":"offramp:error","data":{"reason":"session-spent","retriable":false,"message":"spent"}}"#
    ] {
        #expect(offramp.handle(raw, BridgeResponder()) == nil)
    }

    #expect(log == ["ready", "status reviewing o-1", "completed o-1 0xhash", "cancelled", "error session-spent false spent"])
}

@MainActor
@Test(arguments: [("verifying-wallet", OfframpStatus.verifyingWallet), ("payout-completed", .payoutCompleted), ("a-later-step", .unknown)])
func offrampStatusDecodesUnknownStepsAsUnknown(wire: String, expected: OfframpStatus) {
    let event = OfframpEvent(messageBody: #"{"event":"offramp:status","data":{"status":"\#(wire)"}}"#)

    #expect(event == .statusChanged(OfframpStatusChange(status: expected, orderId: nil)))
}

@MainActor
@Test func offrampErrorDecodesUnknownReasonsAndMissingFieldsSafely() {
    #expect(OfframpEvent(messageBody: #"{"event":"offramp:error","data":{"reason":"a-later-reason","retriable":true,"message":"m"}}"#)
        == .failed(OfframpError(retriable: true, reason: .unknown, message: "m")))
    #expect(OfframpEvent(messageBody: #"{"event":"offramp:error","data":{"reason":"amount-too-low","retriable":true,"message":"m"}}"#)
        == .failed(OfframpError(retriable: true, reason: .amountTooLow, message: "m")))
    #expect(OfframpEvent(messageBody: #"{"event":"offramp:error"}"#)
        == .failed(OfframpError(retriable: false, reason: .unknown, message: "")))
}

@MainActor
@Test(arguments: [(812.5, true), (0, false), (-1, false)])
func offrampTakesOnlyAPositiveHeight(reported: Double, taken: Bool) {
    let event = OfframpEvent(messageBody: #"{"event":"ui:height.changed","data":{"height":\#(reported)}}"#)

    #expect(event == (taken ? .heightChanged(CGFloat(reported)) : nil))
}

@MainActor
@Test(arguments: [
    #"{"event":"offramp:completed","data":{"orderId":"o-1"}}"#,
    #"{"event":"crypto:send-transaction","data":{"chain":"base"}}"#,
    #"{"event":"crypto:sign-message","data":{}}"#,
    #"{"event":"kyc:ready","data":{}}"#,
    #"{"event":"order:updated","data":{}}"#
])
func offrampIgnoresIncompleteOrForeignEvents(raw: String) {
    #expect(OfframpEvent(messageBody: raw) == nil)
}

// MARK: - Load failures

@MainActor
@Test(arguments: [
    (404, OfframpError.Reason.invalidConfiguration, false),
    (503, .providerError, true),
    (nil, .providerError, true)
] as [(Int?, OfframpError.Reason, Bool)])
func offrampReportsALoadFailureByWhetherARetryCanWork(statusCode: Int?, reason: OfframpError.Reason, retriable: Bool) {
    let error = OfframpError(loadFailure: "boom", statusCode: statusCode)

    #expect(error == OfframpError(retriable: retriable, reason: reason, message: "boom"))
}

// MARK: - Credentials

@MainActor
@Test func offrampCredentialsDescriptionsHideTheClientSecret() {
    for text in [String(describing: CREDENTIALS), "\(CREDENTIALS)", String(reflecting: CREDENTIALS)] {
        #expect(text == "EmbeddedOfframpCredentials(sessionId: ses-1)")
    }
}

@MainActor
@Test func offrampCredentialsDecodeTheSessionResponse() throws {
    let json = Data(#"{"sessionId":"ses-1","clientSecret":"cs-secret","expiresAt":"2026-11-05"}"#.utf8)

    #expect(try JSONDecoder().decode(EmbeddedOfframpCredentials.self, from: json) == CREDENTIALS)
}
