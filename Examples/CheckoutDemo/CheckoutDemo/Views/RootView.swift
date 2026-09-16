//
//  RootView.swift
//  CheckoutDemo
//
//  Created by Tomás Martins on 9/16/26.
//

import SwiftUI

struct RootView: View {
    @Environment(DemoConfiguration.self) private var configuration

    var body: some View {
        if let apiKey = configuration.apiKey {
            PlaygroundView(apiKey: apiKey, configuration: configuration)
        } else {
            APIKeySetupView()
        }
    }
}

#Preview {
    RootView()
        .environment(DemoConfiguration())
}
