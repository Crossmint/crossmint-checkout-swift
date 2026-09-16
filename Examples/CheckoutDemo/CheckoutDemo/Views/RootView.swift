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
        PlaygroundView(
            apiKey: configuration.apiKey ?? "",
            configuration: configuration
        )
    }
}

#Preview {
    RootView()
        .environment(DemoConfiguration())
}
