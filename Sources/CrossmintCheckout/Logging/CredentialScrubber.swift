//
//  CredentialScrubber.swift
//  CrossmintCheckout
//
//  Created by Tomás Martins on 9/11/26.
//

import Foundation

enum CredentialScrubber {
    struct Pattern {
        let regex: NSRegularExpression
        let replacement: String

        init?(_ expression: String, replacedWith replacement: String) {
            guard let regex = try? NSRegularExpression(pattern: expression) else { return nil }
            self.regex = regex
            self.replacement = replacement
        }
    }

    private static let credentialValues = [
        Pattern(
            #"\beyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]+"#,
            replacedWith: "[REDACTED_JWT]"
        ),
        Pattern(
            #"\b(?:ck|sk)_(?:development|staging|production)_[A-Za-z0-9]{16,}"#,
            replacedWith: "[REDACTED_API_KEY]"
        )
    ]

    private static let credentialKeys = [
        Pattern(
            #""(apiKey|clientSecret|orderClientSecret|sessionToken)"\s*:\s*"[^"]*""#,
            replacedWith: #""$1":"[REDACTED]""#
        ),
        Pattern(
            #"\b(apiKey|clientSecret|credentials)=[^&\s"']+"#,
            replacedWith: "$1=[REDACTED]"
        )
    ]

    static let patterns = (credentialValues + credentialKeys).compactMap { $0 }

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

    static func scrub(_ attributes: [String: Encodable]?) -> [String: Encodable]? {
        attributes?.mapValues { value -> Encodable in
            guard let string = value as? String else { return value }
            return scrub(string)
        }
    }
}
