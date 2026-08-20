//
//  CheckoutOrderTests.swift
//  CrossmintCheckoutTests
//
//  Created by Tomás Martins on 8/17/26.
//

import Foundation
import Testing
@testable import CrossmintCheckout

private func orderUpdate(_ raw: String) throws -> CheckoutOrderUpdate {
    guard case .orderUpdated(let update)? = CheckoutEvent(messageBody: raw) else {
        throw CheckoutError.invalidConfiguration("expected an order:updated event")
    }
    return update
}

private let REQUIRES_KYC_EVENT = #"""
{"event":"order:updated","data":{
    "order":{
        "orderId":"order-1",
        "phase":"payment",
        "payment":{
            "status":"requires-kyc",
            "preparation":{
                "kyc":{"provider":"persona","inquiryId":"inq-1","sessionToken":"tok-1","environmentId":null,"future":1}
            }
        }
    },
    "orderClientSecret":"cs-1"
}}
"""#

@MainActor
@Test func decodesCredentialsFromKycPreparation() throws {
    let update = try orderUpdate(REQUIRES_KYC_EVENT)
    let credentials = try #require(update.order?.identityVerificationCredentials)
    #expect(credentials.inquiryId == "inq-1")
    #expect(credentials.sessionToken == "tok-1")
    #expect(credentials.provider == "persona")
}

@MainActor
@Test func readsOrderFieldsAndRequiresKycStatus() throws {
    let order = try #require(try orderUpdate(REQUIRES_KYC_EVENT).order)
    #expect(order.orderId == "order-1")
    #expect(order.phase == .payment)
    #expect(order.payment?.status == "requires-kyc")
}

@MainActor
@Test func credentialsNilWithoutKycPreparation() throws {
    let raw = #"{"event":"order:updated","data":{"order":{"orderId":"o","payment":{"status":"awaiting-payment","preparation":{"chain":"base","payerAddress":"0x1"}}}}}"#
    let update = try orderUpdate(raw)
    #expect(update.order?.identityVerificationCredentials == nil)
}

@MainActor
@Test func credentialsNilForUnknownProvider() throws {
    let raw = #"{"event":"order:updated","data":{"order":{"payment":{"preparation":{"kyc":{"provider":"other","inquiryId":"inq-1"}}}}}}"#
    let update = try orderUpdate(raw)
    #expect(update.order?.identityVerificationCredentials == nil)
}

@MainActor
@Test func emptySessionTokenBecomesNil() throws {
    let raw = #"{"event":"order:updated","data":{"order":{"payment":{"preparation":{"kyc":{"provider":"persona","inquiryId":"inq-1","sessionToken":""}}}}}}"#
    let credentials = try #require(try orderUpdate(raw).order?.identityVerificationCredentials)
    #expect(credentials.sessionToken == nil)
}

@MainActor
@Test func flattenedPayloadTreatedAsOrder() throws {
    let raw = #"{"event":"order:updated","data":{"orderId":"order-2","phase":"quote","clientSecret":"cs-2"}}"#
    let update = try orderUpdate(raw)
    #expect(update.order?.orderId == "order-2")
    #expect(update.orderClientSecret == "cs-2")
}

@MainActor
@Test func unknownPhaseDecodesAsNil() throws {
    let update = try orderUpdate(#"{"event":"order:updated","data":{"order":{"orderId":"o","phase":"a-future-phase"}}}"#)
    let order = try #require(update.order)
    #expect(order.phase == nil)
    #expect(order.orderId == "o")
}

@MainActor
@Test func payloadWithoutOrderShapeYieldsNoOrder() throws {
    let raw = #"{"event":"order:updated","data":{"unrelated":true}}"#
    let update = try orderUpdate(raw)
    #expect(update.order == nil)
    #expect(update.orderClientSecret == nil)
}

@MainActor
@Test func clientSecretFallbackChain() throws {
    let fromOrderClientSecret = try orderUpdate(#"{"event":"order:updated","data":{"order":{"orderId":"o"},"orderClientSecret":"a","clientSecret":"b"}}"#)
    #expect(fromOrderClientSecret.orderClientSecret == "a")

    let fromClientSecret = try orderUpdate(#"{"event":"order:updated","data":{"order":{"orderId":"o"},"clientSecret":"b"}}"#)
    #expect(fromClientSecret.orderClientSecret == "b")

    let fromOrder = try orderUpdate(#"{"event":"order:updated","data":{"order":{"orderId":"o","clientSecret":"c"}}}"#)
    #expect(fromOrder.orderClientSecret == "c")
}

@MainActor
@Test func controllerNeverClobbersSecretWithNil() throws {
    let controller = CrossmintCheckoutController()
    controller.handle(try orderUpdate(REQUIRES_KYC_EVENT))
    #expect(controller.orderClientSecret == "cs-1")
    #expect(controller.identityVerificationCredentials != nil)

    controller.handle(try orderUpdate(#"{"event":"order:updated","data":{"order":{"orderId":"order-1","phase":"delivery"}}}"#))
    #expect(controller.orderClientSecret == "cs-1")
    #expect(controller.order?.phase == .delivery)
}

@MainActor
@Test func controllerClearResetsState() throws {
    let controller = CrossmintCheckoutController()
    controller.handle(try orderUpdate(REQUIRES_KYC_EVENT))
    controller.clear()
    #expect(controller.order == nil)
    #expect(controller.orderClientSecret == nil)
    #expect(controller.identityVerificationCredentials == nil)
}

@MainActor
@Test func orderCreationFailedForwardsMessage() throws {
    guard case .orderCreationFailed(let message)? = CheckoutEvent(messageBody: #"{"event":"order:creation-failed","data":{"errorMessage":"nope"}}"#) else {
        Issue.record("expected orderCreationFailed")
        return
    }
    #expect(message == "nope")
}

@MainActor
@Test func decodesOrderJsonDirectly() throws {
    let json = Data(#"""
    {"orderId":"order-9","phase":"payment","payment":{"status":"requires-kyc","preparation":{"kyc":{"provider":"persona","inquiryId":"inq-9"}}}}
    """#.utf8)
    let order = try JSONDecoder().decode(CheckoutOrder.self, from: json)
    #expect(order.orderId == "order-9")
    #expect(order.payment?.status == "requires-kyc")
    #expect(order.identityVerificationCredentials?.inquiryId == "inq-9")
}
