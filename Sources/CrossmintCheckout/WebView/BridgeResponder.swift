//
//  BridgeResponder.swift
//  CrossmintCheckout
//
//  Created by Tomás Martins on 8/20/26.
//

import Foundation
import WebKit

@MainActor
final class BridgeResponder {
    weak var webView: WKWebView?
    // The page has one request of each kind in flight and sends no request IDs.
    private var pending: [String: UUID] = [:]
    // Tests replace it to run without WebKit.
    lazy var runScript: @MainActor (String) async throws -> Void = { [weak self] script in
        guard let webView = self?.webView else { throw WKError(.webViewInvalidated) }
        _ = try await webView.callAsyncJavaScript(script, contentWorld: .page)
    }

    private struct Message: Encodable {
        let event: String
        let data: BridgeReply
    }

    func send(_ reply: BridgeReply) {
        guard let script = Self.script(for: reply) else {
            return Logger.checkout.error(LogEvents.bridgeOutboundDropped, attributes: Self.attributes(for: reply, reason: "not-encodable"))
        }
        guard let webView else {
            return Logger.checkout.warning(LogEvents.bridgeOutboundDropped, attributes: Self.attributes(for: reply, reason: "no-web-view"))
        }
        Logger.checkout.debug(LogEvents.bridgeOutbound, attributes: Self.attributes(for: reply))
        webView.evaluateJavaScript(script) { _, error in
            guard let error else { return }
            Logger.checkout.error(LogEvents.bridgeOutboundError, attributes: Self.attributes(for: reply, error: error.localizedDescription))
        }
    }

    /// Replies once to a request the page awaits. A request of a kind already in flight gets no reply.
    @discardableResult
    func answer(_ request: String, with reply: @escaping @MainActor () async -> BridgeReply) -> Task<Void, Never>? {
        guard pending[request] == nil else {
            Logger.checkout.warning(LogEvents.bridgeInboundIgnored, attributes: ["event": request, "reason": "in-flight"])
            return nil
        }
        let id = UUID()
        pending[request] = id
        return Task {
            let reply = await reply()
            guard pending[request] == id else {
                return Logger.checkout.warning(LogEvents.bridgeOutboundDropped, attributes: Self.attributes(for: reply, reason: "stale"))
            }
            pending[request] = nil
            guard let script = Self.script(for: reply) else {
                return Logger.checkout.error(LogEvents.bridgeOutboundDropped, attributes: Self.attributes(for: reply, reason: "not-encodable"))
            }
            do {
                try await runScript(script)
                Logger.checkout.info(LogEvents.bridgeOutbound, attributes: Self.attributes(for: reply))
            } catch {
                Logger.checkout.error(LogEvents.bridgeOutboundError, attributes: Self.attributes(for: reply, error: error.localizedDescription))
            }
        }
    }

    /// Drops the replies to the requests of a document the web view no longer shows.
    func forgetPendingRequests() {
        pending = [:]
    }

    private static func attributes(for reply: BridgeReply, reason: String? = nil, error: String? = nil) -> [String: String] {
        var attributes = ["event": reply.event]
        attributes["error"] = error ?? reply.error
        attributes["reason"] = reason
        return attributes
    }

    static func script(for reply: BridgeReply) -> String? {
        let message = Message(event: reply.event, data: reply)
        guard let json = try? message.toJSON() else { return nil }
        return """
        (() => {
            const message = \(json);
            if (window.onMessageFromRN) { window.onMessageFromRN(JSON.stringify(message)); return; }
            window.dispatchEvent(new MessageEvent('message', { data: message }));
        })();
        """
    }
}
