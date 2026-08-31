//
//  DemoStore.swift
//  CheckoutDemo
//
//  Created by Tomás Martins on 8/31/26.
//

import CrossmintCheckout
import Foundation
import Observation

@Observable
@MainActor
final class DemoStore {
    var selection: SidebarSection? = .order
    var draft = OrderDraft()
    var options = CheckoutOptions() {
        didSet { if options != oldValue { previewToken = UUID() } }
    }

    private(set) var previewToken = UUID()
    private(set) var session: OrderSession?
    private(set) var events: [DemoEvent] = []
    private(set) var latestOrder: CheckoutOrder?
    private(set) var isCreatingOrder = false
    var orderErrorMessage: String?

    var isShowingOrderError: Bool {
        get { orderErrorMessage != nil }
        set { if !newValue { orderErrorMessage = nil } }
    }

    var pastedOrderId = ""
    var pastedClientSecret = ""

    private let api: OrdersAPI?

    init() {
        if let apiKey = DemoConfiguration.apiKey, let host = DemoConfiguration.environment?.host {
            api = OrdersAPI(apiKey: apiKey, host: host)
        } else {
            api = nil
        }
    }

    // MARK: - Derived

    var phaseDescription: String {
        latestOrder?.phase?.rawValue.capitalized ?? "—"
    }

    var paymentStatusDescription: String {
        latestOrder?.payment?.status ?? "—"
    }

    var identityVerificationCredentials: IdentityVerificationCredentials? {
        latestOrder?.identityVerificationCredentials
    }

    var canPasteOrder: Bool {
        !pastedOrderId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !pastedClientSecret.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Order lifecycle

    func createOrder() async {
        guard let api else {
            orderErrorMessage = "Add a Crossmint client key before creating an order."
            return
        }
        guard draft.validationMessage == nil else {
            orderErrorMessage = draft.validationMessage
            return
        }

        isCreatingOrder = true
        orderErrorMessage = nil
        clearOrderState()

        do {
            let created = try await api.createOrder(from: draft)
            session = created
            previewToken = UUID()
            log(.order, "Order created", created.orderId)
        } catch {
            orderErrorMessage = error.localizedDescription
            log(.failure, "Order creation failed", error.localizedDescription)
        }

        isCreatingOrder = false
    }

    func usePastedOrder() {
        clearOrderState()
        orderErrorMessage = nil
        session = OrderSession(
            orderId: pastedOrderId.trimmingCharacters(in: .whitespacesAndNewlines),
            clientSecret: pastedClientSecret.trimmingCharacters(in: .whitespacesAndNewlines),
            source: .pasted
        )
        log(.order, "Order pasted", session?.orderId)
    }

    func discardOrder() {
        session = nil
        clearOrderState()
    }

    func reloadPreview() {
        previewToken = UUID()
    }

    // MARK: - SDK callbacks

    func handleOrderUpdate(_ update: CheckoutOrderUpdate) {
        guard let order = update.order else { return }
        let previousStatus = latestOrder?.payment?.status
        let previousPhase = latestOrder?.phase
        latestOrder = order

        guard order.phase != previousPhase || order.payment?.status != previousStatus else { return }
        log(
            .order,
            "Phase \(order.phase?.rawValue ?? "unknown")",
            order.payment?.status.map { "payment: \($0)" }
        )

        if order.identityVerificationCredentials != nil {
            log(.identity, "Identity verification required", "The order waits on KYC.")
        }
    }

    func handleOrderCreationFailure(_ message: String) {
        orderErrorMessage = message
        log(.failure, "Checkout reported a failure", message)
    }

    func handleIdentityVerification(status: IdentityVerificationStatus) {
        log(.identity, "Identity verification \(status.rawValue)", nil)
    }

    func handleIdentityVerification(error: IdentityVerificationError) {
        log(.failure, "Identity verification failed", error.message)
    }

    // MARK: - Event log

    func clearEvents() {
        events.removeAll()
    }

    private func log(_ kind: DemoEvent.Kind, _ title: String, _ detail: String?) {
        events.insert(DemoEvent(kind: kind, title: title, detail: detail), at: 0)
        if events.count > 100 { events.removeLast(events.count - 100) }
    }

    private func clearOrderState() {
        latestOrder = nil
    }
}
