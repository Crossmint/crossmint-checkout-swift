//
//  HostedPageURL.swift
//  CrossmintCheckout
//
//  Created by Tomás Martins on 8/20/26.
//

import Foundation

enum HostedPageURL {
    static func sdkMetadataItem() throws -> URLQueryItem {
        let sdkMetadata: [String: String] = [
            "name": "@crossmint/checkout-swift",
            "version": SDKVersion.version
        ]
        return URLQueryItem(name: "sdkMetadata", value: try sdkMetadata.toJSON())
    }

    static func build(host: String, path: String, queryItems: [URLQueryItem]) throws -> String {
        guard var components = URLComponents(string: "https://\(host)\(path)") else {
            throw CheckoutError.invalidConfiguration("Invalid base URL")
        }
        components.queryItems = queryItems
        guard let url = components.url?.absoluteString else {
            throw CheckoutError.invalidConfiguration("Failed to construct URL")
        }
        return url
    }
}
