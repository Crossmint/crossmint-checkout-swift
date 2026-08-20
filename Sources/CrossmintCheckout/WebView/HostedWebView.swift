//
//  HostedWebView.swift
//  CrossmintCheckout
//
//  Created by Tomás Martins on 8/17/26.
//

import SwiftUI
import WebKit

struct HostedWebView: UIViewRepresentable {
    let url: String
    let navigationPolicy: NavigationPolicy
    var allowsMediaCapture = false
    var isScrollEnabled = false
    var injectsViewportScript = true
    var onMessage: @MainActor (Any, BridgeResponder) -> Void = { _, _ in }
    var onLoadFailure: ((String) -> Void)?

    private static let messageHandlerName = "crossmint"

    private static let bridgeShimScript = """
    window.ReactNativeWebView = { postMessage: function(message) {
        window.webkit.messageHandlers.\(messageHandlerName).postMessage(message);
    } };
    """

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero, configuration: makeConfiguration(coordinator: context.coordinator))
        webView.scrollView.isScrollEnabled = isScrollEnabled
        webView.scrollView.bounces = false
        webView.scrollView.alwaysBounceVertical = false
        webView.scrollView.alwaysBounceHorizontal = false
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        #if DEBUG
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
        #endif

        context.coordinator.responder.webView = webView
        context.coordinator.load(url, in: webView)

        return webView
    }

    private func makeConfiguration(coordinator: Coordinator) -> WKWebViewConfiguration {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.defaultWebpagePreferences.preferredContentMode = .mobile
        config.applicationNameForUserAgent = "CrossmintCheckout"

        config.userContentController.addUserScript(
            WKUserScript(source: Self.bridgeShimScript, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        )
        config.userContentController.add(coordinator, name: Self.messageHandlerName)

        if injectsViewportScript {
            let viewportScript = """
            var meta = document.createElement('meta');
            meta.name = 'viewport';
            meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
            document.getElementsByTagName('head')[0].appendChild(meta);
            """
            config.userContentController.addUserScript(
                WKUserScript(source: viewportScript, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
            )
        }

        return config
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        context.coordinator.host = self
        if context.coordinator.loadedURL != url {
            context.coordinator.load(url, in: uiView)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(host: self)
    }

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        uiView.configuration.userContentController.removeScriptMessageHandler(
            forName: messageHandlerName
        )
    }

    @MainActor
    final class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate, WKUIDelegate {
        var host: HostedWebView
        let responder = BridgeResponder()
        private(set) var loadedURL: String?
        private var loadFailureGate = LoadFailureGate()

        init(host: HostedWebView) {
            self.host = host
        }

        func load(_ url: String, in webView: WKWebView) {
            loadedURL = url
            loadFailureGate = LoadFailureGate()
            guard let url = URL(string: url) else { return }
            webView.load(URLRequest(url: url))
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.frameInfo.isMainFrame else { return }
            host.onMessage(message.body, responder)
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction
        ) async -> WKNavigationActionPolicy {
            guard let url = navigationAction.request.url else { return .cancel }
            let isMainFrame = navigationAction.targetFrame?.isMainFrame ?? true
            return host.navigationPolicy.allows(url: url, isMainFrame: isMainFrame) ? .allow : .cancel
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationResponse: WKNavigationResponse
        ) async -> WKNavigationResponsePolicy {
            if navigationResponse.isForMainFrame,
               let statusCode = (navigationResponse.response as? HTTPURLResponse)?.statusCode,
               let message = loadFailureGate.reportOnce(forHTTPStatus: statusCode) {
                host.onLoadFailure?(message)
                return .cancel
            }
            return .allow
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            reportLoadFailure(error)
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            reportLoadFailure(error)
        }

        private func reportLoadFailure(_ error: Error) {
            guard let message = loadFailureGate.reportOnce(for: error) else { return }
            host.onLoadFailure?(message)
        }

        func webView(
            _ webView: WKWebView,
            requestMediaCapturePermissionFor origin: WKSecurityOrigin,
            initiatedByFrame frame: WKFrameInfo,
            type: WKMediaCaptureType,
            decisionHandler: @escaping @MainActor (WKPermissionDecision) -> Void
        ) {
            decisionHandler(host.allowsMediaCapture && type == .camera ? .grant : .prompt)
        }
    }
}
