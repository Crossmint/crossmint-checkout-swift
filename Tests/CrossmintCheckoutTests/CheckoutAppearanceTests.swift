//
//  CheckoutAppearanceTests.swift
//  CrossmintCheckoutTests
//

import SwiftUI
import Testing
import UIKit
@testable import CrossmintCheckout

@Test func variablesColorsSerializeWithCheckoutVariableKeys() throws {
    let appearance = CheckoutAppearance(
        variables: CheckoutAppearanceVariables(
            colors: CheckoutVariablesColorStyle(
                textPrimary: .hex("#FFFFFF"),
                textSecondary: .hex("#A3A3A3"),
                backgroundPrimary: .hex("#141414"),
                borderPrimary: .hex("#2A2A2E"),
                accent: .hex("#0076F3")
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
                colors: CheckoutColorStyle(text: .hex("#FFFFFF"), background: .css("rgb(0, 118, 243)"))
            )
        )
    )

    let json = try appearance.toJSON()

    #expect(json.contains("\"PrimaryButton\""))
    #expect(json.contains("\"text\":\"#FFFFFF\""))
    #expect(json.contains("\"background\":\"rgb(0, 118, 243)\""))
}

@Test func fontsSerializeWithCheckoutKeys() throws {
    let appearance = CheckoutAppearance(
        fonts: [.googleFonts("Inter", weights: [.regular, .semibold])],
        variables: CheckoutAppearanceVariables(
            fontFamily: "Inter, sans-serif",
            fontSizeUnit: .px(4)
        )
    )

    let json = try appearance.toJSON()

    #expect(json.contains("\"fonts\":[{\"cssSrc\":\"https://fonts.googleapis.com/css2?family=Inter:wght@400;600&display=swap\"}]"))
    #expect(json.contains("\"fontFamily\":\"Inter, sans-serif\""))
    #expect(json.contains("\"fontSizeUnit\":\"4px\""))
}

@Test(arguments: [
    (
        CheckoutFontSource.googleFonts("Chakra Petch", weights: [.bold, 400, .bold, CheckoutFontWeight("bold")]),
        "https://fonts.googleapis.com/css2?family=Chakra+Petch:wght@400;700&display=swap"
    ),
    (.googleFonts("Inter"), "https://fonts.googleapis.com/css2?family=Inter&display=swap")
])
func googleFontsBuildsStylesheetURL(source: CheckoutFontSource, expected: String) {
    #expect(source.cssSrc == expected)
}

@Test(arguments: [
    (CheckoutLength.px(16), "16px"),
    (.px(15.5), "15.5px"),
    (.rem(1.25), "1.25rem"),
    (.em(2), "2em"),
    (.custom("clamp(14px, 4vw, 18px)"), "clamp(14px, 4vw, 18px)"),
    (12, "12px"),
    (7.5, "7.5px")
])
func lengthEncodesAsCSSValue(length: CheckoutLength, expected: String) throws {
    #expect(try length.toJSON() == "\"\(expected)\"")
}

@Test(arguments: [
    (CheckoutFontWeight(1), "1"),
    (.thin, "100"),
    (.extraLight, "200"),
    (.semibold, "600"),
    (.extraBold, "800"),
    (.black, "900"),
    (1000, "1000"),
    (450, "450"),
    (CheckoutFontWeight("bold"), "bold")
])
func fontWeightEncodesAsCSSValue(weight: CheckoutFontWeight, expected: String) throws {
    #expect(try weight.toJSON() == "\"\(expected)\"")
}

@Test func ruleFontSerializesSizeAndWeightAsStrings() throws {
    let appearance = CheckoutAppearance(
        rules: CheckoutAppearanceRules(
            primaryButton: CheckoutPrimaryButtonRule(
                font: CheckoutFontStyle(family: "Inter", size: .px(17), weight: 600)
            )
        )
    )

    let json = try appearance.toJSON()

    #expect(json.contains("\"font\":{\"family\":\"Inter\",\"size\":\"17px\",\"weight\":\"600\"}"))
}

@available(*, deprecated)
@Test func stringFontStyleMapsToTypedValues() {
    let size: String? = "17px"
    let weight: String? = "600"
    let style = CheckoutFontStyle(size: size, weight: weight)

    #expect(style.fontSize == .custom("17px"))
    #expect(style.fontWeight == CheckoutFontWeight(600))
    #expect(style.size == "17px")
    #expect(style.weight == "600")
}

@Test func spacingAndRadiusSerializeAsLengths() throws {
    let variables = CheckoutAppearanceVariables(spacingUnit: 4, borderRadius: .rem(0.5))

    #expect(try variables.toJSON() == "{\"borderRadius\":\"0.5rem\",\"spacingUnit\":\"4px\"}")
}

@Test(arguments: [
    (CheckoutColor.color(Color(red: 0, green: 118 / 255, blue: 243 / 255)), "#0076F3"),
    (.uiColor(UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)), "#FFFFFF80"),
    (.uiColor(UIColor(displayP3Red: 1, green: 0, blue: 0, alpha: 1)), "#FF0000")
])
func colorEncodesAsCSSValue(color: CheckoutColor, expected: String) throws {
    #expect(try color.toJSON() == "\"\(expected)\"")
}


@available(*, deprecated)
@Test func stringColorsAndRadiusMapToTypedValues() {
    let color: String? = "#0076F3"
    let radius: String? = "8px"
    let rule = CheckoutPrimaryButtonRule(borderRadius: radius, colors: CheckoutColorStyle(text: color))
    let variables = CheckoutVariablesColorStyle(accent: color)

    #expect(rule.cornerRadius == .custom("8px"))
    #expect(rule.colors?.textColor == .css("#0076F3"))
    #expect(variables.accentColor == .css("#0076F3"))
    #expect(rule.borderRadius == "8px")
    #expect(rule.colors?.text == "#0076F3")
    #expect(variables.accent == "#0076F3")
}

@available(*, deprecated)
@Test func typedValuesReadBackAsCSSStrings() {
    let dynamic = UIColor { $0.userInterfaceStyle == .dark ? .white : .black }
    let rule = CheckoutInputRule(borderRadius: 12, colors: CheckoutColorStyle(text: .uiColor(dynamic)))
    let font = CheckoutFontStyle(size: .rem(1.5), weight: .semibold)

    #expect(rule.borderRadius == "12px")
    #expect(rule.colors?.text == "#000000")
    #expect(font.size == "1.5rem")
    #expect(font.weight == "600")
}
