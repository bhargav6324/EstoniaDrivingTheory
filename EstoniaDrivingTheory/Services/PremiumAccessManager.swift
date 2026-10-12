import Foundation
import StoreKit
import SwiftUI

public enum StoreError: LocalizedError {
    case failedVerification
    case productNotFound(String)
    case purchaseFailed(String)
    case notEntitled
    case storeKitUnavailable

    public var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Transaction verification failed. The purchase could not be verified by Apple."
        case .productNotFound(let id):
            return "Product with ID '\(id)' was not found."
        case .purchaseFailed(let reason):
            return "Purchase failed: \(reason)"
        case .notEntitled:
            return "No active entitlement found for this Apple ID."
        case .storeKitUnavailable:
            return "StoreKit service is currently unavailable."
        }
    }
}

public enum SubscriptionType: String, Codable {
    case monthly
    case lifetime
}

public enum PremiumFeature {
    case unlimitedMockExams
    case fullPractice
    case roadSignFlashcards
    case roadSignTest
    case fullMistakes
    case weakTopicPractice
    case advancedProgress
}

/// Central manager for StoreKit 2 monetization and Estonia Driving Theory Pro entitlement verification.
/// Follows the verified RuralKeep StoreKit 2 architecture with dual product support.
@MainActor
public final class PremiumAccessManager: ObservableObject {
    public static let shared = PremiumAccessManager()

    // Canonical StoreKit 2 Product Identifiers (Single source of truth)
    nonisolated public static let lifetimeProductID = "com.estoniadrivingtheory.premium.lifetime"
    nonisolated public static let monthlyProductID = "com.estoniadrivingtheory.premium.monthly"

    // Backwards-compatibility aliases
    nonisolated public static var lifetimeProductId: String { lifetimeProductID }
    nonisolated public static var monthlyProductId: String { monthlyProductID }

    // UserDefaults Keys (for fast cache display while StoreKit verifies)
    private let hasCompletedFreeMockKey = "estonia_has_completed_free_mock_v1"
    private let freeQuestionIDsKey = "estonia_free_question_ids_v1"
    private let cachedPremiumKey = "estonia_driving_cached_is_premium"
    private let cachedPremiumTypeKey = "estonia_driving_cached_premium_type"

    // Published State (matching RuralKeep pattern)
    @Published public private(set) var isPremium: Bool = false
    @Published public private(set) var subscriptionType: SubscriptionType? = nil
    @Published public private(set) var products: [Product] = []
    @Published public private(set) var monthlyProduct: Product? = nil
    @Published public private(set) var lifetimeProduct: Product? = nil
    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var isLoadingProducts: Bool = false
    @Published public private(set) var hasLoadedProducts: Bool = false
    @Published public var errorMessage: String? = nil
    @Published public var storeError: String? = nil
    @Published public var restoreMessage: String? = nil

    @Published public private(set) var hasCompletedFreeMock: Bool = false
    @Published public private(set) var freeQuestionIDs: [String] = []

    private var transactionListenerTask: Task<Void, Never>?
    private var storefrontListenerTask: Task<Void, Never>?

    // MARK: - Localized Pricing Display

    /// Localized display price for lifetime full access (uses product.displayPrice from StoreKit).
    public var lifetimeDisplayPrice: String {
        if let product = lifetimeProduct {
            return product.displayPrice
        }
        return countryAwareFallbackPrice(amountINR: 999.0, amountEUR: 7.99, amountUSD: 7.99)
    }

    /// Localized display price for monthly subscription (uses product.displayPrice from StoreKit).
    public var monthlyDisplayPrice: String {
        if let product = monthlyProduct {
            return product.displayPrice
        }
        return countryAwareFallbackPrice(amountINR: 299.0, amountEUR: 4.99, amountUSD: 4.99)
    }

    /// Formats fallback price matching the user's active device region/locale.
    public func countryAwareFallbackPrice(amountINR: Double, amountEUR: Double, amountUSD: Double) -> String {
        let locale = Locale.current
        let region = (locale.region?.identifier ?? locale.identifier).uppercased()
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2

        if region.contains("IN") {
            formatter.currencyCode = "INR"
            return formatter.string(from: NSNumber(value: amountINR)) ?? "₹\(String(format: "%.2f", amountINR))"
        } else if region.contains("US") {
            formatter.currencyCode = "USD"
            return formatter.string(from: NSNumber(value: amountUSD)) ?? "$\(String(format: "%.2f", amountUSD))"
        } else {
            formatter.currencyCode = "EUR"
            return formatter.string(from: NSNumber(value: amountEUR)) ?? "€\(String(format: "%.2f", amountEUR))"
        }
    }

