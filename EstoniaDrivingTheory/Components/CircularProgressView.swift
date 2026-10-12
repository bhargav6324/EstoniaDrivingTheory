import SwiftUI

public struct CircularProgressView: View {
    public var progress: Double // 0.0 to 1.0
    public var lineWidth: CGFloat
    public var tintColor: Color
    public var labelText: String?
    public var sublabelText: String?

    public init(
        progress: Double,
        lineWidth: CGFloat = 10,
        tintColor: Color = AppColors.estoniaBlue,
        labelText: String? = nil,
        sublabelText: String? = nil
    ) {
        self.progress = max(0, min(1, progress))
        self.lineWidth = lineWidth
        self.tintColor = tintColor
        self.labelText = labelText
        self.sublabelText = sublabelText
    }

    public var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(tintColor.opacity(0.15), lineWidth: lineWidth)

            // Animated Progress
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(
                    tintColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6), value: progress)

            // Center Text
            VStack(spacing: 2) {
                if let label = labelText {
                    Text(label)
                        .font(.system(.title2, design: .rounded).bold())
                        .foregroundColor(AppColors.textPrimary)
                } else {
                    Text("\(Int(progress * 100))%")
                        .font(.system(.title2, design: .rounded).bold())
                        .foregroundColor(AppColors.textPrimary)
                }

                if let sub = sublabelText {
                    Text(sub)
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
    }
}
