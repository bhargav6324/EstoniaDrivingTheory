import SwiftUI

public struct TopicDetailView: View {
    public var topic: TopicCategory

    @ObservedObject private var progressStore = ProgressStore.shared
    @ObservedObject private var localization = LocalizationManager.shared
    @ObservedObject private var premium = PremiumAccessManager.shared
    @State private var activeQuizConfig: QuizSessionConfig? = nil
    @State private var showPaywall = false

    private var questions: [Question] {
        premium.accessibleQuestions(for: topic)
    }

    private var totalTopicQuestionsCount: Int {
        QuestionRepository.shared.questions(for: topic).count
    }

    public init(topic: TopicCategory) {
        self.topic = topic
    }

    public var body: some View {
        let stats = progressStore.topicStats(for: topic)

        ScrollView {
            VStack(spacing: 20) {
                // Header Card
                VStack(spacing: 12) {
                    TopicIconView(topic: topic, size: 38, color: AppColors.estoniaBlue)
                        .frame(width: 80, height: 80)
                        .background(AppColors.estoniaBlue.opacity(0.12))
                        .clipShape(Circle())

                    Text(topic.title(for: localization.currentLanguage))
                        .font(.system(.title2, design: .rounded).bold())
                        .foregroundColor(AppColors.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(topic.description(for: localization.currentLanguage))
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity)
                .appCard(padding: 20)

                // Free Mode Upsell Callout (when not premium)
                if !premium.isPremium {
                    HStack(spacing: 12) {
                        Image(systemName: "lock.shield.fill")
                            .font(.title2)
                            .foregroundColor(AppColors.warningAmber)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Free Practice: \(questions.count) Questions")
                                .font(.system(.subheadline, design: .rounded).bold())
                                .foregroundColor(AppColors.textPrimary)
                            Text("Unlock all \(totalTopicQuestionsCount) questions for this topic with Premium.")
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }

                        Spacer()

                        Button {
                            showPaywall = true
                        } label: {
                            Text("Unlock")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(AppColors.estoniaBlue)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(14)
                    .background(AppColors.warningAmber.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(AppColors.warningAmber.opacity(0.3), lineWidth: 1)
                    )
                }

                // Progress Metrics Grid
                VStack(spacing: 14) {
                    HStack(spacing: 12) {
                        StatCardView(
                            title: premium.isPremium ? "Questions" : "Free Questions",
                            value: "\(questions.count)",
                            icon: "doc.text.fill",
                            iconColor: AppColors.estoniaBlue
                        )

                        StatCardView(
                            title: localization.t(.accuracy),
                            value: "\(stats.accuracy)%",
                            icon: "chart.line.uptrend.xyaxis",
                            iconColor: stats.accuracy >= 75 ? AppColors.successGreen : AppColors.warningAmber
                        )
                    }

                    HStack(spacing: 12) {
                        StatCardView(
                            title: localization.t(.questionsMastered),
                            value: "\(stats.mastered)",
                            icon: "checkmark.seal.fill",
                            iconColor: AppColors.successGreen
                        )

                        StatCardView(
                            title: "Mistakes",
                            value: "\(stats.mistakes)",
                            icon: "exclamationmark.triangle.fill",
                            iconColor: stats.mistakes > 0 ? AppColors.errorRed : AppColors.textSecondary
                        )
                    }
                }

                // Action Buttons
                VStack(spacing: 12) {
                    if questions.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 32))
                                .foregroundColor(AppColors.warningAmber)
                            Text("Premium Topic")
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                            Text("This topic has questions exclusive to Premium. Upgrade to practice all official curriculum topics.")
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)

                            Button {
                                showPaywall = true
                            } label: {
                                Text(localization.t(.unlockWithPremium))
                                    .primaryButton()
                            }
                            .padding(.top, 6)
                        }
                        .padding(.vertical, 12)
                    } else {
                        Button {
                            guard !questions.isEmpty else { return }
                            activeQuizConfig = QuizSessionConfig(mode: .topic(topic), questions: questions)
                        } label: {
                            HStack {
                                Image(systemName: "play.fill")
                                Text(localization.t(.startPractice))
                            }
                            .primaryButton()
                        }

                        if stats.mistakes > 0 {
                            Button {
                                let accessibleIDs = Set(questions.map { $0.id })
                                let mistakeQuestions = questions.filter { q in
                                    accessibleIDs.contains(q.id) && progressStore.mistakesMap[q.id]?.isResolved == false
                                }
                                guard !mistakeQuestions.isEmpty else { return }
                                activeQuizConfig = QuizSessionConfig(mode: .mistakes, questions: mistakeQuestions)
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                    Text(localization.t(.reviewMistakes))
                                }
                                .font(.headline)
                                .foregroundColor(AppColors.errorRed)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(AppColors.errorRed.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
                    }
                }
                .padding(.top, 8)
            }
            .padding(20)
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle(topic.title(for: localization.currentLanguage))
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $activeQuizConfig) { config in
            QuizView(mode: config.mode, questions: config.questions) {
                activeQuizConfig = nil
            }
        }
        .sheet(isPresented: $showPaywall) {
            PremiumPaywallView()
        }
    }
}
