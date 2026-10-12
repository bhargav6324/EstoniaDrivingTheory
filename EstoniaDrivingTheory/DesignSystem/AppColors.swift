import SwiftUI

public enum AppColors {
    // Official Estonian Blue & Modern UI Accents
    public static let estoniaBlue = Color(red: 0.0, green: 0.447, blue: 0.808) // #0072CE
    public static let estoniaBlueLight = Color(red: 0.15, green: 0.55, blue: 0.95)
    public static let estoniaBlueDark = Color(red: 0.0, green: 0.32, blue: 0.65)

    // Semantic Status Colors
    public static let successGreen = Color(red: 0.1, green: 0.72, blue: 0.45)
    public static let errorRed = Color(red: 0.93, green: 0.28, blue: 0.28)
    public static let warningAmber = Color(red: 0.96, green: 0.62, blue: 0.12)
    public static let safetyPurple = Color(red: 0.55, green: 0.35, blue: 0.95)

    // Adaptive Backgrounds
    public static let background = Color(UIColor.systemGroupedBackground)
    public static let cardBackground = Color(UIColor.secondarySystemGroupedBackground)
    public static let cardBackgroundElevated = Color(UIColor.tertiarySystemGroupedBackground)

    // Subtle Borders
    public static let cardBorder = Color(UIColor.separator).opacity(0.4)
    public static let activeBorder = estoniaBlue.opacity(0.6)

    // Text & Subtitles
    public static let textPrimary = Color(UIColor.label)
    public static let textSecondary = Color(UIColor.secondaryLabel)
    public static let textTertiary = Color(UIColor.tertiaryLabel)
}

public extension Color {
    static let appBlue = AppColors.estoniaBlue
    static let appCardBg = AppColors.cardBackground
    static let appCardBorder = AppColors.cardBorder
    static let appSuccess = AppColors.successGreen
    static let appError = AppColors.errorRed
    static let appWarning = AppColors.warningAmber
}
