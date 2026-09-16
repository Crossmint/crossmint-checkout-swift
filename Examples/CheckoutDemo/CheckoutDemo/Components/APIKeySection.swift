//
//  APIKeySection.swift
//  CheckoutDemo
//
//  Created by Tomás Martins on 9/16/26.
//

import SwiftUI

struct APIKeySection: View {
    @Environment(DemoConfiguration.self) private var configuration

    @State private var draft = ""

    var body: some View {
        Section {
            if let buildAPIKey = configuration.buildAPIKey {
                LabeledContent("Current key") {
                    Text(DemoConfiguration.masked(buildAPIKey))
                        .font(.callout.monospaced())
                        .foregroundStyle(.secondary)
                }
                .accessibilityValue("Hidden")
                .accessibilityIdentifier("api-key-masked-label")
            } else {
                TextField("Paste your key", text: $draft, axis: .vertical)
                    .font(.callout.monospaced())
                    .lineLimit(1...4)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .accessibilityLabel("API key")
                    .accessibilityIdentifier("api-key-input")

                Button("Save key") {
                    configuration.save(apiKey: draft)
                }
                .disabled(!canSave)
                .accessibilityIdentifier("save-api-key-button")

                if !configuration.savedAPIKey.isEmpty {
                    Button("Remove key", role: .destructive) {
                        configuration.removeSavedAPIKey()
                        draft = ""
                    }
                    .accessibilityIdentifier("remove-api-key-button")
                }
            }
        } header: {
            Text("API key")
        } footer: {
            Text(footer)
        }
        .onAppear {
            draft = configuration.savedAPIKey
        }
    }

    private var trimmedDraft: String {
        draft.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSave: Bool {
        DemoConfiguration.environment(for: trimmedDraft) != nil
            && trimmedDraft != configuration.savedAPIKey
    }

    private var footer: String {
        if configuration.isManagedByBuildSettings {
            "This build carries its own key, so the app cannot change it."
        } else if !trimmedDraft.isEmpty && DemoConfiguration.environment(for: trimmedDraft) == nil {
            "That does not look like a Crossmint key. Keys start with ck_ and you can copy one from the Crossmint console."
        } else {
            "Copy a key from console.crossmint.com. It stays on this device."
        }
    }
}

#Preview {
    Form {
        APIKeySection()
    }
    .environment(DemoConfiguration())
}
