//
//  DataDogLoggerProvider.swift
//  CrossmintCheckout
//
//  Created by Tomás Martins on 9/11/26.
//

import Foundation
import UIKit

private let datadogIntakeUrl = "https://http-intake.logs.datadoghq.com/v1/input"
private let telemetryProxyUrl = "https://telemetry.crossmint.com/dd"

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

struct LogEntry {
    let level: CheckoutLogLevel
    let message: String
    let date: Date
    let environment: String
    let threadName: String
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

struct DeviceInfo: Sendable {
    var model: String?
    var name: String?
    var brand: String?
    var osName: String?
    var osVersion: String?
    var osBuild: String?
    var architecture: String?
    var appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    var appBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String

    @MainActor
    static func capture() -> DeviceInfo {
        let device = UIDevice.current
        return DeviceInfo(
            model: device.model,
            name: device.name,
            brand: "Apple",
            osName: device.systemName,
            osVersion: device.systemVersion,
            osBuild: osBuild(),
            architecture: architecture()
        )
    }

    private static func osBuild() -> String? {
        var size = 0
        sysctlbyname("kern.osversion", nil, &size, nil, 0)
        guard size > 0 else { return nil }
        var build = [UInt8](repeating: 0, count: size)
        sysctlbyname("kern.osversion", &build, &size, nil, 0)
        let value = String(decoding: build.prefix(while: { $0 != 0 }), as: UTF8.self)
        return value.isEmpty ? nil : value
    }

    private static func architecture() -> String? {
        #if arch(arm64e)
        return "arm64e"
        #elseif arch(arm64)
        return "arm64"
        #elseif arch(x86_64)
        return "x86_64"
        #else
        return nil
        #endif
    }
}

actor DataDogLoggerProvider: LoggerProvider {
    private static let batchSize = 10
    private static let batchTimeoutNanoseconds: UInt64 = 5_000_000_000

    private let formatter: DataDogLogFormatter
    private let intakeUrl: URL?
    private var queue: [LogEntry] = []
    private var flushTask: Task<Void, Never>?
    private var device = DeviceInfo()

    init(service: String, clientToken: String = DataDogConfig.clientToken) {
        self.formatter = DataDogLogFormatter(
            loggerName: service,
            sessionId: UUID().uuidString,
            hostname: Bundle.main.bundleIdentifier
        )
        let intake = "\(datadogIntakeUrl)/\(clientToken)"
        let encoded = intake.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? intake
        self.intakeUrl = URL(string: "\(telemetryProxyUrl)?ddforward=\(encoded)")

        Self.observeLifecycle(of: self)
        Task { await self.captureDevice() }
    }

    private func captureDevice() async {
        device = await DeviceInfo.capture()
    }

    nonisolated func log(_ level: CheckoutLogLevel, _ message: String, attributes: [String: String]?) {
        let entry = LogEntry(
            level: level,
            message: message,
            date: Date(),
            environment: DataDogConfig.environment,
            threadName: Self.threadName(),
            attributes: attributes ?? [:]
        )
        Task { [weak self] in await self?.enqueue(entry) }
    }

    private static func threadName() -> String {
        if Thread.isMainThread { return "main" }
        if let name = Thread.current.name, !name.isEmpty { return name }
        return "background"
    }

    private func enqueue(_ entry: LogEntry) {
        queue.append(entry)

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
            let logs = batch.map { formatter.payload(for: $0, device: device) }
            request.httpBody = try JSONSerialization.data(withJSONObject: logs)

            let (_, response) = try await URLSession.shared.data(for: request)
            if let status = (response as? HTTPURLResponse)?.statusCode, status >= 400 {
                print("[CrossmintCheckout Logger] DataDog proxy returned \(status)")
            }
        } catch {
            print("[CrossmintCheckout Logger] Failed to send logs: \(error)")
        }
    }

    private static func observeLifecycle(of provider: DataDogLoggerProvider) {
        for name in [UIApplication.willResignActiveNotification, UIApplication.willTerminateNotification] {
            NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak provider] _ in
                Task { await provider?.flush() }
            }
        }
    }
}
