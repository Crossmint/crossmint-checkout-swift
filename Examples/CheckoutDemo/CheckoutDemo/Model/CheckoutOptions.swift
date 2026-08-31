//
//  CheckoutOptions.swift
//  CheckoutDemo
//
//  Created by Tomás Martins on 8/31/26.
//

import CrossmintCheckout

nonisolated struct CheckoutOptions: Equatable {
    var cryptoEnabled: Bool = false
    var fiatEnabled: Bool = true
    var allowCard: Bool = true
    var allowApplePay: Bool = true
    var allowGooglePay: Bool = false

    var hideDestinationInput: Bool = false
    var hideReceiptEmailInput: Bool = false
    var hideGlobalMessage: Bool = false

    var colors = AppearanceColors()
    var borderRadius: Double?

    var externalIdentityVerification: Bool = true

    var payment: CheckoutPayment {
        CheckoutPayment(
            crypto: CheckoutCryptoPayment(enabled: cryptoEnabled),
            fiat: CheckoutFiatPayment(
                enabled: fiatEnabled,
                allowedMethods: CheckoutAllowedMethods(
                    googlePay: allowGooglePay,
                    applePay: allowApplePay,
                    card: allowCard
                )
            )
        )
    }

    var appearance: CheckoutAppearance? {
        let variables = colors.variables
        let rules = appearanceRules
        guard variables != nil || rules != nil else { return nil }
        return CheckoutAppearance(variables: variables, rules: rules)
    }

    var identityVerificationHandling: IdentityVerificationHandling? {
        externalIdentityVerification ? .external : nil
    }

    private var appearanceRules: CheckoutAppearanceRules? {
        let radius = borderRadius.map { "\(Int($0))px" }
        let hasDisplayRule = hideDestinationInput || hideReceiptEmailInput || hideGlobalMessage
        guard hasDisplayRule || radius != nil else { return nil }

        return CheckoutAppearanceRules(
            destinationInput: hideDestinationInput
                ? CheckoutDestinationInputRule(display: "hidden") : nil,
            receiptEmailInput: hideReceiptEmailInput
                ? CheckoutReceiptEmailInputRule(display: "hidden") : nil,
            globalMessage: hideGlobalMessage
                ? CheckoutGlobalMessageRule(display: "hidden") : nil,
            input: radius.map { CheckoutInputRule(borderRadius: $0) },
            tab: radius.map { CheckoutTabRule(borderRadius: $0) },
            primaryButton: radius.map { CheckoutPrimaryButtonRule(borderRadius: $0) }
        )
    }
}

nonisolated struct AppearanceColors: Equatable {
    var textPrimary: String = ""
    var textSecondary: String = ""
    var backgroundPrimary: String = ""
    var borderPrimary: String = ""
    var danger: String = ""
    var warning: String = ""
    var accent: String = ""

    var isEmpty: Bool {
        [textPrimary, textSecondary, backgroundPrimary, borderPrimary, danger, warning, accent]
            .allSatisfy(\.isEmpty)
    }

    var variables: CheckoutAppearanceVariables? {
        guard !isEmpty else { return nil }
        return CheckoutAppearanceVariables(
            colors: CheckoutVariablesColorStyle(
                textPrimary: nilIfEmpty(textPrimary),
                textSecondary: nilIfEmpty(textSecondary),
                backgroundPrimary: nilIfEmpty(backgroundPrimary),
                borderPrimary: nilIfEmpty(borderPrimary),
                danger: nilIfEmpty(danger),
                warning: nilIfEmpty(warning),
                accent: nilIfEmpty(accent)
            )
        )
    }

    private func nilIfEmpty(_ value: String) -> String? {
        value.isEmpty ? nil : value
    }
}
