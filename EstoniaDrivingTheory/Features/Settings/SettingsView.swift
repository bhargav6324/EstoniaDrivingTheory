import SwiftUI

public struct SettingsView: View {
    @ObservedObject private var localization = LocalizationManager.shared
    @ObservedObject private var premium = PremiumAccessManager.shared
    @ObservedObject private var progressStore = ProgressStore.shared
    @ObservedObject private var goalManager = DailyGoalManager.shared
    @Environment(\.openURL) private var openURL

    @State private var showLanguagePicker = false
    @State private var showPaywall = false
    @State private var showDailyGoalPicker = false
    @State private var showResetConfirm = false
    @State private var showDisclaimerSheet = false
    @State private var isRestoring = false
    @State private var showRestoreAlert = false
    @State private var restoreAlertMessage = ""

    public init() {}

    private var appVersionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (Build \(build))"
    }

    private var reminderDateBinding: Binding<Date> {
        Binding(
            get: {
                var components = DateComponents()
                components.hour = goalManager.goal.reminderHour
                components.minute = goalManager.goal.reminderMinute
                return Calendar.current.date(from: components) ?? Date()
            },
            set: { newDate in
                let calendar = Calendar.current
                let hour = calendar.component(.hour, from: newDate)
                let minute = calendar.component(.minute, from: newDate)
                goalManager.updateReminderTime(hour: hour, minute: minute)
            }
        )
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 1. Premium Section
                    premiumSection

                    // 2. Study Preferences Section
                    studyPreferencesSection

                    // 3. Progress Section
                    progressSection

                    // 4. About Section
                    aboutSection

                    // 5. Legal Section
                    legalSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 60)
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle(localization.t(.tabSettings))
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showLanguagePicker) {
                LanguagePickerSheet(isDismissable: true) {
                    showLanguagePicker = false
                }
            }
            .sheet(isPresented: $showPaywall) {
                PremiumPaywallView()
            }
            .sheet(isPresented: $showDailyGoalPicker) {
                dailyGoalPickerSheet
            }
            .sheet(isPresented: $showDisclaimerSheet) {
                disclaimerSheet
            }
            .alert(isPresented: $showResetConfirm) {
                Alert(
                    title: Text(localization.t(.resetProgressTitle)),
                    message: Text(localization.t(.resetProgressMessage)),
                    primaryButton: .destructive(Text("Reset")) {
                        progressStore.resetAllProgress()
                    },
                    secondaryButton: .cancel(Text(localization.t(.cancel)))
                )
            }
            .alert(isPresented: $showRestoreAlert) {
                Alert(
                    title: Text(localization.t(.restorePurchases)),
                    message: Text(restoreAlertMessage),
                    dismissButton: .default(Text(localization.t(.done)))
                )
            }
        }
    }

    // MARK: - 1. Premium Section
    private var premiumSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(localization.t(.sectionPremium))
                .font(.subheadline.weight(.semibold))
                .foregroundColor(AppColors.textSecondary)
                .padding(.leading, 4)

            VStack(alignment: .leading, spacing: 14) {
                // Header Row
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppColors.estoniaBlue)

                    Text(localization.t(.proCardTitle))
                        .font(.system(.headline, design: .rounded).bold())
                        .foregroundColor(AppColors.textPrimary)

                    Spacer()

                    if premium.isPremium {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption.bold())
                                .foregroundColor(AppColors.successGreen)
                            Text(localization.t(.premiumActive))
                                .font(.caption.bold())
                                .foregroundColor(AppColors.successGreen)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppColors.successGreen.opacity(0.12))
                        .clipShape(Capsule())
                    } else {
                        Text(localization.t(.freePlan))
                            .font(.caption.bold())
                            .foregroundColor(AppColors.textSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppColors.background)
                            .clipShape(Capsule())
                    }
                }

                if !premium.isPremium {
                    Text(localization.t(.freePlanDescription))
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                        .lineSpacing(2)
                } else {
                    Text(premium.subscriptionType == .monthly ? localization.t(.monthlyPremium) : localization.t(.lifetimeAccess))
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                }

                Divider()

                // Row: Upgrade to Pro (or Manage if already premium)
                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        Text(premium.isPremium ? localization.t(.viewPremiumButton) : localization.t(.upgradeToPro))
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(AppColors.estoniaBlue)

                        Spacer()

                        if !premium.isPremium {
                            HStack(spacing: 6) {
                                Text(premium.lifetimeDisplayPrice)
                                    .font(.subheadline)
                                    .foregroundColor(AppColors.textSecondary)

                                Image(systemName: "chevron.right")
                                    .font(.caption.bold())
                                    .foregroundColor(AppColors.textTertiary)
                            }
                        } else {
                            Image(systemName: "chevron.right")
                                .font(.caption.bold())
                                .foregroundColor(AppColors.textTertiary)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())

                Divider()

                // Row: Restore Purchases
                Button {
                    Task {
                        isRestoring = true
                        let restored = await premium.restorePurchases()
                        isRestoring = false
                        if restored {
                            restoreAlertMessage = "Purchases successfully restored!"
                        } else {
                            restoreAlertMessage = "No previous purchases found for this Apple ID."
                        }
                        showRestoreAlert = true
                    }
                } label: {
                    HStack(spacing: 8) {
                        if isRestoring {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.estoniaBlue))
                                .scaleEffect(0.8)
                        }
                        Text(localization.t(.restorePurchases))
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(AppColors.estoniaBlue)

                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(18)
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AppColors.cardBorder.opacity(0.8), lineWidth: 1)
            )
        }
    }

    // MARK: - 2. Study Preferences Section
    private var studyPreferencesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(localization.t(.studyPreferences))
                .font(.subheadline.weight(.semibold))
                .foregroundColor(AppColors.textSecondary)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                // Language Selection Row
                Button {
                    showLanguagePicker = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "globe")
                            .font(.system(size: 16))
                            .foregroundColor(AppColors.estoniaBlue)

                        Text(localization.t(.language))
                            .font(.subheadline)
                            .foregroundColor(AppColors.textPrimary)

                        Spacer()

                        Text("\(localization.currentLanguage.flag) \(localization.currentLanguage.displayName)")
                            .font(.subheadline)
                            .foregroundColor(AppColors.textSecondary)

                        Image(systemName: "chevron.right")
                            .font(.caption.bold())
                            .foregroundColor(AppColors.textTertiary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())

                Divider().padding(.horizontal, 16)

                // Daily Goal Row
                Button {
                    showDailyGoalPicker = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "target")
                            .font(.system(size: 16))
                            .foregroundColor(AppColors.estoniaBlue)

                        Text(localization.t(.dailyGoal))
                            .font(.subheadline)
                            .foregroundColor(AppColors.textPrimary)

                        Spacer()

                        Text("\(goalManager.goal.targetQuestions) questions / day")
                            .font(.subheadline)
                            .foregroundColor(AppColors.textSecondary)

                        Image(systemName: "chevron.right")
                            .font(.caption.bold())
                            .foregroundColor(AppColors.textTertiary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())

                Divider().padding(.horizontal, 16)

                // Study Reminder Toggle Row
                HStack(spacing: 12) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.estoniaBlue)

                    Text(localization.t(.studyReminder))
                        .font(.subheadline)
                        .foregroundColor(AppColors.textPrimary)

                    Spacer()

                    Toggle("", isOn: Binding(
                        get: { goalManager.goal.reminderEnabled },
                        set: { enabled in
                            goalManager.setReminderEnabled(enabled) { _ in }
                        }
                    ))
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: AppColors.estoniaBlue))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                // Reminder Time Picker Row (Only shown when enabled)
                if goalManager.goal.reminderEnabled {
                    Divider().padding(.horizontal, 16)

                    HStack(spacing: 12) {
                        Image(systemName: "clock")
                            .font(.system(size: 16))
                            .foregroundColor(AppColors.estoniaBlue)

                        Text(localization.t(.reminderTime))
                            .font(.subheadline)
                            .foregroundColor(AppColors.textPrimary)

                        Spacer()

                        DatePicker(
                            "",
                            selection: reminderDateBinding,
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AppColors.cardBorder.opacity(0.8), lineWidth: 1)
            )
        }
        .animation(.easeInOut(duration: 0.2), value: goalManager.goal.reminderEnabled)
    }

    // MARK: - 3. Progress Section
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(localization.t(.progress))
                .font(.subheadline.weight(.semibold))
                .foregroundColor(AppColors.textSecondary)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                Button {
                    showResetConfirm = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "trash")
                            .font(.system(size: 16))
                            .foregroundColor(AppColors.errorRed)

                        Text(localization.t(.resetProgress))
                            .font(.subheadline)
                            .foregroundColor(AppColors.errorRed)

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AppColors.cardBorder.opacity(0.8), lineWidth: 1)
            )
        }
    }

    // MARK: - 4. About Section
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(localization.t(.about))
                .font(.subheadline.weight(.semibold))
                .foregroundColor(AppColors.textSecondary)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                // App Name
                aboutInfoRow(title: localization.t(.appNameLabel), value: AppLinks.appName)
                Divider().padding(.horizontal, 16)

                // Subtitle
                aboutInfoRow(title: localization.t(.subtitleLabel), value: AppLinks.subtitle)
                Divider().padding(.horizontal, 16)

                // Version
                aboutInfoRow(title: localization.t(.versionLabel), value: appVersionString)
                Divider().padding(.horizontal, 16)

                // Support Email
                Button {
                    if let url = URL(string: AppLinks.supportEmailMailto) {
                        openURL(url)
                    }
                } label: {
                    HStack {
                        Text(localization.t(.supportLabel))
                            .font(.subheadline)
                            .foregroundColor(AppColors.textPrimary)

                        Spacer()

                        Text(AppLinks.supportEmail)
                            .font(.subheadline)
                            .foregroundColor(AppColors.estoniaBlue)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                Divider().padding(.horizontal, 16)

                // Support Website
                Button {
                    if let url = URL(string: AppLinks.supportURL) {
                        openURL(url)
                    }
                } label: {
                    HStack {
                        Text(localization.t(.supportWebsiteLabel))
                            .font(.subheadline)
                            .foregroundColor(AppColors.estoniaBlue)

                        Spacer()

                        Image(systemName: "arrow.up.right")
                            .font(.caption2.bold())
                            .foregroundColor(AppColors.estoniaBlue.opacity(0.7))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                Divider().padding(.horizontal, 16)

                // Privacy Policy
                Button {
                    if let url = URL(string: AppLinks.privacyURL) {
                        openURL(url)
                    }
                } label: {
                    HStack {
                        Text(localization.t(.privacyPolicyLabel))
                            .font(.subheadline)
                            .foregroundColor(AppColors.estoniaBlue)

                        Spacer()

                        Image(systemName: "arrow.up.right")
                            .font(.caption2.bold())
                            .foregroundColor(AppColors.estoniaBlue.opacity(0.7))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                Divider().padding(.horizontal, 16)

                // Terms of Use
                Button {
                    if let url = URL(string: AppLinks.termsURL) {
                        openURL(url)
                    }
                } label: {
                    HStack {
                        Text(localization.t(.termsOfUseLabel))
                            .font(.subheadline)
                            .foregroundColor(AppColors.estoniaBlue)

                        Spacer()

                        Image(systemName: "arrow.up.right")
                            .font(.caption2.bold())
                            .foregroundColor(AppColors.estoniaBlue.opacity(0.7))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AppColors.cardBorder.opacity(0.8), lineWidth: 1)
            )
        }
    }

    // MARK: - 5. Legal Section
    private var legalSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(localization.t(.legal))
                .font(.subheadline.weight(.semibold))
                .foregroundColor(AppColors.textSecondary)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                Button {
                    showDisclaimerSheet = true
                } label: {
                    HStack {
                        Text(localization.t(.disclaimerLabel))
                            .font(.subheadline)
                            .foregroundColor(AppColors.textPrimary)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption.bold())
                            .foregroundColor(AppColors.textTertiary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AppColors.cardBorder.opacity(0.8), lineWidth: 1)
            )
        }
    }

    private func aboutInfoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(AppColors.textPrimary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Sheets
    private var disclaimerSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .font(.title2)
                            .foregroundColor(AppColors.estoniaBlue)

                        Text(localization.t(.disclaimerLabel))
                            .font(.title2.bold())
                            .foregroundColor(AppColors.textPrimary)
                    }

                    Text(localization.t(.governmentDisclaimerText))
                        .font(.body)
                        .foregroundColor(AppColors.textSecondary)
                        .lineSpacing(4)
                }
                .padding(24)
            }
            .background(AppColors.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localization.t(.done)) {
                        showDisclaimerSheet = false
                    }
                }
            }
        }
    }

    private var dailyGoalPickerSheet: some View {
        NavigationStack {
            List {
                ForEach([5, 10, 20, 30, 40], id: \.self) { count in
                    Button {
                        goalManager.updateGoal(targetQuestions: count)
                        showDailyGoalPicker = false
                    } label: {
                        HStack {
                            Text("\(count) questions / day")
                                .foregroundColor(AppColors.textPrimary)
                            Spacer()
                            if goalManager.goal.targetQuestions == count {
                                Image(systemName: "checkmark")
                                    .foregroundColor(AppColors.estoniaBlue)
                                    .font(.headline)
                            }
                        }
                    }
                }
            }
            .navigationTitle(localization.t(.dailyGoal))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localization.t(.done)) {
                        showDailyGoalPicker = false
                    }
                }
            }
        }
    }
}
