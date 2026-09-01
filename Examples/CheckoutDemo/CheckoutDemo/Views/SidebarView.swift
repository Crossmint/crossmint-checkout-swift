//
//  SidebarView.swift
//  CheckoutDemo
//
//  Created by Tomás Martins on 8/31/26.
//

import SwiftUI

struct SidebarView: View {
    @Binding var selection: SidebarSection?

    var body: some View {
        List(selection: $selection) {
            Section("Configuration") {
                ForEach(SidebarSection.configuration) { section in
                    row(for: section)
                }
            }
            Section("Components") {
                ForEach(SidebarSection.components) { section in
                    row(for: section)
                }
            }
            Section("Diagnostics") {
                ForEach(SidebarSection.diagnostics) { section in
                    row(for: section)
                }
            }
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
        }
        .accessibilityIdentifier("sidebar-list")
    }

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
    }
}
