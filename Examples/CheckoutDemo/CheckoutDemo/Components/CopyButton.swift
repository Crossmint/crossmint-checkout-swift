//
//  CopyButton.swift
//  CheckoutDemo
//
//  Created by Tomás Martins on 9/2/26.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct CopyButton: View {
    let value: String
    let label: String

    @State private var didCopy = false

    var body: some View {
        Button {
            copy()
        } label: {
            Image(systemName: didCopy ? "checkmark" : "doc.on.doc")
        }
        .buttonStyle(.plain)
        .foregroundStyle(.tint)
        .accessibilityLabel(label)
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

#Preview {
    CopyButton(value: "ord_123", label: "Copy order ID")
}
