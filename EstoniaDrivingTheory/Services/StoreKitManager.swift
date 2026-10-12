import Foundation
import StoreKit

/// Facade for backwards compatibility with any components expecting StoreKitManager.
/// All monetization, StoreKit 2 loading, and entitlement verification is powered by PremiumAccessManager.
@MainActor
public final class StoreKitManager: ObservableObject {
    public static let shared = StoreKitManager()

    private var manager: PremiumAccessManager {
        PremiumAccessManager.shared
    }

    nonisolated public static var lifetimeProductID: String {
        PremiumAccessManager.lifetimeProductID
    }

    nonisolated public static var monthlyProductID: String {
        PremiumAccessManager.monthlyProductID
    }

    nonisolated public static var lifetimeProductId: String { lifetimeProductID }
    nonisolated public static var monthlyProductId: String { monthlyProductID }

    public var isPremiumUnlocked: Bool { manager.isPremium }
    public var product: Product? { manager.lifetimeProduct }
    public var monthlyProduct: Product? { manager.monthlyProduct }
    public var lifetimeProduct: Product? { manager.lifetimeProduct }
    public var products: [Product] { manager.products }
    public var isLoading: Bool { manager.isLoading }
    public var isLoadingProducts: Bool { manager.isLoadingProducts }
    public var errorMessage: String? { manager.errorMessage }
    public var storeError: String? { manager.storeError }
    public var restoreMessage: String? { manager.restoreMessage }
    public var hasLoadedProducts: Bool { manager.hasLoadedProducts }

    public init() {}

    public func loadProducts() async {
        await manager.loadProducts()
    }

    public func purchase(_ product: Product) async -> Bool {
        await manager.purchase(product)
    }

    public func purchase() async -> Bool {
        if let lifetime = manager.lifetimeProduct {
            return await manager.purchase(lifetime)
        } else if let monthly = manager.monthlyProduct {
            return await manager.purchase(monthly)
        }
        return false
    }

    public func restorePurchases() async {
        _ = await manager.restorePurchases()
    }

    public func refreshEntitlements() async {
        await manager.refreshEntitlements()
    }

    public func checkVerifiedEntitlements() async {
        await manager.checkVerifiedEntitlements()
    }

    public func setPremiumUnlocked(_ unlocked: Bool) {
        manager.setPremiumState(unlocked: unlocked, type: unlocked ? .lifetime : nil)
    }

    public var lifetimeDisplayPrice: String {
        manager.lifetimeDisplayPrice
    }

    public var monthlyDisplayPrice: String {
        manager.monthlyDisplayPrice
    }
}
