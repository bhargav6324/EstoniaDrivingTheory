import SwiftUI

public struct TrafficLightVectorView: View {
    public var activeState: String // "red", "yellow" / "amber", "green"
    public var scale: CGFloat

    public init(activeState: String = "green", scale: CGFloat = 1.0) {
        self.activeState = activeState.lowercased()
        self.scale = scale
    }

    public var body: some View {
        VStack(spacing: 4 * scale) {
            lightLens(color: Color(red: 0.95, green: 0.2, blue: 0.2), isActive: activeState == "red")
            lightLens(color: Color(red: 0.98, green: 0.72, blue: 0.1), isActive: activeState == "yellow" || activeState == "amber")
            lightLens(color: Color(red: 0.15, green: 0.85, blue: 0.4), isActive: activeState == "green")
        }
        .padding(6 * scale)
        .background(
            RoundedRectangle(cornerRadius: 8 * scale, style: .continuous)
                .fill(Color(white: 0.15))
                .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8 * scale, style: .continuous)
                .stroke(Color(white: 0.25), lineWidth: 1)
        )
    }

    private func lightLens(color: Color, isActive: Bool) -> some View {
        Circle()
            .fill(isActive ? color : color.opacity(0.2))
            .frame(width: 14 * scale, height: 14 * scale)
            .overlay(
                Circle()
                    .stroke(Color.black.opacity(0.4), lineWidth: 1)
            )
            .shadow(color: isActive ? color.opacity(0.8) : .clear, radius: 4)
    }
}
