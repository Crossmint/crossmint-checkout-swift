//
//  OrderDraft.swift
//  CheckoutDemo
//
//  Created by Tomás Martins on 8/31/26.
//

import Foundation

nonisolated struct OrderDraft: Equatable {
    enum Method: String, CaseIterable, Identifiable {
        case card
        case crypto

        var id: Self { self }

        var title: String {
            switch self {
            case .card: "Card"
            case .crypto: "Crypto"
            }
        }
    }

    var tokenSymbol: String = TokenPreset.usdc.symbol
    var networkLocator: String = TokenPreset.usdc.networks[0].locator
    var customTokenLocator: String = ""
    var amount: Decimal = 10
    var method: Method = .card
    var recipientWalletAddress: String = ""
    var payerAddress: String = ""
    var receiptEmail: String = ""

    var preset: TokenPreset? {
        TokenPreset.all.first { $0.symbol == tokenSymbol }
    }

    var network: TokenPreset.Network? {
        guard let preset else { return nil }
        return preset.networks.first { $0.locator == networkLocator } ?? preset.networks.first
    }

    var networkSelection: String {
        get { network?.locator ?? networkLocator }
        set { networkLocator = newValue }
    }

    var tokenLocator: String {
        network?.locator ?? customTokenLocator.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var amountString: String {
        amount.formatted(.number.grouping(.never).precision(.fractionLength(0...6)))
    }

    var chain: String {
        network?.chainID ?? String(tokenLocator.prefix(while: { $0 != ":" }))
    }

    var validationMessage: String? {
        if tokenLocator.isEmpty { return "Enter a token locator." }
        if !tokenLocator.contains(":") { return "A token locator looks like <chain>:<contractAddress>." }
        if amount <= 0 { return "Enter an amount greater than zero." }
        if recipientWalletAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Enter the wallet address that receives the token."
        }
        if method == .crypto, payerAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Enter the address that pays."
        }
        if receiptEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Enter a receipt email."
        }
        return nil
    }
}
