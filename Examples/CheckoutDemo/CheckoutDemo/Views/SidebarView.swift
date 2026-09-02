//
//  SidebarView.swift
//  CheckoutDemo
//
//  Created by Tomás Martins on 8/31/26.
//

import SwiftUI

struct SidebarView: View {
    @Binding var selection: SidebarSection?

    @State private var isShowingAbout = false

    var body: some View {
        List(selection: $selection) {
            Section("Checkout") {
                ForEach(SidebarSection.checkout) { section in
                    row(for: section)
                }
            }
            Section("Activity") {
                ForEach(SidebarSection.activity) { section in
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
            ToolbarItem(placement: .topBarLeading) {
                Button("About", systemImage: "info.circle") {
                    isShowingAbout = true
                }
                .accessibilityIdentifier("show-about-button")
            }
        }
        .sheet(isPresented: $isShowingAbout) {
            NavigationStack {
                AboutView()
                    .navigationTitle("About")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { isShowingAbout = false }
                                .accessibilityIdentifier("close-about-button")
                        }
                    }
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
