//
//  CopyableRow.swift
//  CheckoutDemo
//
//  Created by Tomás Martins on 8/31/26.
//

import SwiftUI

struct CopyableRow: View {
    let label: String
    let value: String
    var accessibilityID: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer(minLength: 12)
            Text(value)
                .font(.callout.monospaced())
                .lineLimit(1)
                .truncationMode(.middle)
                .accessibilityIdentifier(accessibilityID ?? label)
            CopyButton(value: value, label: "Copy \(label)")
        }
    }
}

#Preview {
    List {
        CopyableRow(label: "orderId", value: "ord_a1b2c3d4e5f6")
    }
}
