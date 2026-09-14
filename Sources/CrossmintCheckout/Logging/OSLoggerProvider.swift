//
//  OSLoggerProvider.swift
//  CrossmintCheckout
//
//  Created by Tomás Martins on 9/11/26.
//

import Foundation
import OSLog

final class OSLoggerProvider: LoggerProvider {
    private let osLogger: OSLog

    init(category: String) {
        self.osLogger = OSLog(subsystem: "com.crossmint.CrossmintCheckout", category: category)
    }

    func log(_ level: CheckoutLogLevel, _ message: String, attributes: [String: String]?) {
        guard Logger.level.includes(level) else { return }
        let pairs = attributes.map { $0.map { "\($0.key)=\($0.value)" }.sorted().joined(separator: " ") }
        let line = pairs.map { "\(message) \($0)" } ?? message
        os_log(Self.type(for: level), log: osLogger, "%{public}@", line)
    }

    private static func type(for level: CheckoutLogLevel) -> OSLogType {
        switch level {
        case .debug: .debug
        case .info: .info
        case .warning: .default
        case .error, .silent: .error
        }
    }
}
