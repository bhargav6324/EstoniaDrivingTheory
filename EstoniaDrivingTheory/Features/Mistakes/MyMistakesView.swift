import SwiftUI

public struct MyMistakesView: View {
    @ObservedObject private var progressStore = ProgressStore.shared
    @ObservedObject private var localization = LocalizationManager.shared
    @ObservedObject private var premium = PremiumAccessManager.shared
    @State private var activeQuizConfig: QuizSessionConfig? = nil

    private var accessibleMistakes: [MistakeRecord] {
        let accessibleIDs = Set(premium.accessibleQuestions().map { $0.id })
        return progressStore.activeMistakes.filter { accessibleIDs.contains($0.questionId) }
    }

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if accessibleMistakes.isEmpty {
                    // Empty State
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 56))
                            .foregroundColor(AppColors.successGreen)
                            .padding(.top, 40)

                        Text(localization.t(.noMistakesTitle))
                            .font(.system(.title3, design: .rounded).bold())
                            .foregroundColor(AppColors.textPrimary)

                        Text(localization.t(.noMistakesSubtitle))
                            .font(.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .frame(maxWidth: .infinity)
                    .appCard(padding: 24)
                } else {
                    // Hero Mistake Count Card
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(localization.t(.myMistakesTitle))
                                    .font(.headline)
                                    .foregroundColor(AppColors.textPrimary)
                                Text(localization.t(.activeMistakes(accessibleMistakes.count)))
                                    .font(.subheadline)
                                    .foregroundColor(AppColors.errorRed)
                            }
                            Spacer()
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.title)
                                .foregroundColor(AppColors.errorRed)
                        }

                        Button {
                            let snapshot = accessibleMistakes.compactMap { mistake in
                                QuestionRepository.shared.question(with: mistake.questionId)
                            }
                            guard !snapshot.isEmpty else { return }
                            activeQuizConfig = QuizSessionConfig(mode: .mistakes, questions: snapshot)
                        } label: {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text(localization.t(.practiceMyMistakes))
                            }
                            .primaryButton(backgroundColor: AppColors.errorRed)
                        }
                    }
                    .appCard(padding: 18)

                    // Mistakes breakdown by Question
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Questions to Review")
                            .font(.headline)
                            .foregroundColor(AppColors.textPrimary)

                        ForEach(accessibleMistakes) { mistake in
                            if let q = QuestionRepository.shared.question(with: mistake.questionId) {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(q.topic.title(for: localization.currentLanguage))
                                            .font(.caption2.bold())
                                            .foregroundColor(AppColors.estoniaBlue)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(AppColors.estoniaBlue.opacity(0.12))
                                            .clipShape(Capsule())

                                        Spacer()

                                        Text("\(mistake.mistakeCount) errors")
                                            .font(.caption)
                                            .foregroundColor(AppColors.errorRed)
                                    }

                                    Text(q.questionText(for: localization.currentLanguage))
                                        .font(.subheadline)
                                        .foregroundColor(AppColors.textPrimary)
                                        .lineLimit(2)
                                }
                                .padding(12)
                                .background(AppColors.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.cardBorder, lineWidth: 1))
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle(localization.t(.myMistakesTitle))
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $activeQuizConfig) { config in
            QuizView(mode: config.mode, questions: config.questions) {
                activeQuizConfig = nil
            }
        }
    }
}
