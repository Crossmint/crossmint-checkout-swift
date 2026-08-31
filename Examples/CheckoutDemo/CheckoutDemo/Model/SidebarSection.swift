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
    case identity
    case events
    case settings

    var id: Self { self }

    var title: String {
        switch self {
        case .order: "Order"
        case .payment: "Payment"
        case .appearance: "Appearance"
        case .elements: "Elements"
        case .identity: "Identity"
        case .events: "Events"
        case .settings: "Settings"
        }
    }

    var symbolName: String {
        switch self {
        case .order: "shippingbox"
        case .payment: "creditcard"
        case .appearance: "paintbrush"
        case .elements: "slider.horizontal.3"
        case .identity: "person.text.rectangle"
        case .events: "list.bullet.rectangle"
        case .settings: "gearshape"
        }
    }

    static let configuration: [SidebarSection] = [.order, .payment, .appearance, .elements]
    static let components: [SidebarSection] = [.identity]
    static let diagnostics: [SidebarSection] = [.events, .settings]
}
