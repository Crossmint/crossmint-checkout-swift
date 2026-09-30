//
//  CheckoutColor.swift
//  CrossmintCheckout
//
//  Created by Tomás Martins on 9/28/26.
//

import SwiftUI
import UIKit

/// A color of the checkout.
///
/// Use ``color(_:)`` for a SwiftUI color, or ``uiColor(_:)`` for a UIKit color. Use ``hex(_:)``
/// for a hex string, or ``css(_:)`` for a different CSS color value.
///
/// Some colors change between light and dark mode, such as `Color.primary`. The checkout uses
/// the value for its mode when it loads. If the mode changes later, the checkout keeps that value.
public struct CheckoutColor: Codable, Sendable, Hashable {
    private enum Value: Sendable, Hashable {
        case css(String)
        case swiftUI(Color)
        case uiKit(UIColor)
    }

    private let value: Value

    private init(_ value: Value) {
        self.value = value
    }

    /// Creates a color from a SwiftUI color, for example `.accentColor`.
    public static func color(_ color: Color) -> CheckoutColor {
        CheckoutColor(.swiftUI(color))
    }

    /// Creates a color from a UIKit color, for example `.systemBlue`.
    public static func uiColor(_ color: UIColor) -> CheckoutColor {
        CheckoutColor(.uiKit(color))
    }

    /// Creates a color from a hex string, for example `"#1A1A1A"` or `"#1A1A1A80"`.
    ///
    /// - Parameter value: A `#` and then three, four, six, or eight hex digits. If the value has
    ///   a different format, the SDK logs an error and sends the value to the checkout as it is.
    public static func hex(_ value: String) -> CheckoutColor {
        if !isHex(value) {
            Logger.checkout.error(LogEvents.appearanceColorInvalid, attributes: ["value": value])
        }
        return CheckoutColor(.css(value))
    }

    /// Creates a color from a CSS color value, for example `"rgb(26, 26, 26)"`.
    ///
    /// The SDK sends the value to the checkout as it is.
    public static func css(_ value: String) -> CheckoutColor {
        CheckoutColor(.css(value))
    }

    public init(from decoder: Decoder) throws {
        value = .css(try decoder.singleValueContainer().decode(String.self))
    }

    public func encode(to encoder: Encoder) throws {
        let colorScheme = encoder.userInfo[.checkoutColorScheme] as? ColorScheme ?? .light
        var container = encoder.singleValueContainer()
        try container.encode(cssValue(for: colorScheme))
    }

    func cssValue(for colorScheme: ColorScheme) -> String {
        switch value {
        case .css(let value):
            value
        case .swiftUI(let color):
            Self.hexString(of: color, in: colorScheme)
        case .uiKit(let color):
            Self.hexString(of: color.resolvedColor(with: Self.traits(for: colorScheme)))
        }
    }

    private static func isHex(_ value: String) -> Bool {
        guard value.first == "#" else { return false }
        let digits = value.dropFirst()
        return [3, 4, 6, 8].contains(digits.count) && digits.allSatisfy(\.isHexDigit)
    }

    private static func traits(for colorScheme: ColorScheme) -> UITraitCollection {
        UITraitCollection(userInterfaceStyle: colorScheme == .dark ? .dark : .light)
    }

    private static func hexString(of color: Color, in colorScheme: ColorScheme) -> String {
        if #available(iOS 17.0, *) {
            var environment = EnvironmentValues()
            environment.colorScheme = colorScheme
            let resolved = color.resolve(in: environment)
            return hexString(
                red: Double(resolved.red),
                green: Double(resolved.green),
                blue: Double(resolved.blue),
                alpha: Double(resolved.opacity)
            )
        }
        return hexString(of: UIColor(color).resolvedColor(with: traits(for: colorScheme)))
    }

    private static func hexString(of color: UIColor) -> String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return hexString(red: red, green: green, blue: blue, alpha: alpha)
    }

    private static func hexString(red: Double, green: Double, blue: Double, alpha: Double) -> String {
        let channels = alpha < 1 ? [red, green, blue, alpha] : [red, green, blue]
        return "#" + channels
            .map { String(format: "%02X", Int((min(max($0, 0), 1) * 255).rounded())) }
            .joined()
    }
}

extension CodingUserInfoKey {
    static let checkoutColorScheme = CodingUserInfoKey(rawValue: "checkoutColorScheme")!
}
