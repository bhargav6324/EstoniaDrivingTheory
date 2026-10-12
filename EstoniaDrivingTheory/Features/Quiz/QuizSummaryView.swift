import SwiftUI

public struct QuizSummaryView: View {
    public var score: Int
    public var attempted: Int
    public var total: Int
    public var isEndedEarly: Bool
    public var mistakeQuestions: [Question]
    public var userAnswers: [String: Int]
    public var onDismiss: () -> Void
    public var onRetryMistakes: (() -> Void)?

    @ObservedObject private var localization = LocalizationManager.shared

    public init(
        score: Int,
        attempted: Int? = nil,
        total: Int,
        isEndedEarly: Bool = false,
        mistakeQuestions: [Question] = [],
        userAnswers: [String: Int] = [:],
        onDismiss: @escaping () -> Void,
        onRetryMistakes: (() -> Void)? = nil
    ) {
        self.score = score
        self.attempted = attempted ?? total
        self.total = total
        self.isEndedEarly = isEndedEarly
        self.mistakeQuestions = mistakeQuestions
        self.userAnswers = userAnswers
        self.onDismiss = onDismiss
        self.onRetryMistakes = onRetryMistakes
    }

    private var percentage: Int {
        guard attempted > 0 else { return 0 }
        return Int(Double(score) / Double(attempted) * 100)
    }

    private var mistakesCount: Int {
        max(0, attempted - score)
    }

    private var isGood: Bool {
        percentage >= 80
    }

    private var gaugeColor: Color {
        if percentage >= 80 {
            return AppColors.successGreen
        } else if percentage >= 50 {
            return AppColors.warningAmber
        } else {
            return AppColors.errorRed
        }
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                // Top Status Hero
                VStack(spacing: 8) {
                    Image(systemName: isEndedEarly ? "pause.circle.fill" : (isGood ? "checkmark.circle.fill" : "flag.checkered"))
                        .font(.system(size: 46))
                        .foregroundColor(isEndedEarly ? AppColors.estoniaBlue : (isGood ? AppColors.successGreen : AppColors.warningAmber))
                        .padding(.top, 16)

                    Text(isEndedEarly ? localization.t(.sessionEndedEarly) : localization.t(.quizCompleted))
                        .font(.system(.title2, design: .rounded).bold())
                        .foregroundColor(AppColors.textPrimary)

                    Text(isEndedEarly ? localization.t(.sessionEarlySubtitle(attempted)) : (isGood ? localization.t(.wellDone) : localization.t(.keepPracticing)))
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }

                // Circular Score / Accuracy Gauge
                CircularProgressView(
                    progress: attempted > 0 ? (Double(score) / Double(attempted)) : 0,
                    lineWidth: 12,
                    tintColor: gaugeColor,
                    labelText: "\(score) / \(attempted)",
                    sublabelText: "\(percentage)% \(localization.t(.accuracy))"
                )
                .frame(width: 140, height: 140)
                .padding(.vertical, 4)

                // Stats Cards Grid (Attempted, Correct, Mistakes, Accuracy)
                HStack(spacing: 8) {
                    StatCardView(
                        title: localization.t(.questionsAttempted),
                        value: "\(attempted)/\(total)",
                        icon: "list.bullet.clipboard",
                        iconColor: AppColors.estoniaBlue
                    )

                    StatCardView(
                        title: localization.t(.correctStat),
                        value: "\(score)",
                        icon: "checkmark.circle.fill",
                        iconColor: AppColors.successGreen
                    )

                    StatCardView(
                        title: localization.t(.mistakesStat),
                        value: "\(mistakesCount)",
                        icon: "xmark.circle.fill",
                        iconColor: mistakesCount > 0 ? AppColors.errorRed : AppColors.textSecondary
                    )

                    StatCardView(
                        title: localization.t(.accuracy),
                        value: "\(percentage)%",
                        icon: "percent",
                        iconColor: gaugeColor
                    )
                }

                // Mistakes Review Section
                if !mistakeQuestions.isEmpty {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(AppColors.errorRed)
                            Text("\(localization.t(.questionsToReview)) (\(mistakeQuestions.count))")
                                .font(.system(.headline, design: .rounded).bold())
                                .foregroundColor(AppColors.textPrimary)

                            Spacer()
                        }

                        ForEach(mistakeQuestions) { question in
                            QuizMistakeDetailCard(
                                question: question,
                                chosenIndex: userAnswers[question.id],
                                language: localization.currentLanguage
                            )
                        }
                    }
                    .padding(.top, 8)
                } else if attempted > 0 {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 32))
                            .foregroundColor(AppColors.successGreen)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(localization.t(.noMistakesInSession))
                                .font(.system(.subheadline, design: .rounded).bold())
                                .foregroundColor(AppColors.textPrimary)
                            Text("All questions answered were 100% correct.")
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        Spacer()
                    }
                    .appCard(padding: 16)
                    .padding(.top, 4)
                }

                // Action Buttons
                VStack(spacing: 12) {
                    if !mistakeQuestions.isEmpty, let onRetryMistakes = onRetryMistakes {
                        Button(action: onRetryMistakes) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("\(localization.t(.practiceMistakesAction)) (\(mistakeQuestions.count))")
                            }
                            .font(.headline)
                            .foregroundColor(AppColors.errorRed)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(AppColors.errorRed.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }

                    Button(action: onDismiss) {
                        Text(localization.t(.finishQuiz))
                            .primaryButton()
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
            .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background.ignoresSafeArea())
    }
}

