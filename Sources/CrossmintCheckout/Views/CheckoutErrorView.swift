//
//  CheckoutErrorView.swift
//  CrossmintCheckout
//
//  Created by Tomás Martins on 8/20/26.
//

import SwiftUI

struct CheckoutErrorView: View {
    let error: Error

    var body: some View {
        VStack(spacing: 20) {
            Text("Error")
                .font(.headline)
            Text(error.localizedDescription)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
                .padding()
        }
    }
}
