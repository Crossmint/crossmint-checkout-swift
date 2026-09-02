//
//  SettingsSectionView.swift
//  CheckoutDemo
//
//  Created by Tomás Martins on 8/31/26.
//

import SwiftUI

struct SettingsSectionView: View {
    var body: some View {
        Form {
            Section("Environment") {
                LabeledContent("Environment", value: DemoConfiguration.environment?.title ?? "Unknown")
                    .accessibilityIdentifier("environment-label")
                LabeledContent("Host", value: DemoConfiguration.environment?.host ?? "unknown")
                    .accessibilityIdentifier("environment-host-label")
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsSectionView()
    }
}
