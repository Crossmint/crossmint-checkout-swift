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
    case fields
    case identity
    case events

    var id: Self { self }

    var title: String {
        switch self {
        case .order: "Order"
        case .payment: "Payment"
        case .appearance: "Appearance"
        case .fields: "Fields"
        case .identity: "Identity verification"
        case .events: "Events"
        }
    }

    var symbolName: String {
        switch self {
        case .order: "shippingbox"
        case .payment: "creditcard"
        case .appearance: "paintbrush"
        case .fields: "text.cursor"
        case .identity: "person.text.rectangle"
        case .events: "list.bullet.rectangle"
        }
    }

    var configuresCheckout: Bool {
        switch self {
        case .order, .payment, .appearance, .fields: true
        case .identity, .events: false
        }
    }

    static let paymentSections: [SidebarSection] = [.order, .payment, .appearance, .fields]
    static let identitySections: [SidebarSection] = [.identity]
    static let activitySections: [SidebarSection] = [.events]
}
