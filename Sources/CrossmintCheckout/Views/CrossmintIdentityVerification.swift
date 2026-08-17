//
//  CrossmintIdentityVerification.swift
//  CrossmintCheckout
//
//  Created by Tomás Martins on 8/17/26.
//

import SwiftUI

/// Renders Crossmint's hosted identity verification (KYC) step in your own layout.
///
/// The view is self-sizing: it renders at zero height until the hosted page reports its content
/// height, then tracks it. Use `onReady` to drive your own loading UI.
///
/// Document capture needs camera access: add `NSCameraUsageDescription` to your app's Info.plist,
/// or the capture step fails.
public struct CrossmintIdentityVerification: View {
    private let apiKey: String
    private let credentials: IdentityVerificationCredentials
    private let locale: CheckoutLocale?
    private let environment: CheckoutEnvironment
    private let onReady: (() -> Void)?
    private let onComplete: ((IdentityVerificationStatus) -> Void)?
    private let onCancel: (() -> Void)?
    private let onError: ((IdentityVerificationError) -> Void)?

    @State private var height: CGFloat = 0

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
                navigationPolicy: .crossmintMainFrame(resolvedHost: resolvedHost),
                allowsMediaCapture: true,
                isScrollEnabled: true,
                injectsViewportScript: false,
                onEnvelope: { envelope, _ in handle(envelope) },
                onLoadFailure: { message in
                    onError?(IdentityVerificationError(
                        retriable: false,
                        reason: .widgetUnavailable,
                        message: message
                    ))
                }
            )
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .onChange(of: url) { _ in
                height = 0
            }
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

    private func handle(_ envelope: BridgeEnvelope) {
        guard let event = IdentityVerificationEvent(envelope: envelope) else { return }
        switch event {
        case .heightChanged(let reported):
            guard reported.isFinite, reported > 0 else { return }
            height = reported
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

    private var resolvedHost: String {
        environment == .production ? "www.crossmint.com" : "staging.crossmint.com"
    }

    private var verificationUrlResult: Result<String, Error> {
        Result { try generateVerificationUrl() }
    }

    func generateVerificationUrl() throws -> String {
        guard !apiKey.isEmpty else {
            throw CheckoutError.invalidConfiguration("apiKey is required")
        }

        let baseUrl = "https://\(resolvedHost)/sdk/unstable/identity-verification"
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
