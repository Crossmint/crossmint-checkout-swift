//
//  DataDogLoggerProvider.swift
//  CrossmintCheckout
//
//  Created by Tomás Martins on 9/11/26.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

actor DataDogLoggerProvider: LoggerProvider {
    private let batchSize = 10
    private let batchTimeoutSeconds: TimeInterval = 5.0

    private let service: String
    private let intakeUrl: String
    private let serviceName = "crossmint-ios-sdk"

    private var batchQueue: [LogEntry] = []
    private var batchTask: Task<Void, Never>?
    private let sessionId: String
    private var deviceInfo: DeviceInfoCache?

    private static let captureTask: Task<DeviceInfoCache, Never> = Task {
        await DeviceInfoCache.capture()
    }

    private let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    init(service: String, clientToken: String) {
        self.service = service
        self.sessionId = Self.generateSessionId()
        self.deviceInfo = nil

        let datadogUrl = "https://http-intake.logs.datadoghq.com/v1/input/\(clientToken)"
        let encodedUrl = datadogUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? datadogUrl
        self.intakeUrl = "https://telemetry.crossmint.com/dd?ddforward=\(encodedUrl)"

        Self.setupLifecycleObservers(provider: self)

        Task {
            await self.captureDeviceInfo()
        }
    }

    private func captureDeviceInfo() async {
        self.deviceInfo = await Self.captureTask.value
    }

    nonisolated func debug(_ message: String, attributes: [String: Encodable]?) {
        let attrs = UnsafeSendableAttributes(value: attributes)
        Task.detached { [weak self] in
            await self?.write(level: .debug, message: message, attributes: attrs.value)
        }
    }

    nonisolated func error(_ message: String, attributes: [String: Encodable]?) {
        let attrs = UnsafeSendableAttributes(value: attributes)
        Task.detached { [weak self] in
            await self?.write(level: .error, message: message, attributes: attrs.value)
        }
    }

    nonisolated func info(_ message: String, attributes: [String: Encodable]?) {
        let attrs = UnsafeSendableAttributes(value: attributes)
        Task.detached { [weak self] in
            await self?.write(level: .info, message: message, attributes: attrs.value)
        }
    }

    nonisolated func warning(_ message: String, attributes: [String: Encodable]?) {
        let attrs = UnsafeSendableAttributes(value: attributes)
        Task.detached { [weak self] in
            await self?.write(level: .warning, message: message, attributes: attrs.value)
        }
    }

    private func write(level: CheckoutLogLevel, message: String, attributes: [String: Encodable]?) {
        let entry = LogEntry(
            level: level,
            message: LogFormatting.format(message, attributes: attributes),
            timestamp: iso8601Formatter.string(from: Date()),
            context: attributes ?? [:]
        )

        batchQueue.append(entry)

        if batchQueue.count >= batchSize {
            flush()
        } else {
            scheduleBatchTimeout()
        }
    }

    private func scheduleBatchTimeout() {
        batchTask?.cancel()

        let timeout = batchTimeoutSeconds
        batchTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await self?.flush()
        }
    }

    func flush() {
        batchTask?.cancel()
        batchTask = nil

        guard !batchQueue.isEmpty else { return }

        let batch = batchQueue
        batchQueue.removeAll()

        Task {
            await sendBatch(batch)
        }
    }

    private func sendBatch(_ batch: [LogEntry]) async {
        let logs = batch.map { entry in
            formatLogForDataDog(entry)
        }

        do {
            guard let url = URL(string: intakeUrl) else {
                print("[CrossmintCheckout Logger] Invalid intake URL")
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: logs)

            let (_, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
                print("[CrossmintCheckout Logger] DataDog proxy returned error: \(httpResponse.statusCode)")
            }
        } catch {
            print("[CrossmintCheckout Logger] Error sending logs to DataDog: \(error)")
        }
    }

    private func formatLogForDataDog(_ entry: LogEntry) -> [String: Any] {
        let bundleId = Bundle.main.bundleIdentifier ?? "unknown"
        let info = deviceInfo ?? .unknown

        var attributes: [String: Any] = [
            "date": entry.timestamp,
            "os": [
                "build": info.osBuild,
                "name": info.osName,
                "version": info.osVersion
            ],
            "build_version": info.appBuild,
            "service": serviceName,
            "logger": [
                "thread_name": Self.getThreadName(),
                "name": service,
                "version": SDKVersion.version
            ],
            "version": info.appVersion,
            "platform": "ios",
            "sdk_name": SDKVersion.name,
            "sdk_version": SDKVersion.version,
            "_dd": [
                "device": [
                    "name": info.deviceName,
                    "model": info.model,
                    "brand": "Apple",
                    "architecture": info.architecture
                ]
            ],
            "status": mapLevelToStatus(entry.level)
        ]

        var client: [String: Any] = ["type": info.networkConnectionType]
        if let cellularTech = info.cellularTechnology {
            client["cellular_technology"] = cellularTech
        }
        attributes["network"] = ["client": client]

        for (key, value) in entry.context {
            attributes[key] = value
        }

        return [
            "timestamp": entry.timestamp,
            "tags": [
                "env:\(DataDogConfig.environment)",
                "version:\(info.appVersion)",
                "source:ios"
            ],
            "service": serviceName,
            "message": entry.message,
            "hostname": bundleId,
            "dd-session_id": sessionId,
            "attributes": attributes
        ]
    }

    private static func getThreadName() -> String {
        if Thread.isMainThread {
            return "main"
        }
        if let name = Thread.current.name, !name.isEmpty {
            return name
        }
        return "background"
    }

    private func mapLevelToStatus(_ level: CheckoutLogLevel) -> String {
        switch level {
        case .debug, .info:
            "info"
        case .warning:
            "warn"
        case .error:
            "error"
        case .silent:
            "none"
        }
    }

    private static func generateSessionId() -> String {
        var bytes = [UInt8](repeating: 0, count: 8)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return bytes.map { String(format: "%02x", $0) }.joined()
    }

    private static func setupLifecycleObservers(provider: DataDogLoggerProvider) {
        #if canImport(UIKit)
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task { await provider.flush() }
        }

        NotificationCenter.default.addObserver(
            forName: UIApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task { await provider.flush() }
        }
        #endif
    }
}
