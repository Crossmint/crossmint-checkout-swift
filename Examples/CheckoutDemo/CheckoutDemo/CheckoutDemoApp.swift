//
//  CheckoutDemoApp.swift
//  CheckoutDemo
//
//  Created by Robin Curbelo on 2/25/26.
//

import SwiftUI

@main
struct CheckoutDemoApp: App {
    var body: some Scene {
        WindowGroup {
            if let apiKey = DemoConfiguration.apiKey {
                PlaygroundView(apiKey: apiKey)
            } else {
                MissingConfigurationView()
            }
        }
    }
}
