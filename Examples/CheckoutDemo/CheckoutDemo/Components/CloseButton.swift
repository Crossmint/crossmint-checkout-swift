//
//  CloseButton.swift
//  CheckoutDemo
//
//  Created by Tomás Martins on 9/2/26.
//

import SwiftUI

struct CloseButton: View {
    let action: () -> Void

    var body: some View {
        Button(role: .close, action: action)
    }
}

#Preview {
    NavigationStack {
        Text("Sheet")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    CloseButton {}
                }
            }
    }
}
