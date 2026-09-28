//
//  CheckoutAppearance.swift
//  CrossmintCheckout
//
//  Created by Robin Curbelo on 2/25/26.
//

import Foundation

// MARK: - Fonts

/// A stylesheet that loads a custom font into the checkout.
///
/// Use ``googleFonts(_:weights:)`` to load a font from Google Fonts. Use ``cssURL(_:)`` for a
/// Google Fonts link that ``googleFonts(_:weights:)`` cannot build, such as one with italic styles.
/// The checkout ignores stylesheets from other domains.
///
/// To use the loaded font, set its name in ``CheckoutAppearanceVariables/fontFamily`` or in
/// ``CheckoutFontStyle/family`` of a rule.
public struct CheckoutFontSource: Codable, Sendable, Hashable {
    let cssSrc: String

    private init(cssSrc: String) {
        self.cssSrc = cssSrc
    }

    /// Loads a font family from Google Fonts.
    ///
    /// - Parameters:
    ///   - family: The name of the font family as Google Fonts shows it, for example `"Chakra Petch"`.
    ///   - weights: The weights to load. Only number weights apply, such as ``CheckoutFontWeight/semibold``
    ///     or `600`. A weight such as `CheckoutFontWeight("bold")` has no effect here. If the value is `nil`,
    ///     Google Fonts loads the regular weight.
    public static func googleFonts(
        _ family: String,
        weights: [CheckoutFontWeight]? = nil
    ) -> CheckoutFontSource {
        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.")
        let name = family
            .split(separator: " ")
            .map { $0.addingPercentEncoding(withAllowedCharacters: allowed) ?? String($0) }
            .joined(separator: "+")
        let numericWeights = Set((weights ?? []).compactMap { Int($0.cssValue) }).sorted()
        let axis = numericWeights.isEmpty ? "" : ":wght@" + numericWeights.map(String.init).joined(separator: ";")
        return CheckoutFontSource(cssSrc: "https://fonts.googleapis.com/css2?family=\(name)\(axis)&display=swap")
    }

    /// Loads the fonts that a CSS stylesheet declares.
    ///
    /// - Parameter url: The URL of a CSS file with `@font-face` rules, such as a Google Fonts link.
    ///   A URL to a font file, such as a `.woff2` file, does not work.
    public static func cssURL(_ url: URL) -> CheckoutFontSource {
        CheckoutFontSource(cssSrc: url.absoluteString)
    }
}

/// A CSS length, such as a font size, a corner radius, or a spacing unit.
///
/// Use ``px(_:)``, ``rem(_:)``, or ``em(_:)`` for the common units. Use ``custom(_:)`` for
/// a different CSS value. A number literal is a length in CSS pixels, so `12` is the same as
/// `.px(12)`. In the checkout, one CSS pixel is one point.
public enum CheckoutLength: Codable, Sendable, Hashable, ExpressibleByIntegerLiteral, ExpressibleByFloatLiteral {
    /// A length in CSS pixels.
    case px(Double)
    /// A length relative to the font size of the root element.
    case rem(Double)
    /// A length relative to the font size of the parent element.
    case em(Double)
    /// A CSS length value, for example `"clamp(14px, 4vw, 18px)"`.
    case custom(String)

    /// Creates a length in CSS pixels from an integer literal.
    public init(integerLiteral value: Int) {
        self = .px(Double(value))
    }

    /// Creates a length in CSS pixels from a floating-point literal.
    public init(floatLiteral value: Double) {
        self = .px(value)
    }

    public init(from decoder: Decoder) throws {
        self = .custom(try decoder.singleValueContainer().decode(String.self))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(cssValue)
    }

    var cssValue: String {
        switch self {
        case .px(let value): Self.format(value) + "px"
        case .rem(let value): Self.format(value) + "rem"
        case .em(let value): Self.format(value) + "em"
        case .custom(let value): value
        }
    }

    private static func format(_ value: Double) -> String {
        value.rounded() == value ? String(Int(value)) : String(value)
    }
}

