//
//  CrossmintEmbeddedOfframp.swift
//  CrossmintCheckout
//
//  Created by Angel Calderaro on 11/5/26.
//

import SwiftUI

/// A view that runs one Crossmint offramp session.
///
/// The user adds a bank account, gets a quote, verifies their identity when the session needs it, and confirms one
/// deposit that the payer signs and sends. The view then follows the payout.
///
/// The Crossmint environment comes from the API key. Attach event handlers with ``onReady(_:)``,
/// ``onStatusChange(_:)``, ``onComplete(_:)``, ``onCancel(_:)``, and ``onError(_:)``.
///
/// The view takes the height of the page, unless `fill` is `true`. A change to the credentials, the appearance, the
/// locale, `fill`, or to whether the payer has `signMessage` reloads the page. The payer and the handlers can change
/// without a reload.
///
/// Identity verification uses the camera. Add `NSCameraUsageDescription` to your app's Info.plist.
///
/// ```swift
/// CrossmintEmbeddedOfframp(
///     apiKey: "ck_production_...",
///     credentials: EmbeddedOfframpCredentials(sessionId: sessionId, clientSecret: clientSecret),
///     payer: EmbeddedOfframpPayer(signAndSendTransaction: { transaction in
///         try await wallet.signAndSend(transaction.serializedTransaction, on: transaction.chain)
///     })
/// )
/// .onComplete { completion in print("Deposit sent: \(completion.txId)") }
/// .onCancel { dismiss() }
/// ```
public struct CrossmintEmbeddedOfframp: View {
    private let apiKey: String
    private let credentials: EmbeddedOfframpCredentials
    private let payer: EmbeddedOfframpPayer
    private let appearance: CheckoutAppearance?
    private let locale: CheckoutLocale?
    private let fill: Bool
    private var onReadyHandler: (() -> Void)?
    private var onStatusChangeHandler: ((OfframpStatusChange) -> Void)?
    private var onCompleteHandler: ((OfframpCompletion) -> Void)?
    private var onCancelHandler: (() -> Void)?
    private var onErrorHandler: ((OfframpError) -> Void)?
    @Environment(\.colorScheme) private var colorScheme
    @State private var loadColorScheme: ColorScheme?
    // Until the page reports its own height. WebKit may throttle a page that has no height.
    private static let initialHeight: CGFloat = 500
    @State private var height = Self.initialHeight
    private static let surface = LogSurface.embeddedOfframp

    /// Creates an offramp view.
    ///
    /// - Parameters:
    ///   - apiKey: Your client-side API key. The key starts with `ck_`.
    ///   - credentials: The credentials of the offramp session.
    ///   - payer: Signs and sends the deposit from your wallet.
    ///   - appearance: The visual customization. A `nil` value keeps the offramp defaults.
    ///   - locale: The language of the screens. A `nil` value uses the device language, else English.
    ///   - fill: Fills the height that the layout gives the view instead of taking the height of the page.
    ///   - consoleLogLevel: The minimum level of the SDK messages that reach the system console.
    public init(
        apiKey: String,
        credentials: EmbeddedOfframpCredentials,
        payer: EmbeddedOfframpPayer,
        appearance: CheckoutAppearance? = nil,
        locale: CheckoutLocale? = nil,
        fill: Bool = false,
        consoleLogLevel: CheckoutLogLevel = .error
    ) {
        Logger.level = consoleLogLevel
        self.apiKey = apiKey
        self.credentials = credentials
        self.payer = payer
        self.appearance = appearance
        self.locale = locale
        self.fill = fill
    }

    /// Adds an action to perform when the first screen shows. It runs once per load.
    public func onReady(_ action: @escaping () -> Void) -> Self {
        var view = self
        view.onReadyHandler = action
        return view
    }

    /// Adds an action to perform when the flow moves to another step.
    public func onStatusChange(_ action: @escaping (OfframpStatusChange) -> Void) -> Self {
        var view = self
        view.onStatusChangeHandler = action
        return view
    }

    /// Adds an action to perform when the deposit is confirmed. It can run again for a reopened withdrawal,
    /// so deduplicate by `orderId`.
    public func onComplete(_ action: @escaping (OfframpCompletion) -> Void) -> Self {
        var view = self
        view.onCompleteHandler = action
        return view
    }

    /// Adds an action to perform when the user closes the flow. Without it, the Continue, Close, and Cancel buttons
    /// do nothing.
    public func onCancel(_ action: @escaping () -> Void) -> Self {
        var view = self
        view.onCancelHandler = action
        return view
    }

    /// Adds an action to perform when something goes wrong. `retriable` shows if a new attempt can work.
    public func onError(_ action: @escaping (OfframpError) -> Void) -> Self {
        var view = self
        view.onErrorHandler = action
        return view
    }

