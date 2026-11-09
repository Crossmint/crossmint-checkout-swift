# CrossmintCheckout

A Swift Package for embedding [Crossmint's](https://www.crossmint.com) checkout experience in iOS apps.

## Installation

Add the package via Swift Package Manager:

In Xcode: **File > Add Package Dependencies**, paste the URL below, and select **Up to Next Major Version** from `1.0.0`.

```
https://github.com/Crossmint/crossmint-checkout-swift.git
```

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/Crossmint/crossmint-checkout-swift.git", from: "1.0.0")
]
```

Then add `"CrossmintCheckout"` to your target's dependencies.

## Quick Start

### 1. Create an order server-side

Use the [Crossmint Orders API](https://docs.crossmint.com/api-reference/headless/create-order) to create an order from your backend. The response includes an `orderId` and `clientSecret`.

```
POST https://www.crossmint.com/api/2022-06-09/orders
```

### 2. Render the checkout client-side

Pass your **client-side API key** (`ck_...`) — the same key used by the Orders API's client-side counterpart. It is required; without it the hosted checkout renders an "Invalid input" configuration error.

```swift
import SwiftUI
import CrossmintCheckout

struct CheckoutView: View {
    let orderId: String
    let clientSecret: String

    var body: some View {
        CrossmintEmbeddedCheckout(
            apiKey: "ck_production_...",
            orderId: orderId,
            clientSecret: clientSecret
        )
    }
}
```

## Properties

| Property | Type | Required | Description |
|---|---|---|---|
| `apiKey` | `String` | Yes | Your client-side API key (`ck_...`) |
| `orderId` | `String?` | Yes* | The order ID returned by the Orders API |
| `clientSecret` | `String?` | Yes* | The client secret returned by the Orders API |
| `payment` | `CheckoutPayment?` | No | Payment configuration (fiat/crypto, allowed methods) |
| `appearance` | `CheckoutAppearance?` | No | UI customization (colors, fonts, border radius) |
| `lineItems` | `CheckoutLineItems?` | No | Line item configuration (not yet implemented) |
| `recipient` | `CheckoutRecipient?` | No | Recipient configuration (not yet implemented) |
| `identityVerificationHandling` | `IdentityVerificationHandling?` | No | `.external` renders no KYC step inside checkout; you present it yourself (see below) |
| `controller` | `CrossmintCheckoutController?` | No | Observable order state (order, client secret, KYC credentials) |
| `consoleLogLevel` | `CheckoutLogLevel` | No | Minimum level of SDK messages written to the system console. Diagnostics also go to Crossmint at every level. Defaults to `.error` |

### Payment Configuration

```swift
CrossmintEmbeddedCheckout(
    apiKey: "ck_production_...",
    orderId: orderId,
    clientSecret: clientSecret,
    payment: CheckoutPayment(
        crypto: CheckoutCryptoPayment(enabled: true, defaultChain: "base"),
        fiat: CheckoutFiatPayment(
            enabled: true,
            defaultCurrency: "usd",
            allowedMethods: CheckoutAllowedMethods(applePay: true, card: true)
        ),
        defaultMethod: .fiat
    )
)
```

### Appearance Customization

```swift
CrossmintEmbeddedCheckout(
    apiKey: "ck_production_...",
    orderId: orderId,
    clientSecret: clientSecret,
    appearance: CheckoutAppearance(
        fonts: [.googleFonts("Inter", weights: [.regular, .semibold])],
        variables: CheckoutAppearanceVariables(
            fontFamily: "Inter, sans-serif",
            spacingUnit: 4,
            borderRadius: 8,
            colors: CheckoutVariablesColorStyle(
                textPrimary: .color(.primary),
                textSecondary: .color(.secondary),
                backgroundPrimary: .uiColor(.systemBackground),
                borderPrimary: .hex("#E0E0E0")
            )
        ),
        rules: CheckoutAppearanceRules(
            primaryButton: CheckoutPrimaryButtonRule(
                borderRadius: 12,
                font: CheckoutFontStyle(size: .px(17), weight: .semibold),
                colors: CheckoutColorStyle(text: .color(.white), background: .hex("#6C5CE7"))
            )
        )
    )
)
```

Load fonts with `.googleFonts(_:weights:)`, or with `.cssURL(_:)` for other Google Fonts links. The checkout ignores stylesheets from other domains.

Set colors with a SwiftUI `Color`, a `UIColor`, a hex string, or a CSS color string. If a color changes between light and dark mode, the checkout uses the value for its mode when it loads.

Set lengths such as `borderRadius` and `spacingUnit` with a number of points, or with `.rem(_:)`, `.em(_:)`, or `.custom(_:)`.

> **Note:** `lineItems` and `recipient` are accepted as parameters but not yet implemented. Passing either will display an error.

## Order Updates

Pass a `CrossmintCheckoutController` to observe the order as the buyer progresses. The controller exposes the latest `order`, the `orderClientSecret`, and derived `identityVerificationCredentials`.

```swift
struct CheckoutView: View {
    @StateObject private var controller = CrossmintCheckoutController()

