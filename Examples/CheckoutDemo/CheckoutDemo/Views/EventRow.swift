//
//  EventRow.swift
//  CheckoutDemo
//
//  Created by Tomás Martins on 8/31/26.
//

import SwiftUI

struct EventRow: View {
    let event: DemoEvent

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: event.kind.symbolName)
                .foregroundStyle(event.kind == .failure ? AnyShapeStyle(.red) : AnyShapeStyle(.secondary))
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                if let detail = event.detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 8)
            Text(event.timestamp)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.tertiary)
        }
    }
}

#Preview {
    List {
        EventRow(event: DemoEvent(kind: .order, title: "Phase payment", detail: "payment: requires-kyc"))
        EventRow(event: DemoEvent(kind: .failure, title: "Order creation failed", detail: "Missing wallet address"))
    }
}
