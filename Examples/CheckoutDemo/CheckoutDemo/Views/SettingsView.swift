//
//  SettingsView.swift
//  CheckoutDemo
//
//  Created by Tomás Martins on 9/16/26.
//

import SwiftUI

struct SettingsView: View {
    @Environment(DemoConfiguration.self) private var configuration

    private let documentationURL = URL(string: "https://docs.crossmint.com")!
    private let consoleURL = URL(string: "https://console.crossmint.com")!

    var body: some View {
        Form {
            APIKeySection()

            Section {
                LabeledContent("Environment", value: configuration.environment?.title ?? "Unknown")
                    .accessibilityIdentifier("settings-environment-label")
            } footer: {
                Text(environmentNote)
            }

            Section {
                Link("Documentation", destination: documentationURL)
                    .accessibilityIdentifier("documentation-link")
                Link("Crossmint Console", destination: consoleURL)
                    .accessibilityIdentifier("console-link")
            }
        }
    }

    private var environmentNote: String {
        if let environment = configuration.environment {
            environment.note
        } else if configuration.apiKey == nil {
            "The demo needs a key before it can create an order."
        } else {
            "The demo cannot tell which environment this key belongs to. Use a key that starts with ck_staging_ or ck_production_."
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .navigationTitle("Settings")
    }
    .environment(DemoConfiguration())
}