public struct QuizMistakeDetailCard: View {
    public let question: Question
    public let chosenIndex: Int?
    public let language: AppLanguage

    public init(question: Question, chosenIndex: Int?, language: AppLanguage) {
        self.question = question
        self.chosenIndex = chosenIndex
        self.language = language
    }

    private var options: [String] {
        question.options(for: language)
    }

    private var correctIndex: Int {
        question.correctIndex(for: language)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Badges row
            HStack(spacing: 6) {
                Text(question.topic.title(for: language))
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.estoniaBlue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AppColors.estoniaBlue.opacity(0.12))
                    .clipShape(Capsule())

                if question.isSafetyQuestion {
                    HStack(spacing: 3) {
                        Image(systemName: "exclamationmark.shield.fill")
                            .font(.system(size: 9))
                        Text("Safety")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(AppColors.errorRed)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AppColors.errorRed.opacity(0.12))
                    .clipShape(Capsule())
                }

                Spacer()
            }

            // Question Text
            Text(question.questionText(for: language))
                .font(.system(.subheadline, design: .rounded).bold())
                .foregroundColor(AppColors.textPrimary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            // Visual Graphic Preview
            if let visual = question.visual {
                visualGraphic(visual)
            }

            // User Answer (Wrong)
            if let chosen = chosenIndex, chosen >= 0 && chosen < options.count {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppColors.errorRed)
                        .font(.subheadline)
                        .padding(.top, 1)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(LocalizationManager.shared.t(.yourAnswerLabel))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(AppColors.errorRed)
                        Text(options[chosen])
                            .font(.caption)
                            .foregroundColor(AppColors.textPrimary)
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.errorRed.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppColors.errorRed.opacity(0.25), lineWidth: 1)
                )
                .cornerRadius(8)
            }

            // Correct Answer
            if correctIndex >= 0 && correctIndex < options.count {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppColors.successGreen)
                        .font(.subheadline)
                        .padding(.top, 1)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(LocalizationManager.shared.t(.correctAnswerLabel))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(AppColors.successGreen)
                        Text(options[correctIndex])
                            .font(.caption.bold())
                            .foregroundColor(AppColors.textPrimary)
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.successGreen.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppColors.successGreen.opacity(0.25), lineWidth: 1)
                )
                .cornerRadius(8)
            }

            // Explanation & Citation
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "info.circle.fill")
                        .font(.caption2)
                        .foregroundColor(AppColors.estoniaBlue)
                    Text(LocalizationManager.shared.t(.whyExplanation))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AppColors.estoniaBlue)
                }

                Text(question.explanation(for: language))
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)

                if let src = question.source {
                    Text("\(src.title) • \(src.section)")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.textTertiary)
                        .padding(.top, 2)
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(AppColors.cardBorder, lineWidth: 1)
            )
            .cornerRadius(8)
        }
        .appCard(padding: 14)
    }

    @ViewBuilder
    private func visualGraphic(_ visual: VisualConfiguration) -> some View {
        switch visual.type {
        case .intersection, .laneMarking:
            IntersectionView(config: visual, height: 140)
        case .roadSign:
            if let signType = visual.signType {
                HStack {
                    Spacer()
                    TrafficSignVectorView.forSignType(signType, size: 54)
                    Spacer()
                }
                .padding(.vertical, 4)
            }
        case .trafficLight:
            HStack {
                Spacer()
                TrafficLightVectorView(activeState: visual.trafficLightState ?? "red", scale: 1.5)
                Spacer()
            }
            .padding(.vertical, 4)
        }
    }
}
