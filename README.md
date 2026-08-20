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
            clientSecret: clientSecret,
            environment: .production
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
| `environment` | `CheckoutEnvironment` | No | `.staging` (default) or `.production` |
| `lineItems` | `CheckoutLineItems?` | No | Line item configuration (not yet implemented) |
| `recipient` | `CheckoutRecipient?` | No | Recipient configuration (not yet implemented) |
| `identityVerificationHandling` | `IdentityVerificationHandling?` | No | `.external` renders no KYC step inside checkout; you present it yourself (see below) |
| `controller` | `CrossmintCheckoutController?` | No | Observable order state (order, client secret, KYC credentials) |
| `onOrderUpdated` | `((CheckoutOrderUpdate) -> Void)?` | No | Called on every order update from the checkout page |
| `onOrderCreationFailed` | `((String) -> Void)?` | No | Called with the error message when order creation fails |

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
    ),
    environment: .production
)
```

### Appearance Customization

```swift
CrossmintEmbeddedCheckout(
    apiKey: "ck_production_...",
    orderId: orderId,
    clientSecret: clientSecret,
    appearance: CheckoutAppearance(
        variables: CheckoutAppearanceVariables(
            colors: CheckoutColorStyle(
                background: "#FFFFFF",
                text: "#000000"
            )
        ),
        rules: CheckoutAppearanceRules(
            primaryButton: CheckoutPrimaryButtonRule(
                borderRadius: "8px",
                colors: CheckoutColorStyle(background: "#6C5CE7", text: "#FFFFFF")
            )
        )
    ),
    environment: .production
)
```

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
            controller: controller,
            environment: .production
        )
        .onReceive(controller.$order) { order in
            print("Order phase: \(order?.phase ?? "-")")
        }
    }
}
```

Reusing a controller across checkout sessions requires calling `clear()` first.

## Identity Verification (KYC)

Some orders require identity verification before payment. By default checkout renders that step inline and you do nothing.

To show the step in your own layout instead, pass `identityVerificationHandling: .external` to checkout. Then watch the controller for credentials and present `CrossmintIdentityVerification` with them. A sheet works well: the credentials appear when the order needs verification, and they go away when the backend confirms it.

```swift
struct CheckoutView: View {
    @StateObject private var controller = CrossmintCheckoutController()
    @State private var kycCredentials: IdentityVerificationCredentials?

    var body: some View {
        CrossmintEmbeddedCheckout(
            apiKey: "ck_production_...",
            orderId: orderId,
            clientSecret: clientSecret,
            identityVerificationHandling: .external,
            controller: controller,
            environment: .production
        )
        .onReceive(controller.$order) { _ in
            kycCredentials = controller.identityVerificationCredentials
        }
        .sheet(item: $kycCredentials) { credentials in
            ScrollView {
                CrossmintIdentityVerification(
                    apiKey: "ck_production_...",
                    credentials: credentials,
                    environment: .production,
                    onComplete: { status in print("KYC finished: \(status)") },
                    onError: { error in print("KYC error: \(error.message)") }
                )
            }
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
| `environment` | `CheckoutEnvironment` | No | `.staging` (default) or `.production` |
| `onReady` | `(() -> Void)?` | No | The verification UI finished loading |
| `onComplete` | `((IdentityVerificationStatus) -> Void)?` | No | The buyer finished; carries the outcome |
| `onCancel` | `(() -> Void)?` | No | The buyer dismissed the flow |
| `onError` | `((IdentityVerificationError) -> Void)?` | No | Something failed; `retriable` says whether presenting again can work |

The view renders at zero height until the hosted page reports its size, then tracks it. Use `onReady` to drive your own loading indicator.

> **Note:** Document capture needs camera access. Add `NSCameraUsageDescription` to your app's Info.plist or the capture step fails.

> **Note:** `identityVerificationHandling` requires a current Crossmint deployment. Older deployments ignore the flag and render the verification step inline as well.

## Example App

See a full working example at [crossmint-swift-checkout-demo](https://github.com/Crossmint/crossmint-swift-checkout-demo).

## Documentation

- [Swift Quickstart](https://docs.crossmint.com/stablecoin-orchestration/onramp/quickstarts/swift)
- [Create Order API](https://docs.crossmint.com/api-reference/headless/create-order)
- [Crossmint Docs](https://docs.crossmint.com)

## License

See [LICENSE](LICENSE) for details.