    // MARK: - Initialization

    private init() {
        // Step 1: Immediately read cached Pro status for UI continuity when offline
        self.isPremium = UserDefaults.standard.bool(forKey: cachedPremiumKey)
        if let typeStr = UserDefaults.standard.string(forKey: cachedPremiumTypeKey),
           let type = SubscriptionType(rawValue: typeStr) {
            self.subscriptionType = type
        }

        self.hasCompletedFreeMock = UserDefaults.standard.bool(forKey: hasCompletedFreeMockKey)

        if let storedIDs = UserDefaults.standard.stringArray(forKey: freeQuestionIDsKey), !storedIDs.isEmpty {
            self.freeQuestionIDs = storedIDs
        } else {
            initializeFreeQuestionPool()
        }

        // Step 2: Start background transaction updates & storefront listeners
        startTransactionListener()
        startStorefrontListener()

        // Step 3: Load StoreKit products and refresh verified entitlements
        Task {
            await self.loadProducts()
            await self.refreshEntitlements()
        }
    }

    deinit {
        transactionListenerTask?.cancel()
        storefrontListenerTask?.cancel()
    }

    // MARK: - Transaction & Storefront Listeners (RuralKeep pattern)

    private func startTransactionListener() {
        transactionListenerTask = Task.detached { [weak self] in
            for await result in StoreKit.Transaction.updates {
                await self?.handleTransactionResult(result)
            }
        }
    }

    private func startStorefrontListener() {
        storefrontListenerTask = Task.detached { [weak self] in
            for await updatedStorefront in Storefront.updates {
                #if DEBUG
                print("[StoreKit] Storefront updated to country code: \(updatedStorefront.countryCode)")
                #endif
                await self?.loadProducts()
            }
        }
    }

    private func handleTransactionResult(_ result: VerificationResult<StoreKit.Transaction>) async {
        switch result {
        case .verified(let transaction):
            let isActive = (transaction.revocationDate == nil)
            if isActive {
                if transaction.productID == Self.lifetimeProductID {
                    setPremiumState(unlocked: true, type: .lifetime)
                } else if transaction.productID == Self.monthlyProductID {
                    setPremiumState(unlocked: true, type: .monthly)
                }
            } else {
                // Transaction was revoked
                await refreshEntitlements()
            }
            await transaction.finish()
        case .unverified(_, let error):
            #if DEBUG
            print("[StoreKit] Unverified transaction: \(error.localizedDescription)")
            #endif
        }
    }

