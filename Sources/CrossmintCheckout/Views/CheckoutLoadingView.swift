//
//  CheckoutLoadingView.swift
//  CrossmintCheckout
//
//  Created by Tomás Martins on 9/2/26.
//

import SwiftUI

struct CheckoutLoadingView: View {
    var body: some View {
        ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityLabel("Loading")
    }
}
