import SwiftUI

public struct RoadSignDetailView: View {
    public var sign: RoadSign
    @ObservedObject private var localization = LocalizationManager.shared
    @Environment(\.presentationMode) private var presentationMode

    public init(sign: RoadSign) {
        self.sign = sign
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Vector Sign Preview
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(AppColors.cardBackgroundElevated)
                        .frame(height: 180)

                    TrafficSignVectorView(
                        shape: sign.shape,
                        symbolType: sign.symbolType,
                        speedValue: sign.speedValue,
                        size: 110
                    )
                }
                .padding(.top, 12)

                // Sign Code & Category
                HStack(spacing: 8) {
                    Text(localization.t(.signCode(sign.code)))
                        .font(.system(.subheadline, design: .monospaced).bold())
                        .foregroundColor(AppColors.estoniaBlue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(AppColors.estoniaBlue.opacity(0.12))
                        .clipShape(Capsule())

                    Text(sign.category.title(for: localization.currentLanguage))
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }

                // Title & Meaning Card
                VStack(alignment: .leading, spacing: 14) {
                    Text(sign.name(for: localization.currentLanguage))
                        .font(.system(.title3, design: .rounded).bold())
                        .foregroundColor(AppColors.textPrimary)

                    Divider()

                    Text(sign.meaning(for: localization.currentLanguage))
                        .font(.body)
                        .foregroundColor(AppColors.textPrimary)
                        .lineSpacing(3)

                    if let rule = sign.content(for: localization.currentLanguage).legalRule {
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "book.closed.fill")
                                .font(.caption)
                                .foregroundColor(AppColors.estoniaBlue)
                                .padding(.top, 2)
                            Text(rule)
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        .padding(.top, 4)
                    }
                }
                .appCard(padding: 20)

                Spacer(minLength: 20)
            }
            .padding(20)
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle(sign.name(for: localization.currentLanguage))
        .navigationBarTitleDisplayMode(.inline)
    }
}
