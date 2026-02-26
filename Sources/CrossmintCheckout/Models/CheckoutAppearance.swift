//
//  CheckoutAppearance.swift
//  CrossmintCheckout
//
//  Created by Robin Curbelo on 2/25/26.
//

import Foundation

// MARK: - Base Styles

public struct CheckoutFontStyle: Codable, Sendable {
    public let family: String?
    public let size: String?
    public let weight: String?

    public init(family: String? = nil, size: String? = nil, weight: String? = nil) {
        self.family = family
        self.size = size
        self.weight = weight
    }
}

public struct CheckoutColorStyle: Codable, Sendable {
    public let text: String?
    public let background: String?
    public let backgroundPrimary: String?
    public let border: String?
    public let boxShadow: String?
    public let placeholder: String?

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

public struct CheckoutStateStyle: Codable, Sendable {
    public let colors: CheckoutColorStyle?

    public init(colors: CheckoutColorStyle? = nil) {
        self.colors = colors
    }
}

// MARK: - UI Element Rules

public struct CheckoutDestinationInputRule: Codable, Sendable {
    public let display: String?

    public init(display: String? = nil) {
        self.display = display
    }
}

public struct CheckoutReceiptEmailInputRule: Codable, Sendable {
    public let display: String?

    public init(display: String? = nil) {
        self.display = display
    }
}

public struct CheckoutLabelRule: Codable, Sendable {
    public let font: CheckoutFontStyle?
    public let colors: CheckoutColorStyle?

    public init(font: CheckoutFontStyle? = nil, colors: CheckoutColorStyle? = nil) {
        self.font = font
        self.colors = colors
    }
}

public struct CheckoutInputRule: Codable, Sendable {
    public let borderRadius: String?
    public let font: CheckoutFontStyle?
    public let colors: CheckoutColorStyle?
    public let hover: CheckoutStateStyle?
    public let focus: CheckoutStateStyle?

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

public struct CheckoutTabRule: Codable, Sendable {
    public let borderRadius: String?
    public let font: CheckoutFontStyle?
    public let colors: CheckoutColorStyle?
    public let hover: CheckoutStateStyle?
    public let selected: CheckoutStateStyle?

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

public struct CheckoutPrimaryButtonRule: Codable, Sendable {
    public let borderRadius: String?
    public let font: CheckoutFontStyle?
    public let colors: CheckoutColorStyle?
    public let hover: CheckoutStateStyle?
    public let disabled: CheckoutStateStyle?

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

public struct CheckoutAppearanceRules: Codable, Sendable {
    public let destinationInput: CheckoutDestinationInputRule?
    public let receiptEmailInput: CheckoutReceiptEmailInputRule?
    public let label: CheckoutLabelRule?
    public let input: CheckoutInputRule?
    public let tab: CheckoutTabRule?
    public let primaryButton: CheckoutPrimaryButtonRule?

    enum CodingKeys: String, CodingKey {
        case destinationInput = "DestinationInput"
        case receiptEmailInput = "ReceiptEmailInput"
        case label = "Label"
        case input = "Input"
        case tab = "Tab"
        case primaryButton = "PrimaryButton"
    }

    public init(
        destinationInput: CheckoutDestinationInputRule? = nil,
        receiptEmailInput: CheckoutReceiptEmailInputRule? = nil,
        label: CheckoutLabelRule? = nil,
        input: CheckoutInputRule? = nil,
        tab: CheckoutTabRule? = nil,
        primaryButton: CheckoutPrimaryButtonRule? = nil
    ) {
        self.destinationInput = destinationInput
        self.receiptEmailInput = receiptEmailInput
        self.label = label
        self.input = input
        self.tab = tab
        self.primaryButton = primaryButton
    }
}

// MARK: - Appearance Variables

public struct CheckoutAppearanceVariables: Codable, Sendable {
    public let colors: CheckoutColorStyle?

    public init(colors: CheckoutColorStyle? = nil) {
        self.colors = colors
    }
}

// MARK: - Appearance

public struct CheckoutAppearance: Codable, Sendable {
    public let variables: CheckoutAppearanceVariables?
    public let rules: CheckoutAppearanceRules?

    public init(
        variables: CheckoutAppearanceVariables? = nil,
        rules: CheckoutAppearanceRules? = nil
    ) {
        self.variables = variables
        self.rules = rules
    }
}
