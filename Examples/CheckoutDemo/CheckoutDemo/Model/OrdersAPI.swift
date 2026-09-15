//
//  OrdersAPI.swift
//  CheckoutDemo
//
//  Created by Tomás Martins on 8/31/26.
//

import Foundation

nonisolated struct OrderSession: Equatable {
    enum Source: String {
        case createdInApp = "Created in app"
        case existing = "Existing"
    }

    var orderId: String
    var clientSecret: String
    var source: Source
}

nonisolated struct OrdersAPI: Sendable {
    let apiKey: String
    let host: String

    struct APIError: LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }

    func createOrder(from draft: OrderDraft) async throws -> OrderSession {
        var payment: [String: Any] = [
            "method": "card",
            "currency": "usd",
        ]
        let receiptEmail = draft.receiptEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        if !receiptEmail.isEmpty {
            payment["receiptEmail"] = receiptEmail
        }
        let body: [String: Any] = [
            "payment": payment,
            "lineItems": [
                "tokenLocator": draft.tokenLocator,
                "executionParameters": ["mode": "exact-in", "amount": draft.amountString],
            ],
            "recipient": [
                "walletAddress": draft.recipientWalletAddress
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            ],
        ]

        var request = URLRequest(url: URL(string: "https://\(host)/api/2022-06-09/orders")!)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "X-API-KEY")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw APIError(message: "The Orders API returned a response the demo could not read.")
        }
        if let message = json["message"] as? String, json["error"] != nil {
            throw APIError(message: message)
        }
        guard let clientSecret = json["clientSecret"] as? String,
              let order = json["order"] as? [String: Any],
              let orderId = order["orderId"] as? String else {
            throw APIError(message: "The Orders API response had no orderId or clientSecret.")
        }

        return OrderSession(orderId: orderId, clientSecret: clientSecret, source: .createdInApp)
    }
}
