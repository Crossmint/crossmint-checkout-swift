//
//  WebViewBridge.swift
//  CrossmintCheckout
//
//  Created by Tomás Martins on 8/17/26.
//

import Foundation

/// A `{event, data}` message posted by a Crossmint hosted page.
struct BridgeEnvelope: Decodable {
    let event: String
    let data: [String: AnyCodable]

    enum CodingKeys: String, CodingKey {
        case event
        case data
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        event = try container.decode(String.self, forKey: .event)
        data = (try? container.decodeIfPresent([String: AnyCodable].self, forKey: .data)) ?? [:]
    }
}

/// The `window.ReactNativeWebView` bridge Crossmint's hosted pages speak.
///
/// The pages check for `window.ReactNativeWebView` at first render and, when present, post their
/// lifecycle events through it as JSON strings — otherwise they post to `window.parent`, which in a
/// WKWebView is the page itself, and every event is lost. The check also switches the page to its
/// mobile CSS (scrollable body while the keyboard is open, no zoom on input focus), so the shim must
/// be installed before any page content runs.
enum WebViewBridge {
    static let messageHandlerName = "crossmint"

    static let shimScript = """
    window.ReactNativeWebView = { postMessage: function(message) {
        window.webkit.messageHandlers.\(messageHandlerName).postMessage(message);
    } };
    """

    /// Parses a script-message body into an envelope.
    ///
    /// Returns nil for everything that is not a well-formed event envelope — non-string bodies,
    /// malformed JSON, the page's bare "frame-ready" string, and console-forwarding messages
    /// (`{"type": "console.log", ...}`, no `event` key). None of those are errors; the hosted pages
    /// share one channel for all of them.
    static func parse(_ body: Any) -> BridgeEnvelope? {
        guard let string = body as? String, let data = string.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(BridgeEnvelope.self, from: data)
    }

    /// JavaScript that delivers a `{event, data}` message to the page.
    ///
    /// `window.onMessageFromRN` is defined by React Native's injected bridge, not by the page, so a
    /// native host cannot rely on it existing — the `MessageEvent` fallback is what the page's own
    /// listener receives in that case.
    static func dispatchScript(event: String, data: [String: String]) throws -> String {
        let message = try ["event": AnyCodable(event), "data": AnyCodable(data)].toJSON()
        let escaped = escapeForSingleQuotedJS(message)
        return """
        (() => {
            if (window.onMessageFromRN) { window.onMessageFromRN('\(escaped)'); return; }
            try {
                const message = JSON.parse('\(escaped)');
                window.dispatchEvent(new MessageEvent('message', { data: message }));
            } catch (_) {}
        })();
        """
    }

    private static func escapeForSingleQuotedJS(_ string: String) -> String {
        string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\u{2028}", with: "\\u2028")
            .replacingOccurrences(of: "\u{2029}", with: "\\u2029")
    }
}