    var body: some View {
        CrossmintEmbeddedCheckout(
            apiKey: "ck_production_...",
            orderId: orderId,
            clientSecret: clientSecret,
            controller: controller
        )
        .onReceive(controller.$order) { order in
            print("Order phase: \(String(describing: order?.phase))")
        }
    }
}
```

Order events are also available as chained methods: `.onOrderUpdated { update in }` and `.onOrderCreationFailed { message in }`.

Reusing a controller across checkout sessions requires calling `clear()` first.

## Identity Verification (KYC)

Some orders require identity verification before payment. By default checkout renders that step inline and you do nothing.

To show the step in your own layout instead, pass `identityVerificationHandling: .external` to checkout. Then watch the controller for credentials and present `CrossmintIdentityVerification` with them. A sheet works well: present it when the order first has credentials, keep passing the latest ones while it is open, close it in `onComplete` or `onCancel`, and do not reopen it for that order, even after a swipe dismiss. Do not close it when the credentials go away: the order can leave `requires-kyc` as soon as the buyer submits, before the flow shows its result. Track the closed order by its `orderId`, not the credentials `id`, which can repeat across orders.

```swift
struct CheckoutView: View {
    @StateObject private var controller = CrossmintCheckoutController()
    @State private var kycCredentials: IdentityVerificationCredentials?
    @State private var kycClosedOrderId: String?

