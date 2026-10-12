import SwiftUI

public struct AppCardModifier: ViewModifier {
    var padding: CGFloat
    var cornerRadius: CGFloat
    var strokeColor: Color

    public init(padding: CGFloat = 16, cornerRadius: CGFloat = 16, strokeColor: Color = AppColors.cardBorder) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.strokeColor = strokeColor
    }

    public func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(strokeColor, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

public struct PrimaryButtonModifier: ViewModifier {
    var backgroundColor: Color
    var foregroundColor: Color

    public init(backgroundColor: Color = AppColors.estoniaBlue, foregroundColor: Color = .white) {
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
    }

    public func body(content: Content) -> some View {
        content
            .font(.headline)
            .foregroundColor(foregroundColor)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: backgroundColor.opacity(0.25), radius: 6, x: 0, y: 3)
    }
}

public extension View {
    func appCard(padding: CGFloat = 16, cornerRadius: CGFloat = 16, strokeColor: Color = AppColors.cardBorder) -> some View {
        self.modifier(AppCardModifier(padding: padding, cornerRadius: cornerRadius, strokeColor: strokeColor))
    }

    func primaryButton(backgroundColor: Color = AppColors.estoniaBlue, foregroundColor: Color = .white) -> some View {
        self.modifier(PrimaryButtonModifier(backgroundColor: backgroundColor, foregroundColor: foregroundColor))
    }
}
