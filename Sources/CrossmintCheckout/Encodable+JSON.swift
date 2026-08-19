//
//  Encodable+JSON.swift
//  CrossmintCheckout
//
//  Created by Robin Curbelo on 2/25/26.
//

import Foundation

extension Encodable {
    func toJSON() throws -> String {
        let encoder = JSONEncoder()
        // sortedKeys keeps the serialized form stable across encodes: these strings end up in
        // webview URLs that reload when they change, and JSONEncoder's default key order is
        // nondeterministic, which caused an infinite reload loop on every SwiftUI re-render.
        encoder.outputFormatting = [.withoutEscapingSlashes, .sortedKeys]
        let data = try encoder.encode(self)

        guard let json = String(data: data, encoding: .utf8) else {
            throw CheckoutError.invalidConfiguration("Failed to encode JSON")
        }

        return json
    }
}
