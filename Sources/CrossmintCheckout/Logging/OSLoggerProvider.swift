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

    func debug(_ message: String, attributes: [String: any Encodable]?) {
        guard Logger.level.rawValue <= CheckoutLogLevel.debug.rawValue else { return }
        os_log(.debug, log: osLogger, "%{public}@", LogFormatting.format(message, attributes: attributes))
    }

    func error(_ message: String, attributes: [String: any Encodable]?) {
        guard Logger.level.rawValue <= CheckoutLogLevel.error.rawValue else { return }
        os_log(.error, log: osLogger, "%{public}@", LogFormatting.format(message, attributes: attributes))
    }

    func info(_ message: String, attributes: [String: any Encodable]?) {
        guard Logger.level.rawValue <= CheckoutLogLevel.info.rawValue else { return }
        os_log(.info, log: osLogger, "%{public}@", LogFormatting.format(message, attributes: attributes))
    }

    func warning(_ message: String, attributes: [String: any Encodable]?) {
        guard Logger.level.rawValue <= CheckoutLogLevel.warning.rawValue else { return }
        os_log(.default, log: osLogger, "%{public}@", LogFormatting.format(message, attributes: attributes))
    }
}
