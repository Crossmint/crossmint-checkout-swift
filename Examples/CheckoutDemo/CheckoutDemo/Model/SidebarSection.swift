//
//  SidebarSection.swift
//  CheckoutDemo
//
//  Created by Tomás Martins on 8/31/26.
//

import Foundation

nonisolated enum SidebarSection: String, CaseIterable, Identifiable, Hashable {
    case order
    case payment
    case appearance
    case elements
    case events
    case settings

    var id: Self { self }

    var title: String {
        switch self {
        case .order: "Order"
        case .payment: "Payment"
        case .appearance: "Appearance"
        case .elements: "Elements"
        case .events: "Events"
        case .settings: "Settings"
        }
    }

    var subtitle: String {
        switch self {
        case .order: "What you're selling and its parameters"
        case .payment: "Accepted methods and currencies"
        case .appearance: "Colors and corner radius"
        case .elements: "Which fields the checkout shows"
        case .events: "What the SDK reported"
        case .settings: "Environment and API key"
        }
    }

    var symbolName: String {
        switch self {
        case .order: "shippingbox"
        case .payment: "creditcard"
        case .appearance: "paintbrush"
        case .elements: "slider.horizontal.3"
        case .events: "list.bullet.rectangle"
        case .settings: "gearshape"
        }
    }

    static let configuration: [SidebarSection] = [.order, .payment, .appearance, .elements]
    static let diagnostics: [SidebarSection] = [.events, .settings]
}
