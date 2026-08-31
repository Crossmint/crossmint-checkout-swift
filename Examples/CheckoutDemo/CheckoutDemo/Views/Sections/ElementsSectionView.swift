//
//  ElementsSectionView.swift
//  CheckoutDemo
//
//  Created by Tomás Martins on 8/31/26.
//

import SwiftUI

struct ElementsSectionView: View {
    @Environment(DemoStore.self) private var store

    var body: some View {
        @Bindable var store = store

        Form {
            Section {
                Toggle("Hide destination input", isOn: $store.options.hideDestinationInput)
                    .accessibilityIdentifier("hide-destination-toggle")
                Toggle("Hide receipt email input", isOn: $store.options.hideReceiptEmailInput)
                    .accessibilityIdentifier("hide-receipt-email-toggle")
                Toggle("Hide global message", isOn: $store.options.hideGlobalMessage)
                    .accessibilityIdentifier("hide-global-message-toggle")
            } header: {
                Text("Field visibility")
            } footer: {
                Text("When you hide an input, the order must already supply that value. If it does not, the checkout shows an error.")
            }
        }
    }
}

#Preview {
    NavigationStack {
        ElementsSectionView().environment(DemoStore())
    }
}
