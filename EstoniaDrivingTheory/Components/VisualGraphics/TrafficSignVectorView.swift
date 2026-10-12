import SwiftUI

public struct TrafficSignVectorView: View {
    public var shape: SignShape
    public var symbolType: String
    public var speedValue: Int?
    public var size: CGFloat

    public init(shape: SignShape, symbolType: String = "", speedValue: Int? = nil, size: CGFloat = 64) {
        self.shape = shape
        self.symbolType = symbolType
        self.speedValue = speedValue
        self.size = size
    }

    public var body: some View {
        ZStack {
            switch shape {
            case .diamondPriority:
                // Sign 211: Peatee (Priority road) - Yellow diamond with white border
                ZStack {
                    RoundedRectangle(cornerRadius: size * 0.08)
                        .fill(Color.white)
                        .frame(width: size, height: size)
                        .rotationEffect(.degrees(45))
                        .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 1)

                    RoundedRectangle(cornerRadius: size * 0.04)
                        .fill(Color(red: 0.98, green: 0.82, blue: 0.05)) // Vibrant road yellow
                        .frame(width: size * 0.72, height: size * 0.72)
                        .rotationEffect(.degrees(45))
                }

            case .invertedTriangle:
                // Sign 221: Anna teed (Give Way) - Inverted triangle
                InvertedTriangle()
                    .fill(Color(red: 0.88, green: 0.15, blue: 0.12))
                    .frame(width: size * 1.1, height: size)
                    .overlay(
                        InvertedTriangle()
                            .fill(Color.white)
                            .frame(width: size * 0.78, height: size * 0.7)
                    )
                    .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 1)

            case .octagonStop:
                // Sign 222: STOP
                RegularOctagon()
                    .fill(Color(red: 0.85, green: 0.12, blue: 0.12))
                    .frame(width: size, height: size)
                    .overlay(
                        RegularOctagon()
                            .stroke(Color.white, lineWidth: size * 0.05)
                            .frame(width: size * 0.9, height: size * 0.9)
                    )
                    .overlay(
                        Text("STOP")
                            .font(.system(size: size * 0.28, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                    )
                    .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 1)

            case .triangleWarning:
                // Warning triangle (red border, white background)
                UprightTriangle()
                    .fill(Color(red: 0.88, green: 0.15, blue: 0.12))
                    .frame(width: size * 1.1, height: size)
                    .overlay(
                        UprightTriangle()
                            .fill(Color.white)
                            .frame(width: size * 0.78, height: size * 0.7)
                    )
                    .overlay(
                        renderWarningSymbol()
                            .foregroundColor(.black)
                            .padding(.top, size * 0.18)
                    )
                    .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 1)

            case .circleProhibitory:
                // Red circle with white center (or speed limit)
                ZStack {
                    Circle()
                        .fill(Color(red: 0.88, green: 0.15, blue: 0.12))
                        .frame(width: size, height: size)

                    Circle()
                        .fill(Color.white)
                        .frame(width: size * 0.74, height: size * 0.74)

                    if let speed = speedValue {
                        Text("\(speed)")
                            .font(.system(size: size * 0.36, weight: .heavy, design: .rounded))
                            .foregroundColor(.black)
                    } else if symbolType == "no_entry" {
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: size * 0.58, height: size * 0.15)
                            .clipShape(RoundedRectangle(cornerRadius: 2))
                    } else {
                        renderProhibitorySymbol()
                    }
                }
                .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 1)

            case .circleMandatory:
                // Blue circle with white arrows
                ZStack {
                    Circle()
                        .fill(Color(red: 0.02, green: 0.42, blue: 0.76))
                        .frame(width: size, height: size)

                    renderMandatorySymbol()
                        .foregroundColor(.white)
                }
                .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 1)

            case .squareBlue:
                // Information square (e.g. Pedestrian crossing 543)
                ZStack {
                    RoundedRectangle(cornerRadius: size * 0.12)
                        .fill(Color(red: 0.02, green: 0.42, blue: 0.76))
                        .frame(width: size, height: size)

                    if symbolType == "pedestrian_cross" {
                        UprightTriangle()
                            .fill(Color.white)
                            .frame(width: size * 0.72, height: size * 0.65)
                            .overlay(
                                Image(systemName: "figure.walk")
                                    .font(.system(size: size * 0.35, weight: .bold))
                                    .foregroundColor(.black)
                                    .padding(.top, size * 0.12)
                            )
                    } else if symbolType == "parking" {
                        Text("P")
                            .font(.system(size: size * 0.55, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: size * 0.45))
                            .foregroundColor(.white)
                    }
                }
                .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 1)

            case .rectanglePlate:
                ZStack {
                    RoundedRectangle(cornerRadius: size * 0.08)
                        .fill(Color.white)
                        .frame(width: size * 1.3, height: size * 0.6)
                        .overlay(
                            RoundedRectangle(cornerRadius: size * 0.08)
                                .stroke(Color.black, lineWidth: 2)
                        )
                    Text(symbolType.isEmpty ? "300 m" : symbolType)
                        .font(.system(size: size * 0.22, weight: .bold, design: .monospaced))
                        .foregroundColor(.black)
                }
            }
        }
    }

    @ViewBuilder
    private func renderWarningSymbol() -> some View {
        switch symbolType {
        case "curve_right", "111":
            Image(systemName: "arrow.turn.up.right")
                .font(.system(size: size * 0.3, weight: .heavy))
        case "curve_left", "112":
            Image(systemName: "arrow.turn.up.left")
                .font(.system(size: size * 0.3, weight: .heavy))
        case "crossroad", "121":
            Image(systemName: "plus")
                .font(.system(size: size * 0.35, weight: .heavy))
        case "pedestrian", "123":
            Image(systemName: "figure.walk")
                .font(.system(size: size * 0.32, weight: .bold))
        case "slippery", "131", "142":
            Image(systemName: "car.side.rear.open")
                .font(.system(size: size * 0.3, weight: .bold))
        case "wild_animals", "144":
            Image(systemName: "hare.fill")
                .font(.system(size: size * 0.3, weight: .bold))
        case "road_works", "132":
            Image(systemName: "cone.fill")
                .font(.system(size: size * 0.3, weight: .bold))
        case "railway_barrier", "151":
            Image(systemName: "fence.fill")
                .font(.system(size: size * 0.3, weight: .bold))
        case "railway_no_barrier", "152":
            Image(systemName: "tram.fill")
                .font(.system(size: size * 0.3, weight: .bold))
        case "two_way", "141":
            Image(systemName: "arrow.up.and.down")
                .font(.system(size: size * 0.3, weight: .heavy))
        case "railway_cross", "161":
            Image(systemName: "xmark")
                .font(.system(size: size * 0.36, weight: .black))
                .foregroundColor(Color(red: 0.88, green: 0.15, blue: 0.12))
        default:
            Image(systemName: "exclamationmark")
                .font(.system(size: size * 0.32, weight: .heavy))
        }
    }

    @ViewBuilder
    private func renderProhibitorySymbol() -> some View {
        switch symbolType {
        case "no_overtaking", "351":
            HStack(spacing: size * 0.04) {
                Image(systemName: "car.fill")
                    .foregroundColor(Color(red: 0.88, green: 0.15, blue: 0.12))
                    .font(.system(size: size * 0.22))
                Image(systemName: "car.fill")
                    .foregroundColor(.black)
                    .font(.system(size: size * 0.22))
            }
        case "end_no_overtaking", "352":
            ZStack {
                HStack(spacing: size * 0.04) {
                    Image(systemName: "car.fill")
                        .foregroundColor(Color.gray)
                        .font(.system(size: size * 0.22))
                    Image(systemName: "car.fill")
                        .foregroundColor(Color.gray)
                        .font(.system(size: size * 0.22))
                }
                Rectangle()
                    .fill(Color.black)
                    .frame(width: size * 0.7, height: 3)
                    .rotationEffect(.degrees(-45))
            }
        case "no_stopping", "361":
            ZStack {
                Circle()
                    .fill(Color(red: 0.02, green: 0.42, blue: 0.76))
                    .frame(width: size * 0.74, height: size * 0.74)
                Rectangle()
                    .fill(Color(red: 0.88, green: 0.15, blue: 0.12))
                    .frame(width: size * 0.74, height: size * 0.1)
                    .rotationEffect(.degrees(45))
                Rectangle()
                    .fill(Color(red: 0.88, green: 0.15, blue: 0.12))
                    .frame(width: size * 0.74, height: size * 0.1)
                    .rotationEffect(.degrees(-45))
            }
        case "no_parking", "362":
            ZStack {
                Circle()
                    .fill(Color(red: 0.02, green: 0.42, blue: 0.76))
                    .frame(width: size * 0.74, height: size * 0.74)
                Rectangle()
                    .fill(Color(red: 0.88, green: 0.15, blue: 0.12))
                    .frame(width: size * 0.74, height: size * 0.1)
                    .rotationEffect(.degrees(-45))
            }
        case "no_u_turn", "332":
            ZStack {
                Image(systemName: "arrow.uturn.left")
                    .font(.system(size: size * 0.32, weight: .bold))
                    .foregroundColor(.black)
                Rectangle()
                    .fill(Color(red: 0.88, green: 0.15, blue: 0.12))
                    .frame(width: size * 0.74, height: size * 0.08)
                    .rotationEffect(.degrees(-45))
            }
        case "no_left_turn", "333":
            ZStack {
                Image(systemName: "arrow.turn.up.left")
                    .font(.system(size: size * 0.32, weight: .bold))
                    .foregroundColor(.black)
                Rectangle()
                    .fill(Color(red: 0.88, green: 0.15, blue: 0.12))
                    .frame(width: size * 0.74, height: size * 0.08)
                    .rotationEffect(.degrees(-45))
            }
        case "no_pedestrians", "316":
            ZStack {
                Image(systemName: "figure.walk")
                    .font(.system(size: size * 0.32, weight: .bold))
                    .foregroundColor(.black)
                Rectangle()
                    .fill(Color(red: 0.88, green: 0.15, blue: 0.12))
                    .frame(width: size * 0.74, height: size * 0.08)
                    .rotationEffect(.degrees(-45))
            }
        default:
            Image(systemName: "slash.circle")
                .font(.system(size: size * 0.35))
                .foregroundColor(.black)
        }
    }

    @ViewBuilder
    private func renderMandatorySymbol() -> some View {
        switch symbolType {
        case "roundabout", "421":
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: size * 0.45, weight: .bold))
        case "turn_right", "412":
            Image(systemName: "arrow.right")
                .font(.system(size: size * 0.45, weight: .black))
        case "turn_left", "413":
            Image(systemName: "arrow.left")
                .font(.system(size: size * 0.45, weight: .black))
        case "straight", "411":
            Image(systemName: "arrow.up")
                .font(.system(size: size * 0.45, weight: .black))
        case "cycle_path", "431":
            Image(systemName: "bicycle")
                .font(.system(size: size * 0.4, weight: .bold))
        case "pass_left_right", "423":
            Image(systemName: "arrow.left.and.right")
                .font(.system(size: size * 0.4, weight: .bold))
        default:
            Image(systemName: "arrow.up")
                .font(.system(size: size * 0.45, weight: .black))
        }
    }

    @ViewBuilder
    public static func forSignType(_ signType: String, size: CGFloat = 84) -> some View {
        switch signType {
        case "diamondPriority", "211", "priority_road":
            TrafficSignVectorView(shape: .diamondPriority, size: size)
        case "end_priority", "212":
            ZStack {
                TrafficSignVectorView(shape: .diamondPriority, size: size)
                Rectangle()
                    .fill(Color.black)
                    .frame(width: size * 0.9, height: 4)
                    .rotationEffect(.degrees(-45))
            }
        case "give_way", "221":
            TrafficSignVectorView(shape: .invertedTriangle, size: size)
        case "stop", "222":
            TrafficSignVectorView(shape: .octagonStop, size: size)
        case "speed_30", "311_30":
            TrafficSignVectorView(shape: .circleProhibitory, speedValue: 30, size: size)
        case "speed_50", "311_50":
            TrafficSignVectorView(shape: .circleProhibitory, speedValue: 50, size: size)
        case "speed_70", "311_70":
            TrafficSignVectorView(shape: .circleProhibitory, speedValue: 70, size: size)
        case "speed_90", "311_90":
            TrafficSignVectorView(shape: .circleProhibitory, speedValue: 90, size: size)
        case "no_entry", "331":
            TrafficSignVectorView(shape: .circleProhibitory, symbolType: "no_entry", size: size)
        case "no_overtaking", "351":
            TrafficSignVectorView(shape: .circleProhibitory, symbolType: "no_overtaking", size: size)
        case "end_no_overtaking", "352":
            TrafficSignVectorView(shape: .circleProhibitory, symbolType: "end_no_overtaking", size: size)
        case "no_stopping", "361":
            TrafficSignVectorView(shape: .circleProhibitory, symbolType: "no_stopping", size: size)
        case "no_parking", "362":
            TrafficSignVectorView(shape: .circleProhibitory, symbolType: "no_parking", size: size)
        case "no_u_turn", "332":
            TrafficSignVectorView(shape: .circleProhibitory, symbolType: "no_u_turn", size: size)
        case "no_left_turn", "333":
            TrafficSignVectorView(shape: .circleProhibitory, symbolType: "no_left_turn", size: size)
        case "no_pedestrians", "316":
            TrafficSignVectorView(shape: .circleProhibitory, symbolType: "no_pedestrians", size: size)
        case "roundabout", "421":
            TrafficSignVectorView(shape: .circleMandatory, symbolType: "roundabout", size: size)
        case "turn_right", "412":
            TrafficSignVectorView(shape: .circleMandatory, symbolType: "turn_right", size: size)
        case "turn_left", "413":
            TrafficSignVectorView(shape: .circleMandatory, symbolType: "turn_left", size: size)
        case "straight", "411", "mandatory_straight":
            TrafficSignVectorView(shape: .circleMandatory, symbolType: "straight", size: size)
        case "cycle_path", "431":
            TrafficSignVectorView(shape: .circleMandatory, symbolType: "cycle_path", size: size)
        case "pedestrian_cross", "543":
            TrafficSignVectorView(shape: .squareBlue, symbolType: "pedestrian_cross", size: size)
        case "parking", "575":
            TrafficSignVectorView(shape: .squareBlue, symbolType: "parking", size: size)
        case "residential_zone", "573":
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.12)
                    .fill(Color(red: 0.02, green: 0.42, blue: 0.76))
                    .frame(width: size, height: size)
                VStack(spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "house.fill")
                            .font(.system(size: size * 0.28))
                        Image(systemName: "figure.walk")
                            .font(.system(size: size * 0.26))
                    }
                    Image(systemName: "car.fill")
                        .font(.system(size: size * 0.28))
                }
                .foregroundColor(.white)
            }
        case "motorway", "511":
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.12)
                    .fill(Color(red: 0.05, green: 0.5, blue: 0.3)) // Green background for motorway
                    .frame(width: size, height: size)
                HStack(spacing: 6) {
                    Rectangle().fill(Color.white).frame(width: 4, height: size * 0.6)
                    Rectangle().fill(Color.white).frame(width: size * 0.4, height: 4)
                    Rectangle().fill(Color.white).frame(width: 4, height: size * 0.6)
                }
            }
        case "one_way", "521":
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.12)
                    .fill(Color(red: 0.02, green: 0.42, blue: 0.76))
                    .frame(width: size, height: size)
                Image(systemName: "arrow.up")
                    .font(.system(size: size * 0.5, weight: .black))
                    .foregroundColor(.white)
            }
        case "dead_end", "531":
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.12)
                    .fill(Color(red: 0.02, green: 0.42, blue: 0.76))
                    .frame(width: size, height: size)
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: size * 0.44, height: size * 0.1)
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: size * 0.1, height: size * 0.36)
                }
            }
        case "bus_lane", "545":
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.12)
                    .fill(Color(red: 0.02, green: 0.42, blue: 0.76))
                    .frame(width: size, height: size)
                VStack(spacing: 2) {
                    Image(systemName: "bus.fill")
                        .font(.system(size: size * 0.35))
                        .foregroundColor(.white)
                    Text("A")
                        .font(.system(size: size * 0.28, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }
            }
        case "curve_right", "111":
            TrafficSignVectorView(shape: .triangleWarning, symbolType: "curve_right", size: size)
        case "curve_left", "112":
            TrafficSignVectorView(shape: .triangleWarning, symbolType: "curve_left", size: size)
        case "crossroad", "121":
            TrafficSignVectorView(shape: .triangleWarning, symbolType: "crossroad", size: size)
        case "pedestrian", "123":
            TrafficSignVectorView(shape: .triangleWarning, symbolType: "pedestrian", size: size)
        case "slippery", "131", "142":
            TrafficSignVectorView(shape: .triangleWarning, symbolType: "slippery", size: size)
        case "wild_animals", "144":
            TrafficSignVectorView(shape: .triangleWarning, symbolType: "wild_animals", size: size)
        case "road_works", "132":
            TrafficSignVectorView(shape: .triangleWarning, symbolType: "road_works", size: size)
        case "railway_barrier", "151":
            TrafficSignVectorView(shape: .triangleWarning, symbolType: "railway_barrier", size: size)
        case "railway_no_barrier", "152":
            TrafficSignVectorView(shape: .triangleWarning, symbolType: "railway_no_barrier", size: size)
        case "two_way", "141":
            TrafficSignVectorView(shape: .triangleWarning, symbolType: "two_way", size: size)
        case "railway_cross", "161", "162":
            TrafficSignVectorView(shape: .triangleWarning, symbolType: "railway_cross", size: size)
        default:
            TrafficSignVectorView(shape: .diamondPriority, size: size)
        }
    }
}

// Geometric shapes for road signs
struct InvertedTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct UprightTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct RegularOctagon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let sideCut = rect.width * 0.2929
        path.move(to: CGPoint(x: rect.minX + sideCut, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - sideCut, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + sideCut))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - sideCut))
        path.addLine(to: CGPoint(x: rect.maxX - sideCut, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + sideCut, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - sideCut))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + sideCut))
        path.closeSubpath()
        return path
    }
}
