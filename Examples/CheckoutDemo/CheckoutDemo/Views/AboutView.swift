//
//  AboutView.swift
//  CheckoutDemo
//
//  Created by Tomás Martins on 8/31/26.
//

import SwiftUI

struct AboutView: View {
    private let documentationURL = URL(string: "https://docs.crossmint.com")!
    private let consoleURL = URL(string: "https://console.crossmint.com")!

    var body: some View {
        Form {
            Section {
                LabeledContent("Environment", value: DemoConfiguration.environment?.title ?? "Unknown")
                    .accessibilityIdentifier("environment-label")
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
        switch DemoConfiguration.environment {
        case .staging:
            "This build points at staging. Orders use testnet tokens, so a checkout here cannot move real funds."
        case .production:
            "This build points at production. A checkout here moves real funds."
        case nil:
            "The demo cannot tell which environment this key belongs to. Use a key that starts with ck_staging_ or ck_production_."
        }
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}
