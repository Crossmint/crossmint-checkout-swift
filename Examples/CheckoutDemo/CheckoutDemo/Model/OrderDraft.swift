//
//  OrderDraft.swift
//  CheckoutDemo
//
//  Created by Tomás Martins on 8/31/26.
//

import Foundation

nonisolated struct OrderDraft: Equatable {
    var tokenSymbol: String = TokenPreset.usdc.symbol
    var networkLocator: String = TokenPreset.usdc.networks[0].locator
    var customTokenLocator: String = ""
    var amountText: String = "1"
    var recipientWalletAddress: String = ""
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

    var amount: Decimal? {
        try? Decimal(amountText.trimmingCharacters(in: .whitespacesAndNewlines), format: .number)
    }

    var amountString: String {
        (amount ?? 0).formatted(
            .number
                .grouping(.never)
                .precision(.fractionLength(0...6))
                .locale(Locale(identifier: "en_US_POSIX"))
        )
    }

    var validationMessage: String? {
        if tokenLocator.isEmpty { return "Enter a token locator." }
        if !tokenLocator.contains(":") { return "A token locator looks like <chain>:<contractAddress>." }
        guard let amount, amount > 0 else { return "Enter an amount greater than zero." }
        if recipientWalletAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Enter the wallet address that receives the token."
        }
        if receiptEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Enter a receipt email."
        }
        return nil
    }
}
