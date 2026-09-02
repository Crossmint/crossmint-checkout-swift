//
//  PlaygroundView.swift
//  CheckoutDemo
//
//  Created by Tomás Martins on 8/31/26.
//

import SwiftUI

struct PlaygroundView: View {
    let apiKey: String

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var store = DemoStore()

    var body: some View {
        @Bindable var store = store

        NavigationSplitView {
            SidebarView(selection: $store.selection)
        } content: {
            SectionDetailView(
                section: store.selection,
                apiKey: apiKey,
                showsCheckoutButton: horizontalSizeClass == .compact
            )
        } detail: {
            CheckoutPreviewView(apiKey: apiKey)
        }
        .environment(store)
        .onChange(of: horizontalSizeClass) { _, newValue in
            guard newValue != .compact, store.selection == nil else { return }
            store.selection = store.lastSelection
        }
    }
}

#Preview {
    PlaygroundView(apiKey: "ck_staging_example")
}
