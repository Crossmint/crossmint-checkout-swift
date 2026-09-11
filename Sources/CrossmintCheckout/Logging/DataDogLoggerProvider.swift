//
//  DataDogLoggerProvider.swift
//  CrossmintCheckout
//
//  Created by Tomás Martins on 9/11/26.
//

import Foundation
import UIKit

enum DataDogConfig {
    static let clientToken = "pub946d87ea0c2cc02431c15e9446f776fc"

    private static let environmentBox = LockedValue("production")

    static var environment: String {
        environmentBox.value
    }

    static func configure(for environment: CheckoutEnvironment) {
        environmentBox.value = switch environment {
        case .staging: "staging"
        case .production: "production"
        }
    }
}

private struct LogEntry {
    let level: CheckoutLogLevel
    let message: String
    let timestamp: String
    let attributes: [String: String]

    var status: String {
        switch level {
        case .debug, .info: "info"
        case .warning: "warn"
        case .error: "error"
        case .silent: "none"
        }
    }
}

private struct DeviceInfo: Sendable {
    var model = "unknown"
    var name = "unknown"
    var osName = "unknown"
    var osVersion = "unknown"
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    let appBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"

    @MainActor
    static func capture() -> DeviceInfo {
        let device = UIDevice.current
        return DeviceInfo(model: device.model, name: device.name, osName: device.systemName, osVersion: device.systemVersion)
    }
}

actor DataDogLoggerProvider: LoggerProvider {
    private static let serviceName = "crossmint-ios-sdk"
    private static let batchSize = 10
    private static let batchTimeoutNanoseconds: UInt64 = 5_000_000_000

    private let service: String
    private let intakeUrl: URL?
    private let sessionId = UUID().uuidString
    private var queue: [LogEntry] = []
    private var flushTask: Task<Void, Never>?
    private var device = DeviceInfo()

    private let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    init(service: String, clientToken: String = DataDogConfig.clientToken) {
        self.service = service
        let intake = "https://http-intake.logs.datadoghq.com/v1/input/\(clientToken)"
        let encoded = intake.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? intake
        self.intakeUrl = URL(string: "https://telemetry.crossmint.com/dd?ddforward=\(encoded)")

        Self.observeLifecycle(of: self)
        Task { await self.captureDevice() }
    }

    private func captureDevice() async {
        device = await DeviceInfo.capture()
    }

    nonisolated func log(_ level: CheckoutLogLevel, _ message: String, attributes: [String: String]?) {
        let date = Date()
        Task { [weak self] in
            await self?.enqueue(level: level, message: message, attributes: attributes ?? [:], date: date)
        }
    }

    private func enqueue(level: CheckoutLogLevel, message: String, attributes: [String: String], date: Date) {
        queue.append(LogEntry(level: level, message: message, timestamp: dateFormatter.string(from: date), attributes: attributes))

        if queue.count >= Self.batchSize {
            Task { await flush() }
        } else if flushTask == nil {
            flushTask = Task { [weak self] in
                try? await Task.sleep(nanoseconds: Self.batchTimeoutNanoseconds)
                guard !Task.isCancelled else { return }
                await self?.flush()
            }
        }
    }

    func flush() async {
        flushTask?.cancel()
        flushTask = nil
        guard !queue.isEmpty else { return }

        let batch = queue
        queue.removeAll()
        await send(batch)
    }

    private func send(_ batch: [LogEntry]) async {
        guard let intakeUrl else { return }
        do {
            var request = URLRequest(url: intakeUrl)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: batch.map(payload))

            let (_, response) = try await URLSession.shared.data(for: request)
            if let status = (response as? HTTPURLResponse)?.statusCode, status >= 400 {
                print("[CrossmintCheckout Logger] DataDog proxy returned \(status)")
            }
        } catch {
            print("[CrossmintCheckout Logger] Failed to send logs: \(error)")
        }
    }

    private func payload(for entry: LogEntry) -> [String: Any] {
        var attributes: [String: Any] = [
            "date": entry.timestamp,
            "status": entry.status,
            "service": Self.serviceName,
            "sdk_name": SDKVersion.name,
            "sdk_version": SDKVersion.version,
            "logger": ["name": service, "version": SDKVersion.version],
            "platform": "ios",
            "version": device.appVersion,
            "build_version": device.appBuild,
            "os": ["name": device.osName, "version": device.osVersion],
            "_dd": ["device": ["name": device.name, "model": device.model, "brand": "Apple"]]
        ]
        for (key, value) in entry.attributes {
            attributes[key] = value
        }

        return [
            "timestamp": entry.timestamp,
            "tags": ["env:\(DataDogConfig.environment)", "version:\(device.appVersion)", "source:ios"],
            "service": Self.serviceName,
            "message": entry.message,
            "hostname": Bundle.main.bundleIdentifier ?? "unknown",
            "dd-session_id": sessionId,
            "attributes": attributes
        ]
    }

    private static func observeLifecycle(of provider: DataDogLoggerProvider) {
        for name in [UIApplication.willResignActiveNotification, UIApplication.willTerminateNotification] {
            NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak provider] _ in
                Task { await provider?.flush() }
            }
        }
    }
}
