import SwiftUI
import Charts

/// Shows a line chart of completed mock exam scores over time.
/// Falls back to an empty-state message when fewer than 2 exams have been completed.
struct MockExamChartView: View {
    @ObservedObject private var progressStore = ProgressStore.shared
    @ObservedObject private var localization = LocalizationManager.shared
    @ObservedObject private var premium = PremiumAccessManager.shared

    // Show max 10 most recent exams, oldest first for the chart
    private var chartExams: [ExamResult] {
        let accessible = premium.isPremium
            ? progressStore.mockExamHistory
            : Array(progressStore.mockExamHistory.prefix(1))
        return Array(accessible.prefix(10).reversed())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(AppColors.estoniaBlue)
                Text(localization.t(.mockScoreTrend))
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
            }

            if chartExams.count < 2 {
                emptyState
            } else {
                chartContent
            }
        }
        .appCard(padding: 16)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        HStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.title2)
                .foregroundColor(AppColors.textTertiary)
            Text(localization.t(.mockScoreTrendEmpty))
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Chart

    private var chartContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Summary row
            HStack(spacing: 16) {
                if let best = chartExams.max(by: { $0.score < $1.score }) {
                    miniStat(label: localization.t(.statsBestMockScore),
                             value: "\(best.score)/\(best.totalQuestions)")
                }
                if let last = chartExams.last {
                    let label = last.passed ? localization.t(.mockPassLabel) : localization.t(.mockFailLabel)
                    miniStat(label: "Latest",
                             value: "\(last.score)/\(last.totalQuestions)",
                             valueColor: last.passed ? AppColors.successGreen : AppColors.errorRed,
                             badge: label,
                             badgeColor: last.passed ? AppColors.successGreen : AppColors.errorRed)
                }
                Spacer()
            }

            // Line chart using Swift Charts
            Chart {
                // Pass/fail threshold line
                let threshold = chartExams.first.map { $0.totalQuestions - $0.maxAllowedErrors } ?? 35
                RuleMark(y: .value("Pass", threshold))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    .foregroundStyle(AppColors.successGreen.opacity(0.6))
                    .annotation(position: .top, alignment: .trailing) {
                        Text(localization.t(.mockPassLabel))
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(AppColors.successGreen)
                    }

                ForEach(Array(chartExams.enumerated()), id: \.offset) { index, exam in
                    LineMark(
                        x: .value("Exam", index + 1),
                        y: .value("Score", exam.score)
                    )
                    .foregroundStyle(AppColors.estoniaBlue)
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Exam", index + 1),
                        y: .value("Score", exam.score)
                    )
                    .foregroundStyle(exam.passed ? AppColors.successGreen : AppColors.errorRed)
                    .symbolSize(50)
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { value in
                    AxisGridLine()
                        .foregroundStyle(AppColors.cardBorder)
                    AxisValueLabel()
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: min(chartExams.count, 5))) { value in
                    AxisValueLabel {
                        if let idx = value.as(Int.self) {
                            Text("#\(idx)")
                                .font(.system(size: 9))
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                }
            }
            .frame(height: 130)
        }
    }

    // MARK: - Mini Stat

    private func miniStat(
        label: String,
        value: String,
        valueColor: Color = AppColors.textPrimary,
        badge: String? = nil,
        badgeColor: Color = AppColors.successGreen
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(AppColors.textTertiary)
            HStack(spacing: 4) {
                Text(value)
                    .font(.system(.subheadline, design: .rounded).bold())
                    .foregroundColor(valueColor)
                if let badge = badge {
                    Text(badge)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(badgeColor)
                        .clipShape(Capsule())
                }
            }
        }
    }
}
