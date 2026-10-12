import SwiftUI

public struct IntersectionView: View {
    public var config: VisualConfiguration
    public var height: CGFloat

    public init(config: VisualConfiguration, height: CGFloat = 220) {
        self.config = config
        self.height = height
    }

    public var body: some View {
        ZStack {
            // Grass / Ground Base
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(red: 0.22, green: 0.42, blue: 0.28)) // Nordic grass green

            // Roads Canvas
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                let roadWidth: CGFloat = min(w, h) * 0.38
                let asphalt = Color(red: 0.24, green: 0.26, blue: 0.28)

                if config.intersectionLayout == .roundabout {
                    // Roundabout Road Layout
                    Circle()
                        .fill(asphalt)
                        .frame(width: roadWidth * 2.1, height: roadWidth * 2.1)
                        .position(x: w / 2, y: h / 2)

                    // Vertical and Horizontal approach roads
                    Rectangle()
                        .fill(asphalt)
                        .frame(width: roadWidth, height: h)
                        .position(x: w / 2, y: h / 2)

                    Rectangle()
                        .fill(asphalt)
                        .frame(width: w, height: roadWidth)
                        .position(x: w / 2, y: h / 2)

                    // Center Island
                    Circle()
                        .fill(Color(red: 0.22, green: 0.42, blue: 0.28))
                        .frame(width: roadWidth * 0.9, height: roadWidth * 0.9)
                        .position(x: w / 2, y: h / 2)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.8), lineWidth: 3)
                                .frame(width: roadWidth * 0.9, height: roadWidth * 0.9)
                                .position(x: w / 2, y: h / 2)
                        )
                } else if config.intersectionLayout == .tJunction {
                    // T-Junction: Horizontal road and Bottom vertical road
                    Rectangle()
                        .fill(asphalt)
                        .frame(width: w, height: roadWidth)
                        .position(x: w / 2, y: h * 0.4)

                    Rectangle()
                        .fill(asphalt)
                        .frame(width: roadWidth, height: h * 0.6)
                        .position(x: w / 2, y: h * 0.7)
                } else {
                    // Standard 4-Way Crossroad
                    // Vertical road
                    Rectangle()
                        .fill(asphalt)
                        .frame(width: roadWidth, height: h)
                        .position(x: w / 2, y: h / 2)

                    // Horizontal road
                    Rectangle()
                        .fill(asphalt)
                        .frame(width: w, height: roadWidth)
                        .position(x: w / 2, y: h / 2)

                    // Center Dashed Guidelines
                    Path { path in
                        // Vertical dashed lines
                        path.move(to: CGPoint(x: w / 2, y: 0))
                        path.addLine(to: CGPoint(x: w / 2, y: (h - roadWidth) / 2))

                        path.move(to: CGPoint(x: w / 2, y: (h + roadWidth) / 2))
                        path.addLine(to: CGPoint(x: w / 2, y: h))

                        // Horizontal dashed lines
                        path.move(to: CGPoint(x: 0, y: h / 2))
                        path.addLine(to: CGPoint(x: (w - roadWidth) / 2, y: h / 2))

                        path.move(to: CGPoint(x: (w + roadWidth) / 2, y: h / 2))
                        path.addLine(to: CGPoint(x: w, y: h / 2))
                    }
                    .stroke(Color.white.opacity(0.7), style: StrokeStyle(lineWidth: 2, dash: [6, 6]))

                    // Zebra Pedestrian Crossing if configured
                    if config.hasPedestrianCrossing == true {
                        pedestrianCrossing(w: roadWidth, h: 22)
                            .position(x: w / 2, y: (h + roadWidth) / 2 + 18)
                    }

                    // Render Priority signs
                    if let priority = config.prioritySetting {
                        switch priority {
                        case .verticalPriority:
                            // Priority diamond on bottom & top, give way on left & right
                            TrafficSignVectorView(shape: .diamondPriority, size: 22)
                                .position(x: w / 2 + roadWidth / 2 + 14, y: (h + roadWidth) / 2 + 10)
                            TrafficSignVectorView(shape: .invertedTriangle, size: 20)
                                .position(x: (w - roadWidth) / 2 - 14, y: h / 2 + roadWidth / 2 + 12)
                        case .horizontalPriority:
                            TrafficSignVectorView(shape: .diamondPriority, size: 22)
                                .position(x: (w + roadWidth) / 2 + 14, y: h / 2 - roadWidth / 2 - 10)
                            TrafficSignVectorView(shape: .invertedTriangle, size: 20)
                                .position(x: w / 2 + roadWidth / 2 + 14, y: (h + roadWidth) / 2 + 10)
                        default:
                            EmptyView()
                        }
                    }
                }

                // Traffic Light if present
                if let state = config.trafficLightState {
                    TrafficLightVectorView(activeState: state, scale: 0.8)
                        .position(x: w / 2 + roadWidth / 2 + 18, y: (h + roadWidth) / 2 + 2)
                }

                // Render Vehicles
                if let vehicles = config.vehicles {
                    ForEach(vehicles) { vehicle in
                        renderVehicle(vehicle, in: geo, roadWidth: roadWidth)
                    }
                }
            }
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppColors.cardBorder, lineWidth: 1)
        )
    }

    @ViewBuilder
    private func renderVehicle(_ vehicle: VehicleInScenario, in geo: GeometryProxy, roadWidth: CGFloat) -> some View {
        let w = geo.size.width
        let h = geo.size.height
        let laneOffset = roadWidth * 0.24

        let (pos, rotation) = vehiclePositionAndRotation(vehicle.position, in: geo, roadWidth: roadWidth, laneOffset: laneOffset)

        ZStack {
            // Trajectory Arrow
            trajectoryArrow(turn: vehicle.turn, vehiclePos: vehicle.position, roadWidth: roadWidth)

            // Vehicle
            VehicleVectorView(vehicle: vehicle, width: 28, length: 50)
                .rotationEffect(.degrees(rotation))
        }
        .position(pos)
    }

    private func vehiclePositionAndRotation(
        _ pos: VehiclePosition,
        in geo: GeometryProxy,
        roadWidth: CGFloat,
        laneOffset: CGFloat
    ) -> (CGPoint, Double) {
        let w = geo.size.width
        let h = geo.size.height

        switch pos {
        case .bottom:
            // Heading north (0 deg) on right lane
            return (CGPoint(x: w / 2 + laneOffset, y: h * 0.82), 0)
        case .top:
            // Heading south (180 deg) on right lane
            return (CGPoint(x: w / 2 - laneOffset, y: h * 0.18), 180)
        case .left:
            // Heading east (90 deg) on right lane
            return (CGPoint(x: w * 0.18, y: h / 2 + laneOffset), 90)
        case .right:
            // Heading west (270 deg) on right lane
            return (CGPoint(x: w * 0.82, y: h / 2 - laneOffset), 270)
        }
    }

    @ViewBuilder
    private func trajectoryArrow(turn: VehicleTurn, vehiclePos: VehiclePosition, roadWidth: CGFloat) -> some View {
        switch turn {
        case .straight:
            Image(systemName: "arrow.up")
                .font(.system(size: 20, weight: .black))
                .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.1))
                .offset(y: -42)
                .shadow(color: .black.opacity(0.4), radius: 2)
        case .turnLeft:
            Image(systemName: "arrow.turn.up.left")
                .font(.system(size: 20, weight: .black))
                .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.1))
                .offset(x: -16, y: -38)
                .shadow(color: .black.opacity(0.4), radius: 2)
        case .turnRight:
            Image(systemName: "arrow.turn.up.right")
                .font(.system(size: 20, weight: .black))
                .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.1))
                .offset(x: 16, y: -38)
                .shadow(color: .black.opacity(0.4), radius: 2)
        case .uTurn:
            Image(systemName: "arrow.uturn.backward")
                .font(.system(size: 20, weight: .black))
                .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.1))
                .offset(x: -16, y: -30)
                .shadow(color: .black.opacity(0.4), radius: 2)
        }
    }

    private func pedestrianCrossing(w: CGFloat, h: CGFloat) -> some View {
        HStack(spacing: 4) {
            ForEach(0..<6) { _ in
                Rectangle()
                    .fill(Color.white)
                    .frame(width: (w - 30) / 6, height: h)
            }
        }
    }
}
