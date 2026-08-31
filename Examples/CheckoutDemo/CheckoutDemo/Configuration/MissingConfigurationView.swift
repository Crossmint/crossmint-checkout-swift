//
//  MissingConfigurationView.swift
//  CheckoutDemo
//
//  Created by Tomás Martins on 8/31/26.
//

import SwiftUI

struct MissingConfigurationView: View {
    private let setupCommand = "cp Config/Secrets.example.xcconfig Config/Secrets.xcconfig"

    var body: some View {
        ContentUnavailableView {
            Label("No API key", systemImage: "key.slash")
        } description: {
            VStack(spacing: 16) {
                Text("CheckoutDemo needs a Crossmint client key before it can create an order.")

                Text(setupCommand)
                    .font(.footnote.monospaced())
                    .multilineTextAlignment(.leading)
                    .textSelection(.enabled)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.quaternary, in: .rect(cornerRadius: 8))

                Text("Run that from Examples/CheckoutDemo, put your ck_staging_ key in the new file, then build again. Secrets.xcconfig is gitignored.")
            }
            .padding(.top, 4)
        }
        .accessibilityIdentifier("missing-configuration-view")
    }
}

#Preview {
    MissingConfigurationView()
}