/// A CSS font weight.
///
/// Use a named weight such as ``semibold``, or a number from `1` to `1000`. Use
/// ``init(_:)-(String)`` for a different CSS `font-weight` value, for example `"bold"`.
public struct CheckoutFontWeight: Codable, Sendable, Hashable, ExpressibleByIntegerLiteral {
    let cssValue: String

    /// The weight `100`.
    public static let thin = CheckoutFontWeight(100)
    /// The weight `200`.
    public static let extraLight = CheckoutFontWeight(200)
    /// The weight `300`.
    public static let light = CheckoutFontWeight(300)
    /// The weight `400`.
    public static let regular = CheckoutFontWeight(400)
    /// The weight `500`.
    public static let medium = CheckoutFontWeight(500)
    /// The weight `600`.
    public static let semibold = CheckoutFontWeight(600)
    /// The weight `700`.
    public static let bold = CheckoutFontWeight(700)
    /// The weight `800`.
    public static let extraBold = CheckoutFontWeight(800)
    /// The weight `900`.
    public static let black = CheckoutFontWeight(900)

    /// Creates a weight from a number, for example `600`.
    ///
    /// - Precondition: `value` is in the range `1...1000`.
    public init(_ value: Int) {
        precondition((1...1000).contains(value), "A font weight must be in the range 1...1000, but it is \(value).")
        cssValue = String(value)
    }

    /// Creates a weight from a CSS `font-weight` value, for example `"bold"`.
    public init(_ value: String) {
        cssValue = value
    }

    /// Creates a weight from an integer literal.
    public init(integerLiteral value: Int) {
        self.init(value)
    }

    public init(from decoder: Decoder) throws {
        cssValue = try decoder.singleValueContainer().decode(String.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(cssValue)
    }
}

// MARK: - Base Styles

/// The font of one checkout element.
///
/// The checkout applies only the values you set. It keeps the default for the rest.
public struct CheckoutFontStyle: Codable, Sendable {
    /// The CSS `font-family` value, for example `"Inter, sans-serif"`.
    ///
    /// To use a font that the device does not have, load it with ``CheckoutAppearance/fonts``.
    public let family: String?
    /// The font size.
    public let fontSize: CheckoutLength?
    /// The font weight.
    public let fontWeight: CheckoutFontWeight?


    enum CodingKeys: String, CodingKey {
        case family
        case fontSize = "size"
        case fontWeight = "weight"
    }

    /// Creates a font style.
    public init(family: String? = nil, size: CheckoutLength? = nil, weight: CheckoutFontWeight? = nil) {
        self.family = family
        self.fontSize = size
        self.fontWeight = weight
    }

    /// Creates a font style from CSS strings.
    ///
    /// Use ``init(family:size:weight:)-(String?,CheckoutLength?,CheckoutFontWeight?)`` instead.
    @available(*, deprecated, message: "Use a typed size such as .px(17) or .custom(\"17px\"), and a typed weight such as .semibold, 600, or CheckoutFontWeight(\"bold\").")
    @_disfavoredOverload
    public init(family: String? = nil, size: String? = nil, weight: String? = nil) {
        self.init(
            family: family,
            size: size.map(CheckoutLength.custom),
            weight: weight.map { CheckoutFontWeight($0) }
        )
    }

    /// The font size as a CSS string.
    @available(*, deprecated, message: "Use fontSize instead.")
    public var size: String? { fontSize?.cssValue }

    /// The font weight as a CSS string.
    @available(*, deprecated, message: "Use fontWeight instead.")
    public var weight: String? { fontWeight?.cssValue }
}

/// The colors of one checkout element.
///
/// Each element reads only the keys that apply to it. A key the element does not use
/// has no effect.
public struct CheckoutColorStyle: Codable, Sendable {
    /// The text color.
    public let textColor: CheckoutColor?
    /// The background color.
    public let backgroundColor: CheckoutColor?
    /// The primary background color.
    ///
    /// For the checkout as a whole, use ``CheckoutVariablesColorStyle/backgroundPrimaryColor`` instead.
    public let backgroundPrimaryColor: CheckoutColor?
    /// The border color.
    public let borderColor: CheckoutColor?
    /// The CSS `box-shadow` value, for example `"0 0 0 2px #0066FF"`.
    public let boxShadow: String?
    /// The placeholder text color.
    ///
    /// Only inputs read this key.
    public let placeholderColor: CheckoutColor?