    var body: some View {
        CrossmintEmbeddedCheckout(
            apiKey: "ck_production_...",
            orderId: orderId,
            clientSecret: clientSecret,
            identityVerificationHandling: .external,
            controller: controller
        )
        .onChange(of: controller.identityVerificationCredentials) { credentials in
            if let credentials, controller.order?.orderId != kycClosedOrderId {
                kycCredentials = credentials
            }
        }
        .sheet(item: $kycCredentials, onDismiss: { kycClosedOrderId = controller.order?.orderId }) { credentials in
            CrossmintIdentityVerification(
                apiKey: "ck_production_...",
                credentials: credentials
            )
            .onComplete { status in
                print("KYC finished: \(status)")
                kycCredentials = nil
            }
            .onCancel { kycCredentials = nil }
            .onError { error in print("KYC error: \(error.message)") }
        }
    }
}
```

Checkout does not wait for a signal from your component. It polls the order until the backend confirms the verification, then continues on its own.

`CrossmintIdentityVerification` can also be used standalone, without embedded checkout, if you obtain the credentials from your backend's order response (`payment.preparation.kyc`).

### CrossmintIdentityVerification Properties

| Property | Type | Required | Description |
|---|---|---|---|
| `apiKey` | `String` | Yes | Your client-side API key (`ck_...`) |
| `credentials` | `IdentityVerificationCredentials` | Yes | From the controller or your backend's order response |
| `locale` | `CheckoutLocale?` | No | UI language of the verification flow |
| `consoleLogLevel` | `CheckoutLogLevel` | No | Minimum level of SDK messages written to the system console. Diagnostics also go to Crossmint at every level. Defaults to `.error` |

### Event handlers

Attach handlers with chained methods, all optional:

- `.onReady { }` — the verification UI finished loading
- `.onComplete { status in }` — the buyer finished; the status carries the outcome
- `.onCancel { }` — the buyer dismissed the flow
- `.onError { error in }` — something failed; `retriable` says whether showing the view again can work

The view fills the space you give it, and the verification content scrolls inside the view. Use `onReady` to drive your own loading indicator.

> **Note:** Document capture needs camera access. Add `NSCameraUsageDescription` to your app's Info.plist or the capture step fails.

> **Note:** `identityVerificationHandling` requires a current Crossmint deployment. Older deployments ignore the flag and render the verification step inline as well.

## Embedded Offramp

`CrossmintEmbeddedOfframp` runs one offramp session: the user adds a bank account, gets a quote, verifies their identity when needed, and confirms one deposit that your wallet signs and sends. The view then follows the payout.

Create the session on your server with Create Offramp Session and pass its `sessionId` and `clientSecret`. The payer signs with your wallet.

```swift
struct OfframpView: View {
    let sessionId: String
    let clientSecret: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        CrossmintEmbeddedOfframp(
            apiKey: "ck_production_...",
            credentials: EmbeddedOfframpCredentials(sessionId: sessionId, clientSecret: clientSecret),
            payer: EmbeddedOfframpPayer(
                signAndSendTransaction: { transaction in
                    try await wallet.signAndSend(transaction.serializedTransaction, on: transaction.chain)
                },
                signMessage: { request in try await wallet.sign(request.message) }
            ),
            locale: .esES
        )
        .onComplete { completion in print("Deposit sent: \(completion.txId)") }
        .onCancel { dismiss() }
        .onError { error in if !error.retriable { dismiss() } }
    }
}
```

`signAndSendTransaction` returns the transaction hash, or the signature on Solana. `signMessage` is optional: the offramp asks for it only when the user must prove that they own the wallet. Throw `OfframpSignatureRejectedError` from either one only when the user declined; the offramp treats any other error as an unknown outcome and waits for the deposit. Keep the view on screen while the payer runs, since a removed view drops the reply.

### CrossmintEmbeddedOfframp Properties

| Property | Type | Required | Description |
|---|---|---|---|
| `apiKey` | `String` | Yes | Your client-side API key (`ck_...`) |
| `credentials` | `EmbeddedOfframpCredentials` | Yes | The `sessionId` and `clientSecret` of the offramp session |
| `payer` | `EmbeddedOfframpPayer` | Yes | Signs and sends the deposit, and optionally signs the wallet ownership proof |
| `appearance` | `CheckoutAppearance?` | No | UI customization, as in checkout |
| `locale` | `CheckoutLocale?` | No | UI language of the offramp |
| `fill` | `Bool` | No | Fills the height the layout gives the view instead of taking the height of the page. Defaults to `false` |
| `consoleLogLevel` | `CheckoutLogLevel` | No | Minimum level of SDK messages written to the system console. Defaults to `.error` |

Attach handlers with `.onReady { }`, `.onStatusChange { change in }`, `.onComplete { completion in }`, `.onCancel { }` and `.onError { error in }`. `onComplete` can run again for a reopened withdrawal, so deduplicate by `orderId`. Without `onCancel`, the Continue, Close and Cancel buttons do nothing.

Links the user opens away from the offramp open in Safari. Identity verification uses the camera, so add `NSCameraUsageDescription` to your app's Info.plist.

## Example App

See a full working example at [crossmint-swift-checkout-demo](https://github.com/Crossmint/crossmint-swift-checkout-demo).

## Documentation

- [Swift Quickstart](https://docs.crossmint.com/stablecoin-orchestration/onramp/quickstarts/swift)
- [Create Order API](https://docs.crossmint.com/api-reference/headless/create-order)
- [Crossmint Docs](https://docs.crossmint.com)

## License

See [LICENSE](LICENSE) for details.
