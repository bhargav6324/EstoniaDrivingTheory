import SwiftUI

public struct VehicleVectorView: View {
    public var vehicle: VehicleInScenario
    public var width: CGFloat
    public var length: CGFloat

    public init(vehicle: VehicleInScenario, width: CGFloat = 34, length: CGFloat = 58) {
        self.vehicle = vehicle
        self.width = width
        self.length = length
    }

    public var body: some View {
        ZStack {
            // Wheels
            VStack {
                HStack {
                    wheel()
                    Spacer()
                    wheel()
                }
                Spacer()
                HStack {
                    wheel()
                    Spacer()
                    wheel()
                }
            }
            .frame(width: width + 6, height: length * 0.78)

            // Car Body
            RoundedRectangle(cornerRadius: width * 0.28, style: .continuous)
                .fill(vehicle.color.swiftUIColor)
                .frame(width: width, height: length)
                .overlay(
                    RoundedRectangle(cornerRadius: width * 0.28, style: .continuous)
                        .stroke(Color.black.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 2)

            // Cabin / Roof
            VStack(spacing: 3) {
                // Front windshield
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(white: 0.15).opacity(0.85))
                    .frame(width: width * 0.72, height: length * 0.18)

                // Roof with Label
                RoundedRectangle(cornerRadius: 4)
                    .fill(vehicle.color.swiftUIColor.opacity(0.9))
                    .frame(width: width * 0.68, height: length * 0.28)
                    .overlay(
                        Text(vehicle.isUser ? "YOU" : vehicle.label)
                            .font(.system(size: vehicle.isUser ? 9 : 11, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                    )

                // Rear window
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(white: 0.15).opacity(0.85))
                    .frame(width: width * 0.65, height: length * 0.12)
            }

            // Headlights & Tail lights
            VStack {
                // Front headlights
                HStack {
                    Circle()
                        .fill(Color(red: 1.0, green: 0.95, blue: 0.6))
                        .frame(width: 5, height: 5)
                    Spacer()
                    Circle()
                        .fill(Color(red: 1.0, green: 0.95, blue: 0.6))
                        .frame(width: 5, height: 5)
                }
                .padding(.horizontal, 4)
                .padding(.top, 3)

                Spacer()

                // Rear brake lights
                HStack {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color(red: 0.9, green: 0.1, blue: 0.1))
                        .frame(width: 6, height: 3)
                    Spacer()
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color(red: 0.9, green: 0.1, blue: 0.1))
                        .frame(width: 6, height: 3)
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 2)
            }
            .frame(width: width, height: length)
        }
    }

    private func wheel() -> some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color.black.opacity(0.85))
            .frame(width: 4, height: 11)
    }
}
