//
//  DataDogLogFormatter.swift
//  CrossmintCheckout
//
//  Created by Tomás Martins on 9/15/26.
//

import Foundation

struct DataDogLogFormatter: Sendable {
    static let serviceName = "crossmint-ios-sdk"
    static let sourceName = "ios"
    static let platform = "ios"
    static let deviceBrand = "Apple"

    let loggerName: String
    let sessionId: String
    let hostname: String

    func payload(for entry: LogEntry, device: DeviceInfo) -> [String: Any] {
        var log: [String: Any] = entry.attributes
        log.merge(reservedAttributes(for: entry, device: device)) { _, reserved in reserved }
        log.merge(structuredAttributes(for: entry, device: device)) { _, reserved in reserved }
        return log
    }

    private func reservedAttributes(for entry: LogEntry, device: DeviceInfo) -> [String: Any] {
        [
            "message": entry.message,
            "status": entry.status,
            "service": Self.serviceName,
            "ddsource": Self.sourceName,
            "ddtags": tags(environment: entry.environment, appVersion: device.appVersion),
            "hostname": hostname,
            "timestamp": entry.timestamp,
            "dd-session_id": sessionId,
            "platform": Self.platform,
            "version": device.appVersion,
            "build_version": device.appBuild,
            "sdk_name": SDKVersion.name
        ]
    }

    private func structuredAttributes(for entry: LogEntry, device: DeviceInfo) -> [String: Any] {
        [
            "os": [
                "name": device.osName,
                "version": device.osVersion,
                "build": device.osBuild
            ],
            "device": [
                "name": device.name,
                "model": device.model,
                "brand": Self.deviceBrand,
                "architecture": device.architecture
            ],
            "logger": [
                "name": loggerName,
                "version": SDKVersion.version,
                "thread_name": entry.threadName,
                "app_id": hostname
            ]
        ]
    }

    private func tags(environment: String, appVersion: String) -> String {
        [
            "env:\(environment)",
            "sdk_version:\(SDKVersion.version)",
            "version:\(appVersion)"
        ].joined(separator: ",")
    }
}
