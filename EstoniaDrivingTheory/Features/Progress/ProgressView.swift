import SwiftUI
import Charts

public struct ProgressView: View {
    @ObservedObject private var progressStore = ProgressStore.shared
    @ObservedObject private var goalManager = DailyGoalManager.shared
    @ObservedObject private var localization = LocalizationManager.shared
    @ObservedObject private var premium = PremiumAccessManager.shared

    @State private var activeQuizConfig: QuizSessionConfig? = nil
    @State private var showGoalSettings = false
    @State private var showReadinessInfo = false

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 1. Exam Readiness Hero
                    examReadinessSection

                    // 2. Daily Goal + Streak strip
                    dailyGoalSection

                    // 3. Statistics Grid
                    statisticsGrid

                    // 4. Mock Exam Chart
                    MockExamChartView()

                    // 5. Activity Calendar
                    ActivityCalendarView()

                    // 6. Topic Performance (full section)
                    TopicPerformanceView()
                }
                .padding(20)
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle(localization.t(.tabProgress))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showGoalSettings = true
                    } label: {
                        Image(systemName: "target")
                            .foregroundColor(AppColors.estoniaBlue)
                    }
                }
            }
            .sheet(isPresented: $showGoalSettings) {
                DailyGoalSettingsView()
            }
            .sheet(isPresented: $showReadinessInfo) {
                readinessInfoSheet
            }
            .fullScreenCover(item: $activeQuizConfig) { config in
                QuizView(mode: config.mode, questions: config.questions) {
                    activeQuizConfig = nil
                }
            }
        }
    }

    // MARK: - 1. Exam Readiness

    private var examReadinessSection: some View {
        let readiness = progressStore.examReadiness

        return VStack(spacing: 14) {
            HStack(spacing: 18) {
                // Circular gauge
                ZStack {
                    CircularProgressView(
                        progress: Double(readiness.percentage ?? 0) / 100.0,
                        lineWidth: 10,
                        tintColor: readinessColor(readiness.percentage ?? 0),
                        labelText: readiness.hasEnoughData ? "\(readiness.percentage!)%" : "—"
                    )
                    .frame(width: 88, height: 88)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(localization.t(.examReadiness))
                        .font(.system(.title3, design: .rounded).bold())
                        .foregroundColor(AppColors.textPrimary)

                    if readiness.hasEnoughData {
                        readinessTagView(readiness.percentage!)
                    } else {
                        Text(localization.t(.examReadinessNotEnoughData))
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }

                    Button {
                        showReadinessInfo = true
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "info.circle")
                                .font(.caption)
                            Text(localization.t(.examReadinessInfoTitle))
                                .font(.caption)
                        }
                        .foregroundColor(AppColors.estoniaBlue)
                    }
                }

                Spacer()
            }

            if readiness.hasEnoughData {
                // Breakdown bars
                Divider()
                VStack(spacing: 6) {
                    readinessBar(label: "Mock Exams (35%)", value: readiness.mockWeight / 35.0)
                    readinessBar(label: "Practice (30%)", value: readiness.practiceWeight / 30.0)
                    readinessBar(label: "Coverage (20%)", value: readiness.topicWeight / 20.0)
                    readinessBar(label: "Mastery (15%)", value: readiness.masteryWeight / 15.0)
                }
            }
        }
        .appCard(padding: 18)
    }

    private func readinessTagView(_ pct: Int) -> some View {
        let (label, color): (String, Color) = {
            switch pct {
            case 80...100: return ("Ready", AppColors.successGreen)
            case 60..<80:  return ("Getting There", AppColors.estoniaBlue)
            case 40..<60:  return ("Keep Practicing", AppColors.warningAmber)
            default:       return ("Early Stage", AppColors.errorRed)
            }
        }()
        return Text(label)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    private func readinessBar(label: String, value: Double) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(AppColors.textTertiary)
                .frame(width: 110, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(AppColors.cardBackgroundElevated).frame(height: 5)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(AppColors.estoniaBlue.opacity(0.7))
                        .frame(width: geo.size.width * max(0, min(1, value)), height: 5)
                        .animation(.spring(response: 0.5), value: value)
                }
            }
            .frame(height: 5)
        }
    }

    private func readinessColor(_ pct: Int) -> Color {
        switch pct {
        case 80...100: return AppColors.successGreen
        case 60..<80:  return AppColors.estoniaBlue
        default:       return AppColors.warningAmber
        }
    }

    // MARK: - 2. Daily Goal + Streak

    private var dailyGoalSection: some View {
        VStack(spacing: 14) {
            // Today's Goal
            DailyGoalCardView()

            Divider()

            // Streak + quick configure button
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(goalManager.currentStreak > 0 ? AppColors.warningAmber : AppColors.textTertiary)
                        .font(.title3)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(localization.t(.studyStreak))
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                        Text(goalManager.currentStreak > 0
                             ? localization.t(.streakDays(goalManager.currentStreak))
                             : localization.t(.streakZero))
                            .font(.system(.subheadline, design: .rounded).bold())
                            .foregroundColor(AppColors.textPrimary)
                    }
                }

                Spacer()

                Button {
                    showGoalSettings = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.caption)
                        Text(localization.t(.questionsPerDay(goalManager.goal.targetQuestions)))
                            .font(.caption.weight(.medium))
                    }
                    .foregroundColor(AppColors.estoniaBlue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppColors.estoniaBlue.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
        }
        .appCard(padding: 16)
    }

    // MARK: - 3. Statistics Grid

    private var statisticsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localization.t(.statsTitle))
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                StatCardView(
                    title: localization.t(.questionsAttempted),
                    value: "\(progressStore.totalQuestionsAttempted)",
                    icon: "checkmark.circle.fill",
                    iconColor: AppColors.estoniaBlue
                )
                StatCardView(
                    title: localization.t(.accuracy),
                    value: "\(progressStore.overallAccuracyPercentage)%",
                    icon: "chart.bar.fill",
                    iconColor: AppColors.successGreen
                )
                StatCardView(
                    title: localization.t(.questionsMastered),
                    value: "\(progressStore.totalQuestionsMastered)",
                    icon: "star.fill",
                    iconColor: AppColors.warningAmber
                )
                StatCardView(
                    title: localization.t(.statsMistakesRemaining),
                    value: "\(progressStore.activeMistakeCount)",
                    icon: "exclamationmark.triangle.fill",
                    iconColor: AppColors.errorRed
                )
                StatCardView(
                    title: localization.t(.statsMockExamsCompleted),
                    value: "\(progressStore.mockExamHistory.count)",
                    icon: "doc.text.fill",
                    iconColor: AppColors.safetyPurple
                )
                StatCardView(
                    title: localization.t(.statsBestMockScore),
                    value: bestMockScoreText,
                    icon: "trophy.fill",
                    iconColor: AppColors.warningAmber
                )
            }
        }
        .appCard(padding: 16)
    }

    private var bestMockScoreText: String {
        guard let best = progressStore.mockExamHistory.max(by: { $0.score < $1.score }) else { return "—" }
        return "\(best.score)/\(best.totalQuestions)"
    }

    // MARK: - Readiness Info Sheet

    private var readinessInfoSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(localization.t(.examReadinessExplanation))
                        .font(.body)
                        .foregroundColor(AppColors.textPrimary)
                        .padding()

                    VStack(alignment: .leading, spacing: 12) {
                        readinessWeightRow(label: "Mock Exam Performance", weight: "35%", icon: "doc.text.fill", color: AppColors.safetyPurple)
                        readinessWeightRow(label: "Practice Accuracy", weight: "30%", icon: "chart.bar.fill", color: AppColors.successGreen)
                        readinessWeightRow(label: "Topic Coverage", weight: "20%", icon: "list.bullet.clipboard", color: AppColors.estoniaBlue)
                        readinessWeightRow(label: "Mastery Progress", weight: "15%", icon: "star.fill", color: AppColors.warningAmber)
                    }
                    .appCard(padding: 16)
                    .padding(.horizontal)
                }
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle(localization.t(.examReadinessInfoTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(localization.t(.done)) { showReadinessInfo = false }
                        .foregroundColor(AppColors.estoniaBlue)
                }
            }
        }
    }

    private func readinessWeightRow(label: String, weight: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            Text(label)
                .font(.subheadline)
                .foregroundColor(AppColors.textPrimary)
            Spacer()
            Text(weight)
                .font(.system(.subheadline, design: .rounded).bold())
                .foregroundColor(AppColors.textSecondary)
        }
    }
}
