//
//  DataDogConfig.swift
//  CrossmintCheckout
//
//  Created by Tomás Martins on 9/11/26.
//

import Foundation

enum DataDogConfig {
    static let clientToken = "pub946d87ea0c2cc02431c15e9446f776fc"

    private(set) nonisolated(unsafe) static var environment: String = "production"

    static func configure(environment: String) {
        self.environment = environment
    }
}