    enum CodingKeys: String, CodingKey {
        case textColor = "text"
        case backgroundColor = "background"
        case backgroundPrimaryColor = "backgroundPrimary"
        case borderColor = "border"
        case boxShadow
        case placeholderColor = "placeholder"
    }

    /// Creates a color style.
    public init(
        text: CheckoutColor? = nil,
        background: CheckoutColor? = nil,
        backgroundPrimary: CheckoutColor? = nil,
        border: CheckoutColor? = nil,
        boxShadow: String? = nil,
        placeholder: CheckoutColor? = nil
    ) {
        self.textColor = text
        self.backgroundColor = background
        self.backgroundPrimaryColor = backgroundPrimary
        self.borderColor = border
        self.boxShadow = boxShadow
        self.placeholderColor = placeholder
    }

    /// Creates a color style from CSS color strings.
    ///
    /// Use ``init(text:background:backgroundPrimary:border:boxShadow:placeholder:)-(CheckoutColor?,CheckoutColor?,CheckoutColor?,CheckoutColor?,String?,CheckoutColor?)`` instead.
    @available(*, deprecated, message: "Use a CheckoutColor such as .color(.blue), .uiColor(.systemBlue), .hex(\"#0066FF\"), or .css(\"rgb(0, 102, 255)\").")
    @_disfavoredOverload
    public init(
        text: String? = nil,
        background: String? = nil,
        backgroundPrimary: String? = nil,
        border: String? = nil,
        boxShadow: String? = nil,
        placeholder: String? = nil
    ) {
        self.init(
            text: text.map(CheckoutColor.css),
            background: background.map(CheckoutColor.css),
            backgroundPrimary: backgroundPrimary.map(CheckoutColor.css),
            border: border.map(CheckoutColor.css),
            boxShadow: boxShadow,
            placeholder: placeholder.map(CheckoutColor.css)
        )
    }

    /// The text color as a CSS string.
    ///
    /// For a color that changes between light and dark mode, this is the light mode value.
    @available(*, deprecated, message: "Use textColor instead.")
    public var text: String? { textColor?.cssValue(for: .light) }

    /// The background color as a CSS string.
    ///
    /// For a color that changes between light and dark mode, this is the light mode value.
    @available(*, deprecated, message: "Use backgroundColor instead.")
    public var background: String? { backgroundColor?.cssValue(for: .light) }

    /// The primary background color as a CSS string.
    ///
    /// For a color that changes between light and dark mode, this is the light mode value.
    @available(*, deprecated, message: "Use backgroundPrimaryColor instead.")
    public var backgroundPrimary: String? { backgroundPrimaryColor?.cssValue(for: .light) }

    /// The border color as a CSS string.
    ///
    /// For a color that changes between light and dark mode, this is the light mode value.
    @available(*, deprecated, message: "Use borderColor instead.")
    public var border: String? { borderColor?.cssValue(for: .light) }

    /// The placeholder text color as a CSS string.
    ///
    /// For a color that changes between light and dark mode, this is the light mode value.
    @available(*, deprecated, message: "Use placeholderColor instead.")
    public var placeholder: String? { placeholderColor?.cssValue(for: .light) }
}

/// The colors of an element while it is in one interaction state, such as hover or focus.
public struct CheckoutStateStyle: Codable, Sendable {
    /// The colors the element uses while it is in this state.
    public let colors: CheckoutColorStyle?

    /// Creates a state style.
    public init(colors: CheckoutColorStyle? = nil) {
        self.colors = colors
    }
}

// MARK: - UI Element Rules

/// The rule for the destination input, where the buyer enters the wallet address or
/// email that receives the purchase.
public struct CheckoutDestinationInputRule: Codable, Sendable {
    private let displayValue: String?

    enum CodingKeys: String, CodingKey {
        case displayValue = "display"
    }

    /// A Boolean value that shows if the checkout hides the input.
    public var isHidden: Bool {
        displayValue == "hidden"
    }

