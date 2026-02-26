//
//  CrossmintEmbeddedCheckout.swift
//  CrossmintCheckout
//
//  Created by Robin Curbelo on 2/25/26.
//

import SwiftUI

public struct CrossmintEmbeddedCheckout: View {
    private let orderId: String?
    private let clientSecret: String?
    private let lineItems: CheckoutLineItems?
    private let payment: CheckoutPayment?
    private let recipient: CheckoutRecipient?
    private let apiKey: String?
    private let appearance: CheckoutAppearance?
    private let environment: CheckoutEnvironment

    public init(
        orderId: String? = nil,
        clientSecret: String? = nil,
        lineItems: CheckoutLineItems? = nil,
        payment: CheckoutPayment? = nil,
        recipient: CheckoutRecipient? = nil,
        apiKey: String? = nil,
        appearance: CheckoutAppearance? = nil,
        environment: CheckoutEnvironment = .staging
    ) {
        self.orderId = orderId
        self.clientSecret = clientSecret
        self.lineItems = lineItems
        self.payment = payment
        self.recipient = recipient
        self.apiKey = apiKey
        self.appearance = appearance
        self.environment = environment
    }

    public var body: some View {
        switch checkoutUrlResult {
        case .success(let url):
            CheckoutWebView(url: url)
        case .failure(let error):
            VStack(spacing: 20) {
                Text("Error")
                    .font(.headline)
                Text(error.localizedDescription)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
    }

    private var checkoutUrlResult: Result<String, Error> {
        Result { try generateCheckoutUrl() }
    }

    func generateCheckoutUrl() throws -> String {
        if lineItems != nil {
            throw CheckoutError.notImplemented(
                "Crossmint Checkout SDK: passing lineItems is not yet implemented"
            )
        }
        if recipient != nil {
            throw CheckoutError.notImplemented(
                "Crossmint Checkout SDK: passing recipient is not yet implemented"
            )
        }

        let domain = environment == .production ? "www" : "staging"
        let baseUrl = "https://\(domain).crossmint.com/sdk/2024-03-05/embedded-checkout"

        guard var components = URLComponents(string: baseUrl) else {
            throw CheckoutError.invalidConfiguration("Invalid base URL")
        }

        var queryItems: [URLQueryItem] = []

        let sdkMetadata: [String: String] = [
            "name": "@crossmint/checkout-swift",
            "version": SDKVersion.version
        ]
        queryItems.append(URLQueryItem(name: "sdkMetadata", value: try sdkMetadata.toJSON()))

        if let orderId {
            queryItems.append(URLQueryItem(name: "orderId", value: orderId))
        }
        if let clientSecret {
            queryItems.append(URLQueryItem(name: "clientSecret", value: clientSecret))
        }
        if let payment {
            queryItems.append(URLQueryItem(name: "payment", value: try payment.toJSON()))
        }
        if let appearance {
            queryItems.append(URLQueryItem(name: "appearance", value: try appearance.toJSON()))
        }

        components.queryItems = queryItems

        guard let url = components.url?.absoluteString else {
            throw CheckoutError.invalidConfiguration("Failed to construct URL")
        }

        return url
    }
}

public enum CheckoutEnvironment: Sendable {
    case staging
    case production
}
