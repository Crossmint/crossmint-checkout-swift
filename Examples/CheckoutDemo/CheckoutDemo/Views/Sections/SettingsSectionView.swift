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
                LabeledContent("Key", value: maskedKey)
                    .font(.callout.monospaced())
            }

            Section {
                Text(setupCommand)
                    .font(.footnote.monospaced())
                    .textSelection(.enabled)
            } header: {
                Text("Changing the key")
            } footer: {
                Text("Edit Config/Secrets.xcconfig and build again. It is gitignored, and the environment comes from the key prefix.")
            }
        }
    }

    private let setupCommand = "Examples/CheckoutDemo/Config/Secrets.xcconfig"

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
