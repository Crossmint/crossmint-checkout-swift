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
    ///     or `600`. A weight such as `CheckoutFontWeight("bold")` has no effect here.
    public static func googleFonts(
        _ family: String,
        weights: [CheckoutFontWeight] = [.regular]
    ) -> CheckoutFontSource {
        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.")
        let name = family
            .split(separator: " ")
            .map { $0.addingPercentEncoding(withAllowedCharacters: allowed) ?? String($0) }
            .joined(separator: "+")
        let numericWeights = Set(weights.compactMap { Int($0.cssValue) }).sorted()
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

/// A CSS font size.
///
/// Use ``px(_:)``, ``rem(_:)``, or ``em(_:)`` for the common units. Use ``custom(_:)`` for
/// a different CSS value.
public enum CheckoutFontSize: Codable, Sendable, Hashable {
    /// A size in CSS pixels.
    case px(Double)
    /// A size relative to the font size of the root element.
    case rem(Double)
    /// A size relative to the font size of the parent element.
    case em(Double)
    /// A CSS `font-size` value, for example `"clamp(14px, 4vw, 18px)"`.
    case custom(String)

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
/// Use a named weight such as ``semibold``, or a number from `100` to `900`. Use
/// ``init(_:)-(String)`` for a different CSS `font-weight` value, for example `"bold"`.
public struct CheckoutFontWeight: Codable, Sendable, Hashable, ExpressibleByIntegerLiteral {
    let cssValue: String

    /// The weight `100`.
    public static let ultraLight = CheckoutFontWeight(100)
    /// The weight `200`.
    public static let thin = CheckoutFontWeight(200)
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
    public static let heavy = CheckoutFontWeight(800)
    /// The weight `900`.
    public static let black = CheckoutFontWeight(900)

    /// Creates a weight from a number, for example `600`.
    public init(_ value: Int) {
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
    public let size: CheckoutFontSize?
    /// The font weight.
    public let weight: CheckoutFontWeight?

    /// Creates a font style.
    public init(family: String? = nil, size: CheckoutFontSize? = nil, weight: CheckoutFontWeight? = nil) {
        self.family = family
        self.size = size
        self.weight = weight
    }

    /// Creates a font style from CSS strings.
    ///
    /// Use ``init(family:size:weight:)-(String?,CheckoutFontSize?,CheckoutFontWeight?)`` instead.
    @available(*, deprecated, message: "Use a typed size such as .px(17) or .custom(\"17px\"), and a typed weight such as .semibold, 600, or CheckoutFontWeight(\"bold\").")
    @_disfavoredOverload
    public init(family: String? = nil, size: String? = nil, weight: String? = nil) {
        self.init(
            family: family,
            size: size.map(CheckoutFontSize.custom),
            weight: weight.map { CheckoutFontWeight($0) }
        )
    }
}

/// The colors of one checkout element.
///
/// Each value is a CSS color string, for example `"#1A1A1A"` or `"rgb(26, 26, 26)"`.
/// Each element reads only the keys that apply to it. A key the element does not use
/// has no effect.
public struct CheckoutColorStyle: Codable, Sendable {
    /// The text color.
    public let text: String?
    /// The background color.
    public let background: String?
    /// The primary background color.
    ///
    /// For the checkout as a whole, use ``CheckoutVariablesColorStyle/backgroundPrimary`` instead.
    public let backgroundPrimary: String?
    /// The border color.
    public let border: String?
    /// The CSS `box-shadow` value, for example `"0 0 0 2px #0066FF"`.
    public let boxShadow: String?
    /// The placeholder text color.
    ///
    /// Only inputs read this key.
    public let placeholder: String?

    /// Creates a color style.
    public init(
        text: String? = nil,
        background: String? = nil,
        backgroundPrimary: String? = nil,
        border: String? = nil,
        boxShadow: String? = nil,
        placeholder: String? = nil
    ) {
        self.text = text
        self.background = background
        self.backgroundPrimary = backgroundPrimary
        self.border = border
        self.boxShadow = boxShadow
        self.placeholder = placeholder
    }
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
    /// The CSS `display` value of the input.
    ///
    /// The value `"hidden"` removes the input from the page.
    public let display: String?

    /// Creates a destination input rule.
    public init(display: String? = nil) {
        self.display = display
    }
}

/// The rule for the receipt email input.
public struct CheckoutReceiptEmailInputRule: Codable, Sendable {
    /// The CSS `display` value of the input.
    ///
    /// The value `"hidden"` removes the input from the page. When the buyer pays by card,
    /// the checkout always shows the input.
    public let display: String?

    /// Creates a receipt email input rule.
    public init(display: String? = nil) {
        self.display = display
    }
}

/// The rule for the global message the checkout shows above the payment form.
public struct CheckoutGlobalMessageRule: Codable, Sendable {
    /// The CSS `display` value of the message.
    ///
    /// The value `"hidden"` removes the message. The value `"visible"` shows it.
    public let display: String?

    /// Creates a global message rule.
    public init(display: String? = nil) {
        self.display = display
    }
}

/// The rule for the labels above the form fields.
public struct CheckoutLabelRule: Codable, Sendable {
    /// The label font.
    public let font: CheckoutFontStyle?
    /// The label colors.
    ///
    /// Labels read the ``CheckoutColorStyle/text`` key.
    public let colors: CheckoutColorStyle?

    /// Creates a label rule.
    public init(font: CheckoutFontStyle? = nil, colors: CheckoutColorStyle? = nil) {
        self.font = font
        self.colors = colors
    }
}

/// The rule for the text inputs of the payment form.
public struct CheckoutInputRule: Codable, Sendable {
    /// The CSS `border-radius` value, for example `"8px"`.
    public let borderRadius: String?
    /// The input font.
    public let font: CheckoutFontStyle?
    /// The input colors in the rest state.
    public let colors: CheckoutColorStyle?
    /// The input colors while the pointer is over the input.
    public let hover: CheckoutStateStyle?
    /// The input colors while the input has focus.
    public let focus: CheckoutStateStyle?

    /// Creates an input rule.
    public init(
        borderRadius: String? = nil,
        font: CheckoutFontStyle? = nil,
        colors: CheckoutColorStyle? = nil,
        hover: CheckoutStateStyle? = nil,
        focus: CheckoutStateStyle? = nil
    ) {
        self.borderRadius = borderRadius
        self.font = font
        self.colors = colors
        self.hover = hover
        self.focus = focus
    }
}

/// The rule for the payment method tabs, such as the card and crypto tabs.
public struct CheckoutTabRule: Codable, Sendable {
    /// The CSS `border-radius` value, for example `"8px"`.
    public let borderRadius: String?
    /// The tab font.
    public let font: CheckoutFontStyle?
    /// The tab colors in the rest state.
    public let colors: CheckoutColorStyle?
    /// The tab colors while the pointer is over the tab.
    public let hover: CheckoutStateStyle?
    /// The tab colors while the tab is the selected one.
    public let selected: CheckoutStateStyle?

    /// Creates a tab rule.
    public init(
        borderRadius: String? = nil,
        font: CheckoutFontStyle? = nil,
        colors: CheckoutColorStyle? = nil,
        hover: CheckoutStateStyle? = nil,
        selected: CheckoutStateStyle? = nil
    ) {
        self.borderRadius = borderRadius
        self.font = font
        self.colors = colors
        self.hover = hover
        self.selected = selected
    }
}

/// The rule for the primary action button, such as the pay button.
public struct CheckoutPrimaryButtonRule: Codable, Sendable {
    /// The CSS `border-radius` value, for example `"8px"`.
    public let borderRadius: String?
    /// The button font.
    public let font: CheckoutFontStyle?
    /// The button colors in the rest state.
    ///
    /// The button reads the ``CheckoutColorStyle/text`` and ``CheckoutColorStyle/background`` keys.
    public let colors: CheckoutColorStyle?
    /// The button colors while the pointer is over the button.
    public let hover: CheckoutStateStyle?
    /// The button colors in the disabled state.
    public let disabled: CheckoutStateStyle?

    /// Creates a primary button rule.
    public init(
        borderRadius: String? = nil,
        font: CheckoutFontStyle? = nil,
        colors: CheckoutColorStyle? = nil,
        hover: CheckoutStateStyle? = nil,
        disabled: CheckoutStateStyle? = nil
    ) {
        self.borderRadius = borderRadius
        self.font = font
        self.colors = colors
        self.hover = hover
        self.disabled = disabled
    }
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
/// Each value is a CSS color string, for example `"#1A1A1A"` or `"rgb(26, 26, 26)"`.
/// To change the colors of one element, use ``CheckoutColorStyle`` in a rule.
public struct CheckoutVariablesColorStyle: Codable, Sendable {
    /// The color of primary text, such as headings and amounts.
    public let textPrimary: String?
    /// The color of secondary text, such as helper text and captions.
    public let textSecondary: String?
    /// The background color of the checkout.
    public let backgroundPrimary: String?
    /// The default border color of inputs and containers.
    public let borderPrimary: String?
    /// The color of error messages.
    public let danger: String?
    /// The color of warning messages.
    public let warning: String?
    /// The accent color of highlights, links, and selected items.
    public let accent: String?

    /// Creates the global colors.
    public init(
        textPrimary: String? = nil,
        textSecondary: String? = nil,
        backgroundPrimary: String? = nil,
        borderPrimary: String? = nil,
        danger: String? = nil,
        warning: String? = nil,
        accent: String? = nil
    ) {
        self.textPrimary = textPrimary
        self.textSecondary = textSecondary
        self.backgroundPrimary = backgroundPrimary
        self.borderPrimary = borderPrimary
        self.danger = danger
        self.warning = warning
        self.accent = accent
    }
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
    /// The base unit of all the checkout font sizes, for example `.px(4)`.
    ///
    /// The checkout sets each font size as a multiple of this unit. A
    /// ``CheckoutFontStyle/size`` in a rule has priority over it.
    public let fontSizeUnit: CheckoutFontSize?
    /// The global colors.
    public let colors: CheckoutVariablesColorStyle?

    /// Creates the variable set.
    public init(
        fontFamily: String? = nil,
        fontSizeUnit: CheckoutFontSize? = nil,
        colors: CheckoutVariablesColorStyle? = nil
    ) {
        self.fontFamily = fontFamily
        self.fontSizeUnit = fontSizeUnit
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
///         colors: CheckoutVariablesColorStyle(accent: "#0066FF")
///     ),
///     rules: CheckoutAppearanceRules(
///         primaryButton: CheckoutPrimaryButtonRule(
///             borderRadius: "12px",
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
