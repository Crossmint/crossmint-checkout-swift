//
//  CheckoutLogLevel.swift
//  CrossmintCheckout
//
//  Created by Tomás Martins on 9/11/26.
//

import Foundation

/// The minimum level of the SDK messages that reach the system console.
///
/// The level filters only the local console output. Diagnostic messages go to Crossmint at every level.
public enum CheckoutLogLevel: Int, Sendable {
    /// Every message, including the verbose ones.
    case debug
    /// Informational messages and above.
    case info
    /// Warnings and errors.
    case warning
    /// Errors only. The default.
    case error
    /// No console output.
    case silent
}
