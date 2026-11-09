//
//  NavigationPolicy.swift
//  CrossmintCheckout
//
//  Created by Tomás Martins on 8/17/26.
//

import Foundation

enum NavigationPolicy {
    case crossmintMainFrame(resolvedHost: String)

    func allows(url: URL, isMainFrame: Bool) -> Bool {
        let scheme = url.scheme?.lowercased()
        if scheme == "javascript" || scheme == "file" {
            return false
        }

        switch self {
        case .crossmintMainFrame(let resolvedHost):
            guard isMainFrame else { return true }
            guard scheme == "https" || scheme == "http" else { return false }
            let host = url.host?.lowercased()
            return host == resolvedHost.lowercased() || host == "crossmint.com"
        }
    }

    func allowsCamera(originProtocol: String, originHost: String) -> Bool {
        guard originProtocol.lowercased() == "https" else { return false }
        let host = originHost.lowercased()
        switch self {
        case .crossmintMainFrame(let resolvedHost):
            return host == resolvedHost.lowercased()
                || host == "crossmint.com"
                || host == "withpersona.com"
                || host.hasSuffix(".withpersona.com")
        }
    }
}
