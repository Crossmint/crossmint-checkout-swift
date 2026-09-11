//
//  LogFormatting.swift
//  CrossmintCheckout
//
//  Created by Tomás Martins on 9/11/26.
//

import Foundation

enum LogFormatting {
    static func format(_ message: String, attributes: [String: any Encodable]?) -> String {
        guard let attributes, !attributes.isEmpty else {
            return message
        }
        let attributeStrings = attributes.map { key, value in
            "\(key)=\(value)"
        }.sorted().joined(separator: " ")
        return "\(message) \(attributeStrings)"
    }
}
