//
//  CheckoutDemoApp.swift
//  CheckoutDemo
//
//  Created by Robin Curbelo on 2/25/26.
//

import SwiftUI

@main
struct CheckoutDemoApp: App {
    @State private var configuration = DemoConfiguration()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(configuration)
        }
    }
}
