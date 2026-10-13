//
//  DemoEvent.swift
//  CheckoutDemo
//
//  Created by Tomás Martins on 8/31/26.
//

import Foundation

nonisolated struct DemoEvent: Identifiable, Equatable {
    enum Kind: String {
        case order
        case identity
        case failure

        var symbolName: String {
            switch self {
            case .order: "arrow.triangle.2.circlepath"
            case .identity: "person.text.rectangle"
            case .failure: "exclamationmark.triangle"
            }
        }
    }

    let id = UUID()
    let date = Date()
    let kind: Kind
    let title: String
    let detail: String?

    var timestamp: String {
        date.formatted(date: .omitted, time: .standard)
    }
}
