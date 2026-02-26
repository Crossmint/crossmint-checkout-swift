// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "crossmint-checkout-swift",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "CrossmintCheckout",
            targets: ["CrossmintCheckout"]
        )
    ],
    targets: [
        .target(
            name: "CrossmintCheckout"
        ),
        .testTarget(
            name: "CrossmintCheckoutTests",
            dependencies: ["CrossmintCheckout"]
        )
    ]
)
