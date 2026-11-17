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
    @Environment(DemoConfiguration.self) private var configuration
    @State private var store: DemoStore
    @State private var isShowingCheckout = false
    @State private var checkoutDetent: PresentationDetent = .large

    private static let parkedDetent = PresentationDetent.height(96)

    private var needsAPIKey: Bool { configuration.apiKey == nil }

    init(apiKey: String, configuration: DemoConfiguration) {
        self.apiKey = apiKey
        _store = State(initialValue: DemoStore(configuration: configuration))
    }

    var body: some View {
        @Bindable var store = store

        NavigationSplitView {
            SidebarView(
                selection: $store.selection,
                showsActiveOrder: horizontalSizeClass != .compact
            )
        } content: {
            SectionDetailView(
                section: store.selection,
                apiKey: apiKey,
                showsCheckoutButton: horizontalSizeClass == .compact,
                isShowingCheckout: $isShowingCheckout,
                checkoutDetent: $checkoutDetent
            )
            .disabled(needsAPIKey)
            .opacity(needsAPIKey ? 0.5 : 1)
        } detail: {
            CheckoutPreviewView(apiKey: apiKey)
                .disabled(needsAPIKey)
        }
        .environment(store)
        .onChange(of: apiKey) { _, _ in
            store.discardOrder()
        }
        .onChange(of: horizontalSizeClass) { _, newValue in
            if newValue != .compact { isShowingCheckout = false }
            guard newValue != .compact, store.selection == nil else { return }
            store.selection = store.lastSelection
        }
        .onChange(of: store.previewIdentityCredentials) { _, newValue in
            guard newValue != nil, horizontalSizeClass == .compact else { return }
            checkoutDetent = .large
            isShowingCheckout = true
        }
        .sheet(isPresented: $isShowingCheckout) {
            NavigationStack {
                CheckoutPreviewView(apiKey: apiKey, showsOrderDetailsButton: true)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            CloseButton { isShowingCheckout = false }
                                .accessibilityIdentifier("close-checkout-button")
                        }
                    }
            }
            .presentationDetents([Self.parkedDetent, .large], selection: $checkoutDetent)
            .presentationBackgroundInteraction(.enabled(upThrough: Self.parkedDetent))
            .presentationDragIndicator(.visible)
            .environment(store)
        }
    }
}

#Preview {
    PlaygroundView(apiKey: "ck_staging_example", configuration: DemoConfiguration())
}
