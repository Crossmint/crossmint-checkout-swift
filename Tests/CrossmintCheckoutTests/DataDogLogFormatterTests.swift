//
//  DataDogLogFormatterTests.swift
//  CrossmintCheckoutTests
//
//  Created by Tomás Martins on 9/15/26.
//

import Foundation
import Testing
@testable import CrossmintCheckout

private let LOGGER_NAME = "checkout"
private let ENVIRONMENT = "production"
private let SESSION_ID = "0123456789abcdef"
private let HOSTNAME = "com.example.app"
private let THREAD_NAME = "main"
private let TIMESTAMP = "2026-09-15T10:00:00.000Z"

struct DataDogLogFormatterTests {
    let formatter = DataDogLogFormatter(loggerName: LOGGER_NAME, sessionId: SESSION_ID, hostname: HOSTNAME)

    let device = DeviceInfo(
        model: "iPhone",
        name: "Tomas iPhone",
        osName: "iOS",
        osVersion: "26.0",
        osBuild: "23A340",
        architecture: "arm64e",
        appVersion: "3.1.4",
        appBuild: "42"
    )

    func makeEntry(
        level: CheckoutLogLevel = .info,
        message: String = "order updated",
        environment: String = ENVIRONMENT,
        attributes: [String: String] = [:]
    ) -> LogEntry {
        LogEntry(
            level: level,
            message: message,
            timestamp: TIMESTAMP,
            environment: environment,
            threadName: THREAD_NAME,
            attributes: attributes
        )
    }

    func makePayload(entry: LogEntry? = nil) -> [String: Any] {
        formatter.payload(for: entry ?? makeEntry(), device: device)
    }

    @Test func sendsTagsAsCommaSeparatedDdtagsString() throws {
        let ddtags = try #require(makePayload()["ddtags"] as? String)

        #expect(ddtags == "env:production,sdk_version:\(SDKVersion.version),version:3.1.4")
    }

    @Test func usesTheEntryEnvironmentInDdtags() throws {
        let ddtags = try #require(makePayload(entry: makeEntry(environment: "staging"))["ddtags"] as? String)

        #expect(ddtags.hasPrefix("env:staging,"))
    }

    @Test func sendsSourceAsTopLevelDdsource() {
        #expect(makePayload()["ddsource"] as? String == "ios")
    }

    @Test func sendsReservedAttributesAtTopLevel() {
        let payload = makePayload()

        #expect(payload["message"] as? String == "order updated")
        #expect(payload["status"] as? String == "info")
        #expect(payload["service"] as? String == "crossmint-ios-sdk")
        #expect(payload["hostname"] as? String == HOSTNAME)
        #expect(payload["timestamp"] as? String == TIMESTAMP)
        #expect(payload["dd-session_id"] as? String == SESSION_ID)
        #expect(payload["platform"] as? String == "ios")
        #expect(payload["version"] as? String == "3.1.4")
        #expect(payload["build_version"] as? String == "42")
        #expect(payload["sdk_name"] as? String == SDKVersion.name)
    }

    @Test func sendsOsAsTopLevelObject() throws {
        let os = try #require(makePayload()["os"] as? [String: String])

        #expect(os == ["name": "iOS", "version": "26.0", "build": "23A340"])
    }

    @Test func sendsDeviceAsTopLevelObject() throws {
        let device = try #require(makePayload()["device"] as? [String: String])

        #expect(device == ["name": "Tomas iPhone", "model": "iPhone", "brand": "Apple", "architecture": "arm64e"])
    }

    @Test func sendsLoggerAsTopLevelObject() throws {
        let logger = try #require(makePayload()["logger"] as? [String: String])

        #expect(logger == [
            "name": LOGGER_NAME,
            "version": SDKVersion.version,
            "thread_name": THREAD_NAME,
            "app_id": HOSTNAME
        ])
    }

    @Test func sendsAttributeKeysAtTopLevel() {
        let entry = makeEntry(attributes: ["orderId": "order-1", "phase": "payment"])

        let payload = makePayload(entry: entry)

        #expect(payload["orderId"] as? String == "order-1")
        #expect(payload["phase"] as? String == "payment")
    }

    @Test func keepsReservedKeysWhenAttributesUseTheSameName() {
        let entry = makeEntry(attributes: ["status": "pending", "service": "other"])

        let payload = makePayload(entry: entry)

        #expect(payload["status"] as? String == "info")
        #expect(payload["service"] as? String == "crossmint-ios-sdk")
    }

    @Test func dropsLegacyAttributesAndTagsWrappers() {
        let payload = makePayload(entry: makeEntry(attributes: ["orderId": "order-1"]))

        #expect(payload["attributes"] == nil)
        #expect(payload["tags"] == nil)
        #expect(payload["_dd"] == nil)
    }

    @Test(arguments: [
        (CheckoutLogLevel.debug, "info"),
        (.info, "info"),
        (.warning, "warn"),
        (.error, "error"),
        (.silent, "none")
    ])
    func mapsLevelToDatadogStatus(level: CheckoutLogLevel, status: String) {
        #expect(makePayload(entry: makeEntry(level: level))["status"] as? String == status)
    }

    @Test func serializesToJson() throws {
        let entry = makeEntry(attributes: ["orderId": "order-1"])

        let data = try JSONSerialization.data(withJSONObject: [makePayload(entry: entry)])
        let decoded = try #require(try JSONSerialization.jsonObject(with: data) as? [[String: Any]])
        let log = try #require(decoded.first)

        #expect(log["ddtags"] as? String == "env:production,sdk_version:\(SDKVersion.version),version:3.1.4")
        #expect(log["orderId"] as? String == "order-1")
        #expect((log["os"] as? [String: String])?["version"] == "26.0")
    }
}
