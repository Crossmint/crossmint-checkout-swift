//
//  CrossmintEmbeddedCheckout.swift
//  CrossmintCheckout
//
//  Created by Robin Curbelo on 2/25/26.
//

import SwiftUI

/// A view that shows Crossmint's hosted checkout for an order.
///
/// Create the order from your backend with the Crossmint Orders API. Pass the `orderId`
/// and `clientSecret` from the response. The checkout page collects the payment. It also
/// takes the buyer through the other steps the order needs, such as identity verification.
///
/// ```swift
/// CrossmintEmbeddedCheckout(
///     apiKey: apiKey,
///     orderId: orderId,
///     clientSecret: clientSecret
/// )
/// ```
///
/// Pass a ``CrossmintCheckoutController`` to observe the order as the buyer progresses.
/// As an alternative, attach ``onOrderUpdated(_:)`` and ``onOrderCreationFailed(_:)`` to
/// handle the events yourself.
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
    private var onOrderUpdatedHandler: ((CheckoutOrderUpdate) -> Void)?
    private var onOrderCreationFailedHandler: ((String) -> Void)?
    private let explicitEnvironment: CheckoutEnvironment?

    /// Creates a checkout for an order.
    ///
    /// - Parameters:
    ///   - apiKey: Your client-side API key. The key starts with `ck_`.
    ///   - orderId: The identifier of the order your backend created.
    ///   - clientSecret: The client secret from the same order response.
    ///   - lineItems: The items of a new order. Not supported yet, so pass `nil`.
    ///   - payment: The payment settings. A `nil` value keeps the checkout defaults.
    ///   - recipient: The recipient of a new order. Not supported yet, so pass `nil`.
    ///   - appearance: The visual customization. A `nil` value keeps the checkout defaults.
    ///   - identityVerificationHandling: The presentation mode for the identity verification step. Pass ``IdentityVerificationHandling/external`` to show the step yourself.
    ///   - controller: The controller that receives the order updates.
    public init(
        apiKey: String,
        orderId: String? = nil,
        clientSecret: String? = nil,
        lineItems: CheckoutLineItems? = nil,
        payment: CheckoutPayment? = nil,
        recipient: CheckoutRecipient? = nil,
        appearance: CheckoutAppearance? = nil,
        identityVerificationHandling: IdentityVerificationHandling? = nil,
        controller: CrossmintCheckoutController? = nil
    ) {
        self.init(
            apiKey: apiKey,
            orderId: orderId,
            clientSecret: clientSecret,
            lineItems: lineItems,
            payment: payment,
            recipient: recipient,
            appearance: appearance,
            identityVerificationHandling: identityVerificationHandling,
            controller: controller,
            explicitEnvironment: nil
        )
    }

    /// Creates a checkout for an order with an explicit environment.
    ///
    /// The environment normally comes from the API key. Do not use this initializer in new code.
    /// Use ``init(apiKey:orderId:clientSecret:lineItems:payment:recipient:appearance:identityVerificationHandling:controller:)`` instead.
    @available(
        *, deprecated,
        message: "The environment comes from the API key. Remove the environment parameter."
    )
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
        environment: CheckoutEnvironment
    ) {
        self.init(
            apiKey: apiKey,
            orderId: orderId,
            clientSecret: clientSecret,
            lineItems: lineItems,
            payment: payment,
            recipient: recipient,
            appearance: appearance,
            identityVerificationHandling: identityVerificationHandling,
            controller: controller,
            explicitEnvironment: environment
        )
    }

    private init(
        apiKey: String,
        orderId: String?,
        clientSecret: String?,
        lineItems: CheckoutLineItems?,
        payment: CheckoutPayment?,
        recipient: CheckoutRecipient?,
        appearance: CheckoutAppearance?,
        identityVerificationHandling: IdentityVerificationHandling?,
        controller: CrossmintCheckoutController?,
        explicitEnvironment: CheckoutEnvironment?
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
        self.explicitEnvironment = explicitEnvironment
    }

    /// Adds an action to perform on every order update from the checkout page.
    public func onOrderUpdated(_ action: @escaping (CheckoutOrderUpdate) -> Void) -> Self {
        var view = self
        view.onOrderUpdatedHandler = action
        return view
    }

    /// Adds an action to perform when order creation fails. The message describes the failure.
    public func onOrderCreationFailed(_ action: @escaping (String) -> Void) -> Self {
        var view = self
        view.onOrderCreationFailedHandler = action
        return view
    }

    public var body: some View {
        switch checkoutUrlResult {
        case .success(let url):
            HostedWebView(
                url: url,
                navigationPolicy: .crossmintMainFrame(resolvedHost: URL(string: url)?.host ?? ""),
                onMessage: handle
            )
        case .failure(let error):
            CheckoutErrorView(error: error)
        }
    }

    @MainActor
    private func handle(_ messageBody: Any, _ responder: BridgeResponder) {
        guard let event = CheckoutEvent(messageBody: messageBody) else { return }
        switch event {
        case .orderUpdated(let update):
            controller?.handle(update)
            onOrderUpdatedHandler?(update)
        case .orderCreationFailed(let message):
            onOrderCreationFailedHandler?(message)
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

        let environment = try resolvedEnvironment()

        var queryItems: [URLQueryItem] = [try HostedPageURL.sdkMetadataItem()]

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

        return try HostedPageURL.build(
            host: environment.crossmintHost,
            path: "/sdk/2024-03-05/embedded-checkout",
            queryItems: queryItems
        )
    }

    private func resolvedEnvironment() throws -> CheckoutEnvironment {
        if let explicitEnvironment {
            return explicitEnvironment
        }
        guard let environment = CheckoutEnvironment(apiKey: apiKey) else {
            throw CheckoutError.invalidConfiguration("apiKey must be a Crossmint client key (ck_<environment>_...)")
        }
        return environment
    }
}
