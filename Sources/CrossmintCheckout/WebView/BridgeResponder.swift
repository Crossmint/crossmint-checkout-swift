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

    private struct Message: Encodable {
        let event: String
        let data: Payload

        struct Payload: Encodable {
            let error: String?

            enum CodingKeys: String, CodingKey {
                case error
            }

            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encodeIfPresent(error, forKey: .error)
            }
        }
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

    private static func attributes(for reply: BridgeReply, reason: String? = nil, error: String? = nil) -> [String: String] {
        var attributes = ["event": reply.event]
        attributes["error"] = error ?? reply.error
        attributes["reason"] = reason
        return attributes
    }

    static func script(for reply: BridgeReply) -> String? {
        let message = Message(event: reply.event, data: .init(error: reply.error))
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
