import SwiftUI
import StoreKit

public struct PremiumPaywallView: View {
    @ObservedObject private var premium = PremiumAccessManager.shared
    @ObservedObject private var localization = LocalizationManager.shared
    @Environment(\.presentationMode) private var presentationMode

    @State private var selectedTier: SubscriptionType = .lifetime
    @State private var showPrivacySheet = false
    @State private var showTermsSheet = false
    @State private var restoreMessage: String? = nil
    @State private var showRestoreAlert = false
    @State private var purchaseErrorMessage: String? = nil
    @State private var showPurchaseErrorAlert = false
    @State private var isProcessingPurchase = false

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    // 1. App Logo & Brand Header (No crown emoji)
                    headerSection

                    // 2. Official Benefits List (9 Category B benefits, no "official" wording)
                    benefitsSection

                    // 3. StoreKit 2 Pricing Cards (Lifetime vs Monthly)
                    pricingCardsSection

                    // 4. Main Purchase Action Button & Restore Purchases
                    actionButtonsSection

                    // 5. Subscription Disclosure & Legal Links
                    footerDisclosures
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(AppColors.textTertiary)
                    }
                    .accessibilityLabel(localization.t(.cancel))
                }
            }
            .sheet(isPresented: $showPrivacySheet) {
                privacySheet
            }
            .sheet(isPresented: $showTermsSheet) {
                termsSheet
            }
            .alert(isPresented: $showRestoreAlert) {
                Alert(
                    title: Text(localization.t(.restorePurchases)),
                    message: Text(restoreMessage ?? ""),
                    dismissButton: .default(Text(localization.t(.done))) {
                        if premium.isPremium {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                )
            }
            .alert("Purchase Notice", isPresented: $showPurchaseErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(purchaseErrorMessage ?? localization.t(.purchasesUnavailable))
            }
            .task {
                await premium.loadProducts()
                // Default to lifetime if available, else monthly
                if lifetimeProduct == nil && monthlyProduct != nil {
                    selectedTier = .monthly
                }
            }
            .onChange(of: premium.isPremium) { newStatus in
                if newStatus {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }

    // MARK: - 1. App Logo & Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            // Real Estonia Driving Theory App Icon
            AppLogoView(size: 76)
                .padding(.top, 4)

            Text(localization.t(.unlockFullAccess))
                .font(.system(.title2, design: .rounded).bold())
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.center)

            Text(localization.t(.unlockFullAccessSubtitle))
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)
        }
    }

    // MARK: - 2. Benefits Checklist (9 App-Specific Benefits)
    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            benefitRow(icon: "checkmark.seal.fill", text: localization.t(.benefit500Questions))
            benefitRow(icon: "checkmark.seal.fill", text: localization.t(.benefitUnlimitedMocks))
            benefitRow(icon: "checkmark.seal.fill", text: localization.t(.benefitFullPractice))
            benefitRow(icon: "checkmark.seal.fill", text: localization.t(.benefitRoadSignFlashcards))
            benefitRow(icon: "checkmark.seal.fill", text: localization.t(.benefitRoadSignTests))
            benefitRow(icon: "checkmark.seal.fill", text: localization.t(.benefitPracticeMistakes))
            benefitRow(icon: "checkmark.seal.fill", text: localization.t(.benefitWeakTopics))
            benefitRow(icon: "checkmark.seal.fill", text: localization.t(.benefitProgressReadiness))
            benefitRow(icon: "checkmark.seal.fill", text: localization.t(.benefitDailyGoals))
        }
        .appCard(padding: 18)
    }

    private func benefitRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(AppColors.successGreen)
                .padding(.top, 2)
            Text(text)
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(AppColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
    }

    // MARK: - 3. StoreKit Pricing Cards
    private var pricingCardsSection: some View {
        VStack(spacing: 12) {
            if premium.isLoadingProducts && premium.products.isEmpty {
                // Clean loading state
                HStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.estoniaBlue))
                    Text(localization.t(.loadingPurchases))
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .appCard(padding: 16)
            } else if premium.products.isEmpty && !premium.isLoadingProducts {
                // Clean user-facing temporary unavailability message (NO debug info)
                VStack(spacing: 8) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 24))
                        .foregroundColor(AppColors.textSecondary)
                    Text(localization.t(.purchasesUnavailable))
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                    Button {
                        Task { await premium.loadProducts() }
                    } label: {
                        Text(localization.t(.retryLoading))
                            .font(.caption.bold())
                            .foregroundColor(AppColors.estoniaBlue)
                    }
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .appCard(padding: 16)
            } else {
                // 1. Lifetime Card (Highlighted with BEST VALUE badge)
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTier = .lifetime
                    }
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: selectedTier == .lifetime ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundColor(selectedTier == .lifetime ? AppColors.estoniaBlue : AppColors.textTertiary)

                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 8) {
                                Text(localization.t(.lifetimePremiumTitle))
                                    .font(.system(.headline, design: .rounded).bold())
                                    .foregroundColor(AppColors.textPrimary)

                                Text(localization.t(.bestValueBadge))
                                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 3)
                                    .background(
                                        LinearGradient(
                                            colors: [AppColors.warningAmber, Color.orange],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .clipShape(Capsule())
                            }

                            Text(localization.t(.lifetimeSubtext))
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(lifetimePriceDisplay)
                                .font(.system(.title3, design: .rounded).bold())
                                .foregroundColor(AppColors.textPrimary)

                            Text(localization.t(.oneTimePayment))
                                .font(.caption2)
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                    .padding(16)
                    .background(AppColors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(
                                selectedTier == .lifetime ? AppColors.estoniaBlue : AppColors.cardBorder,
                                lineWidth: selectedTier == .lifetime ? 2 : 1
                            )
                    )
                    .shadow(
                        color: selectedTier == .lifetime ? AppColors.estoniaBlue.opacity(0.18) : Color.clear,
                        radius: 8,
                        x: 0,
                        y: 4
                    )
                }
                .buttonStyle(PlainButtonStyle())

                // 2. Monthly Card
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTier = .monthly
                    }
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: selectedTier == .monthly ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundColor(selectedTier == .monthly ? AppColors.estoniaBlue : AppColors.textTertiary)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(localization.t(.monthlyPremiumTitle))
                                .font(.system(.headline, design: .rounded).bold())
                                .foregroundColor(AppColors.textPrimary)

                            Text(localization.t(.billedMonthly))
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(monthlyPriceDisplay)
                                .font(.system(.title3, design: .rounded).bold())
                                .foregroundColor(AppColors.textPrimary)

                            Text(localization.t(.perMonth))
                                .font(.caption2)
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                    .padding(16)
                    .background(AppColors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(
                                selectedTier == .monthly ? AppColors.estoniaBlue : AppColors.cardBorder,
                                lineWidth: selectedTier == .monthly ? 2 : 1
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    // Exact Product Matching by product.id (StoreKit 2)
    private var lifetimeProduct: Product? {
        premium.products.first { $0.id == PremiumAccessManager.lifetimeProductID } ?? premium.lifetimeProduct
    }

    private var monthlyProduct: Product? {
        premium.products.first { $0.id == PremiumAccessManager.monthlyProductID } ?? premium.monthlyProduct
    }

    private var selectedProduct: Product? {
        selectedTier == .lifetime ? lifetimeProduct : monthlyProduct
    }

    private var lifetimePriceDisplay: String {
        if let product = lifetimeProduct {
            return product.displayPrice
        }
        return premium.lifetimeDisplayPrice
    }

    private var monthlyPriceDisplay: String {
        if let product = monthlyProduct {
            return product.displayPrice
        }
        return premium.monthlyDisplayPrice
    }

    // MARK: - 4. Action Buttons
    private var actionButtonsSection: some View {
        VStack(spacing: 14) {
            Button {
                guard !isProcessingPurchase && !premium.isLoading else { return }
                isProcessingPurchase = true
                Task {
                    defer { isProcessingPurchase = false }
                    guard let product = selectedProduct else {
                        #if DEBUG
                        print("❌ [PAYWALL] Selected product was nil during purchase tap.")
                        #endif
                        purchaseErrorMessage = localization.t(.purchasesUnavailable)
                        showPurchaseErrorAlert = true
                        return
                    }

                    let success = await premium.purchase(product)
                    if success || premium.isPremium {
                        presentationMode.wrappedValue.dismiss()
                    } else if let error = premium.storeError, !premium.isPremium {
                        #if DEBUG
                        print("❌ [PAYWALL] Purchase failed with error: \(error)")
                        #endif
                        purchaseErrorMessage = error
                        showPurchaseErrorAlert = true
                    }
                }
            } label: {
                if isProcessingPurchase || premium.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(AppColors.estoniaBlue)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                } else {
                    let buttonTitle = selectedTier == .lifetime
                        ? localization.t(.unlockButtonLifetime)
                        : localization.t(.unlockButtonMonthly)
                    Text(buttonTitle)
                        .primaryButton()
                }
            }
            .disabled(selectedProduct == nil || isProcessingPurchase || premium.isLoading)

            // Restore Purchases Action
            Button {
                Task {
                    let restored = await premium.restorePurchases()
                    if restored {
                        restoreMessage = "Your Premium access has been restored successfully!"
                    } else {
                        restoreMessage = "No previous purchases were found for this Apple ID."
                    }
                    showRestoreAlert = true
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                    Text(localization.t(.restorePurchases))
                }
                .font(.system(.subheadline, design: .rounded).bold())
                .foregroundColor(AppColors.estoniaBlue)
            }
            .disabled(premium.isLoading)
        }
        .padding(.top, 4)
    }

    // MARK: - 5. Footer & Legal
    private var footerDisclosures: some View {
        VStack(spacing: 10) {
            if selectedTier == .monthly {
                Text(localization.t(.subscriptionDisclosure))
                    .font(.system(size: 11))
                    .foregroundColor(AppColors.textTertiary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .padding(.horizontal, 10)
            }

            HStack(spacing: 16) {
                Button(localization.t(.termsOfService)) {
                    showTermsSheet = true
                }
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)

                Text("•")
                    .font(.caption)
                    .foregroundColor(AppColors.textTertiary)

                Button(localization.t(.privacyPolicy)) {
                    showPrivacySheet = true
                }
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
            }
            .padding(.top, 2)
        }
        .padding(.top, 6)
    }

    private var privacySheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(localization.t(.privacyPolicy))
                        .font(.title2.bold())
                        .foregroundColor(AppColors.textPrimary)
                    Text("This application stores all your study data locally on your device. Purchases are handled directly through Apple's StoreKit 2 platform and tied to your Apple ID. We do not maintain any user accounts or external servers.")
                        .font(.body)
                        .foregroundColor(AppColors.textSecondary)
                        .lineSpacing(4)
                }
                .padding(24)
            }
            .background(AppColors.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localization.t(.done)) { showPrivacySheet = false }
                }
            }
        }
    }

    private var termsSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(localization.t(.termsOfService))
                        .font(.title2.bold())
                        .foregroundColor(AppColors.textPrimary)
                    Text("All practice questions and tests are independent educational study materials created for Estonian Category B theory preparation. Payments are processed securely via Apple ID. Auto-renewable monthly subscriptions can be managed and cancelled in your App Store Account Settings.")
                        .font(.body)
                        .foregroundColor(AppColors.textSecondary)
                        .lineSpacing(4)
                }
                .padding(24)
            }
            .background(AppColors.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localization.t(.done)) { showTermsSheet = false }
                }
            }
        }
    }
}
