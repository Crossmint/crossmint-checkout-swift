//
//  CheckoutAppearanceTests.swift
//  CrossmintCheckoutTests
//

import Foundation
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

@Test func googleFontsJoinsFamilyWordsAndSortsWeights() {
    let source = CheckoutFontSource.googleFonts("Chakra Petch", weights: [.bold, 400, .bold, CheckoutFontWeight("bold")])

    #expect(source.cssSrc == "https://fonts.googleapis.com/css2?family=Chakra+Petch:wght@400;700&display=swap")
}

@Test func googleFontsWithoutNumericWeightsOmitsWeightAxis() {
    let source = CheckoutFontSource.googleFonts("Inter", weights: [])

    #expect(source.cssSrc == "https://fonts.googleapis.com/css2?family=Inter&display=swap")
}

@Test func cssURLKeepsTheGivenURL() throws {
    let url = try #require(URL(string: "https://fonts.googleapis.com/css2?family=Lora:ital@1&display=swap"))

    #expect(CheckoutFontSource.cssURL(url).cssSrc == url.absoluteString)
}

@Test(arguments: [
    (CheckoutFontSize.px(16), "16px"),
    (.px(15.5), "15.5px"),
    (.rem(1.25), "1.25rem"),
    (.em(2), "2em"),
    (.custom("clamp(14px, 4vw, 18px)"), "clamp(14px, 4vw, 18px)")
])
func fontSizeEncodesAsCSSValue(size: CheckoutFontSize, expected: String) throws {
    #expect(size.cssValue == expected)
    #expect(try size.toJSON() == "\"\(expected)\"")
}

@Test(arguments: [
    (CheckoutFontWeight.semibold, "600"),
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

@Test func unsetFontsAreOmitted() throws {
    let appearance = CheckoutAppearance(
        variables: CheckoutAppearanceVariables(
            colors: CheckoutVariablesColorStyle(accent: "#0076F3")
        )
    )

    let json = try appearance.toJSON()

    #expect(!json.contains("fonts"))
    #expect(!json.contains("fontFamily"))
    #expect(!json.contains("fontSizeUnit"))
}

@available(*, deprecated)
@Test func stringFontStyleStillEncodesTheSameValues() throws {
    let size: String? = "17px"
    let weight: String? = "600"
    let appearance = CheckoutAppearance(
        rules: CheckoutAppearanceRules(
            label: CheckoutLabelRule(font: CheckoutFontStyle(family: "Inter", size: size, weight: weight))
        )
    )

    let json = try appearance.toJSON()

    #expect(json.contains("\"font\":{\"family\":\"Inter\",\"size\":\"17px\",\"weight\":\"600\"}"))
}

@available(*, deprecated)
@Test func stringLiteralFontStyleMapsToTypedValues() {
    let style = CheckoutFontStyle(size: "17px", weight: "600")

    #expect(style.size == .custom("17px"))
    #expect(style.weight == CheckoutFontWeight(600))
}
