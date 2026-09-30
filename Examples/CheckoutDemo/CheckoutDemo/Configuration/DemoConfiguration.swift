//
//  DemoConfiguration.swift
//  CheckoutDemo
//
//  Created by Tomás Martins on 8/31/26.
//

import Foundation
import Observation

@Observable
final class DemoConfiguration {
    nonisolated enum Environment: String {
        case staging
        case production

        var title: String {
            switch self {
            case .staging: "Staging"
            case .production: "Production"
            }
        }

        var host: String {
            switch self {
            case .staging: "staging.crossmint.com"
            case .production: "www.crossmint.com"
            }
        }

        var note: String {
            switch self {
            case .staging:
                "The demo points at staging. Orders use testnet tokens, so a checkout cannot move real funds."
            case .production:
                "The demo points at production. A checkout here moves real funds."
            }
        }
    }

    nonisolated private static let infoDictionaryKey = "CrossmintAPIKey"
    nonisolated private static let storageKey = "CrossmintAPIKey"
    nonisolated private static let placeholderAPIKey = "ck_staging_YOUR_API_KEY"

    let buildAPIKey: String?
    private(set) var savedAPIKey: String

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        buildAPIKey = Self.sanitized(
            Bundle.main.object(forInfoDictionaryKey: Self.infoDictionaryKey) as? String
        )
        savedAPIKey = defaults.string(forKey: Self.storageKey) ?? ""
    }

    var apiKey: String? {
        buildAPIKey ?? Self.sanitized(savedAPIKey)
    }

    var isManagedByBuildSettings: Bool {
        buildAPIKey != nil
    }

    var environment: Environment? {
        Self.environment(for: apiKey)
    }

    func save(apiKey: String) {
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        savedAPIKey = trimmed
        defaults.set(trimmed, forKey: Self.storageKey)
    }

    func removeSavedAPIKey() {
        savedAPIKey = ""
        defaults.removeObject(forKey: Self.storageKey)
    }

    nonisolated static func masked(_ apiKey: String) -> String {
        let hidden = String(repeating: "•", count: 8)
        guard apiKey.count > 18 else { return hidden }
        return "\(apiKey.prefix(14))\(hidden)\(apiKey.suffix(4))"
    }

    nonisolated static func environment(for apiKey: String?) -> Environment? {
        guard let apiKey = sanitized(apiKey) else { return nil }
        if apiKey.hasPrefix("ck_staging_") || apiKey.hasPrefix("ck_development_") { return .staging }
        if apiKey.hasPrefix("ck_production_") { return .production }
        return nil
    }

    nonisolated private static func sanitized(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let trimmed, !trimmed.isEmpty, trimmed != placeholderAPIKey else { return nil }
        return trimmed
    }
}
