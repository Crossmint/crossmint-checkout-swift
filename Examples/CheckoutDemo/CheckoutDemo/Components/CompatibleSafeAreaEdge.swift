//
//  CompatibleSafeAreaEdge.swift
//  CheckoutDemo
//
//  Created by Tomás Martins on 9/2/26.
//

import SwiftUI

struct CompatibleSafeAreaEdge<Bar: View>: ViewModifier {
    let edge: VerticalEdge
    @ViewBuilder let bar: () -> Bar

    func body(content: Content) -> some View {
        content.safeAreaBar(edge: edge, content: bar)
    }
}

extension View {
    func compatibleSafeAreaEdge<Bar: View>(
        _ edge: VerticalEdge,
        @ViewBuilder content: @escaping () -> Bar
    ) -> some View {
        modifier(CompatibleSafeAreaEdge(edge: edge, bar: content))
    }
}