    /// Creates a destination input rule.
    ///
    /// - Parameter isHidden: If the value is `true`, the checkout removes the input from the page.
    public init(isHidden: Bool = false) {
        displayValue = isHidden ? "hidden" : nil
    }

    /// Creates a destination input rule from a CSS `display` value.
    ///
    /// Use ``init(isHidden:)`` instead.
    @available(*, deprecated, message: "Use init(isHidden:) instead.")
    @_disfavoredOverload
    public init(display: String? = nil) {
        displayValue = display
    }

    /// The CSS `display` value of the input.
    @available(*, deprecated, message: "Use isHidden instead.")
    public var display: String? {
        displayValue
    }
}

/// The rule for the receipt email input.
public struct CheckoutReceiptEmailInputRule: Codable, Sendable {
    private let displayValue: String?

    enum CodingKeys: String, CodingKey {
        case displayValue = "display"
    }

    /// A Boolean value that shows if the checkout hides the input.
    public var isHidden: Bool {
        displayValue == "hidden"
    }

    /// Creates a receipt email input rule.
    ///
    /// - Parameter isHidden: If the value is `true`, the checkout removes the input from the page.
    ///   When the buyer pays by card, the checkout always shows the input.
    public init(isHidden: Bool = false) {
        displayValue = isHidden ? "hidden" : nil
    }

    /// Creates a receipt email input rule from a CSS `display` value.
    ///
    /// Use ``init(isHidden:)`` instead.
    @available(*, deprecated, message: "Use init(isHidden:) instead.")
    @_disfavoredOverload
    public init(display: String? = nil) {
        displayValue = display
    }

    /// The CSS `display` value of the input.
    @available(*, deprecated, message: "Use isHidden instead.")
    public var display: String? {
        displayValue
    }
}

/// The rule for the global message the checkout shows above the payment form.
public struct CheckoutGlobalMessageRule: Codable, Sendable {
    private let displayValue: String?

    enum CodingKeys: String, CodingKey {
        case displayValue = "display"
    }

    /// A Boolean value that shows if the checkout hides the message.
    ///
    /// The value is `nil` when the checkout uses its default.
    public var isHidden: Bool? {
        switch displayValue {
        case "hidden": true
        case "visible": false
        default: nil
        }
    }

    /// Creates a global message rule.
    ///
    /// - Parameter isHidden: If the value is `true`, the checkout removes the message. If the
    ///   value is `false`, the checkout shows the message. If the value is `nil`, the checkout
    ///   uses its default.
    public init(isHidden: Bool? = nil) {
        displayValue = isHidden.map { $0 ? "hidden" : "visible" }
    }

    /// Creates a global message rule from a CSS `display` value.
    ///
    /// Use ``init(isHidden:)`` instead.
    @available(*, deprecated, message: "Use init(isHidden:) instead.")
    @_disfavoredOverload
    public init(display: String? = nil) {
        displayValue = display
    }

    /// The CSS `display` value of the message.
    @available(*, deprecated, message: "Use isHidden instead.")
    public var display: String? {
        displayValue
    }
}

/// The rule for the labels above the form fields.
public struct CheckoutLabelRule: Codable, Sendable {
    /// The label font.
    public let font: CheckoutFontStyle?
    /// The label colors.
    ///
    /// Labels use only the ``CheckoutColorStyle/textColor`` value.
    public let colors: CheckoutColorStyle?

    /// Creates a label rule.
    public init(font: CheckoutFontStyle? = nil, colors: CheckoutColorStyle? = nil) {
        self.font = font
        self.colors = colors
    }
}

/// The rule for the text inputs of the payment form.
public struct CheckoutInputRule: Codable, Sendable {
    /// The corner radius, for example `.px(8)` or `8`.
    public let cornerRadius: CheckoutLength?
    /// The input font.
    public let font: CheckoutFontStyle?
    /// The input colors in the rest state.
    public let colors: CheckoutColorStyle?
    /// The input colors while the pointer is over the input.
    public let hover: CheckoutStateStyle?
    /// The input colors while the input has focus.
    public let focus: CheckoutStateStyle?


