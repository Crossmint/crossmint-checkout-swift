//
//  SidebarView.swift
//  CheckoutDemo
//
//  Created by Tomás Martins on 8/31/26.
//

import SwiftUI

struct SidebarView: View {
    @Binding var selection: SidebarSection?
    var showsActiveOrder = false

    @Environment(DemoStore.self) private var store
    @Environment(DemoConfiguration.self) private var configuration
    @State private var isShowingSettings = false

    var body: some View {
        List(selection: $selection) {
            if needsAPIKey {
                Section {
                    Button("Add client key", systemImage: "key") {
                        isShowingSettings = true
                    }
                    .accessibilityIdentifier("add-api-key-button")
                }
            }

            Group {
                Section("Payment") {
                    ForEach(SidebarSection.paymentSections) { section in
                        row(for: section)
                    }
                }
                Section("Identity") {
                    ForEach(SidebarSection.identitySections) { section in
                        row(for: section)
                    }
                }
                Section("Activity") {
                    ForEach(SidebarSection.activitySections) { section in
                        row(for: section)
                    }
                }
            }
            .disabled(needsAPIKey)
            .opacity(needsAPIKey ? 0.5 : 1)
        }
        .navigationTitle("Playground")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Label {
                    Text("Playground")
                } icon: {
                    Image("crossmint-icon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }
                .labelStyle(.titleAndIcon)
            }
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    isShowingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .overlay(alignment: .topTrailing) {
                            if needsAPIKey {
                                Circle()
                                    .fill(.red)
                                    .frame(width: 7, height: 7)
                            }
                        }
                }
                .accessibilityLabel("Settings")
                .accessibilityValue(needsAPIKey ? "Client key needed" : "")
                .accessibilityIdentifier("show-settings-button")
            }
        }
        .task {
            if needsAPIKey { isShowingSettings = true }
        }
        .sheet(isPresented: $isShowingSettings) {
            NavigationStack {
                SettingsView()
                    .navigationTitle("Settings")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            CloseButton { isShowingSettings = false }
                                .accessibilityIdentifier("close-settings-button")
                        }
                    }
            }
        }
        .compatibleSafeAreaEdge(.bottom) {
            if showsActiveOrder, let session = store.session {
                OrderStatusCard(session: session)
            }
        }
        .accessibilityIdentifier("sidebar-list")
    }

    private var needsAPIKey: Bool { configuration.apiKey == nil }

    private func row(for section: SidebarSection) -> some View {
        Label(section.title, systemImage: section.symbolName)
            .tag(section)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier("sidebar-\(section.rawValue)")
    }
}

#Preview {
    NavigationStack {
        SidebarView(selection: .constant(.order))
            .environment(DemoStore(configuration: DemoConfiguration()))
            .environment(DemoConfiguration())
    }
}
