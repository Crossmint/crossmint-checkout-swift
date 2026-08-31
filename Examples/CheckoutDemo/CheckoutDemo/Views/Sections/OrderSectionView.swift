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
            if let session = store.session {
                Section("Active order") {
                    CopyableRow(label: "orderId", value: session.orderId, accessibilityID: "order-id-label")
                    CopyableRow(label: "clientSecret", value: session.clientSecret, accessibilityID: "client-secret-label")
                    LabeledContent("Source", value: session.source.rawValue)
                    LabeledContent("Phase", value: store.phaseDescription)
                        .accessibilityIdentifier("order-phase-label")
                    LabeledContent("Payment", value: store.paymentStatusDescription)
                        .accessibilityIdentifier("payment-status-label")

                    Button("Discard order", systemImage: "trash", role: .destructive) {
                        store.discardOrder()
                    }
                    .accessibilityIdentifier("discard-order-button")
                }
            }

            Section {
                Picker("Token", selection: $store.draft.tokenPresetID) {
                    ForEach(TokenPreset.all) { preset in
                        Text(preset.name).tag(preset.id)
                    }
                    Text("Custom token").tag("custom")
                }
                .accessibilityIdentifier("token-picker")

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
                Text("Each preset is a testnet token, so an order here cannot move real funds.")
            }

            Section("Pay with") {
                Picker("Method", selection: $store.draft.method) {
                    ForEach(OrderDraft.Method.allCases) { method in
                        Text(method.title).tag(method)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("payment-method-picker")

                if store.draft.method == .crypto {
                    TextField("Payer address", text: $store.draft.payerAddress)
                        .font(.callout.monospaced())
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .accessibilityIdentifier("payer-address-input")
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

            Section {
                TextField("orderId", text: $store.pastedOrderId)
                    .font(.callout.monospaced())
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .accessibilityIdentifier("paste-order-id-input")

                TextField("clientSecret", text: $store.pastedClientSecret)
                    .font(.callout.monospaced())
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .accessibilityIdentifier("paste-client-secret-input")

                Button("Use this order") { store.usePastedOrder() }
                    .disabled(!store.canPasteOrder)
                    .accessibilityIdentifier("use-pasted-order-button")
            } header: {
                Text("Paste an order from your backend")
            }
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
}

#Preview {
    NavigationStack {
        OrderSectionView().environment(DemoStore())
    }
}