    enum CodingKeys: String, CodingKey {
        case cornerRadius = "borderRadius"
        case font
        case colors
        case hover
        case focus
    }

    /// Creates an input rule.
    public init(
        borderRadius: CheckoutLength? = nil,
        font: CheckoutFontStyle? = nil,
        colors: CheckoutColorStyle? = nil,
        hover: CheckoutStateStyle? = nil,
        focus: CheckoutStateStyle? = nil
    ) {
        self.cornerRadius = borderRadius
        self.font = font
        self.colors = colors
        self.hover = hover
        self.focus = focus
    }

    /// Creates an input rule with a CSS string for the corner radius.
    ///
    /// Use ``init(borderRadius:font:colors:hover:focus:)-(CheckoutLength?,_,_,_,_)`` instead.
    @available(*, deprecated, message: "Use a typed corner radius such as .px(8), 8, or .custom(\"8px\").")
    @_disfavoredOverload
    public init(
        borderRadius: String? = nil,
        font: CheckoutFontStyle? = nil,
        colors: CheckoutColorStyle? = nil,
        hover: CheckoutStateStyle? = nil,
        focus: CheckoutStateStyle? = nil
    ) {
        self.init(
            borderRadius: borderRadius.map(CheckoutLength.custom),
            font: font,
            colors: colors,
            hover: hover,
            focus: focus
        )
    }

    /// The corner radius as a CSS string.
    @available(*, deprecated, message: "Use cornerRadius instead.")
    public var borderRadius: String? { cornerRadius?.cssValue }
}

/// The rule for the payment method tabs, such as the card and crypto tabs.
public struct CheckoutTabRule: Codable, Sendable {
    /// The corner radius, for example `.px(8)` or `8`.
    public let cornerRadius: CheckoutLength?
    /// The tab font.
    public let font: CheckoutFontStyle?
    /// The tab colors in the rest state.
    public let colors: CheckoutColorStyle?
    /// The tab colors while the pointer is over the tab.
    public let hover: CheckoutStateStyle?
    /// The tab colors while the tab is the selected one.
    public let selected: CheckoutStateStyle?


    enum CodingKeys: String, CodingKey {
        case cornerRadius = "borderRadius"
        case font
        case colors
        case hover
        case selected
    }

    /// Creates a tab rule.
    public init(
        borderRadius: CheckoutLength? = nil,
        font: CheckoutFontStyle? = nil,
        colors: CheckoutColorStyle? = nil,
        hover: CheckoutStateStyle? = nil,
        selected: CheckoutStateStyle? = nil
    ) {
        self.cornerRadius = borderRadius
        self.font = font
        self.colors = colors
        self.hover = hover
        self.selected = selected
    }

    /// Creates a tab rule with a CSS string for the corner radius.
    ///
    /// Use ``init(borderRadius:font:colors:hover:selected:)-(CheckoutLength?,_,_,_,_)`` instead.
    @available(*, deprecated, message: "Use a typed corner radius such as .px(8), 8, or .custom(\"8px\").")
    @_disfavoredOverload
    public init(
        borderRadius: String? = nil,
        font: CheckoutFontStyle? = nil,
        colors: CheckoutColorStyle? = nil,
        hover: CheckoutStateStyle? = nil,
        selected: CheckoutStateStyle? = nil
    ) {
        self.init(
            borderRadius: borderRadius.map(CheckoutLength.custom),
            font: font,
            colors: colors,
            hover: hover,
            selected: selected
        )
    }

    /// The corner radius as a CSS string.
    @available(*, deprecated, message: "Use cornerRadius instead.")
    public var borderRadius: String? { cornerRadius?.cssValue }
}

/// The rule for the primary action button, such as the pay button.
public struct CheckoutPrimaryButtonRule: Codable, Sendable {
    /// The corner radius, for example `.px(8)` or `8`.
    public let cornerRadius: CheckoutLength?
    /// The button font.
    public let font: CheckoutFontStyle?
    /// The button colors in the rest state.
    ///
    /// The button uses only the ``CheckoutColorStyle/textColor`` and ``CheckoutColorStyle/backgroundColor`` values.
    public let colors: CheckoutColorStyle?
    /// The button colors while the pointer is over the button.
    public let hover: CheckoutStateStyle?
    /// The button colors in the disabled state.
    public let disabled: CheckoutStateStyle?


