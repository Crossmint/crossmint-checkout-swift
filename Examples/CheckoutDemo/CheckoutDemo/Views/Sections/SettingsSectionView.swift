//
//  SettingsSectionView.swift
//  CheckoutDemo
//
//  Created by Tomás Martins on 8/31/26.
//

import SwiftUI

struct SettingsSectionView: View {
    var body: some View {
        Form {
            Section("Environment") {
                LabeledContent("Host", value: DemoConfiguration.environment?.host ?? "unknown")
                    .accessibilityIdentifier("environment-host-label")
                LabeledContent("Client API key", value: maskedKey)
                    .font(.callout.monospaced())
            }

            Section {
                Text(secretsPath)
                    .font(.footnote.monospaced())
                    .textSelection(.enabled)
            } header: {
                Text("Changing the key")
            } footer: {
                Text("Edit this file and build again. The key prefix sets the environment. Git ignores this file.")
            }
        }
    }

    private let secretsPath = "Examples/CheckoutDemo/Config/Secrets.xcconfig"

    private var maskedKey: String {
        guard let key = DemoConfiguration.apiKey else { return "not set" }
        guard let underscore = key.range(of: "_", options: .backwards) else { return "…\(key.suffix(4))" }
        return "\(key[..<underscore.upperBound])…\(key.suffix(4))"
    }
}

#Preview {
    NavigationStack {
        SettingsSectionView()
    }
}
