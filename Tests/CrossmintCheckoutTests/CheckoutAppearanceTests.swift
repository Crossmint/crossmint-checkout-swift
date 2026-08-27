//
//  CheckoutAppearanceTests.swift
//  CrossmintCheckoutTests
//

import Testing
@testable import CrossmintCheckout

@Test func variablesColorsSerializeWithCheckoutVariableKeys() throws {
    let appearance = CheckoutAppearance(
        variables: CheckoutAppearanceVariables(
            colors: CheckoutVariablesColorStyle(
                textPrimary: "#FFFFFF",
                textSecondary: "#A3A3A3",
                backgroundPrimary: "#141414",
                borderPrimary: "#2A2A2E",
                accent: "#0076F3"
            )
        )
    )

    let json = try appearance.toJSON()

    #expect(json.contains("\"textPrimary\":\"#FFFFFF\""))
    #expect(json.contains("\"textSecondary\":\"#A3A3A3\""))
    #expect(json.contains("\"backgroundPrimary\":\"#141414\""))
    #expect(json.contains("\"borderPrimary\":\"#2A2A2E\""))
    #expect(json.contains("\"accent\":\"#0076F3\""))
}

@Test func ruleColorsKeepPerElementKeys() throws {
    let appearance = CheckoutAppearance(
        rules: CheckoutAppearanceRules(
            primaryButton: CheckoutPrimaryButtonRule(
                colors: CheckoutColorStyle(text: "#FFFFFF", background: "#0076F3")
            )
        )
    )

    let json = try appearance.toJSON()

    #expect(json.contains("\"PrimaryButton\""))
    #expect(json.contains("\"text\":\"#FFFFFF\""))
    #expect(json.contains("\"background\":\"#0076F3\""))
}
