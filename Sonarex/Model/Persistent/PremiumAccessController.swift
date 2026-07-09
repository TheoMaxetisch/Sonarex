import Foundation
import Observation
import StoreKit

/// Kapselt Testphase, StoreKit-Kaufstatus und Paywall-Entscheidungen an einer Stelle.
@MainActor
@Observable
final class PremiumAccessController {
    static let productID = "sonarex.premium.unlock"
    static let trialDurationDays = 14

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private var transactionUpdatesTask: Task<Void, Never>?
    @ObservationIgnored private let trialStartKey = "premiumTrialStartedAt"

    var products: [Product] = []
    var hasPurchasedPremium = false
    var isLoading = false
    var errorMessage: String?
    var isPaywallPresented = false
    var requestedFeature = "Premium"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        // Die Testphase startet automatisch beim ersten App-Start und wird in UserDefaults gespeichert.
        startTrialIfNeeded()
        transactionUpdatesTask = listenForTransactionUpdates()
    }

    deinit {
        transactionUpdatesTask?.cancel()
    }

    var trialStartedAt: Date {
        if let date = defaults.object(forKey: trialStartKey) as? Date {
            return date
        }
        let now = Date.now
        defaults.set(now, forKey: trialStartKey)
        return now
    }

    var trialEndsAt: Date {
        Calendar.current.date(byAdding: .day, value: Self.trialDurationDays, to: trialStartedAt) ?? trialStartedAt
    }

    var isTrialActive: Bool {
        Date.now < trialEndsAt
    }

    var remainingTrialDays: Int {
        guard isTrialActive else { return 0 }
        let startOfToday = Calendar.current.startOfDay(for: .now)
        let endDay = Calendar.current.startOfDay(for: trialEndsAt)
        return max(Calendar.current.dateComponents([.day], from: startOfToday, to: endDay).day ?? 0, 1)
    }

    var hasPremiumAccess: Bool {
        isTrialActive || hasPurchasedPremium
    }

    var premiumStatusText: String {
        if hasPurchasedPremium {
            return "Premium aktiv"
        }
        if isTrialActive {
            return "\(remainingTrialDays) Tage Testphase übrig"
        }
        return "Basisversion aktiv"
    }

    var premiumProduct: Product? {
        products.first { $0.id == Self.productID }
    }

    func refresh() async {
        isLoading = true
        errorMessage = nil
        do {
            products = try await Product.products(for: [Self.productID])
            try await refreshPurchasedPremium()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func purchasePremium() async {
        isLoading = true
        errorMessage = nil
        do {
            if products.isEmpty {
                products = try await Product.products(for: [Self.productID])
            }
            guard let product = premiumProduct else {
                throw PremiumAccessError.productUnavailable
            }

            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try verified(verification)
                hasPurchasedPremium = transaction.productID == Self.productID
                await transaction.finish()
                isPaywallPresented = !hasPremiumAccess
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        do {
            try await AppStore.sync()
            try await refreshPurchasedPremium()
            isPaywallPresented = !hasPremiumAccess
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func requirePremium(for feature: String) -> Bool {
        // Views fragen diese Methode vor Premium-Aktionen ab und zeigen bei Bedarf die Paywall.
        guard hasPremiumAccess else {
            requestedFeature = feature
            isPaywallPresented = true
            return false
        }
        return true
    }

    private func startTrialIfNeeded() {
        _ = trialStartedAt
    }

    private func refreshPurchasedPremium() async throws {
        var isPurchased = false
        // CurrentEntitlements bildet den zuletzt verifizierten App-Store-Status ab.
        for await result in Transaction.currentEntitlements {
            let transaction = try verified(result)
            if transaction.productID == Self.productID {
                isPurchased = transaction.revocationDate == nil
            }
        }
        hasPurchasedPremium = isPurchased
    }

    private func listenForTransactionUpdates() -> Task<Void, Never> {
        // StoreKit-Updates koennen auch nach dem Kaufdialog eintreffen und muessen dauerhaft beobachtet werden.
        Task { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                do {
                    let transaction = try self.verified(result)
                    if transaction.productID == Self.productID {
                        self.hasPurchasedPremium = transaction.revocationDate == nil
                        self.isPaywallPresented = !self.hasPremiumAccess
                    }
                    await transaction.finish()
                } catch {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value):
            return value
        case .unverified:
            throw PremiumAccessError.unverifiedTransaction
        }
    }
}

private enum PremiumAccessError: LocalizedError {
    case productUnavailable
    case unverifiedTransaction

    var errorDescription: String? {
        switch self {
        case .productUnavailable:
            "Premium ist in StoreKit noch nicht konfiguriert."
        case .unverifiedTransaction:
            "Der Kauf konnte nicht verifiziert werden."
        }
    }
}
