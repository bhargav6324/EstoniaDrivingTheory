import SwiftUI

public struct AnswerOptionCard: View {
    public var letter: String // "A", "B", "C", "D"
    public var text: String
    public var isSelected: Bool
    public var isCorrect: Bool? // nil if not yet answered/revealed
    public var showFeedback: Bool
    public var onSelect: () -> Void

    public init(
        letter: String,
        text: String,
        isSelected: Bool,
        isCorrect: Bool? = nil,
        showFeedback: Bool = false,
        onSelect: @escaping () -> Void
    ) {
        self.letter = letter
        self.text = text
        self.isSelected = isSelected
        self.isCorrect = isCorrect
        self.showFeedback = showFeedback
        self.onSelect = onSelect
    }

    private var backgroundColor: Color {
        if showFeedback {
            if isCorrect == true {
                return AppColors.successGreen.opacity(0.12)
            } else if isSelected && isCorrect == false {
                return AppColors.errorRed.opacity(0.12)
            }
        } else if isSelected {
            return AppColors.estoniaBlue.opacity(0.10)
        }
        return AppColors.cardBackground
    }

    private var borderColor: Color {
        if showFeedback {
            if isCorrect == true {
                return AppColors.successGreen
            } else if isSelected && isCorrect == false {
                return AppColors.errorRed
            }
        } else if isSelected {
            return AppColors.estoniaBlue
        }
        return AppColors.cardBorder
    }

    private var badgeColor: Color {
        if showFeedback {
            if isCorrect == true {
                return AppColors.successGreen
            } else if isSelected && isCorrect == false {
                return AppColors.errorRed
            }
        } else if isSelected {
            return AppColors.estoniaBlue
        }
        return Color(UIColor.tertiarySystemFill)
    }

    private var badgeTextColor: Color {
        if (showFeedback && (isCorrect == true || isSelected)) || (!showFeedback && isSelected) {
            return .white
        }
        return AppColors.textPrimary
    }

    public var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: 14) {
                // Letter Badge (A, B, C, D)
                ZStack {
                    Circle()
                        .fill(badgeColor)
                        .frame(width: 32, height: 32)

                    if showFeedback && isCorrect == true {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    } else if showFeedback && isSelected && isCorrect == false {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Text(letter)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(badgeTextColor)
                    }
                }
                .padding(.top, 2)

                // Answer Text
                Text(text)
                    .font(.body)
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(borderColor, lineWidth: isSelected || (showFeedback && isCorrect == true) ? 2 : 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

public struct ScaleButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
