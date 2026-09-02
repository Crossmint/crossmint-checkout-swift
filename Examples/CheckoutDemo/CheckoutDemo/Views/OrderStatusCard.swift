//
//  OrderStatusCard.swift
//  CheckoutDemo
//
//  Created by Tomás Martins on 9/2/26.
//

import CrossmintCheckout
import SwiftUI

struct OrderStatusCard: View {
    let session: OrderSession

    @Environment(DemoStore.self) private var store
    @State private var isShowingDetails = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: symbolName)
                    .font(.title3)
                    .foregroundStyle(tint)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(2)
                    Text(session.orderId)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .accessibilityIdentifier("order-id-label")
                }

                Spacer(minLength: 8)

                CopyButton(value: session.orderId, label: "Copy orderId")
            }

            Divider()

            HStack {
                Button("Details") { isShowingDetails = true }
                    .accessibilityIdentifier("order-details-button")
                Spacer()
                Button("Discard", systemImage: "trash", role: .destructive) {
                    store.discardOrder()
                }
                .accessibilityIdentifier("discard-order-button")
            }
            .font(.subheadline)
            .buttonStyle(.borderless)
        }
        .padding(14)
        .background(.background, in: .rect(cornerRadius: 16))
        .padding(.horizontal)
        .padding(.bottom, 8)
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $isShowingDetails) {
            OrderDetailsSheet(session: session).environment(store)
        }
    }

    private var title: String {
        if let status = store.latestOrder?.payment?.status {
            return status.replacingOccurrences(of: "-", with: " ").capitalized
                .replacingOccurrences(of: "Kyc", with: "KYC")
        }
        if let phase = store.latestOrder?.phase {
            return "\(phase.rawValue.capitalized) phase"
        }
        return "No updates yet"
    }

    private var symbolName: String {
        switch store.latestOrder?.phase {
        case .quote: "tag"
        case .payment: "creditcard"
        case .delivery: "shippingbox"
        case .completed: "checkmark.circle.fill"
        case nil: "clock"
        }
    }

    private var tint: Color {
        switch store.latestOrder?.phase {
        case .quote: .secondary
        case .payment: .orange
        case .delivery: .blue
        case .completed: .green
        case nil: .secondary
        }
    }
}

#Preview {
    OrderStatusCard(
        session: OrderSession(
            orderId: "ord_a1b2c3d4e5f6a7b8",
            clientSecret: "cs_a1b2c3d4e5f6",
            source: .createdInApp
        )
    )
    .environment(DemoStore())
}