    enum CodingKeys: String, CodingKey {
        case cornerRadius = "borderRadius"
        case font
        case colors
        case hover
        case disabled
    }

    /// Creates a primary button rule.
    public init(
        borderRadius: CheckoutLength? = nil,
        font: CheckoutFontStyle? = nil,
        colors: CheckoutColorStyle? = nil,
        hover: CheckoutStateStyle? = nil,
        disabled: CheckoutStateStyle? = nil
    ) {
        self.cornerRadius = borderRadius
        self.font = font
        self.colors = colors
        self.hover = hover
        self.disabled = disabled
    }

    /// Creates a primary button rule with a CSS string for the corner radius.
    ///
    /// Use ``init(borderRadius:font:colors:hover:disabled:)-(CheckoutLength?,_,_,_,_)`` instead.
    @available(*, deprecated, message: "Use a typed corner radius such as .px(8), 8, or .custom(\"8px\").")
    @_disfavoredOverload
    public init(
        borderRadius: String? = nil,
        font: CheckoutFontStyle? = nil,
        colors: CheckoutColorStyle? = nil,
        hover: CheckoutStateStyle? = nil,
        disabled: CheckoutStateStyle? = nil
    ) {
        self.init(
            borderRadius: borderRadius.map(CheckoutLength.custom),
            font: font,
            colors: colors,
            hover: hover,
            disabled: disabled
        )
    }

    /// The corner radius as a CSS string.
    @available(*, deprecated, message: "Use cornerRadius instead.")
    public var borderRadius: String? { cornerRadius?.cssValue }
}

// MARK: - Appearance Rules

/// Per-element style overrides for the checkout.
///
/// Each property targets one element of the checkout. A rule has priority over the values
/// that the element gets from ``CheckoutAppearanceVariables``. Set a property to `nil` to
/// keep the checkout default for that element.
public struct CheckoutAppearanceRules: Codable, Sendable {
    /// The rule for the destination input.
    public let destinationInput: CheckoutDestinationInputRule?
    /// The rule for the receipt email input.
    public let receiptEmailInput: CheckoutReceiptEmailInputRule?
    /// The rule for the global message above the payment form.
    public let globalMessage: CheckoutGlobalMessageRule?
    /// The rule for the form field labels.
    public let label: CheckoutLabelRule?
    /// The rule for the text inputs.
    public let input: CheckoutInputRule?
    /// The rule for the payment method tabs.
    public let tab: CheckoutTabRule?
    /// The rule for the primary action button.
    public let primaryButton: CheckoutPrimaryButtonRule?

    enum CodingKeys: String, CodingKey {
        case destinationInput = "DestinationInput"
        case receiptEmailInput = "ReceiptEmailInput"
        case globalMessage = "GlobalMessage"
        case label = "Label"
        case input = "Input"
        case tab = "Tab"
        case primaryButton = "PrimaryButton"
    }

    /// Creates the rule set.
    public init(
        destinationInput: CheckoutDestinationInputRule? = nil,
        receiptEmailInput: CheckoutReceiptEmailInputRule? = nil,
        globalMessage: CheckoutGlobalMessageRule? = nil,
        label: CheckoutLabelRule? = nil,
        input: CheckoutInputRule? = nil,
        tab: CheckoutTabRule? = nil,
        primaryButton: CheckoutPrimaryButtonRule? = nil
    ) {
        self.destinationInput = destinationInput
        self.receiptEmailInput = receiptEmailInput
        self.globalMessage = globalMessage
        self.label = label
        self.input = input
        self.tab = tab
        self.primaryButton = primaryButton
    }
}

// MARK: - Appearance Variables

/// The colors that every element of the checkout inherits.
///
/// To change the colors of one element, use ``CheckoutColorStyle`` in a rule.
public struct CheckoutVariablesColorStyle: Codable, Sendable {
    /// The color of primary text, such as headings and amounts.
    public let textPrimaryColor: CheckoutColor?
    /// The color of secondary text, such as helper text and captions.
    public let textSecondaryColor: CheckoutColor?
    /// The background color of the checkout.
    public let backgroundPrimaryColor: CheckoutColor?
    /// The default border color of inputs and containers.
    public let borderPrimaryColor: CheckoutColor?
    /// The color of error messages.
    public let dangerColor: CheckoutColor?
    /// The color of warning messages.
    public let warningColor: CheckoutColor?
    /// The accent color of highlights, links, and selected items.
    public let accentColor: CheckoutColor?


