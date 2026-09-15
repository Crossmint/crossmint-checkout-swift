//
//  FieldsSectionView.swift
//  CheckoutDemo
//
//  Created by Tomás Martins on 8/31/26.
//

import SwiftUI

struct FieldsSectionView: View {
    @Environment(DemoStore.self) private var store

    var body: some View {
        @Bindable var store = store

        Form {
            Section {
                Toggle("Wallet address", isOn: $store.options.showsDestinationInput)
                    .accessibilityIdentifier("destination-field-toggle")
                Toggle("Receipt email", isOn: $store.options.showsReceiptEmailInput)
                    .accessibilityIdentifier("receipt-email-field-toggle")
                Toggle("Status message", isOn: $store.options.showsStatusMessage)
                    .accessibilityIdentifier("status-message-field-toggle")
            } header: {
                Text("Show in the checkout")
            } footer: {
                Text("Turn one off only when the order already carries the value. If it does not, the checkout shows an error.")
            }
        }
    }
}

#Preview {
    NavigationStack {
        FieldsSectionView().environment(DemoStore())
    }
}
