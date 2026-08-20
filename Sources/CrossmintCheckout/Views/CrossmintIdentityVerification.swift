//
//  CrossmintIdentityVerification.swift
//  CrossmintCheckout
//
//  Created by Tomás Martins on 8/17/26.
//

import SwiftUI

/// A view that shows Crossmint's hosted identity verification (KYC) step.
///
/// The view fills the space the layout gives it, and the verification content scrolls inside it.
/// Use `onReady` to control your own loading indicator.
///
/// Document capture needs camera access. Add `NSCameraUsageDescription` to your app's Info.plist.
public struct CrossmintIdentityVerification: View {
    private let apiKey: String
    private let credentials: IdentityVerificationCredentials
    private let locale: CheckoutLocale?
    private let environment: CheckoutEnvironment
    private let onReady: (() -> Void)?
    private let onComplete: ((IdentityVerificationStatus) -> Void)?
    private let onCancel: (() -> Void)?
    private let onError: ((IdentityVerificationError) -> Void)?

    public init(
        apiKey: String,
        credentials: IdentityVerificationCredentials,
        locale: CheckoutLocale? = nil,
        environment: CheckoutEnvironment = .staging,
        onReady: (() -> Void)? = nil,
        onComplete: ((IdentityVerificationStatus) -> Void)? = nil,
        onCancel: (() -> Void)? = nil,
        onError: ((IdentityVerificationError) -> Void)? = nil
    ) {
        self.apiKey = apiKey
        self.credentials = credentials
        self.locale = locale
        self.environment = environment
        self.onReady = onReady
        self.onComplete = onComplete
        self.onCancel = onCancel
        self.onError = onError
    }

    public var body: some View {
        switch verificationUrlResult {
        case .success(let url):
            HostedWebView(
                url: url,
                navigationPolicy: .crossmintMainFrame(resolvedHost: environment.crossmintHost),
                allowsMediaCapture: true,
                isScrollEnabled: true,
                injectsViewportScript: false,
                onMessage: { body, _ in handle(body) },
                onLoadFailure: { message in
                    onError?(IdentityVerificationError(
                        retriable: false,
                        reason: .widgetUnavailable,
                        message: message
                    ))
                }
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
    private func handle(_ messageBody: Any) {
        guard let event = IdentityVerificationEvent(messageBody: messageBody) else { return }
        switch event {
        case .ready:
            onReady?()
        case .completed(let status):
            onComplete?(status)
        case .cancelled:
            onCancel?()
        case .failed(let error):
            onError?(error)
        }
    }

    private var verificationUrlResult: Result<String, Error> {
        Result { try generateVerificationUrl() }
    }

    func generateVerificationUrl() throws -> String {
        guard !apiKey.isEmpty else {
            throw CheckoutError.invalidConfiguration("apiKey is required")
        }

        let baseUrl = "https://\(environment.crossmintHost)/sdk/unstable/identity-verification"
        guard var components = URLComponents(string: baseUrl) else {
            throw CheckoutError.invalidConfiguration("Invalid base URL")
        }

        var queryItems: [URLQueryItem] = []
        queryItems.append(URLQueryItem(name: "credentials", value: try credentials.toJSON()))
        if let locale {
            queryItems.append(URLQueryItem(name: "locale", value: locale.rawValue))
        }
        queryItems.append(URLQueryItem(name: "apiKey", value: apiKey))

        let sdkMetadata: [String: String] = [
            "name": "@crossmint/checkout-swift",
            "version": SDKVersion.version
        ]
        queryItems.append(URLQueryItem(name: "sdkMetadata", value: try sdkMetadata.toJSON()))

        components.queryItems = queryItems

        guard let url = components.url?.absoluteString else {
            throw CheckoutError.invalidConfiguration("Failed to construct URL")
        }

        return url
    }
}
