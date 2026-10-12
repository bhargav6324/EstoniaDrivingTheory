import SwiftUI

public struct MockExamActiveView: View {
    @StateObject private var viewModel = MockExamViewModel()
    @ObservedObject private var localization = LocalizationManager.shared
    @Environment(\.presentationMode) private var presentationMode
    @State private var showNavigator = false
    @State private var showQuitConfirm = false

    public init() {}

    public var body: some View {
        Group {
            if viewModel.isExamSubmitted, let result = viewModel.examResult {
                MockExamResultView(result: result) {
                    presentationMode.wrappedValue.dismiss()
                }
            } else if viewModel.isReviewing {
                MockExamReviewView(viewModel: viewModel) {
                    viewModel.isReviewing = false
                }
            } else if viewModel.currentQuestion != nil {
                VStack(spacing: 0) {
                    // Top Bar
                    topBar

                    // Swipeable Question Content
                    TabView(selection: $viewModel.currentIndex) {
                        ForEach(0..<viewModel.questions.count, id: \.self) { questionIndex in
                            let question = viewModel.questions[questionIndex]
                            ScrollView {
                                VStack(alignment: .leading, spacing: 18) {
                                    // Safety badge if applicable
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

                                    // Visual scenario if present
                                    if let visual = question.visual {
                                        renderVisual(visual)
                                    }

                                    // Options without immediate answers revealed
                                    VStack(spacing: 12) {
                                        let options = question.options(for: localization.currentLanguage)
                                        let letters = ["A", "B", "C", "D"]
                                        let selectedIndex = viewModel.userAnswers[question.id]

                                        ForEach(0..<options.count, id: \.self) { idx in
                                            AnswerOptionCard(
                                                letter: idx < letters.count ? letters[idx] : "\(idx + 1)",
                                                text: options[idx],
                                                isSelected: selectedIndex == idx,
                                                isCorrect: nil,
                                                showFeedback: false,
                                                onSelect: {
                                                    viewModel.selectAnswer(idx, for: question.id)
                                                }
                                            )
                                        }
                                    }

                                    Spacer(minLength: 40)
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 14)
                            }
                            .tag(questionIndex)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))

                    // Bottom Navigation Bar
                    bottomBar
                }
            }
        }
        .background(AppColors.background.ignoresSafeArea())
        .sheet(isPresented: $showNavigator) {
            questionNavigatorSheet
        }
    }

    private var topBar: some View {
        VStack(spacing: 10) {
            HStack {
                // Exit Button with explicit hit target and confirmation alert
                Button {
                    showQuitConfirm = true
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppColors.textSecondary)
                        .frame(width: 44, height: 44)
                        .background(AppColors.cardBackground)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(AppColors.cardBorder, lineWidth: 1))
                }
                .buttonStyle(ScaleButtonStyle())
                .contentShape(Rectangle())
                .alert(isPresented: $showQuitConfirm) {
                    Alert(
                        title: Text("Leave Mock Exam?"),
                        message: Text("Your current mock exam progress will be lost."),
                        primaryButton: .destructive(Text("Leave Exam")) {
                            viewModel.abandonExam()
                            presentationMode.wrappedValue.dismiss()
                        },
                        secondaryButton: .cancel(Text("Continue Exam"))
                    )
                }

                Spacer()

                // Timer Pill
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .foregroundColor(viewModel.secondsRemaining < 300 ? AppColors.errorRed : AppColors.estoniaBlue)
                    Text(viewModel.formattedTime)
                        .font(.system(.subheadline, design: .monospaced).bold())
                        .foregroundColor(viewModel.secondsRemaining < 300 ? AppColors.errorRed : AppColors.textPrimary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppColors.cardBackground)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(AppColors.cardBorder, lineWidth: 1))

                Spacer()

