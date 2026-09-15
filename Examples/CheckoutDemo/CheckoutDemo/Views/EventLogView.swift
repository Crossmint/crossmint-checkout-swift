//
//  EventLogView.swift
//  CheckoutDemo
//
//  Created by Tomás Martins on 8/31/26.
//

import SwiftUI

struct EventLogView: View {
    @Environment(DemoStore.self) private var store

    var body: some View {
        List(store.events) { event in
            EventRow(event: event)
        }
        .accessibilityIdentifier("event-log-list")
        .listStyle(.insetGrouped)
        .overlay {
            if store.events.isEmpty {
                ContentUnavailableView(
                    "No events yet",
                    systemImage: "list.bullet.rectangle",
                    description: Text("Start a checkout. The SDK reports order updates here.")
                )
            }
        }
        .navigationTitle("Events")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Clear") { store.clearEvents() }
                    .disabled(store.events.isEmpty)
                    .accessibilityIdentifier("clear-events-button")
            }
        }
    }
}

#Preview {
    NavigationStack {
        EventLogView().environment(DemoStore())
    }
}
