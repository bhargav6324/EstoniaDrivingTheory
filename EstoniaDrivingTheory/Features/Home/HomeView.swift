import SwiftUI

public enum HomeRoute: Hashable {
    case mockExam
    case myMistakes
    case roadSigns
    case topic(TopicCategory)
}

public struct HomeView: View {
    @ObservedObject private var progressStore = ProgressStore.shared
    @ObservedObject private var localization = LocalizationManager.shared
    @ObservedObject private var premium = PremiumAccessManager.shared
    @ObservedObject private var goalManager = DailyGoalManager.shared
    @State private var showLanguagePicker = false
    @State private var navPath: [HomeRoute] = []

    public init() {}

    public var body: some View {
        NavigationStack(path: $navPath) {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerView

                    // 1. Exam Readiness Card
                    examReadinessCard

                    // 2. Continue Learning Card
                    continueLearningCard

                    // 3. Main Action Grid
                    mainActionsGrid
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationBarHidden(true)
            .sheet(isPresented: $showLanguagePicker) {
                LanguagePickerSheet(isDismissable: true) {
                    showLanguagePicker = false
                }
            }
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case .mockExam:
                    MockExamIntroView()
                case .myMistakes:
                    MyMistakesView()
                case .roadSigns:
                    RoadSignsView()
                case .topic(let topic):
                    TopicDetailView(topic: topic)
                }
            }
        }
    }

    // Header
    private var headerView: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(localization.t(.appTitle))
                    .font(.system(.title2, design: .rounded).bold())
                    .foregroundColor(AppColors.textPrimary)

                Text(localization.t(.categoryB))
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()

            // Language Selector Button
            Button {
                showLanguagePicker = true
            } label: {
                HStack(spacing: 6) {
                    Text(localization.currentLanguage.flag)
                        .font(.headline)
                    Text(localization.currentLanguage.displayName)
                        .font(.system(.caption, design: .rounded).bold())
                        .foregroundColor(AppColors.textPrimary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(AppColors.cardBackground)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(AppColors.cardBorder, lineWidth: 1))
            }
        }
        .padding(.top, 8)
    }

    // 1. Exam Readiness Card
    private var examReadinessCard: some View {
        let readiness = progressStore.examReadiness

        return VStack(spacing: 16) {
            HStack(spacing: 18) {
                CircularProgressView(
                    progress: Double(readiness.percentage ?? 0) / 100.0,
                    lineWidth: 10,
                    tintColor: AppColors.estoniaBlue,
                    labelText: readiness.hasEnoughData ? "\(readiness.percentage!)%" : "—"
                )
                .frame(width: 82, height: 82)

                VStack(alignment: .leading, spacing: 4) {
                    Text(localization.t(.examReadiness))
                        .font(.system(.title3, design: .rounded).bold())
                        .foregroundColor(AppColors.textPrimary)

                    Text(readiness.hasEnoughData
                         ? localization.t(.examReadinessExplanation)
                         : localization.t(.examReadinessNotEnoughData))
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(2)
                }
            }

            Divider()

            // Compact goal + streak + mastered strip
            HomeProgressSummaryView()
        }
        .appCard(padding: 18)
    }

    // 2. Continue Learning Card
    private var continueLearningCard: some View {
        let accessibleTopics = TopicCategory.allCases.filter { premium.hasAccessibleQuestions(for: $0) }
        let resumeTopic = progressStore.recentTopic.flatMap { accessibleTopics.contains($0) ? $0 : nil } ?? accessibleTopics.first ?? .rightOfWay

        return NavigationLink(value: HomeRoute.topic(resumeTopic)) {
            HStack(spacing: 16) {
                TopicIconView(topic: resumeTopic, size: 24, color: .white)
                    .frame(width: 48, height: 48)
                    .background(Color.white.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 3) {
                    Text(localization.t(.continuePractice))
                        .font(.headline)
                        .foregroundColor(.white)

                    Text(resumeTopic.title(for: localization.currentLanguage))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.85))
                }

                Spacer()

                Image(systemName: "arrow.right.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: [AppColors.estoniaBlue, AppColors.estoniaBlueDark],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: AppColors.estoniaBlue.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // 3. Main Action Grid
    private var mainActionsGrid: some View {
        VStack(spacing: 14) {
            // Mock Exam
            NavigationLink(value: HomeRoute.mockExam) {
                let subtitle: String = {
                    if premium.isPremium {
                        return localization.t(.mockExamSubtitle)
                    } else if premium.hasCompletedFreeMock {
                        return "Free mock completed • Tap to unlock"
                    } else {
                        return "1 Free Mock Exam Available"
                    }
                }()

                return mainActionRow(
                    icon: "doc.text.fill",
                    iconColor: AppColors.estoniaBlue,
                    title: localization.t(.mockExamTitle),
                    subtitle: subtitle
                )
            }

            // My Mistakes
            NavigationLink(value: HomeRoute.myMistakes) {
                let mistakeCount = progressStore.activeMistakeCount(filteredBy: premium.isPremium ? nil : Set(premium.freeQuestionIDs))

                return HStack(spacing: 14) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title3)
                        .foregroundColor(AppColors.errorRed)
                        .frame(width: 42, height: 42)
                        .background(AppColors.errorRed.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(localization.t(.myMistakesTitle))
                            .font(.headline)
                            .foregroundColor(AppColors.textPrimary)

                        Text(localization.t(.myMistakesSubtitle))
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }

                    Spacer()

                    if mistakeCount > 0 {
                        Text("\(mistakeCount)")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(AppColors.errorRed)
                            .clipShape(Capsule())
                    }

                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundColor(AppColors.textTertiary)
                }
                .appCard(padding: 16)
            }

            // Road Signs
            NavigationLink(value: HomeRoute.roadSigns) {
                mainActionRow(
                    icon: "shield.fill",
                    iconColor: AppColors.warningAmber,
                    title: localization.t(.roadSignsTitle),
                    subtitle: localization.t(.roadSignsSubtitle)
                )
            }
        }
    }

    private func mainActionRow(icon: String, iconColor: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(iconColor)
                .frame(width: 42, height: 42)
                .background(iconColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundColor(AppColors.textTertiary)
        }
        .appCard(padding: 16)
    }
}
