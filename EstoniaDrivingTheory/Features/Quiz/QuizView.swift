import SwiftUI

public struct QuizView: View {
    @StateObject private var viewModel: QuizViewModel
    @ObservedObject private var localization = LocalizationManager.shared
    @Environment(\.presentationMode) private var presentationMode
    @State private var showExitConfirm = false
    @State private var showSourceDetail = false
    private let initialQuestions: [Question]
    public var onFinished: (() -> Void)?

    public init(mode: QuizMode, questions: [Question], onFinished: (() -> Void)? = nil) {
        self.initialQuestions = questions
        self.onFinished = onFinished
        _viewModel = StateObject(wrappedValue: QuizViewModel(mode: mode, questions: questions))
    }

    public var body: some View {
        Group {
            if viewModel.questions.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "tray.fill")
                        .font(.system(size: 48))
                        .foregroundColor(AppColors.textTertiary)
                    Text("No questions available yet")
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)
                    Text("Questions for this topic will be added soon.")
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Text("Close")
                            .font(.system(.body, design: .rounded).bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(AppColors.estoniaBlue)
                            .clipShape(Capsule())
                    }
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppColors.background.ignoresSafeArea())
            } else if viewModel.isCompleted {
                QuizSummaryView(
                    score: viewModel.sessionScore,
                    attempted: viewModel.attemptedCount,
                    total: viewModel.questions.count,
                    isEndedEarly: viewModel.isEndedEarly,
                    mistakeQuestions: viewModel.mistakeQuestions,
                    userAnswers: viewModel.userAnswers,
                    onDismiss: {
                        dismissQuiz()
                    },
                    onRetryMistakes: viewModel.mistakeQuestions.isEmpty ? nil : {
                        withAnimation {
                            viewModel.restartWithMistakes()
                        }
                    }
                )
            } else if let question = viewModel.currentQuestion {
                VStack(spacing: 0) {
                    // Top Bar
                    topNavBar

                    // Scrollable Question Content
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            // Critical Safety Badge
                            if question.isSafetyQuestion {
                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.shield.fill")
                                        .foregroundColor(AppColors.errorRed)
                                    Text(localization.t(.safetyQuestionBadge))
                                        .font(.system(size: 11, weight: .bold, design: .rounded))
                                        .foregroundColor(AppColors.errorRed)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(AppColors.errorRed.opacity(0.12))
                                .clipShape(Capsule())
                            }

                            // Question Title
                            Text(question.questionText(for: localization.currentLanguage))
                                .font(.system(.title3, design: .rounded).bold())
                                .foregroundColor(AppColors.textPrimary)
                                .lineSpacing(3)
                                .fixedSize(horizontal: false, vertical: true)

                            // Visual Diagram if present
                            if let visual = question.visual {
                                renderVisual(visual)
                            }

                            // Answer Options (A, B, C, D)
                            VStack(spacing: 12) {
                                let options = question.options(for: localization.currentLanguage)
                                let correctIdx = question.correctIndex(for: localization.currentLanguage)
                                let letters = ["A", "B", "C", "D"]

                                ForEach(0..<options.count, id: \.self) { idx in
                                    AnswerOptionCard(
                                        letter: idx < letters.count ? letters[idx] : "\(idx + 1)",
                                        text: options[idx],
                                        isSelected: viewModel.selectedOptionIndex == idx,
                                        isCorrect: viewModel.hasAnswered ? (idx == correctIdx) : nil,
                                        showFeedback: viewModel.hasAnswered,
                                        onSelect: {
                                            viewModel.selectOption(idx)
                                        }
                                    )
                                }
                            }

                            // Feedback Drawer (Why? & Source)
                            if viewModel.hasAnswered {
                                feedbackCard(for: question)
                                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                            }

                            Spacer(minLength: 40)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 14)
                    }

                    // Bottom Next Button
                    if viewModel.hasAnswered {
                        VStack {
                            Divider()
                            Button {
                                withAnimation {
                                    viewModel.nextQuestion()
                                }
                            } label: {
                                Text(viewModel.isLastQuestion ? localization.t(.finishQuiz) : localization.t(.nextQuestion))
                                    .primaryButton()
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                            .padding(.bottom, 14)
                        }
                        .background(AppColors.cardBackground)
                    }
                }
            } else {
                Text("No questions available")
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .navigationBarHidden(true)
        .background(AppColors.background.ignoresSafeArea())
        .alert(isPresented: $showExitConfirm) {
            if viewModel.attemptedCount > 0 {
                return Alert(
                    title: Text(localization.t(.quitConfirmTitle)),
                    message: Text(localization.t(.quitConfirmMessage)),
                    primaryButton: .destructive(Text(localization.t(.exitAndReview))) {
                        viewModel.endSessionEarly()
                    },
                    secondaryButton: .cancel(Text(localization.t(.stay)))
                )
            } else {
                return Alert(
                    title: Text(localization.t(.quitConfirmTitle)),
                    message: Text(localization.t(.quitConfirmMessage)),
                    primaryButton: .destructive(Text(localization.t(.quit))) {
                        dismissQuiz()
                    },
                    secondaryButton: .cancel(Text(localization.t(.stay)))
                )
            }
        }
        .onAppear {
            if viewModel.questions.isEmpty && !initialQuestions.isEmpty {
                viewModel.reload(questions: initialQuestions)
            }
        }
        .onChange(of: initialQuestions.count) { _ in
            if viewModel.questions.isEmpty && !initialQuestions.isEmpty {
                viewModel.reload(questions: initialQuestions)
            }
        }
    }

    // Top Navigation
    private var topNavBar: some View {
        VStack(spacing: 8) {
            HStack {
                Button {
                    showExitConfirm = true
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppColors.textSecondary)
                        .frame(width: 36, height: 36)
                        .background(AppColors.cardBackground)
                        .clipShape(Circle())
                }

                Spacer()

                Text(localization.t(.questionOf(viewModel.currentIndex + 1, viewModel.questions.count)))
                    .font(.system(.subheadline, design: .rounded).bold())
                    .foregroundColor(AppColors.textSecondary)

                Spacer()

                // Topic icon
                if let topic = viewModel.currentQuestion?.topic {
                    TopicIconView(topic: topic, size: 16, color: AppColors.estoniaBlue)
                        .frame(width: 36, height: 36)
                        .background(AppColors.estoniaBlue.opacity(0.12))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            // Progress Bar
            ProgressBarView(progress: viewModel.progressFraction, height: 4)
                .padding(.horizontal, 20)
        }
        .padding(.bottom, 6)
    }

    // Visual Graphic Renderer
    @ViewBuilder
    private func renderVisual(_ visual: VisualConfiguration) -> some View {
        switch visual.type {
        case .intersection:
            IntersectionView(config: visual, height: 210)
        case .roadSign:
            if let signType = visual.signType {
                HStack {
                    Spacer()
                    signView(for: signType)
                    Spacer()
                }
                .padding(.vertical, 8)
            }
        case .trafficLight:
            HStack {
                Spacer()
                TrafficLightVectorView(activeState: visual.trafficLightState ?? "red", scale: 2.2)
                    .padding(.vertical, 8)
                Spacer()
            }
        case .laneMarking:
            IntersectionView(config: visual, height: 210)
        }
    }

    @ViewBuilder
    private func signView(for signType: String) -> some View {
        TrafficSignVectorView.forSignType(signType, size: 84)
    }

    // Feedback Card (Why? & Source)
    private func feedbackCard(for question: Question) -> some View {
        let isCorrect = viewModel.selectedOptionIndex == question.correctIndex(for: localization.currentLanguage)

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(isCorrect ? AppColors.successGreen : AppColors.errorRed)

                Text(localization.t(.whyExplanation))
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)

                Spacer()
            }

            Text(question.explanation(for: localization.currentLanguage))
                .font(.subheadline)
                .foregroundColor(AppColors.textPrimary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            // Legal Citation Source
            if let src = question.source {
                HStack(spacing: 6) {
                    Image(systemName: "book.closed.fill")
                        .font(.caption2)
                        .foregroundColor(AppColors.estoniaBlue)
                    Text("\(src.title) • \(src.section)")
                        .font(.system(.caption, design: .rounded).bold())
                        .foregroundColor(AppColors.estoniaBlue)
                }
                .padding(.top, 4)
            }
        }
        .appCard(padding: 16, strokeColor: isCorrect ? AppColors.successGreen.opacity(0.4) : AppColors.errorRed.opacity(0.4))
    }

    private func dismissQuiz() {
        if let onFinished = onFinished {
            onFinished()
        } else {
            presentationMode.wrappedValue.dismiss()
        }
    }
}