    enum CodingKeys: String, CodingKey {
        case textPrimaryColor = "textPrimary"
        case textSecondaryColor = "textSecondary"
        case backgroundPrimaryColor = "backgroundPrimary"
        case borderPrimaryColor = "borderPrimary"
        case dangerColor = "danger"
        case warningColor = "warning"
        case accentColor = "accent"
    }

    /// Creates the global colors.
    public init(
        textPrimary: CheckoutColor? = nil,
        textSecondary: CheckoutColor? = nil,
        backgroundPrimary: CheckoutColor? = nil,
        borderPrimary: CheckoutColor? = nil,
        danger: CheckoutColor? = nil,
        warning: CheckoutColor? = nil,
        accent: CheckoutColor? = nil
    ) {
        self.textPrimaryColor = textPrimary
        self.textSecondaryColor = textSecondary
        self.backgroundPrimaryColor = backgroundPrimary
        self.borderPrimaryColor = borderPrimary
        self.dangerColor = danger
        self.warningColor = warning
        self.accentColor = accent
    }

    /// Creates the global colors from CSS color strings.
    ///
    /// Use ``init(textPrimary:textSecondary:backgroundPrimary:borderPrimary:danger:warning:accent:)-(CheckoutColor?,_,_,_,_,_,_)`` instead.
    @available(*, deprecated, message: "Use a CheckoutColor such as .color(.blue), .uiColor(.systemBlue), .hex(\"#0066FF\"), or .css(\"rgb(0, 102, 255)\").")
    @_disfavoredOverload
    public init(
        textPrimary: String? = nil,
        textSecondary: String? = nil,
        backgroundPrimary: String? = nil,
        borderPrimary: String? = nil,
        danger: String? = nil,
        warning: String? = nil,
        accent: String? = nil
    ) {
        self.init(
            textPrimary: textPrimary.map(CheckoutColor.css),
            textSecondary: textSecondary.map(CheckoutColor.css),
            backgroundPrimary: backgroundPrimary.map(CheckoutColor.css),
            borderPrimary: borderPrimary.map(CheckoutColor.css),
            danger: danger.map(CheckoutColor.css),
            warning: warning.map(CheckoutColor.css),
            accent: accent.map(CheckoutColor.css)
        )
    }

    /// The color of primary text as a CSS string.
    ///
    /// For a color that changes between light and dark mode, this is the light mode value.
    @available(*, deprecated, message: "Use textPrimaryColor instead.")
    public var textPrimary: String? { textPrimaryColor?.cssValue(for: .light) }

    /// The color of secondary text as a CSS string.
    ///
    /// For a color that changes between light and dark mode, this is the light mode value.
    @available(*, deprecated, message: "Use textSecondaryColor instead.")
    public var textSecondary: String? { textSecondaryColor?.cssValue(for: .light) }

    /// The background color of the checkout as a CSS string.
    ///
    /// For a color that changes between light and dark mode, this is the light mode value.
    @available(*, deprecated, message: "Use backgroundPrimaryColor instead.")
    public var backgroundPrimary: String? { backgroundPrimaryColor?.cssValue(for: .light) }

    /// The default border color as a CSS string.
    ///
    /// For a color that changes between light and dark mode, this is the light mode value.
    @available(*, deprecated, message: "Use borderPrimaryColor instead.")
    public var borderPrimary: String? { borderPrimaryColor?.cssValue(for: .light) }

    /// The color of error messages as a CSS string.
    ///
    /// For a color that changes between light and dark mode, this is the light mode value.
    @available(*, deprecated, message: "Use dangerColor instead.")
    public var danger: String? { dangerColor?.cssValue(for: .light) }

