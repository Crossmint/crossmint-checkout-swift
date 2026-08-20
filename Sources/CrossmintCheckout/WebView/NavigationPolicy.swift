//
//  NavigationPolicy.swift
//  CrossmintCheckout
//
//  Created by Tomás Martins on 8/17/26.
//

import Foundation

enum NavigationPolicy {
    case permissive
    case crossmintMainFrame(resolvedHost: String)

    func allows(url: URL, isMainFrame: Bool) -> Bool {
        let scheme = url.scheme?.lowercased()
        if scheme == "javascript" || scheme == "file" {
            return false
        }

        switch self {
        case .permissive:
            return true
        case .crossmintMainFrame(let resolvedHost):
            guard isMainFrame else { return true }
            guard scheme == "https" || scheme == "http" else { return false }
            let host = url.host?.lowercased()
            return host == resolvedHost.lowercased() || host == "crossmint.com"
        }
    }
}
