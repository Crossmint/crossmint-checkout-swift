//
//  DemoConfiguration.swift
//  CheckoutDemo
//
//  Created by Tomás Martins on 8/31/26.
//

import Foundation

enum DemoConfiguration {
    static let apiKey: String? = {
        let raw = Bundle.main.object(forInfoDictionaryKey: "CrossmintAPIKey") as? String
        let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let trimmed, !trimmed.isEmpty, trimmed != "ck_staging_YOUR_API_KEY" else { return nil }
        return trimmed
    }()

    enum Environment: String {
        case staging = "staging"
        case production = "production"

        var host: String {
            switch self {
            case .staging: "staging.crossmint.com"
            case .production: "www.crossmint.com"
            }
        }
    }

    static var environment: Environment? {
        guard let apiKey else { return nil }
        if apiKey.hasPrefix("ck_staging_") || apiKey.hasPrefix("ck_development_") { return .staging }
        if apiKey.hasPrefix("ck_production_") { return .production }
        return nil
    }
}
