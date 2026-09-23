//
//  DataDogLogFormatter.swift
//  CrossmintCheckout
//
//  Created by Tomás Martins on 9/15/26.
//

import Foundation

struct DataDogLogFormatter {
    let loggerName: String
    let sessionId: String
    let hostname: String?

    private let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    func payload(for entry: LogEntry, device: DeviceInfo) -> [String: Any] {
        (entry.attributes as [String: Any]).merging(datadogAttributes(for: entry, device: device)) { _, reserved in reserved }
    }

    private func datadogAttributes(for entry: LogEntry, device: DeviceInfo) -> [String: Any] {
        let attributes: [String: Any?] = [
            "message": entry.message,
            "status": entry.status,
            "service": "crossmint-ios-sdk",
            "ddsource": "ios",
            "ddtags": ddtags(for: entry, device: device),
            "hostname": hostname,
            "timestamp": dateFormatter.string(from: entry.date),
            "dd-session_id": sessionId,
            "platform": "ios",
            "version": device.appVersion,
            "build_version": device.appBuild,
            "sdk_name": SDKVersion.name,
            "os": nonEmptyObject(["name": device.osName, "version": device.osVersion, "build": device.osBuild]),
            "device": nonEmptyObject(["name": device.name, "model": device.model, "brand": device.brand, "architecture": device.architecture]),
            "logger": nonEmptyObject(["name": loggerName, "version": SDKVersion.version, "thread_name": entry.threadName, "app_id": hostname])
        ]
        return attributes.compactMapValues { $0 }
    }

    private func ddtags(for entry: LogEntry, device: DeviceInfo) -> String {
        var tags = ["env:\(entry.environment)", "sdk_version:\(SDKVersion.version)"]
        if let appVersion = device.appVersion {
            tags.append("version:\(appVersion)")
        }
        return tags.joined(separator: ",")
    }

    private func nonEmptyObject(_ values: [String: String?]) -> [String: String]? {
        let present = values.compactMapValues { $0 }
        return present.isEmpty ? nil : present
    }
}
