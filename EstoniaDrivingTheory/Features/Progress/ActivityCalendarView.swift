import SwiftUI

/// A compact heatmap-style calendar showing the last 5 weeks of study activity.
/// Days are colored by intensity: none / light / medium / strong.
struct ActivityCalendarView: View {
    @ObservedObject private var goalManager = DailyGoalManager.shared
    @ObservedObject private var localization = LocalizationManager.shared

    @State private var selectedActivity: DailyActivity? = nil

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 5), count: 7)
    private let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(AppColors.estoniaBlue)
                Text(localization.t(.activityCalendar))
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
            }

            let activities = goalManager.recentActivity(days: 35)
            let hasAnyActivity = activities.contains { $0.questionsAnswered > 0 }

            if !hasAnyActivity {
                Text(localization.t(.activityCalendarEmpty))
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.vertical, 8)
            } else {
                // Day labels row
                HStack(spacing: 0) {
                    ForEach(dayLabels, id: \.self) { label in
                        Text(label)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(AppColors.textTertiary)
                            .frame(maxWidth: .infinity)
                    }
                }

                // Heatmap grid
                LazyVGrid(columns: columns, spacing: 5) {
                    ForEach(activities) { activity in
                        activityCell(for: activity)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3)) {
                                    if selectedActivity?.dateKey == activity.dateKey {
                                        selectedActivity = nil
                                    } else {
                                        selectedActivity = activity.questionsAnswered > 0 ? activity : nil
                                    }
                                }
                            }
                    }
                }

                // Selected day detail
                if let selected = selectedActivity {
                    selectedDayBubble(for: selected)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                // Legend
                intensityLegend
            }
        }
        .appCard(padding: 16)
    }

    // MARK: - Cell

    private func activityCell(for activity: DailyActivity) -> some View {
        let isToday = activity.dateKey == DailyGoalManager.dateKey()
        let isSelected = selectedActivity?.dateKey == activity.dateKey

        return RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(cellColor(for: activity.intensityLevel))
            .frame(height: 20)
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .stroke(isToday ? AppColors.estoniaBlue : (isSelected ? AppColors.estoniaBlue.opacity(0.6) : Color.clear), lineWidth: isToday ? 1.5 : 1)
            )
            .scaleEffect(isSelected ? 1.15 : 1.0)
            .animation(.spring(response: 0.25), value: isSelected)
    }

    private func cellColor(for intensity: ActivityIntensity) -> Color {
        switch intensity {
        case .none:   return AppColors.cardBackgroundElevated
        case .light:  return AppColors.estoniaBlue.opacity(0.25)
        case .medium: return AppColors.estoniaBlue.opacity(0.55)
        case .strong: return AppColors.estoniaBlue
        }
    }

    // MARK: - Detail Bubble

    private func selectedDayBubble(for activity: DailyActivity) -> some View {
        let dateStr: String = {
            if let date = DailyGoalManager.date(from: activity.dateKey) {
                return date.formatted(date: .abbreviated, time: .omitted)
            }
            return activity.dateKey
        }()

        let detail = localization.t(.activityDayDetail(
            activity.questionsAnswered,
            activity.accuracyPercentage,
            activity.mockExamsCompleted
        ))

        return VStack(alignment: .leading, spacing: 4) {
            Text(dateStr)
                .font(.caption.bold())
                .foregroundColor(AppColors.textPrimary)
            Text(detail)
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(AppColors.cardBackgroundElevated)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    // MARK: - Legend

    private var intensityLegend: some View {
        HStack(spacing: 6) {
            Text(localization.t(.activityNoData))
                .font(.system(size: 10))
                .foregroundColor(AppColors.textTertiary)

            ForEach([ActivityIntensity.light, .medium, .strong], id: \.rawValue) { intensity in
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(cellColor(for: intensity))
                    .frame(width: 12, height: 12)
            }

            Text(localization.t(.activityStrongLabel))
                .font(.system(size: 10))
                .foregroundColor(AppColors.textTertiary)

            Spacer()
        }
    }
}
