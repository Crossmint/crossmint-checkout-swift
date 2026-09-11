//
//  CredentialScrubber.swift
//  CrossmintCheckout
//
//  Created by Tomás Martins on 9/11/26.
//

import Foundation

enum CredentialScrubber {
    static let patterns: [(regex: NSRegularExpression, replacement: String)] = [
        (#"\beyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]+"#, "[REDACTED_JWT]"),
        (#"\b(?:ck|sk)_(?:development|staging|production)_[A-Za-z0-9]{16,}"#, "[REDACTED_API_KEY]"),
        (#""(apiKey|clientSecret|orderClientSecret|sessionToken)"\s*:\s*"[^"]*""#, #""$1":"[REDACTED]""#),
        (#"\b(apiKey|clientSecret|credentials)=[^&\s"']+"#, "$1=[REDACTED]")
    ].compactMap { pattern, replacement in
        (try? NSRegularExpression(pattern: pattern)).map { ($0, replacement) }
    }

    static func scrub(_ message: String) -> String {
        let buffer = NSMutableString(string: message)
        var replacements = 0
        for pattern in patterns {
            replacements += pattern.regex.replaceMatches(
                in: buffer,
                range: NSRange(location: 0, length: buffer.length),
                withTemplate: pattern.replacement
            )
        }
        return replacements == 0 ? message : buffer as String
    }
}
