import SwiftUI

/// A compact card that shows today's daily question goal progress.
/// Can be embedded in both HomeView and ProgressView.
struct DailyGoalCardView: View {
    @ObservedObject private var goalManager = DailyGoalManager.shared
    @ObservedObject private var localization = LocalizationManager.shared

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: goalManager.todayGoalReached ? "checkmark.circle.fill" : "target")
                    .foregroundColor(goalManager.todayGoalReached ? AppColors.successGreen : AppColors.estoniaBlue)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text(localization.t(.dailyGoalCardLabel))
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(AppColors.textPrimary)

                    if goalManager.todayGoalReached {
                        Text(localization.t(.dailyGoalCompleted))
                            .font(.caption)
                            .foregroundColor(AppColors.successGreen)
                    } else {
                        Text(localization.t(.dailyGoalProgress(
                            goalManager.todayQuestionsAnswered,
                            goalManager.goal.targetQuestions
                        )))
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                    }
                }

                Spacer()

                // Percentage label
                Text("\(Int(goalManager.todayProgressFraction * 100))%")
                    .font(.system(.subheadline, design: .rounded).bold())
                    .foregroundColor(goalManager.todayGoalReached ? AppColors.successGreen : AppColors.estoniaBlue)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(AppColors.cardBackgroundElevated)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(goalManager.todayGoalReached ? AppColors.successGreen : AppColors.estoniaBlue)
                        .frame(
                            width: max(0, geo.size.width * goalManager.todayProgressFraction),
                            height: 8
                        )
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: goalManager.todayProgressFraction)
                }
            }
            .frame(height: 8)
        }
    }
}

/// A compact trio of home-screen stats: readiness / daily goal / streak.
/// Intended for HomeView's exam readiness card expansion.
struct HomeProgressSummaryView: View {
    @ObservedObject private var progressStore = ProgressStore.shared
    @ObservedObject private var goalManager = DailyGoalManager.shared
    @ObservedObject private var localization = LocalizationManager.shared

    var body: some View {
        HStack(spacing: 0) {
            compactStat(
                icon: "target",
                iconColor: AppColors.estoniaBlue,
                label: localization.t(.dailyGoalCardLabel),
                value: goalManager.todayGoalReached
                    ? "✓"
                    : "\(goalManager.todayQuestionsAnswered)/\(goalManager.goal.targetQuestions)"
            )

            Divider().frame(height: 32)

            compactStat(
                icon: "flame.fill",
                iconColor: goalManager.currentStreak > 0 ? AppColors.warningAmber : AppColors.textTertiary,
                label: localization.t(.studyStreak),
                value: goalManager.currentStreak > 0
                    ? "\(goalManager.currentStreak)d"
                    : "—"
            )

            Divider().frame(height: 32)

            compactStat(
                icon: "checkmark.circle.fill",
                iconColor: AppColors.successGreen,
                label: localization.t(.questionsMastered),
                value: "\(progressStore.totalQuestionsMastered)"
            )
        }
    }

    private func compactStat(icon: String, iconColor: Color, label: String, value: String) -> some View {
        VStack(spacing: 3) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundColor(iconColor)
                Text(value)
                    .font(.system(.subheadline, design: .rounded).bold())
                    .foregroundColor(AppColors.textPrimary)
            }
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(AppColors.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}
