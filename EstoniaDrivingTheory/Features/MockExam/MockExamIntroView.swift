import SwiftUI

public struct MockExamIntroView: View {
    @ObservedObject private var localization = LocalizationManager.shared
    @ObservedObject private var premium = PremiumAccessManager.shared
    @Environment(\.presentationMode) private var presentationMode
    @State private var startExam = false
    @State private var showPaywall = false

    private let config = ExamConfiguration.estonianCategoryB

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Banner
                VStack(spacing: 8) {
                    Image(systemName: "doc.text.badge.checkmark")
                        .font(.system(size: 48))
                        .foregroundColor(AppColors.estoniaBlue)
                        .padding(.top, 16)

                    Text(localization.t(.mockExamRulesTitle))
                        .font(.system(.title2, design: .rounded).bold())
                        .foregroundColor(AppColors.textPrimary)

                    Text(localization.t(.officialCategoryBRules))
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                }

                // Free Exam Status Banner
                if !premium.isPremium {
                    if !premium.hasCompletedFreeMock {
                        HStack(spacing: 12) {
                            Image(systemName: "gift.fill")
                                .font(.title2)
                                .foregroundColor(AppColors.successGreen)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(localization.t(.oneFreeMockBadge))
                                    .font(.system(.subheadline, design: .rounded).bold())
                                    .foregroundColor(AppColors.textPrimary)

                                Text("40 official-format questions. These 40 questions will also become your free practice set.")
                                    .font(.caption)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            Spacer()
                        }
                        .padding(14)
                        .background(AppColors.successGreen.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(AppColors.successGreen.opacity(0.3), lineWidth: 1)
                        )
                    } else {
                        // Free mock was already completed!
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                Image(systemName: "lock.shield.fill")
                                    .font(.title)
                                    .foregroundColor(AppColors.warningAmber)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(localization.t(.mockExamCompletedTitle))
                                        .font(.system(.headline, design: .rounded).bold())
                                        .foregroundColor(AppColors.textPrimary)

                                    Text(localization.t(.mockExamCompletedDescription))
                                        .font(.caption)
                                        .foregroundColor(AppColors.textSecondary)
                                }
                            }

                            Button {
                                showPaywall = true
                            } label: {
                                HStack {
                                    Image(systemName: "crown.fill")
                                    Text(localization.t(.unlockUnlimitedMocks))
                                }
                                .font(.system(.subheadline, design: .rounded).bold())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(
                                    LinearGradient(
                                        colors: [AppColors.estoniaBlue, AppColors.estoniaBlueDark],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .padding(16)
                        .background(AppColors.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(AppColors.warningAmber.opacity(0.4), lineWidth: 1)
                        )
                    }
                }

                // Requirements Card
                VStack(alignment: .leading, spacing: 16) {
                    ruleRow(
                        icon: "clock.fill",
                        color: AppColors.estoniaBlue,
                        title: localization.t(.examDuration),
                        subtitle: "30:00 minutes countdown"
                    )

                    Divider()

                    ruleRow(
                        icon: "checkmark.seal.fill",
                        color: AppColors.successGreen,
                        title: localization.t(.passingRequirements),
                        subtitle: "35 / 40 correct required to pass"
                    )

                    Divider()

                    ruleRow(
                        icon: "exclamationmark.shield.fill",
                        color: AppColors.errorRed,
                        title: localization.t(.strictSafetyLimit),
                        subtitle: "Pedestrian, priority and overtaking questions"
                    )
                }
                .appCard(padding: 20)

                // Info Callout
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "info.circle")
                        .foregroundColor(AppColors.textSecondary)
                        .padding(.top, 2)
                    Text("During the mock exam, answers are not revealed until submission. You can flag questions to review them before finishing.")
                        .font(.footnote)
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding(.horizontal, 4)

                Spacer(minLength: 24)

                // Start or Unlock Button
                if premium.isPremium || !premium.hasCompletedFreeMock {
                    Button {
                        startExam = true
                    } label: {
                        Text(!premium.isPremium ? localization.t(.startFreeMock) : localization.t(.startExam))
                            .primaryButton()
                    }
                    .fullScreenCover(isPresented: $startExam) {
                        MockExamActiveView()
                    }
                } else {
                    Button {
                        showPaywall = true
                    } label: {
                        HStack {
                            Image(systemName: "crown.fill")
                            Text(localization.t(.unlockUnlimitedMocks))
                        }
                        .primaryButton()
                    }
                }
            }
            .padding(20)
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle(localization.t(.mockExamTitle))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) {
            PremiumPaywallView()
        }
    }

    private func ruleRow(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }
}
