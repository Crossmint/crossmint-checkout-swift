//
//  LoadFailureGate.swift
//  CrossmintCheckout
//
//  Created by Tomás Martins on 8/17/26.
//

import Foundation

struct LoadFailureGate {
    private var hasFired = false

    mutating func reportOnce(for error: Error) -> String? {
        let nsError = error as NSError
        guard nsError.code != NSURLErrorCancelled else { return nil }
        return reportOnce(message: nsError.localizedDescription)
    }

    mutating func reportOnce(forHTTPStatus statusCode: Int) -> String? {
        guard statusCode >= 400 else { return nil }
        return reportOnce(message: "HTTP \(statusCode)")
    }

    private mutating func reportOnce(message: String) -> String? {
        guard !hasFired else { return nil }
        hasFired = true
        return message
    }
}
