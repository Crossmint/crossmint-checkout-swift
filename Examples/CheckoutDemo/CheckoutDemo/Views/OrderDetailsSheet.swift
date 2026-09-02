//
//  OrderDetailsSheet.swift
//  CheckoutDemo
//
//  Created by Tomás Martins on 9/2/26.
//

import SwiftUI

struct OrderDetailsSheet: View {
    let session: OrderSession

    @Environment(DemoStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    CopyableRow(
                        label: "orderId",
                        value: session.orderId,
                        accessibilityID: "details-order-id-label"
                    )
                    CopyableRow(
                        label: "clientSecret",
                        value: session.clientSecret,
                        accessibilityID: "client-secret-label"
                    )
                }

                Section {
                    LabeledContent("Source", value: session.source.rawValue)
                    LabeledContent("Phase", value: store.phaseDescription)
                        .accessibilityIdentifier("order-phase-label")
                    LabeledContent("Payment status", value: store.paymentStatusDescription)
                        .accessibilityIdentifier("payment-status-label")
                } footer: {
                    Text("The SDK reports the phase and the payment status as the checkout runs.")
                }

                Section {
                    if store.events.isEmpty {
                        Text("No events yet")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(store.events) { event in
                            EventRow(event: event)
                        }
                    }
                } header: {
                    HStack {
                        Text("Events")
                        Spacer(minLength: 8)
                        Button("Clear") { store.clearEvents() }
                            .disabled(store.events.isEmpty)
                            .accessibilityIdentifier("clear-events-button")
                    }
                }
                .accessibilityIdentifier("order-events-section")
            }
            .navigationTitle("Order details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .accessibilityIdentifier("close-order-details-button")
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    OrderDetailsSheet(
        session: OrderSession(
            orderId: "ord_a1b2c3d4e5f6",
            clientSecret: "cs_a1b2c3d4e5f6",
            source: .createdInApp
        )
    )
    .environment(DemoStore())
}
