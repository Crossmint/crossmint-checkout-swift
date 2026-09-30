//
//  OrderEntry.swift
//  CheckoutDemo
//
//  Created by Tomás Martins on 9/2/26.
//

import Foundation

nonisolated enum OrderEntry: String, CaseIterable, Identifiable {
    case new
    case existing

    var id: Self { self }

    var title: String {
        switch self {
        case .new: "New"
        case .existing: "Existing"
        }
    }
}