                // Flag Button (Toggle on/off, does not affect score or My Mistakes)
                if let q = viewModel.currentQuestion {
                    let isFlagged = viewModel.flaggedQuestionIds.contains(q.id)
                    Button {
                        viewModel.toggleFlag()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: isFlagged ? "flag.fill" : "flag")
                                .font(.system(size: 14, weight: .bold))
                            if isFlagged {
                                Text("Flagged")
                                    .font(.caption2.bold())
                            }
                        }
                        .foregroundColor(isFlagged ? AppColors.warningAmber : AppColors.textSecondary)
                        .frame(minWidth: 44, minHeight: 44)
                        .padding(.horizontal, isFlagged ? 10 : 0)
                        .background(isFlagged ? AppColors.warningAmber.opacity(0.15) : AppColors.cardBackground)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(isFlagged ? AppColors.warningAmber : AppColors.cardBorder, lineWidth: 1))
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            // Progress Header with Question Board Trigger
            HStack {
                Text(localization.t(.questionOf(viewModel.currentIndex + 1, viewModel.questions.count)))
                    .font(.system(.subheadline, design: .rounded).bold())
                    .foregroundColor(AppColors.textSecondary)

                Spacer()

                Button {
                    showNavigator = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "square.grid.2x2")
                            .font(.subheadline.bold())
                        Text("\(viewModel.currentIndex + 1)/\(viewModel.questions.count)")
                            .font(.system(.subheadline, design: .rounded).bold())
                    }
                    .foregroundColor(AppColors.estoniaBlue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppColors.estoniaBlue.opacity(0.12))
                    .clipShape(Capsule())
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(.horizontal, 20)

            ProgressBarView(
                progress: Double(viewModel.currentIndex + 1) / Double(max(1, viewModel.questions.count)),
                height: 4
            )
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 6)
    }

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 12) {
                // Previous Question
                Button {
                    viewModel.goToPreviousQuestion()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("Previous")
                    }
                    .font(.headline)
                    .foregroundColor(viewModel.isFirstQuestion ? AppColors.textTertiary : AppColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(AppColors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.cardBorder, lineWidth: 1))
                }
                .disabled(viewModel.isFirstQuestion)

                // Next Question OR Review Exam
                if viewModel.isLastQuestion {
                    Button {
                        viewModel.isReviewing = true
                    } label: {
                        HStack(spacing: 6) {
                            Text("Review Exam")
                            Image(systemName: "list.bullet.clipboard")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(AppColors.estoniaBlue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(ScaleButtonStyle())
                } else {
                    Button {
                        viewModel.goToNextQuestion()
                    } label: {
                        HStack(spacing: 6) {
                            Text(localization.t(.nextQuestion))
                            Image(systemName: "chevron.right")
                        }
                        .primaryButton()
                        .frame(height: 48)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 16)
        }
        .background(AppColors.cardBackground)
    }

    private var questionNavigatorSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    BoardStatsSummaryView(viewModel: viewModel)
                        .padding(.top, 6)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Questions Navigator")
                            .font(.system(.title3, design: .rounded).bold())
                            .foregroundColor(AppColors.textPrimary)

                        Text("Tap any tile to jump directly to that question.")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }

                    QuestionBoardGridView(viewModel: viewModel) { selectedIndex in
                        viewModel.jumpToQuestion(selectedIndex)
                        showNavigator = false
                    }

                    HStack {
                        Spacer()
                        BoardLegendView()
                        Spacer()
                    }
                    .padding(.top, 4)

                    Button {
                        showNavigator = false
                        viewModel.isReviewing = true
                    } label: {
                        HStack {
                            Image(systemName: "list.bullet.clipboard")
                            Text("Open Exam Review")
                        }
                        .font(.headline)
                        .foregroundColor(AppColors.estoniaBlue)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(AppColors.estoniaBlue.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.top, 8)
                }
                .padding(20)
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("Questions Overview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showNavigator = false
                    }
                    .font(.body.bold())
                }
            }
        }
    }

    @ViewBuilder
    private func renderVisual(_ visual: VisualConfiguration) -> some View {
        switch visual.type {
        case .intersection:
            IntersectionView(config: visual, height: 210)
        case .roadSign:
            if let signType = visual.signType {
                HStack {
                    Spacer()
                    TrafficSignVectorView.forSignType(signType, size: 84)
                    Spacer()
                }
                .padding(.vertical, 8)
            } else {
                HStack {
                    Spacer()
                    TrafficSignVectorView(shape: .diamondPriority, size: 76)
                    Spacer()
                }
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
}
