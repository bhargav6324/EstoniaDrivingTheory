import SwiftUI

public struct QuestionTileView: View {
    public let index: Int
    public let status: ExamQuestionStatus
    public let isCurrent: Bool
    public let action: () -> Void

    public init(index: Int, status: ExamQuestionStatus, isCurrent: Bool, action: @escaping () -> Void) {
        self.index = index
        self.status = status
        self.isCurrent = isCurrent
        self.action = action
    }

    private var fillColor: Color {
        switch status {
        case .answered:
            return AppColors.successGreen
        case .flagged:
            return AppColors.warningAmber
        case .unanswered:
            return AppColors.cardBackground
        }
    }

    private var textColor: Color {
        switch status {
        case .answered, .flagged:
            return .white
        case .unanswered:
            return AppColors.textPrimary
        }
    }

    public var body: some View {
        Button(action: action) {
            ZStack {
                // Base background fill
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(fillColor)

                // Unanswered border
                if status == .unanswered {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(AppColors.cardBorder, lineWidth: 1)
                }

                // Current question highlight ring (does NOT replace status color)
                if isCurrent {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(AppColors.estoniaBlue, lineWidth: 3)
                        .padding(1)
                }

                // Tile Content
                VStack(spacing: 2) {
                    Text("\(index + 1)")
                        .font(.system(.subheadline, design: .rounded).bold())
                        .foregroundColor(textColor)

                    if status == .flagged {
                        Image(systemName: "flag.fill")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .frame(height: 48)
            .shadow(color: isCurrent ? AppColors.estoniaBlue.opacity(0.3) : Color.clear, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

public struct QuestionBoardGridView: View {
    @ObservedObject public var viewModel: MockExamViewModel
    public var onSelect: (Int) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 5)

    public init(viewModel: MockExamViewModel, onSelect: @escaping (Int) -> Void) {
        self.viewModel = viewModel
        self.onSelect = onSelect
    }

    public var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(0..<viewModel.questions.count, id: \.self) { idx in
                QuestionTileView(
                    index: idx,
                    status: viewModel.status(for: idx),
                    isCurrent: viewModel.currentIndex == idx,
                    action: {
                        onSelect(idx)
                    }
                )
            }
        }
    }
}

public struct BoardLegendView: View {
    @ObservedObject private var localization = LocalizationManager.shared

    public init() {}

    public var body: some View {
        HStack(spacing: 16) {
            legendItem(color: AppColors.successGreen, label: "Answered")
            legendItem(color: AppColors.warningAmber, label: "Marked for Review")
            legendItem(color: AppColors.cardBorder, label: "Unanswered")
        }
        .padding(.vertical, 6)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
                .overlay(Circle().stroke(AppColors.cardBorder, lineWidth: color == AppColors.cardBorder ? 1 : 0))

            Text(label)
                .font(.caption2)
                .foregroundColor(AppColors.textSecondary)
        }
    }
}

public struct BoardStatsSummaryView: View {
    @ObservedObject public var viewModel: MockExamViewModel

    public init(viewModel: MockExamViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        HStack(spacing: 12) {
            statBadge(
                title: "Answered",
                value: "\(viewModel.answeredCount)",
                color: AppColors.successGreen,
                icon: "checkmark.circle.fill"
            )

            statBadge(
                title: "Unanswered",
                value: "\(viewModel.unansweredCount)",
                color: AppColors.textSecondary,
                icon: "circle.dashed"
            )

            statBadge(
                title: "Review",
                value: "\(viewModel.flaggedCount)",
                color: AppColors.warningAmber,
                icon: "flag.fill"
            )
        }
    }

    private func statBadge(title: String, value: String, color: Color, icon: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundColor(color)
                Text(value)
                    .font(.system(.headline, design: .rounded).bold())
                    .foregroundColor(AppColors.textPrimary)
            }

            Text(title)
                .font(.caption2)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(AppColors.cardBorder, lineWidth: 1)
        )
    }
}
