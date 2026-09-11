//
//  CrossmintIdentityVerification.swift
//  CrossmintCheckout
//
//  Created by Tomás Martins on 8/17/26.
//

import SwiftUI

/// A view that shows Crossmint's hosted identity verification (KYC) step.
///
/// The view fills the space the layout gives it. The verification content scrolls inside the view.
/// The Crossmint environment comes from the API key. Attach event handlers with
/// ``onReady(_:)``, ``onComplete(_:)``, ``onCancel(_:)``, and ``onError(_:)``.
///
/// Document capture needs camera access. Add `NSCameraUsageDescription` to your app's Info.plist.
public struct CrossmintIdentityVerification: View {
    private let apiKey: String
    private let credentials: IdentityVerificationCredentials
    private let locale: CheckoutLocale?
    private var onReadyHandler: (() -> Void)?
    private var onCompleteHandler: ((IdentityVerificationStatus) -> Void)?
    private var onCancelHandler: (() -> Void)?
    private var onErrorHandler: ((IdentityVerificationError) -> Void)?

    /// Creates an identity verification view.
    ///
    /// - Parameters:
    ///   - apiKey: Your client-side API key. The key starts with `ck_`.
    ///   - credentials: The credentials of the pending verification, from the order.
    ///   - locale: The language of the verification UI. A `nil` value uses the default of the hosted page.
    ///   - consoleLogLevel: The minimum level of the SDK messages that reach the system console.
    public init(
        apiKey: String,
        credentials: IdentityVerificationCredentials,
        locale: CheckoutLocale? = nil,
        consoleLogLevel: CheckoutLogLevel = .error
    ) {
        Logger.level = consoleLogLevel
        self.apiKey = apiKey
        self.credentials = credentials
        self.locale = locale
    }

    /// Adds an action to perform when the verification UI finishes loading.
    public func onReady(_ action: @escaping () -> Void) -> Self {
        var view = self
        view.onReadyHandler = action
        return view
    }

    /// Adds an action to perform when the buyer finishes the verification. The status gives the result.
    public func onComplete(_ action: @escaping (IdentityVerificationStatus) -> Void) -> Self {
        var view = self
        view.onCompleteHandler = action
        return view
    }

    /// Adds an action to perform when the buyer dismisses the verification flow.
    public func onCancel(_ action: @escaping () -> Void) -> Self {
        var view = self
        view.onCancelHandler = action
        return view
    }

    /// Adds an action to perform when the verification fails. `retriable` shows if a new attempt can work.
    public func onError(_ action: @escaping (IdentityVerificationError) -> Void) -> Self {
        var view = self
        view.onErrorHandler = action
        return view
    }

    public var body: some View {
        switch verificationUrlResult {
        case .success(let url):
            HostedWebView(
                url: url,
                navigationPolicy: .crossmintMainFrame(resolvedHost: URL(string: url)?.host ?? ""),
                allowsMediaCapture: true,
                isScrollEnabled: true,
                injectsViewportScript: false,
                onMessage: { body, _ in handle(body) },
                onLoadFailure: { message in
                    onErrorHandler?(IdentityVerificationError(
                        retriable: false,
                        reason: .widgetUnavailable,
                        message: message
                    ))
                }
            )
        case .failure(let error):
            CheckoutErrorView(error: error)
        }
    }

    @MainActor
    private func handle(_ messageBody: Any) {
        guard let event = IdentityVerificationEvent(messageBody: messageBody) else { return }
        switch event {
        case .ready:
            onReadyHandler?()
        case .completed(let status):
            onCompleteHandler?(status)
        case .cancelled:
            onCancelHandler?()
        case .failed(let error):
            onErrorHandler?(error)
        }
    }

    private var verificationUrlResult: Result<String, Error> {
        Result { try generateVerificationUrl() }
    }

    func generateVerificationUrl() throws -> String {
        let environment = try CheckoutEnvironment(apiKey: apiKey)
        DataDogConfig.configure(for: environment)

        var queryItems: [URLQueryItem] = []
        queryItems.append(URLQueryItem(name: "credentials", value: try credentials.toJSON()))
        if let locale {
            queryItems.append(URLQueryItem(name: "locale", value: locale.rawValue))
        }
        queryItems.append(URLQueryItem(name: "apiKey", value: apiKey))
        queryItems.append(try HostedPageURL.sdkMetadataItem())

        return try HostedPageURL.build(
            host: environment.crossmintHost,
            path: "/sdk/unstable/identity-verification",
            queryItems: queryItems
        )
    }
}
