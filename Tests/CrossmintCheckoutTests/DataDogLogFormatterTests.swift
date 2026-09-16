//
//  DataDogLogFormatterTests.swift
//  CrossmintCheckoutTests
//
//  Created by Tomás Martins on 9/15/26.
//

import Foundation
import Testing
@testable import CrossmintCheckout

struct DataDogLogFormatterTests {
    let formatter = DataDogLogFormatter(loggerName: "checkout", sessionId: "0123456789abcdef", hostname: "com.example.app")

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

    func payload(
        level: CheckoutLogLevel = .info,
        environment: String = "production",
        attributes: [String: String] = [:]
    ) -> [String: Any] {
        let entry = LogEntry(
            level: level,
            message: "order updated",
            date: Date(timeIntervalSince1970: 1_789_466_400),
            environment: environment,
            threadName: "main",
            attributes: attributes
        )
        return formatter.payload(for: entry, device: device)
    }

    @Test(arguments: ["production", "staging"])
    func sendsTagsAsCommaSeparatedDdtagsString(environment: String) {
        let ddtags = payload(environment: environment)["ddtags"] as? String

        #expect(ddtags == "env:\(environment),sdk_version:\(SDKVersion.version),version:3.1.4")
    }

    @Test func sendsReservedAttributesAtTopLevel() {
        let payload = payload()

        #expect(payload["message"] as? String == "order updated")
        #expect(payload["service"] as? String == "crossmint-ios-sdk")
        #expect(payload["ddsource"] as? String == "ios")
        #expect(payload["hostname"] as? String == "com.example.app")
        #expect(payload["timestamp"] as? String == "2026-09-15T10:00:00.000Z")
        #expect(payload["dd-session_id"] as? String == "0123456789abcdef")
        #expect(payload["platform"] as? String == "ios")
        #expect(payload["version"] as? String == "3.1.4")
        #expect(payload["build_version"] as? String == "42")
        #expect(payload["sdk_name"] as? String == SDKVersion.name)
    }

    @Test(arguments: [
        ("os", ["name": "iOS", "version": "26.0", "build": "23A340"]),
        ("device", ["name": "Tomas iPhone", "model": "iPhone", "brand": "Apple", "architecture": "arm64e"]),
        ("logger", ["name": "checkout", "version": SDKVersion.version, "thread_name": "main", "app_id": "com.example.app"])
    ])
    func sendsStructuredObjectsAtTopLevel(key: String, expected: [String: String]) {
        #expect(payload()[key] as? [String: String] == expected)
    }

    @Test func sendsAttributeKeysAtTopLevel() {
        let payload = payload(attributes: ["orderId": "order-1", "phase": "payment"])

        #expect(payload["orderId"] as? String == "order-1")
        #expect(payload["phase"] as? String == "payment")
    }

    @Test func keepsReservedKeysWhenAttributesUseTheSameName() {
        let payload = payload(attributes: ["status": "pending", "service": "other"])

        #expect(payload["status"] as? String == "info")
        #expect(payload["service"] as? String == "crossmint-ios-sdk")
    }

    @Test func dropsLegacyAttributesAndTagsWrappers() {
        let payload = payload(attributes: ["orderId": "order-1"])

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
        #expect(payload(level: level)["status"] as? String == status)
    }

    @Test func serializesToJson() {
        #expect(JSONSerialization.isValidJSONObject([payload(attributes: ["orderId": "order-1"])]))
    }
}