    public nonisolated func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified(_, let error):
            #if DEBUG
            print("[StoreKit] Verification failed: \(error.localizedDescription)")
            #endif
            throw StoreError.failedVerification
        }
    }

    // MARK: - Loading Products (RuralKeep pattern)

    public func loadProducts() async {
        #if DEBUG
        print("[StoreKit] Requested product IDs: \(Self.lifetimeProductID), \(Self.monthlyProductID)")
        #endif

        isLoading = true
        isLoadingProducts = true
        defer {
            isLoading = false
            isLoadingProducts = false
            hasLoadedProducts = true
        }

        do {
            let fetched = try await Product.products(for: [Self.lifetimeProductID, Self.monthlyProductID])
            self.products = fetched
            self.lifetimeProduct = fetched.first { $0.id == Self.lifetimeProductID }
            self.monthlyProduct = fetched.first { $0.id == Self.monthlyProductID }

            #if DEBUG
            print("[StoreKit] Products returned: \(fetched.count)")
            for p in fetched {
                print("  • [StoreKit] Product: \(p.id) | Title: '\(p.displayName)' | Price: \(p.displayPrice)")
            }
            if let storefront = await Storefront.current {
                print("[StoreKit] Storefront: \(storefront.countryCode)")
            }
            #endif
            self.storeError = nil
            self.errorMessage = nil
        } catch {
            #if DEBUG
            print("[StoreKit] ERROR loading products: \(error.localizedDescription)")
            #endif
            self.storeError = nil
            self.errorMessage = nil
        }
    }

    // MARK: - Entitlement Verification (RuralKeep pattern)

    public func refreshEntitlements() async {
        await checkVerifiedEntitlements()
    }

    public func checkVerifiedEntitlements() async {
        var foundLifetime = false
        var foundMonthly = false

        #if DEBUG
        print("[StoreKit] Checking Transaction.currentEntitlements...")
        #endif

        for await result in StoreKit.Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                guard transaction.revocationDate == nil else {
                    #if DEBUG
                    print("[StoreKit] Revoked transaction skipped: \(transaction.productID)")
                    #endif
                    continue
                }

                if transaction.productID == Self.lifetimeProductID {
                    foundLifetime = true
                    await transaction.finish()
                    #if DEBUG
                    print("[StoreKit] Verified Lifetime entitlement active.")
                    #endif
                } else if transaction.productID == Self.monthlyProductID {
                    if let exp = transaction.expirationDate {
                        if exp > Date() {
                            foundMonthly = true
                            await transaction.finish()
                            #if DEBUG
                            print("[StoreKit] Verified Monthly entitlement active until \(exp).")
                            #endif
                        } else {
                            #if DEBUG
                            print("[StoreKit] Monthly subscription expired on \(exp).")
                            #endif
                        }
                    } else {
                        foundMonthly = true
                        await transaction.finish()
                        #if DEBUG
                        print("[StoreKit] Verified Monthly entitlement active (no expiry).")
                        #endif
                    }
                }
            case .unverified(_, let error):
                #if DEBUG
                print("[StoreKit] Unverified entitlement: \(error.localizedDescription)")
                #endif
            }
        }

        let newPremium = foundLifetime || foundMonthly
        let newType: SubscriptionType? = foundLifetime ? .lifetime : (foundMonthly ? .monthly : nil)
        setPremiumState(unlocked: newPremium, type: newType)
    }

    public func setPremiumState(unlocked: Bool, type: SubscriptionType?) {
        self.isPremium = unlocked
        self.subscriptionType = type
        if unlocked {
            self.storeError = nil
            self.errorMessage = nil
        }
        UserDefaults.standard.set(unlocked, forKey: cachedPremiumKey)
        if let type = type {
            UserDefaults.standard.set(type.rawValue, forKey: cachedPremiumTypeKey)
        } else {
            UserDefaults.standard.removeObject(forKey: cachedPremiumTypeKey)
        }
    }

    // MARK: - Purchase Flow (RuralKeep pattern)

    @discardableResult
    public func purchase(_ product: Product) async -> Bool {
        if isPremium && (subscriptionType == .lifetime || product.id == Self.monthlyProductID) {
            #if DEBUG
            print("[StoreKit] Already unlocked. Skipping purchase.")
            #endif
            return true
        }

        isLoading = true
        storeError = nil
        errorMessage = nil
        defer { isLoading = false }

        do {
            let purchaseResult = try await product.purchase()

            switch purchaseResult {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    if transaction.productID == Self.lifetimeProductID {
                        setPremiumState(unlocked: true, type: .lifetime)
                        await transaction.finish()
                        await refreshEntitlements()
                        return true
                    } else if transaction.productID == Self.monthlyProductID {
                        setPremiumState(unlocked: true, type: .monthly)
                        await transaction.finish()
                        await refreshEntitlements()
                        return true
                    } else {
                        storeError = "Unexpected product returned. Please try again."
                        errorMessage = storeError
                        return false
                    }
                case .unverified(_, let error):
                    storeError = "Purchase could not be verified by Apple: \(error.localizedDescription)"
                    errorMessage = storeError
                    return false
                }

            case .userCancelled:
                #if DEBUG
                print("[StoreKit] Purchase cancelled by user.")
                #endif
                storeError = nil
                errorMessage = nil
                return false

            case .pending:
                #if DEBUG
                print("[StoreKit] Purchase pending approval (Ask to Buy).")
                #endif
                storeError = "Your purchase is pending approval. Features will unlock once approved."
                errorMessage = storeError
                return false

            @unknown default:
                storeError = "An unexpected purchase state occurred. Please try again."
                errorMessage = storeError
                return false
            }
        } catch {
            #if DEBUG
            print("[StoreKit] Purchase failed: \(error.localizedDescription)")
            #endif
            storeError = "Purchase could not be completed. Please try again."
            errorMessage = storeError
            return false
        }
    }

    @discardableResult
    public func purchaseLifetime() async -> Bool {
        if let product = lifetimeProduct ?? products.first(where: { $0.id == Self.lifetimeProductID }) {
            return await purchase(product)
        }
        await loadProducts()
        if let product = lifetimeProduct ?? products.first(where: { $0.id == Self.lifetimeProductID }) {
            return await purchase(product)
        }
        storeError = "Purchases are temporarily unavailable. Please try again later."
        errorMessage = storeError
        return false
    }

    @discardableResult
    public func purchaseMonthly() async -> Bool {
        if let product = monthlyProduct ?? products.first(where: { $0.id == Self.monthlyProductID }) {
            return await purchase(product)
        }
        await loadProducts()
        if let product = monthlyProduct ?? products.first(where: { $0.id == Self.monthlyProductID }) {
            return await purchase(product)
        }
        storeError = "Purchases are temporarily unavailable. Please try again later."
        errorMessage = storeError
        return false
    }

    // MARK: - Restore Purchases (RuralKeep pattern)

    @discardableResult
    public func restorePurchases() async -> Bool {
        isLoading = true
        storeError = nil
        errorMessage = nil
        restoreMessage = nil
        defer { isLoading = false }

        do {
            try await AppStore.sync()
            await refreshEntitlements()

            if isPremium {
                restoreMessage = "Purchases successfully restored."
                return true
            } else {
                restoreMessage = "No previous purchase found."
                return false
            }
        } catch {
            #if DEBUG
            print("[StoreKit] Restore failed: \(error.localizedDescription)")
            #endif
            restoreMessage = "Unable to restore purchases at this time. Please check your network connection."
            return false
        }
    }

    // MARK: - Free Question Pool Management

    private func initializeFreeQuestionPool() {
        let allQuestions = QuestionRepository.shared.questions
        guard !allQuestions.isEmpty else {
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 200_000_000)
                if self.freeQuestionIDs.isEmpty {
                    self.initializeFreeQuestionPool()
                }
            }
            return
        }

        // Generate a balanced 40-question Category B exam set
        let freeExamSet = QuestionRepository.shared.randomExamQuestions(config: .estonianCategoryB)
        let ids = freeExamSet.map { $0.id }
        self.freeQuestionIDs = ids
        UserDefaults.standard.set(ids, forKey: freeQuestionIDsKey)
        #if DEBUG
        print("[PremiumAccessManager] Initialized 40 free question IDs pool.")
        #endif
    }

    public func markFreeMockCompleted() {
        self.hasCompletedFreeMock = true
        UserDefaults.standard.set(true, forKey: hasCompletedFreeMockKey)
    }

    public func setHasCompletedFreeMockForTesting(_ completed: Bool) {
        self.hasCompletedFreeMock = completed
        UserDefaults.standard.set(completed, forKey: hasCompletedFreeMockKey)
    }

    // MARK: - Central Feature Gating

    public func canAccess(feature: PremiumFeature) -> Bool {
        if isPremium { return true }

        switch feature {
        case .unlimitedMockExams:
            return !hasCompletedFreeMock
        case .fullPractice,
             .roadSignFlashcards,
             .roadSignTest,
             .fullMistakes,
             .weakTopicPractice,
             .advancedProgress:
            return false
        }
    }

    // Accessible Questions (40 free questions or full 503 bank)
    public func accessibleQuestions() -> [Question] {
        if isPremium {
            return QuestionRepository.shared.questions
        }
        let pool = Set(freeQuestionIDs)
        return QuestionRepository.shared.questions.filter { pool.contains($0.id) }
    }

    public func accessibleQuestions(for topic: TopicCategory) -> [Question] {
        if isPremium {
            return QuestionRepository.shared.questions(for: topic)
        }
        let pool = Set(freeQuestionIDs)
        return QuestionRepository.shared.questions(for: topic).filter { pool.contains($0.id) }
    }

    public func hasAccessibleQuestions(for topic: TopicCategory) -> Bool {
        return !accessibleQuestions(for: topic).isEmpty
    }

    public func freeQuestionsCount(for topic: TopicCategory) -> Int {
        let pool = Set(freeQuestionIDs)
        return QuestionRepository.shared.questions(for: topic).filter { pool.contains($0.id) }.count
    }

    public func totalFullQuestionsCount(for topic: TopicCategory) -> Int {
        return QuestionRepository.shared.questions(for: topic).count
    }

    public func freeMockQuestions() -> [Question] {
        let pool = Set(freeQuestionIDs)
        let matched = QuestionRepository.shared.questions.filter { pool.contains($0.id) }
        if matched.count == 40 {
            return matched
        }
        return QuestionRepository.shared.randomExamQuestions(config: .estonianCategoryB)
    }
}
