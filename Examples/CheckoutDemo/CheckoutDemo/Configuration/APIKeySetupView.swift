//
//  APIKeySetupView.swift
//  CheckoutDemo
//
//  Created by Tomás Martins on 9/16/26.
//

import SwiftUI

struct APIKeySetupView: View {
    private let setupCommand = "cp Config/Secrets.example.xcconfig Config/Secrets.xcconfig"

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Label("No API key", systemImage: "key.slash")
                        .font(.headline)
                } footer: {
                    Text("CheckoutDemo needs a Crossmint key before it can create an order.")
                }

                APIKeySection()

                Section {
                    Text(setupCommand)
                        .font(.footnote.monospaced())
                        .textSelection(.enabled)
                } header: {
                    Text("Or set it in the project")
                } footer: {
                    Text("Run this command from Examples/CheckoutDemo, add your key to the new file, then build again. A key there replaces the field above. Git does not track that file.")
                }
            }
            .navigationTitle("Set up the demo")
        }
        .accessibilityIdentifier("api-key-setup-view")
    }
}

#Preview {
    APIKeySetupView()
        .environment(DemoConfiguration())
}
