//
//  NavigationPolicy.swift
//  CrossmintCheckout
//
//  Created by Tomás Martins on 8/17/26.
//

import Foundation

enum NavigationPolicy {
    case crossmintMainFrame(resolvedHost: String)
    /// Keeps the main frame on this page and opens the links the user follows away from it in the browser.
    case page(URL)

    enum Decision: Equatable {
        case allow
        case cancel
        case openExternally(URL)
    }

    func allows(url: URL, isMainFrame: Bool) -> Bool {
        decision(for: url, targetIsMainFrame: isMainFrame, linkActivated: false) == .allow
    }

    /// `targetIsMainFrame` is `nil` for a navigation that opens a new window.
    func decision(for url: URL, targetIsMainFrame: Bool?, linkActivated: Bool) -> Decision {
        let scheme = url.scheme?.lowercased()
        if scheme == "javascript" || scheme == "file" {
            return .cancel
        }
        let isWeb = scheme == "https" || scheme == "http"

        switch self {
        case .crossmintMainFrame(let resolvedHost):
            guard targetIsMainFrame ?? true else { return .allow }
            guard isWeb else { return .cancel }
            let host = url.host?.lowercased()
            return host == resolvedHost.lowercased() || host == "crossmint.com" ? .allow : .cancel
        case .page(let page):
            switch targetIsMainFrame {
            case false?:
                return .allow
            case true? where Self.isPage(url, page):
                return .allow
            case true? where !linkActivated:
                return .cancel
            default:
                return isWeb ? .openExternally(url) : .cancel
            }
        }
    }

    func trustsMessages(from frameURL: URL?) -> Bool {
        switch self {
        case .crossmintMainFrame:
            true
        case .page(let page):
            frameURL.map { Self.isPage($0, page) } ?? false
        }
    }

    private static func isPage(_ url: URL, _ page: URL) -> Bool {
        url.scheme?.lowercased() == "https" && url.host?.lowercased() == page.host?.lowercased()
            && url.port == page.port && url.user == nil && url.password == nil && url.path == page.path
    }

    func allowsCamera(originProtocol: String, originHost: String) -> Bool {
        guard originProtocol.lowercased() == "https" else { return false }
        let host = originHost.lowercased()
        let isPersona = host == "withpersona.com" || host.hasSuffix(".withpersona.com")
        switch self {
        case .crossmintMainFrame(let resolvedHost):
            return host == resolvedHost.lowercased() || host == "crossmint.com" || isPersona
        case .page(let page):
            return host == page.host?.lowercased() || isPersona
        }
    }
}
