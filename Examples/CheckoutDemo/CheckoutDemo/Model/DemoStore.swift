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
    private let configuration: DemoConfiguration

    init(configuration: DemoConfiguration) {
        self.configuration = configuration
        selection = configuration.apiKey == nil ? nil : .order
    }

    var selection: SidebarSection? = .order {
        didSet { if let selection { lastSelection = selection } }
    }

    private(set) var lastSelection: SidebarSection = .order
    var orderEntry: OrderEntry = .new
    var draft = OrderDraft()
    var options = CheckoutOptions() {
        didSet { if options != oldValue { previewToken = UUID() } }
    }

    private(set) var previewToken = UUID()
    private(set) var session: OrderSession?
    private(set) var events: [DemoEvent] = []
    private(set) var latestOrder: CheckoutOrder?
    private(set) var isCreatingOrder = false
    private var pendingOrderRequest: UUID?
    var orderErrorMessage: String?
    var checkoutErrorMessage: String?

    var isShowingOrderError: Bool {
        get { orderErrorMessage != nil }
        set { if !newValue { orderErrorMessage = nil } }
    }

    var isShowingCheckoutError: Bool {
        get { checkoutErrorMessage != nil }
        set { if !newValue { checkoutErrorMessage = nil } }
    }

    var existingOrderId = ""
    var existingClientSecret = ""

    var previewIdentityCredentials: IdentityVerificationCredentials?

    var identityInquiryId = ""
    var identitySessionToken = ""
    var identityLocale: CheckoutLocale?

    private var api: OrdersAPI? {
        guard let apiKey = configuration.apiKey,
              let host = configuration.environment?.host else { return nil }
        return OrdersAPI(apiKey: apiKey, host: host)
    }

    var phaseDescription: String {
        latestOrder?.phase?.rawValue.capitalized ?? "—"
    }

    var paymentStatusDescription: String {
        latestOrder?.payment?.status ?? "—"
    }

    var identityVerificationCredentials: IdentityVerificationCredentials? {
        latestOrder?.identityVerificationCredentials
    }

    var manualIdentityCredentials: IdentityVerificationCredentials? {
        let inquiry = identityInquiryId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !inquiry.isEmpty else { return nil }
        let token = identitySessionToken.trimmingCharacters(in: .whitespacesAndNewlines)
        return IdentityVerificationCredentials(
            inquiryId: inquiry,
            sessionToken: token.isEmpty ? nil : token
        )
    }

    func adoptOrderIdentityCredentials() {
        guard let credentials = identityVerificationCredentials,
              let inquiryId = credentials.inquiryId else { return }
        identityInquiryId = inquiryId
        identitySessionToken = credentials.sessionToken ?? ""
    }

    var canUseExistingOrder: Bool {
        !existingOrderId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !existingClientSecret.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func createOrder() async {
        guard let api else {
            orderErrorMessage = "Add your client key in Settings before creating an order."
            return
        }
        guard draft.validationMessage == nil else {
            orderErrorMessage = draft.validationMessage
            return
        }

        let request = UUID()
        pendingOrderRequest = request
        isCreatingOrder = true
        orderErrorMessage = nil

        do {
            let created = try await api.createOrder(from: draft)
            guard pendingOrderRequest == request else { return }
            clearOrderState()
            session = created
            previewToken = UUID()
            log(.order, "Order created", created.orderId)
        } catch {
            guard pendingOrderRequest == request else { return }
            orderErrorMessage = error.localizedDescription
            log(.failure, "Order creation failed", error.localizedDescription)
        }

        cancelPendingOrder()
    }

    func useExistingOrder() {
        cancelPendingOrder()
        clearOrderState()
        orderErrorMessage = nil
        session = OrderSession(
            orderId: existingOrderId.trimmingCharacters(in: .whitespacesAndNewlines),
            clientSecret: existingClientSecret.trimmingCharacters(in: .whitespacesAndNewlines),
            source: .existing
        )
        log(.order, "Existing order used", session?.orderId)
    }

    func discardOrder() {
        cancelPendingOrder()
        session = nil
        clearOrderState()
    }

    func reloadPreview() {
        previewToken = UUID()
    }

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
            log(.identity, "Identity verification required", "The order returned verification credentials.")
        }
    }

    func handleOrderCreationFailure(_ message: String) {
        checkoutErrorMessage = message
        log(.failure, "Checkout reported a failure", message)
    }

    func handleIdentityVerificationReady() {
        log(.identity, "Identity verification ready", nil)
    }

    func handleIdentityVerificationCancelled() {
        log(.identity, "Identity verification cancelled", nil)
    }

    func handleIdentityVerification(status: IdentityVerificationStatus) {
        log(.identity, "Identity verification \(status.rawValue)", nil)
    }

    func handleIdentityVerification(error: IdentityVerificationError) {
        log(.failure, "Identity verification failed", error.message)
    }

    func clearEvents() {
        events.removeAll()
    }

    private func log(_ kind: DemoEvent.Kind, _ title: String, _ detail: String?) {
        events.insert(DemoEvent(kind: kind, title: title, detail: detail), at: 0)
        if events.count > 100 { events.removeLast(events.count - 100) }
    }

    private func cancelPendingOrder() {
        pendingOrderRequest = nil
        isCreatingOrder = false
    }

    private func clearOrderState() {
        latestOrder = nil
        previewIdentityCredentials = nil
        checkoutErrorMessage = nil
    }
}
