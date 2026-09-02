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

    var showsDestinationInput: Bool = true
    var showsReceiptEmailInput: Bool = true
    var showsStatusMessage: Bool = true

    var colors = AppearanceColors()
    var radii = AppearanceRadii()

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
        let hidesElement = !showsDestinationInput || !showsReceiptEmailInput || !showsStatusMessage
        guard hidesElement || !radii.isEmpty else { return nil }

        return CheckoutAppearanceRules(
            destinationInput: showsDestinationInput
                ? nil : CheckoutDestinationInputRule(display: "hidden"),
            receiptEmailInput: showsReceiptEmailInput
                ? nil : CheckoutReceiptEmailInputRule(display: "hidden"),
            globalMessage: showsStatusMessage
                ? nil : CheckoutGlobalMessageRule(display: "hidden"),
            input: radii.inputValue.map { CheckoutInputRule(borderRadius: $0) },
            tab: radii.tabValue.map { CheckoutTabRule(borderRadius: $0) },
            primaryButton: radii.primaryButtonValue.map { CheckoutPrimaryButtonRule(borderRadius: $0) }
        )
    }
}

nonisolated struct AppearanceRadii: Equatable {
    var input: Double?
    var tab: Double?
    var primaryButton: Double?

    var isEmpty: Bool {
        input == nil && tab == nil && primaryButton == nil
    }

    var inputValue: String? { Self.pixels(input) }
    var tabValue: String? { Self.pixels(tab) }
    var primaryButtonValue: String? { Self.pixels(primaryButton) }

    private static func pixels(_ radius: Double?) -> String? {
        radius.map { "\(Int($0))px" }
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
