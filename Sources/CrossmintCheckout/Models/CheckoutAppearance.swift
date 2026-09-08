//
//  CheckoutAppearance.swift
//  CrossmintCheckout
//
//  Created by Robin Curbelo on 2/25/26.
//

import Foundation

// MARK: - Base Styles

/// The font of one checkout element.
///
/// Each value is a CSS string. The checkout applies only the values you set. It keeps
/// the default for the rest.
public struct CheckoutFontStyle: Codable, Sendable {
    /// The CSS `font-family` value, for example `"Inter, sans-serif"`.
    public let family: String?
    /// The CSS `font-size` value, for example `"14px"`.
    public let size: String?
    /// The CSS `font-weight` value, for example `"600"`.
    public let weight: String?

    /// Creates a font style. Pass `nil` for a value to keep the checkout default.
    public init(family: String? = nil, size: String? = nil, weight: String? = nil) {
        self.family = family
        self.size = size
        self.weight = weight
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
    /// The primary background color. For the checkout as a whole, set
    /// ``CheckoutVariablesColorStyle/backgroundPrimary`` instead.
    public let backgroundPrimary: String?
    /// The border color.
    public let border: String?
    /// The CSS `box-shadow` value, for example `"0 0 0 2px #0066FF"`.
    public let boxShadow: String?
    /// The placeholder text color. Only inputs read this key.
    public let placeholder: String?

    /// Creates a color style. Pass `nil` for a value to keep the checkout default.
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

    /// Creates a state style. Pass `nil` to keep the checkout default for this state.
    public init(colors: CheckoutColorStyle? = nil) {
        self.colors = colors
    }
}

// MARK: - UI Element Rules

/// The rule for the destination input, where the buyer enters the wallet address or
/// email that receives the purchase.
public struct CheckoutDestinationInputRule: Codable, Sendable {
    /// The CSS `display` value. Set `"hidden"` to remove the input from the page.
    public let display: String?

    /// Creates a destination input rule.
    public init(display: String? = nil) {
        self.display = display
    }
}

/// The rule for the receipt email input.
public struct CheckoutReceiptEmailInputRule: Codable, Sendable {
    /// The CSS `display` value. Set `"hidden"` to remove the input from the page.
    public let display: String?

    /// Creates a receipt email input rule.
    public init(display: String? = nil) {
        self.display = display
    }
}

/// The rule for the global message the checkout shows above the payment form.
public struct CheckoutGlobalMessageRule: Codable, Sendable {
    /// The CSS `display` value. Set `"hidden"` to remove the message or `"visible"` to
    /// show it.
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
    /// The label colors. Labels read the ``CheckoutColorStyle/text`` key.
    public let colors: CheckoutColorStyle?

    /// Creates a label rule. Pass `nil` for a value to keep the checkout default.
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

    /// Creates an input rule. Pass `nil` for a value to keep the checkout default.
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

    /// Creates a tab rule. Pass `nil` for a value to keep the checkout default.
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
    /// The button colors in the rest state. The button reads the
    /// ``CheckoutColorStyle/text`` and ``CheckoutColorStyle/background`` keys.
    public let colors: CheckoutColorStyle?
    /// The button colors while the pointer is over the button.
    public let hover: CheckoutStateStyle?
    /// The button colors in the disabled state.
    public let disabled: CheckoutStateStyle?

    /// Creates a primary button rule. Pass `nil` for a value to keep the checkout default.
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
/// Each property targets one element of the hosted page. A rule overrides the values the
/// element inherits from ``CheckoutAppearanceVariables``. Leave a property `nil` to keep
/// the checkout default for that element.
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

    /// Creates the rule set. Pass `nil` for an element to keep the checkout default.
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

/// Global color variables. These use different keys than the per-element `CheckoutColorStyle`
/// used in rules: the checkout reads `textPrimary`/`textSecondary`/`borderPrimary`/etc. at the
/// variables level.
public struct CheckoutVariablesColorStyle: Codable, Sendable {
    /// The color of primary text, such as headings and amounts.
    public let textPrimary: String?
    /// The color of secondary text, such as helper text and captions.
    public let textSecondary: String?
    /// The background color of the checkout.
    public let backgroundPrimary: String?
    /// The default border color of inputs and containers.
    public let borderPrimary: String?
    /// The color for error states and messages.
    public let danger: String?
    /// The color for warning states and messages.
    public let warning: String?
    /// The accent color for highlights, links, and the selected state.
    public let accent: String?

    /// Creates the global colors. Pass `nil` for a value to keep the checkout default.
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
    /// The global colors.
    public let colors: CheckoutVariablesColorStyle?

    /// Creates the variable set. Pass `nil` to keep the checkout default colors.
    public init(colors: CheckoutVariablesColorStyle? = nil) {
        self.colors = colors
    }
}

// MARK: - Appearance

/// The visual customization of ``CrossmintEmbeddedCheckout``.
///
/// Set ``variables`` for the global look. Set ``rules`` for per-element overrides. A rule
/// has priority over a variable for the element it targets.
///
/// ```swift
/// let appearance = CheckoutAppearance(
///     variables: CheckoutAppearanceVariables(
///         colors: CheckoutVariablesColorStyle(accent: "#0066FF")
///     ),
///     rules: CheckoutAppearanceRules(
///         primaryButton: CheckoutPrimaryButtonRule(borderRadius: "12px")
///     )
/// )
/// ```
public struct CheckoutAppearance: Codable, Sendable {
    /// The global style variables.
    public let variables: CheckoutAppearanceVariables?
    /// The per-element style overrides.
    public let rules: CheckoutAppearanceRules?

    /// Creates an appearance. Pass `nil` for a part to keep the checkout default.
    public init(
        variables: CheckoutAppearanceVariables? = nil,
        rules: CheckoutAppearanceRules? = nil
    ) {
        self.variables = variables
        self.rules = rules
    }
}
