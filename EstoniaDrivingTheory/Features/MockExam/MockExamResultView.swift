import SwiftUI

public struct MockExamResultView: View {
    public var result: ExamResult
    public var onDismiss: () -> Void

    @ObservedObject private var localization = LocalizationManager.shared
    @State private var showReviewSheet = false

    public init(result: ExamResult, onDismiss: @escaping () -> Void) {
        self.result = result
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Pass / Fail Hero Banner
                VStack(spacing: 12) {
                    Image(systemName: result.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(result.passed ? AppColors.successGreen : AppColors.errorRed)
                        .padding(.top, 16)

                    Text(result.passed ? localization.t(.passed) : localization.t(.notPassed))
                        .font(.system(.title, design: .rounded).bold())
                        .foregroundColor(result.passed ? AppColors.successGreen : AppColors.errorRed)

                    Text(result.passed ? "You achieved the requirements for Estonian Category B theory!" : "Category B allows maximum 5 errors and max 1 safety error.")
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Stats Grid
                HStack(spacing: 10) {
                    StatCardView(
                        title: localization.t(.examScore),
                        value: "\(result.score)/\(result.totalQuestions)",
                        icon: "number",
                        iconColor: AppColors.estoniaBlue
                    )

                    StatCardView(
                        title: localization.t(.safetyErrors),
                        value: "\(result.safetyErrors)/\(result.maxAllowedSafetyErrors)",
                        icon: "exclamationmark.shield.fill",
                        iconColor: result.safetyErrors > result.maxAllowedSafetyErrors ? AppColors.errorRed : AppColors.successGreen
                    )

                    StatCardView(
                        title: "Review",
                        value: "\(result.flaggedQuestionIds.count)",
                        icon: "flag.fill",
                        iconColor: AppColors.warningAmber
                    )

                    StatCardView(
                        title: "Time",
                        value: result.formattedDuration,
                        icon: "clock.fill",
                        iconColor: AppColors.textSecondary
                    )
                }

                // Topic Breakdown
                if !result.topicScores.isEmpty {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Performance by Topic")
                            .font(.headline)
                            .foregroundColor(AppColors.textPrimary)

                        ForEach(result.topicScores) { topicScore in
                            VStack(spacing: 6) {
                                HStack {
                                    Text(topicScore.topic.title(for: localization.currentLanguage))
                                        .font(.subheadline)
                                        .foregroundColor(AppColors.textPrimary)
                                    Spacer()
                                    Text("\(topicScore.correctCount) / \(topicScore.totalCount)")
                                        .font(.caption.bold())
                                        .foregroundColor(AppColors.textSecondary)
                                }
                                ProgressBarView(
                                    progress: Double(topicScore.percentage) / 100.0,
                                    height: 6,
                                    color: topicScore.percentage >= 80 ? AppColors.successGreen : AppColors.warningAmber
                                )
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .appCard(padding: 16)
                }

                // Review Answers Button
                Button {
                    showReviewSheet = true
                } label: {
                    HStack {
                        Image(systemName: "list.bullet.clipboard")
                        Text(localization.t(.reviewAllAnswers))
                    }
                    .font(.headline)
                    .foregroundColor(AppColors.estoniaBlue)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(AppColors.estoniaBlue.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                // Done Button
                Button(action: onDismiss) {
                    Text("Return to Dashboard")
                        .primaryButton()
                }
            }
            .padding(20)
        }
        .background(AppColors.background.ignoresSafeArea())
        .sheet(isPresented: $showReviewSheet) {
            ExamReviewQuestionsSheet(result: result)
        }
    }
}

public struct ExamReviewQuestionsSheet: View {
    public var result: ExamResult
    @ObservedObject private var localization = LocalizationManager.shared
    @Environment(\.presentationMode) private var presentationMode
    @State private var filterMode: ReviewFilterMode = .all

    enum ReviewFilterMode: String, CaseIterable, Identifiable {
        case all = "All"
        case incorrect = "Incorrect"
        case flagged = "Flagged"
        case safety = "Safety"

        var id: String { rawValue }
    }

    public init(result: ExamResult) {
        self.result = result
    }

    private var filteredQuestionIds: [String] {
        result.questionIds.filter { qId in
            guard let question = QuestionRepository.shared.question(with: qId) else { return false }
            let userChoice = result.userAnswers[qId]
            let correctChoice = question.correctIndex(for: localization.currentLanguage)
            let isCorrect = (userChoice == correctChoice)
            let isFlagged = result.flaggedQuestionIds.contains(qId)

            switch filterMode {
            case .all:
                return true
            case .incorrect:
                return !isCorrect
            case .flagged:
                return isFlagged
            case .safety:
                return question.isSafetyQuestion
            }
        }
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter Picker
                Picker("Filter", selection: $filterMode) {
                    ForEach(ReviewFilterMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 20)
                .padding(.vertical, 10)

                List {
                    if filteredQuestionIds.isEmpty {
                        Text("No questions in this filter.")
                            .font(.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                            .padding(.vertical, 16)
                    } else {
                        ForEach(filteredQuestionIds, id: \.self) { qId in
                            if let question = QuestionRepository.shared.question(with: qId) {
                                let userChoice = result.userAnswers[qId]
                                let correctChoice = question.correctIndex(for: localization.currentLanguage)
                                let isCorrect = (userChoice == correctChoice)
                                let isFlagged = result.flaggedQuestionIds.contains(qId)
                                let options = question.options(for: localization.currentLanguage)

                                VStack(alignment: .leading, spacing: 8) {
                                    // Status Badges Row
                                    HStack(spacing: 6) {
                                        Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                            .foregroundColor(isCorrect ? AppColors.successGreen : AppColors.errorRed)

                                        if isFlagged {
                                            HStack(spacing: 3) {
                                                Image(systemName: "flag.fill")
                                                    .font(.system(size: 9))
                                                Text("Review")
                                                    .font(.system(size: 10, weight: .bold))
                                            }
                                            .foregroundColor(AppColors.warningAmber)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(AppColors.warningAmber.opacity(0.15))
                                            .clipShape(Capsule())
                                        }

                                        if question.isSafetyQuestion {
                                            HStack(spacing: 3) {
                                                Image(systemName: "exclamationmark.shield.fill")
                                                    .font(.system(size: 9))
                                                Text("Safety")
                                                    .font(.system(size: 10, weight: .bold))
                                            }
                                            .foregroundColor(AppColors.errorRed)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(AppColors.errorRed.opacity(0.12))
                                            .clipShape(Capsule())
                                        }

                                        Spacer()

                                        Text(question.topic.title(for: localization.currentLanguage))
                                            .font(.caption2)
                                            .foregroundColor(AppColors.textSecondary)
                                    }

                                    Text(question.questionText(for: localization.currentLanguage))
                                        .font(.headline)
                                        .foregroundColor(AppColors.textPrimary)

                                    if let choice = userChoice, choice >= 0 && choice < options.count {
                                        Text("Your answer: \(options[choice])")
                                            .font(.caption)
                                            .foregroundColor(isCorrect ? AppColors.successGreen : AppColors.errorRed)
                                    } else {
                                        Text("Not answered")
                                            .font(.caption.bold())
                                            .foregroundColor(AppColors.warningAmber)
                                    }

                                    if !isCorrect && correctChoice >= 0 && correctChoice < options.count {
                                        Text("Correct: \(options[correctChoice])")
                                            .font(.caption.bold())
                                            .foregroundColor(AppColors.successGreen)
                                    }

                                    Text(question.explanation(for: localization.currentLanguage))
                                        .font(.caption2)
                                        .foregroundColor(AppColors.textSecondary)
                                        .padding(.top, 2)
                                }
                                .padding(.vertical, 6)
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle(localization.t(.reviewAllAnswers))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localization.t(.done)) {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .font(.body.bold())
                }
            }
        }
    }
}
