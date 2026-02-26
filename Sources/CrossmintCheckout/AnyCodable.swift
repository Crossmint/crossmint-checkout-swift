//
//  AnyCodable.swift
//  CrossmintCheckout
//
//  Created by Robin Curbelo on 2/25/26.
//

import Foundation

public struct AnyCodable: Codable, Sendable {
    public let value: any Sendable

    public init(_ value: any Sendable) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self.value = ()
        } else if let bool = try? container.decode(Bool.self) {
            self.value = bool
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let string = try? container.decode(String.self) {
            self.value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            self.value = array
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            self.value = dictionary
        } else {
            self.value = ()
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [AnyCodable]:
            try container.encode(array)
        case let array as [any Sendable]:
            try container.encode(array.map(AnyCodable.init))
        case let dict as [String: AnyCodable]:
            try container.encode(dict)
        case let dict as [String: any Sendable]:
            try container.encode(dict.mapValues(AnyCodable.init))
        case is ():
            try container.encodeNil()
        default:
            try container.encodeNil()
        }
    }
}
