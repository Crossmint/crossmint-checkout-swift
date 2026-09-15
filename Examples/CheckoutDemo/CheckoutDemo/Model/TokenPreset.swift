//
//  TokenPreset.swift
//  CheckoutDemo
//
//  Created by Tomás Martins on 8/31/26.
//

import Foundation

nonisolated struct TokenPreset: Identifiable, Hashable {
    nonisolated struct Network: Identifiable, Hashable {
        let chain: String
        let network: String
        let locator: String

        var id: String { locator }

        var title: String { "\(chain) (\(network))" }

        var chainID: String {
            String(locator.prefix(while: { $0 != ":" }))
        }
    }

    let symbol: String
    let networks: [Network]

    var id: String { symbol }

    static let custom = "custom"

    static let usdc = TokenPreset(
        symbol: "USDC",
        networks: [
            Network(
                chain: "Base",
                network: "Sepolia",
                locator: "base-sepolia:0x036CbD53842c5426634e7929541eC2318f3dCF7e"
            ),
            Network(
                chain: "Ethereum",
                network: "Sepolia",
                locator: "ethereum-sepolia:0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238"
            ),
            Network(
                chain: "Polygon",
                network: "Amoy",
                locator: "polygon-amoy:0x41E94Eb019C0762f9Bfcf9Fb1E58725BfB0e7582"
            ),
            Network(
                chain: "Solana",
                network: "Devnet",
                locator: "solana:4zMMC9srt5Ri5X14GAgXhaHii3GnPAEERYPJgZJDncDU"
            ),
            Network(
                chain: "Stellar",
                network: "Testnet",
                locator: "stellar:CBIELTK6YBZJU5UP2WWQEUCYKLPU6AUNZ2BQ4WWFEIE3USCIHMXQDAMA"
            ),
        ]
    )

    static let eurc = TokenPreset(
        symbol: "EURC",
        networks: [
            Network(
                chain: "Base",
                network: "Sepolia",
                locator: "base-sepolia:0x808456652fdb597867f38412077A9182bf77359F"
            ),
            Network(
                chain: "Solana",
                network: "Devnet",
                locator: "solana:HzwqbKZw8HxMN6bF2yFZNrht3c2iXXzpKcFu7uBEDKtr"
            ),
            Network(
                chain: "Stellar",
                network: "Testnet",
                locator: "stellar:CCUUDM434BMZMYWYDITHFXHDMIVTGGD6T2I5UKNX5BSLXLW7HVR4MCGZ"
            ),
        ]
    )

    static let all: [TokenPreset] = [usdc, eurc]
}
