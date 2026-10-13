//
//  CheckoutPreviewEmptyState.swift
//  CheckoutDemo
//
//  Created by Tomas Martins on 01/09/2026.
//

import SwiftUI

struct CheckoutPreviewEmptyState: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        VStack(spacing: 12) {
            Image(decorative: "crossmint-icon")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundStyle(.quaternary)
            
            if horizontalSizeClass == .compact {
                VStack(spacing: 12) {
                    Text("No order")
                        .font(.title.bold())
                    
                    Text("Create an order in the Order section. The checkout appears here.")
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
        }
        .multilineTextAlignment(.center)
    }
}

#Preview {
    CheckoutPreviewEmptyState()
}
