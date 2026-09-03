//
//  OrderSectionView.swift
//  CheckoutDemo
//
//  Created by Tomás Martins on 8/31/26.
//

import SwiftUI

struct OrderSectionView: View {
    @Environment(DemoStore.self) private var store

    var body: some View {
        @Bindable var store = store

        Form {
            Section {
                Picker("Order source", selection: $store.orderEntry) {
                    ForEach(OrderEntry.allCases) { entry in
                        Text(entry.title).tag(entry)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .accessibilityLabel("Order source")
                .accessibilityIdentifier("order-entry-picker")
            }

            switch store.orderEntry {
            case .new: newOrderFields
            case .existing: existingOrderFields
            }
        }
        .onChange(of: store.draft.tokenSymbol) { _, newValue in
            guard newValue != TokenPreset.custom else { return }
            store.draft.customTokenLocator = ""
        }
        .alert(
            "Could not create the order",
            isPresented: $store.isShowingOrderError,
            presenting: store.orderErrorMessage
        ) { _ in
            Button("OK", role: .cancel) { store.orderErrorMessage = nil }
        } message: { message in
            Text(message)
        }
    }

    @ViewBuilder private var newOrderFields: some View {
        @Bindable var store = store

        Section {
            Picker("Token", selection: $store.draft.tokenSymbol) {
                ForEach(TokenPreset.all) { preset in
                    Text(preset.symbol).tag(preset.symbol)
                }
                Text("Custom token").tag(TokenPreset.custom)
            }
            .accessibilityIdentifier("token-picker")

            if let preset = store.draft.preset {
                Picker("Chain", selection: $store.draft.networkSelection) {
                    ForEach(preset.networks) { network in
                        Text(network.title).tag(network.locator)
                    }
                }
                .accessibilityIdentifier("chain-picker")
            }

            if store.draft.preset == nil {
                TextField("chain:token-address", text: $store.draft.customTokenLocator)
                    .font(.callout.monospaced())
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .accessibilityIdentifier("custom-token-locator-input")
            }

            LabeledContent("Amount") {
                TextField("Amount", value: $store.draft.amount, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .accessibilityIdentifier("amount-input")
            }
        } header: {
            Text("Item")
        } footer: {
            if store.draft.preset == nil {
                Text("Use the format chain:address, such as base:0x833…. The demo does not check that the token exists.")
            } else {
                Text("Each preset is a testnet token, so an order here cannot move real funds.")
            }
        }

        Section {
            TextField("Recipient wallet address", text: $store.draft.recipientWalletAddress)
                .font(.callout.monospaced())
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .accessibilityIdentifier("recipient-address-input")

            TextField("Receipt email", text: $store.draft.receiptEmail)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .accessibilityIdentifier("receipt-email-input")
        } header: {
            Text("Recipient")
        } footer: {
            if let message = store.draft.validationMessage {
                Text(message).foregroundStyle(.red)
            }
        }

        Section {
            Button {
                Task { await store.createOrder() }
            } label: {
                HStack {
                    Text(store.session == nil ? "Create order" : "Recreate order")
                    Spacer()
                    if store.isCreatingOrder { ProgressView() }
                }
            }
            .disabled(store.draft.validationMessage != nil || store.isCreatingOrder)
            .accessibilityIdentifier("create-order-button")
        } footer: {
            Text("This demo calls the Orders API from the device, so you can try the checkout without a backend. In production, create orders on your server.")
        }
    }

    @ViewBuilder private var existingOrderFields: some View {
        @Bindable var store = store

        Section {
            TextField("orderId", text: $store.existingOrderId)
                .font(.callout.monospaced())
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .accessibilityIdentifier("existing-order-id-input")

            TextField("clientSecret", text: $store.existingClientSecret)
                .font(.callout.monospaced())
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .accessibilityIdentifier("existing-client-secret-input")
        } footer: {
            Text("Both values come from the Orders API response your backend gets.")
        }

        Section {
            Button("Use this order") { store.useExistingOrder() }
                .disabled(!store.canUseExistingOrder)
                .accessibilityIdentifier("use-existing-order-button")
        }
    }
}

#Preview {
    NavigationStack {
        OrderSectionView().environment(DemoStore())
    }
}
