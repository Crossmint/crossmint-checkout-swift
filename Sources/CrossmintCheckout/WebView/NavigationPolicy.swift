//
//  NavigationPolicy.swift
//  CrossmintCheckout
//
//  Created by Tomás Martins on 8/17/26.
//

import Foundation

/// Decides which navigations a hosted webview may perform.
///
/// Sub-frame navigations are always allowed (minus unsafe schemes): the verification provider
/// renders its capture flow in an iframe on its own domain.
enum NavigationPolicy {
    /// Any destination. The embedded checkout page navigates to payment providers and receipts.
    case permissive
    /// Main-frame navigations may only stay on Crossmint hosts.
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

/// Collapses a webview's load failures into a single report.
///
/// A failed main-frame load produces no page event, so the host synthesizes one — but navigation
/// delegates can fail more than once for one user-visible breakage, and the merchant should hear
/// about it once.
struct LoadFailureGate {
    private var hasFired = false

    mutating func message(for error: Error) -> String? {
        let nsError = error as NSError
        guard nsError.code != NSURLErrorCancelled else { return nil }
        return fireOnce(with: nsError.localizedDescription)
    }

    mutating func message(forHTTPStatus statusCode: Int) -> String? {
        guard statusCode >= 400 else { return nil }
        return fireOnce(with: "HTTP \(statusCode)")
    }

    private mutating func fireOnce(with message: String) -> String? {
        guard !hasFired else { return nil }
        hasFired = true
        return message
    }
}
