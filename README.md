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

```swift
import SwiftUI
import CrossmintCheckout

struct CheckoutView: View {
    let orderId: String
    let clientSecret: String

    var body: some View {
        CrossmintEmbeddedCheckout(
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
| `orderId` | `String?` | Yes* | The order ID returned by the Orders API |
| `clientSecret` | `String?` | Yes* | The client secret returned by the Orders API |
| `payment` | `CheckoutPayment?` | No | Payment configuration (fiat/crypto, allowed methods) |
| `appearance` | `CheckoutAppearance?` | No | UI customization (colors, fonts, border radius) |
| `environment` | `CheckoutEnvironment` | No | `.staging` (default) or `.production` |
| `lineItems` | `CheckoutLineItems?` | No | Line item configuration (not yet implemented) |
| `recipient` | `CheckoutRecipient?` | No | Recipient configuration (not yet implemented) |

### Payment Configuration

```swift
CrossmintEmbeddedCheckout(
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

## Example App

See a full working example at [crossmint-swift-checkout-demo](https://github.com/Crossmint/crossmint-swift-checkout-demo).

## Documentation

- [Swift Quickstart](https://docs.crossmint.com/stablecoin-orchestration/onramp/quickstarts/swift)
- [Create Order API](https://docs.crossmint.com/api-reference/headless/create-order)
- [Crossmint Docs](https://docs.crossmint.com)

## License

See [LICENSE](LICENSE) for details.
