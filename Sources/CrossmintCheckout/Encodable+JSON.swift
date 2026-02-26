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
        encoder.outputFormatting = [.withoutEscapingSlashes]
        let data = try encoder.encode(self)

        guard let json = String(data: data, encoding: .utf8) else {
            throw CheckoutError.invalidConfiguration("Failed to encode JSON")
        }

        return json
    }
}
