import SwiftUI

public struct ProgressBarView: View {
    public var progress: Double // 0.0 to 1.0
    public var height: CGFloat
    public var color: Color
    public var backgroundColor: Color

    public init(
        progress: Double,
        height: CGFloat = 8,
        color: Color = AppColors.estoniaBlue,
        backgroundColor: Color = AppColors.cardBorder.opacity(0.3)
    ) {
        self.progress = max(0, min(1, progress))
        self.height = height
        self.color = color
        self.backgroundColor = backgroundColor
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(backgroundColor)
                    .frame(height: height)

                Capsule()
                    .fill(color)
                    .frame(width: geo.size.width * CGFloat(progress), height: height)
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
        }
        .frame(height: height)
    }
}

public struct StatCardView: View {
    public var title: String
    public var value: String
    public var icon: String
    public var iconColor: Color

    public init(title: String, value: String, icon: String, iconColor: Color = AppColors.estoniaBlue) {
        self.title = title
        self.value = value
        self.icon = icon
        self.iconColor = iconColor
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            Text(value)
                .font(.system(.title3, design: .rounded).bold())
                .foregroundColor(AppColors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard(padding: 12, cornerRadius: 12)
    }
}
