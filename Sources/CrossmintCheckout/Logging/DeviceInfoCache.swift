//
//  DeviceInfoCache.swift
//  CrossmintCheckout
//
//  Created by Tomás Martins on 9/11/26.
//

import Foundation
import UIKit

struct DeviceInfoCache: Sendable {
    let model: String
    let deviceName: String
    let osName: String
    let osVersion: String
    let osBuild: String
    let architecture: String
    let appVersion: String
    let appBuild: String

    static let unknown = DeviceInfoCache(
        model: "unknown",
        deviceName: "unknown",
        osName: "unknown",
        osVersion: "unknown",
        osBuild: "unknown",
        architecture: "unknown",
        appVersion: "unknown",
        appBuild: "unknown"
    )

    static func capture() async -> DeviceInfoCache {
        let info = Bundle.main.infoDictionary
        let (model, deviceName, osName, osVersion) = await MainActor.run {
            let device = UIDevice.current
            return (device.model, device.name, device.systemName, device.systemVersion)
        }

        return DeviceInfoCache(
            model: model,
            deviceName: deviceName,
            osName: osName,
            osVersion: osVersion,
            osBuild: osBuild(),
            architecture: architecture(),
            appVersion: info?["CFBundleShortVersionString"] as? String ?? "unknown",
            appBuild: info?["CFBundleVersion"] as? String ?? "unknown"
        )
    }

    private static func osBuild() -> String {
        var size = 0
        sysctlbyname("kern.osversion", nil, &size, nil, 0)
        var build = [UInt8](repeating: 0, count: size)
        sysctlbyname("kern.osversion", &build, &size, nil, 0)
        return String(decoding: build.prefix(while: { $0 != 0 }), as: UTF8.self)
    }

    private static func architecture() -> String {
        #if arch(arm64e)
        return "arm64e"
        #elseif arch(arm64)
        return "arm64"
        #elseif arch(x86_64)
        return "x86_64"
        #else
        return "unknown"
        #endif
    }
}
