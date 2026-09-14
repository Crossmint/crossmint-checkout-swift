//
//  LogEvents.swift
//  CrossmintCheckout
//
//  Created by Tomás Martins on 9/14/26.
//

import Foundation

enum LogEvents {
    static let configError = "checkout.config.error"

    static let webviewUrlInvalid = "checkout.webview.url.invalid"
    static let webviewLoadStart = "checkout.webview.load.start"
    static let webviewLoadSuccess = "checkout.webview.load.success"
    static let webviewLoadCancelled = "checkout.webview.load.cancelled"
    static let webviewLoadError = "checkout.webview.load.error"
    static let webviewHttpError = "checkout.webview.httpError"
    static let webviewNavigationStart = "checkout.webview.navigation.start"
    static let webviewNavigationCommit = "checkout.webview.navigation.commit"
    static let webviewNavigationBlocked = "checkout.webview.navigation.blocked"
    static let webviewProcessTerminated = "checkout.webview.webProcess.terminated"
    static let webviewMediaPermission = "checkout.webview.mediaPermission"
    static let webviewDismantled = "checkout.webview.dismantled"

    static let bridgeInbound = "checkout.bridge.inbound"
    static let bridgeInboundIgnored = "checkout.bridge.inbound.ignored"
    static let bridgeInboundDecodeError = "checkout.bridge.inbound.decodeError"
    static let bridgeOutbound = "checkout.bridge.outbound"
    static let bridgeOutboundDropped = "checkout.bridge.outbound.dropped"
    static let bridgeOutboundError = "checkout.bridge.outbound.error"

    static let orderUpdated = "checkout.order.updated"
    static let orderUpdatedEmpty = "checkout.order.updated.empty"
    static let orderPhaseChanged = "checkout.order.phase.changed"
    static let orderKycRequired = "checkout.order.kyc.required"
    static let orderKycDecodeError = "checkout.order.kyc.decodeError"
    static let orderCreationError = "checkout.order.creation.error"
    static let controllerCleared = "checkout.controller.cleared"

    static let cryptoRequestNoPayer = "checkout.crypto.request.noPayer"
    static let cryptoRequestIgnored = "checkout.crypto.request.ignored"

    static let identityReady = "checkout.identity.ready"
    static let identityCompleted = "checkout.identity.completed"
    static let identityCancelled = "checkout.identity.cancelled"
    static let identityError = "checkout.identity.error"
}