    /// The color of warning messages as a CSS string.
    ///
    /// For a color that changes between light and dark mode, this is the light mode value.
    @available(*, deprecated, message: "Use warningColor instead.")
    public var warning: String? { warningColor?.cssValue(for: .light) }

    /// The accent color as a CSS string.
    ///
    /// For a color that changes between light and dark mode, this is the light mode value.
    @available(*, deprecated, message: "Use accentColor instead.")
    public var accent: String? { accentColor?.cssValue(for: .light) }
}

/// Global style variables that every element of the checkout inherits.
///
/// Use variables to set the base look once. Use ``CheckoutAppearanceRules`` to override
/// single elements.
public struct CheckoutAppearanceVariables: Codable, Sendable {
    /// The CSS `font-family` value of all the checkout text, for example `"Inter, sans-serif"`.
    ///
    /// To use a font that the device does not have, load it with ``CheckoutAppearance/fonts``.
    public let fontFamily: String?
    /// The base unit of all the checkout spacing, for example `.px(4)` or `4`.
    ///
    /// The checkout sets the space around and inside each element as a multiple of this unit.
    public let spacingUnit: CheckoutLength?
    /// The base unit of all the checkout font sizes, for example `.px(4)`.
    ///
    /// The checkout sets each font size as a multiple of this unit. A
    /// ``CheckoutFontStyle/fontSize`` in a rule has priority over it.
    public let fontSizeUnit: CheckoutLength?
    /// The corner radius of the checkout elements, for example `.px(8)` or `8`.
    ///
    /// The corner radius of a rule, such as ``CheckoutInputRule/cornerRadius``, has priority over it.
    public let cornerRadius: CheckoutLength?
    /// The global colors.
    public let colors: CheckoutVariablesColorStyle?


    enum CodingKeys: String, CodingKey {
        case fontFamily
        case spacingUnit
        case fontSizeUnit
        case cornerRadius = "borderRadius"
        case colors
    }

    /// Creates the variable set.
    public init(
        fontFamily: String? = nil,
        spacingUnit: CheckoutLength? = nil,
        fontSizeUnit: CheckoutLength? = nil,
        borderRadius: CheckoutLength? = nil,
        colors: CheckoutVariablesColorStyle? = nil
    ) {
        self.fontFamily = fontFamily
        self.spacingUnit = spacingUnit
        self.fontSizeUnit = fontSizeUnit
        self.cornerRadius = borderRadius
        self.colors = colors
    }
}

// MARK: - Appearance

/// The visual customization of ``CrossmintEmbeddedCheckout``.
///
/// Set ``fonts`` to load custom fonts. Set ``variables`` for the base look of the checkout.
/// Set ``rules`` to change single elements. A rule has priority over a variable.
///
/// ```swift
/// let appearance = CheckoutAppearance(
///     fonts: [.googleFonts("Inter", weights: [.regular, .semibold])],
///     variables: CheckoutAppearanceVariables(
///         fontFamily: "Inter, sans-serif",
///         spacingUnit: 4,
///         colors: CheckoutVariablesColorStyle(accent: .color(.accentColor))
///     ),
///     rules: CheckoutAppearanceRules(
///         primaryButton: CheckoutPrimaryButtonRule(
///             borderRadius: 12,
///             font: CheckoutFontStyle(size: .px(17), weight: .semibold)
///         )
///     )
/// )
/// ```
public struct CheckoutAppearance: Codable, Sendable {
    /// The stylesheets that load custom fonts into the checkout.
    public let fonts: [CheckoutFontSource]?
    /// The global style variables.
    public let variables: CheckoutAppearanceVariables?
    /// The per-element style overrides.
    public let rules: CheckoutAppearanceRules?

    /// Creates an appearance.
    public init(
        fonts: [CheckoutFontSource]? = nil,
        variables: CheckoutAppearanceVariables? = nil,
        rules: CheckoutAppearanceRules? = nil
    ) {
        self.fonts = fonts
        self.variables = variables
        self.rules = rules
    }
}
