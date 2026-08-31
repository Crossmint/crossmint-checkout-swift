//
//  CopyableRow.swift
//  CheckoutDemo
//
//  Created by Tomás Martins on 8/31/26.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct CopyableRow: View {
    let label: String
    let value: String
    var accessibilityID: String?

    @State private var didCopy = false

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
            Button {
                copy()
            } label: {
                Image(systemName: didCopy ? "checkmark" : "doc.on.doc")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.tint)
            .accessibilityLabel("Copy \(label)")
        }
    }

    private func copy() {
        #if canImport(UIKit)
        UIPasteboard.general.string = value
        #endif
        didCopy = true
        Task { @concurrent in
            try? await Task.sleep(for: .seconds(1.5))
            await MainActor.run { didCopy = false }
        }
    }
}