    public var body: some View {
        Group {
            switch pageUrlResult {
            case .success(let url):
                HostedWebView(
                    url: url.absoluteString,
                    navigationPolicy: .page(url),
                    isScrollEnabled: true,
                    injectsViewportScript: false,
                    reloadsAfterProcessTermination: true,
                    logAttributes: logAttributes,
                    onMessage: { body, responder in handle(body, responder) },
                    onLoadFailure: { message, statusCode in
                        report(OfframpError(loadFailure: message, statusCode: statusCode))
                    }
                )
                .frame(height: fill ? nil : height)
                .onChange(of: url) { _ in height = Self.initialHeight }
            case .failure(let error):
                CheckoutErrorView(error: error, surface: Self.surface)
                    .onAppear {
                        onErrorHandler?(OfframpError(
                            retriable: false,
                            reason: .invalidConfiguration,
                            message: error.localizedDescription
                        ))
                    }
            }
        }
        .onAppear {
            if loadColorScheme == nil {
                loadColorScheme = colorScheme
            }
        }
    }

    private var logAttributes: [String: String] {
        [
            "surface": Self.surface.rawValue,
            "sessionId": credentials.sessionId,
            "locale": locale?.rawValue ?? "default",
            "fill": String(fill),
            "canSignMessage": String(payer.signMessage != nil)
        ]
    }

    @MainActor
    @discardableResult
    func handle(_ messageBody: Any, _ responder: BridgeResponder) -> Task<Void, Never>? {
        guard let event = OfframpEvent(messageBody: messageBody) else { return nil }
        let attributes = ["sessionId": credentials.sessionId]
        switch event {
        case .heightChanged(let reported):
            height = reported
        case .ready:
            Logger.checkout.info(LogEvents.offrampReady, attributes: attributes)
            onReadyHandler?()
        case .statusChanged(let change):
            Logger.checkout.info(LogEvents.offrampStatusChanged, attributes: attributes.merging([
                "status": change.status.rawValue,
                "orderId": change.orderId ?? ""
            ]) { $1 })
            onStatusChangeHandler?(change)
        case .completed(let completion):
            Logger.checkout.info(LogEvents.offrampCompleted, attributes: attributes.merging(["orderId": completion.orderId]) { $1 })
            onCompleteHandler?(completion)
        case .cancelled:
            Logger.checkout.info(LogEvents.offrampCancelled, attributes: attributes)
            onCancelHandler?()
        case .failed(let error):
            report(error)
        case .sendTransaction(let transaction):
            let payer = payer
            return responder.answer(OfframpEvent.Name.sendTransaction.rawValue) { await payer.reply(to: transaction) }
        case .signMessage(let message):
            let payer = payer
            return responder.answer(OfframpEvent.Name.signMessage.rawValue) { await payer.reply(to: message) }
        }
        return nil
    }

    private func report(_ error: OfframpError) {
        Logger.checkout.error(LogEvents.offrampError, attributes: [
            "sessionId": credentials.sessionId,
            "reason": error.reason.rawValue,
            "retriable": String(error.retriable),
            "message": error.message
        ])
        onErrorHandler?(error)
    }

    private var pageUrlResult: Result<URL, Error> {
        Result { try generatePageUrl(colorScheme: loadColorScheme ?? colorScheme) }
    }

    func generatePageUrl(colorScheme: ColorScheme = .light) throws -> URL {
        let environment = try CheckoutEnvironment(apiKey: apiKey)
        DataDogConfig.configure(for: environment)

        var queryItems = [
            URLQueryItem(name: "credentials", value: try credentials.toJSON()),
            URLQueryItem(name: "apiKey", value: apiKey),
            try HostedPageURL.sdkMetadataItem()
        ]
        if let appearance {
            queryItems.append(URLQueryItem(
                name: "appearance",
                value: try appearance.toJSON(userInfo: [.checkoutColorScheme: colorScheme])
            ))
        }
        if let locale {
            queryItems.append(URLQueryItem(name: "locale", value: locale.rawValue))
        }
        if fill {
            queryItems.append(URLQueryItem(name: "fill", value: "true"))
        }
        if payer.signMessage != nil {
            queryItems.append(URLQueryItem(name: "canSignMessage", value: "true"))
        }

        let url = try HostedPageURL.build(
            host: environment.crossmintHost,
            path: "/sdk/unstable/embedded-offramp",
            queryItems: queryItems
        )
        // The page reads the query with URLSearchParams, which turns a literal + into a space.
        guard let pageUrl = URL(string: url.replacingOccurrences(of: "+", with: "%2B")) else {
            throw CheckoutError.invalidConfiguration("Failed to construct URL")
        }
        return pageUrl
    }
}
