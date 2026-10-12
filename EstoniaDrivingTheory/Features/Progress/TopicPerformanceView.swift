import SwiftUI

/// Full topic-by-topic performance breakdown with accuracy bars, mastery info, and weak/strong badge.
struct TopicPerformanceView: View {
    @ObservedObject private var progressStore = ProgressStore.shared
    @ObservedObject private var localization = LocalizationManager.shared
    @ObservedObject private var premium = PremiumAccessManager.shared

    /// Topics sorted by accuracy ascending (weakest first) for the weak section, or curriculum order.
    private var topicRows: [(topic: TopicCategory, total: Int, attempted: Int, mastered: Int, accuracy: Int, mistakes: Int)] {
        TopicCategory.allCases.map { topic in
            let stats = progressStore.topicStats(for: topic)
            return (topic, stats.total, stats.attempted, stats.mastered, stats.accuracy, stats.mistakes)
        }
    }

    private var weakTopicRows: [(topic: TopicCategory, total: Int, attempted: Int, mastered: Int, accuracy: Int, mistakes: Int)] {
        topicRows.filter { $0.attempted > 0 && $0.accuracy < 75 }
            .sorted { $0.accuracy < $1.accuracy }
            .prefix(4)
            .map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Weak topics quick-access (premium or has data)
            if !weakTopicRows.isEmpty {
                weakTopicsSection
            }

            // Full topic breakdown
            allTopicsSection
        }
    }

    // MARK: - Weak Topics

    private var weakTopicsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(AppColors.warningAmber)
                Text(localization.t(.weakTopicsSection))
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
            }

            VStack(spacing: 8) {
                ForEach(weakTopicRows, id: \.topic.rawValue) { row in
                    topicRow(row, compact: true)
                }
            }
        }
        .appCard(padding: 16)
    }

    // MARK: - All Topics

    private var allTopicsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "list.bullet.clipboard")
                    .foregroundColor(AppColors.estoniaBlue)
                Text(localization.t(.topicPerformanceTitle))
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
            }

            VStack(spacing: 10) {
                ForEach(topicRows, id: \.topic.rawValue) { row in
                    topicRow(row, compact: false)
                }
            }
        }
        .appCard(padding: 16)
    }

    // MARK: - Row

    private func topicRow(
        _ row: (topic: TopicCategory, total: Int, attempted: Int, mastered: Int, accuracy: Int, mistakes: Int),
        compact: Bool
    ) -> some View {
        let hasData = row.attempted > 0
        let isWeak = hasData && row.accuracy < 75
        let isStrong = hasData && row.accuracy >= 85

        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                // Topic icon
                TopicIconView(topic: row.topic, size: 14, color: hasData ? AppColors.estoniaBlue : AppColors.textTertiary)
                    .frame(width: 28, height: 28)
                    .background((hasData ? AppColors.estoniaBlue : AppColors.textTertiary).opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 7))

                VStack(alignment: .leading, spacing: 1) {
                    Text(row.topic.title(for: localization.currentLanguage))
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(1)

                    if !hasData {
                        Text(localization.t(.topicNoData))
                            .font(.caption2)
                            .foregroundColor(AppColors.textTertiary)
                    } else if !compact {
                        Text("\(localization.t(.topicAttempted(row.attempted)))" +
                             "  •  \(localization.t(.topicMastered(row.mastered)))")
                            .font(.caption2)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }

                Spacer()

                if hasData {
                    // Accuracy badge
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("\(row.accuracy)%")
                            .font(.system(.subheadline, design: .rounded).bold())
                            .foregroundColor(accuracyColor(row.accuracy))

                        if !compact {
                            Text(isWeak ? localization.t(.topicWeak) : (isStrong ? localization.t(.topicStrong) : ""))
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(isWeak ? AppColors.warningAmber : AppColors.successGreen)
                        }
                    }
                } else {
                    Text("—")
                        .font(.subheadline)
                        .foregroundColor(AppColors.textTertiary)
                }
            }

            // Accuracy progress bar
            if hasData {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(AppColors.cardBackgroundElevated)
                            .frame(height: 4)

                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(accuracyColor(row.accuracy))
                            .frame(width: geo.size.width * CGFloat(row.accuracy) / 100.0, height: 4)
                            .animation(.spring(response: 0.5), value: row.accuracy)
                    }
                }
                .frame(height: 4)
            }
        }
        .padding(10)
        .background(AppColors.background.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func accuracyColor(_ accuracy: Int) -> Color {
        switch accuracy {
        case 85...100: return AppColors.successGreen
        case 60..<85:  return AppColors.estoniaBlue
        default:       return AppColors.warningAmber
        }
    }
}
