//
//  TokenPreset.swift
//  CheckoutDemo
//
//  Created by Tomás Martins on 8/31/26.
//

import Foundation

nonisolated struct TokenPreset: Identifiable, Hashable {
    let id: String
    let name: String
    let locator: String
    let chain: String

    static let baseSepoliaUSDC = TokenPreset(
        id: "base-sepolia-usdc",
        name: "USDC on Base Sepolia",
        locator: "base-sepolia:0x036CbD53842c5426634e7929541eC2318f3dCF7e",
        chain: "base-sepolia"
    )

    static let ethereumSepoliaUSDC = TokenPreset(
        id: "ethereum-sepolia-usdc",
        name: "USDC on Ethereum Sepolia",
        locator: "ethereum-sepolia:0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238",
        chain: "ethereum-sepolia"
    )

    static let polygonAmoyUSDC = TokenPreset(
        id: "polygon-amoy-usdc",
        name: "USDC on Polygon Amoy",
        locator: "polygon-amoy:0x41E94Eb019C0762f9Bfcf9Fb1E58725BfB0e7582",
        chain: "polygon-amoy"
    )

    static let all: [TokenPreset] = [baseSepoliaUSDC, ethereumSepoliaUSDC, polygonAmoyUSDC]
}
