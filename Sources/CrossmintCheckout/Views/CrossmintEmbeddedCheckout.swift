//
//  CrossmintEmbeddedCheckout.swift
//  CrossmintCheckout
//
//  Created by Robin Curbelo on 2/25/26.
//

import SwiftUI

public struct CrossmintEmbeddedCheckout: View {
    private let apiKey: String
    private let orderId: String?
    private let clientSecret: String?
    private let lineItems: CheckoutLineItems?
    private let payment: CheckoutPayment?
    private let recipient: CheckoutRecipient?
    private let appearance: CheckoutAppearance?
    private let identityVerificationHandling: IdentityVerificationHandling?
    private let controller: CrossmintCheckoutController?
    private let onOrderUpdated: ((CheckoutOrderUpdate) -> Void)?
    private let onOrderCreationFailed: ((String) -> Void)?
    private let environment: CheckoutEnvironment

    public init(
        apiKey: String,
        orderId: String? = nil,
        clientSecret: String? = nil,
        lineItems: CheckoutLineItems? = nil,
        payment: CheckoutPayment? = nil,
        recipient: CheckoutRecipient? = nil,
        appearance: CheckoutAppearance? = nil,
        identityVerificationHandling: IdentityVerificationHandling? = nil,
        controller: CrossmintCheckoutController? = nil,
        onOrderUpdated: ((CheckoutOrderUpdate) -> Void)? = nil,
        onOrderCreationFailed: ((String) -> Void)? = nil,
        environment: CheckoutEnvironment = .staging
    ) {
        self.apiKey = apiKey
        self.orderId = orderId
        self.clientSecret = clientSecret
        self.lineItems = lineItems
        self.payment = payment
        self.recipient = recipient
        self.appearance = appearance
        self.identityVerificationHandling = identityVerificationHandling
        self.controller = controller
        self.onOrderUpdated = onOrderUpdated
        self.onOrderCreationFailed = onOrderCreationFailed
        self.environment = environment
    }

    public var body: some View {
        switch checkoutUrlResult {
        case .success(let url):
            HostedWebView(
                url: url,
                navigationPolicy: .permissive,
                onMessage: handle
            )
        case .failure(let error):
            VStack(spacing: 20) {
                Text("Error")
                    .font(.headline)
                Text(error.localizedDescription)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
    }

    @MainActor
    private func handle(_ messageBody: Any, _ responder: BridgeResponder) {
        guard let event = CheckoutEvent(messageBody: messageBody) else { return }
        switch event {
        case .orderUpdated(let update):
            controller?.handle(update)
            onOrderUpdated?(update)
        case .orderCreationFailed(let message):
            onOrderCreationFailed?(message)
        case .cryptoRequest(let request):
            guard let reply = request.noPayerReply else { return }
            responder.send(reply)
        }
    }

    private var checkoutUrlResult: Result<String, Error> {
        Result { try generateCheckoutUrl() }
    }

    func generateCheckoutUrl() throws -> String {
        guard !apiKey.isEmpty else {
            throw CheckoutError.invalidConfiguration("apiKey is required")
        }

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

        let baseUrl = "https://\(environment.crossmintHost)/sdk/2024-03-05/embedded-checkout"

        guard var components = URLComponents(string: baseUrl) else {
            throw CheckoutError.invalidConfiguration("Invalid base URL")
        }

        var queryItems: [URLQueryItem] = []

        let sdkMetadata: [String: String] = [
            "name": "@crossmint/checkout-swift",
            "version": SDKVersion.version
        ]
        queryItems.append(URLQueryItem(name: "sdkMetadata", value: try sdkMetadata.toJSON()))

        queryItems.append(URLQueryItem(name: "apiKey", value: apiKey))

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
        if let identityVerificationHandling {
            queryItems.append(URLQueryItem(
                name: "identityVerificationHandling",
                value: identityVerificationHandling.rawValue
            ))
        }

        components.queryItems = queryItems

        guard let url = components.url?.absoluteString else {
            throw CheckoutError.invalidConfiguration("Failed to construct URL")
        }

        return url
    }
}
