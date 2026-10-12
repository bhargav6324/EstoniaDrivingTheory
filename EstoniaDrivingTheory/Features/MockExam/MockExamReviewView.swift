import SwiftUI

public struct MockExamReviewView: View {
    @ObservedObject public var viewModel: MockExamViewModel
    @ObservedObject private var localization = LocalizationManager.shared
    public var onReturnToExam: () -> Void

    @State private var showSubmitConfirm = false

    public init(viewModel: MockExamViewModel, onReturnToExam: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onReturnToExam = onReturnToExam
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Top Navigation Bar
            topBar

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Summary Stats
                    BoardStatsSummaryView(viewModel: viewModel)
                        .padding(.top, 4)

                    // Board Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Question Status")
                            .font(.system(.title3, design: .rounded).bold())
                            .foregroundColor(AppColors.textPrimary)

                        Text("Tap any question to return and inspect or modify your answer.")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }

                    // Question Board Grid
                    QuestionBoardGridView(viewModel: viewModel) { selectedIndex in
                        viewModel.jumpToQuestion(selectedIndex)
                    }

                    // Legend
                    HStack {
                        Spacer()
                        BoardLegendView()
                        Spacer()
                    }
                    .padding(.top, 4)

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
            }

            // Bottom Submit Button
            bottomSubmitSection
        }
        .background(AppColors.background.ignoresSafeArea())
        .alert(isPresented: $showSubmitConfirm) {
            if viewModel.unansweredCount > 0 {
                return Alert(
                    title: Text("Unanswered Questions"),
                    message: Text("You still have \(viewModel.unansweredCount) unanswered questions. Submit anyway?"),
                    primaryButton: .destructive(Text("Submit Exam")) {
                        viewModel.submitExam()
                    },
                    secondaryButton: .cancel(Text("Continue Reviewing"))
                )
            } else {
                return Alert(
                    title: Text("Submit Exam?"),
                    message: Text("Are you ready to submit your exam for grading?"),
                    primaryButton: .default(Text("Submit Exam")) {
                        viewModel.submitExam()
                    },
                    secondaryButton: .cancel(Text("Continue Reviewing"))
                )
            }
        }
    }

    private var topBar: some View {
        HStack {
            Button(action: onReturnToExam) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .bold))
                    Text("Back to Exam")
                        .font(.system(.subheadline, design: .rounded).bold())
                }
                .foregroundColor(AppColors.estoniaBlue)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppColors.cardBackground)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(AppColors.cardBorder, lineWidth: 1))
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
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private var bottomSubmitSection: some View {
        VStack(spacing: 0) {
            Divider()

            Button {
                showSubmitConfirm = true
            } label: {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                    Text("Submit Exam")
                }
                .primaryButton(backgroundColor: AppColors.successGreen)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 16)
        }
        .background(AppColors.cardBackground)
    }
}
