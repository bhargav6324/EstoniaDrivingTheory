import SwiftUI

public struct PracticeView: View {
    @ObservedObject private var progressStore = ProgressStore.shared
    @ObservedObject private var localization = LocalizationManager.shared
    @ObservedObject private var premium = PremiumAccessManager.shared
    @State private var showPaywall = false

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Header Subtitle
                    Text(localization.t(.practiceCategories))
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                        .padding(.horizontal, 20)

                    // Topics List
                    VStack(spacing: 12) {
                        ForEach(TopicCategory.allCases) { topic in
                            let isUnlocked = premium.isPremium
                            let fullTotal = QuestionRepository.shared.questions(for: topic).count
                            let freeCount = premium.freeQuestionsCount(for: topic)
                            let accessibleCount = isUnlocked ? fullTotal : freeCount

                            let stats = progressStore.topicStats(for: topic)
                            let progressFraction = accessibleCount > 0 ? Double(min(stats.attempted, accessibleCount)) / Double(accessibleCount) : 0.0

                            if !isUnlocked && freeCount == 0 {
                                // Locked topic: tapping opens the paywall
                                Button {
                                    showPaywall = true
                                } label: {
                                    topicCardContent(
                                        topic: topic,
                                        accessibleCount: 0,
                                        fullTotal: fullTotal,
                                        stats: stats,
                                        progressFraction: 0,
                                        isLocked: true
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            } else {
                                NavigationLink(value: topic) {
                                    topicCardContent(
                                        topic: topic,
                                        accessibleCount: accessibleCount,
                                        fullTotal: fullTotal,
                                        stats: stats,
                                        progressFraction: progressFraction,
                                        isLocked: false
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 10)
                .padding(.bottom, 24)
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle(localization.t(.tabPractice))
            .navigationDestination(for: TopicCategory.self) { topic in
                TopicDetailView(topic: topic)
            }
            .sheet(isPresented: $showPaywall) {
                PremiumPaywallView()
            }
        }
    }

    private func topicCardContent(
        topic: TopicCategory,
        accessibleCount: Int,
        fullTotal: Int,
        stats: (total: Int, attempted: Int, mastered: Int, accuracy: Int, mistakes: Int),
        progressFraction: Double,
        isLocked: Bool
    ) -> some View {
        HStack(spacing: 14) {
            // Topic Icon
            TopicIconView(topic: topic, size: 20, color: isLocked ? AppColors.textTertiary : AppColors.estoniaBlue)
                .frame(width: 44, height: 44)
                .background(isLocked ? AppColors.cardBorder.opacity(0.3) : AppColors.estoniaBlue.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            // Topic Content
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(topic.title(for: localization.currentLanguage))
                        .font(.headline)
                        .foregroundColor(isLocked ? AppColors.textSecondary : AppColors.textPrimary)
                        .multilineTextAlignment(.leading)
                    Spacer()

                    if isLocked {
                        HStack(spacing: 4) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 10))
                            Text(localization.t(.premiumLockedTopic))
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(AppColors.warningAmber)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(AppColors.warningAmber.opacity(0.15))
                        .clipShape(Capsule())
                    } else if stats.mistakes > 0 {
                        Text("\(stats.mistakes)")
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppColors.errorRed)
                            .clipShape(Capsule())
                    }
                }

                // Progress Bar & Meta
                ProgressBarView(progress: progressFraction, height: 5)

                HStack {
                    if premium.isPremium {
                        Text("\(accessibleCount) questions")
                            .font(.caption2)
                            .foregroundColor(AppColors.textSecondary)
                    } else if isLocked {
                        Text("0 free questions • \(fullTotal) in Premium")
                            .font(.caption2)
                            .foregroundColor(AppColors.textTertiary)
                    } else {
                        HStack(spacing: 4) {
                            Text(localization.t(.freeQuestionsAvailable(accessibleCount)))
                                .font(.caption2.bold())
                                .foregroundColor(AppColors.estoniaBlue)
                            Text("• \(fullTotal) in Premium")
                                .font(.caption2)
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }

                    Spacer()

                    if stats.attempted > 0 && !isLocked {
                        Text("\(stats.accuracy)% accuracy")
                            .font(.caption2.bold())
                            .foregroundColor(stats.accuracy >= 75 ? AppColors.successGreen : AppColors.warningAmber)
                    } else if !premium.isPremium && !isLocked {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
            }

            Image(systemName: isLocked ? "lock.fill" : "chevron.right")
                .font(.caption.bold())
                .foregroundColor(isLocked ? AppColors.warningAmber : AppColors.textTertiary)
        }
        .appCard(padding: 14)
    }
}
