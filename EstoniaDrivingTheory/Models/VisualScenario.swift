import Foundation
import SwiftUI

public enum VisualType: String, Codable {
    case intersection
    case roadSign
    case trafficLight
    case laneMarking
}

public enum IntersectionLayout: String, Codable {
    case crossroadFourWay = "four_way"
    case tJunction = "t_junction"
    case roundabout = "roundabout"

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        switch raw {
        case "four_way", "crossroadFourWay", "crossroad_four_way", "fourWay":
            self = .crossroadFourWay
        case "t_junction", "tJunction":
            self = .tJunction
        case "roundabout":
            self = .roundabout
        default:
            self = .crossroadFourWay
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

public enum PrioritySetting: String, Codable {
    case equalRoads = "equal_roads" // Right hand rule applies
    case verticalPriority = "vertical_priority" // Top/Bottom has priority
    case horizontalPriority = "horizontal_priority" // Left/Right has priority
    case priorityTurnsLeft = "priority_turns_left"
    case priorityTurnsRight = "priority_turns_right"

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        switch raw {
        case "equal_roads", "equalRoads":
            self = .equalRoads
        case "vertical_priority", "verticalPriority", "mainRoadStraight", "main_road_straight":
            self = .verticalPriority
        case "horizontal_priority", "horizontalPriority":
            self = .horizontalPriority
        case "priority_turns_left", "priorityTurnsLeft":
            self = .priorityTurnsLeft
        case "priority_turns_right", "priorityTurnsRight":
            self = .priorityTurnsRight
        default:
            self = .equalRoads
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

public enum VehiclePosition: String, Codable {
    case bottom = "bottom" // Typically the user's car
    case top = "top"
    case left = "left"
    case right = "right"
}

public enum VehicleTurn: String, Codable {
    case straight = "straight"
    case turnLeft = "turn_left"
    case turnRight = "turn_right"
    case uTurn = "u_turn"
}

public enum VehicleColor: String, Codable {
    case blue = "blue"
    case red = "red"
    case silver = "silver"
    case yellow = "yellow"
    case green = "green"

    public var swiftUIColor: Color {
        switch self {
        case .blue: return Color(red: 0.05, green: 0.45, blue: 0.85)
        case .red: return Color(red: 0.85, green: 0.2, blue: 0.2)
        case .silver: return Color(red: 0.65, green: 0.7, blue: 0.75)
        case .yellow: return Color(red: 0.95, green: 0.75, blue: 0.1)
        case .green: return Color(red: 0.15, green: 0.65, blue: 0.35)
        }
    }
}

public struct VehicleInScenario: Codable, Identifiable {
    public var id: String
    public var position: VehiclePosition
    public var turn: VehicleTurn
    public var color: VehicleColor
    public var label: String // e.g. "A", "B", "You"
    public var isUser: Bool

    public init(id: String, position: VehiclePosition, turn: VehicleTurn, color: VehicleColor, label: String, isUser: Bool = false) {
        self.id = id
        self.position = position
        self.turn = turn
        self.color = color
        self.label = label
        self.isUser = isUser
    }

    enum CodingKeys: String, CodingKey {
        case id, position, turn, color, label, isUser
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        self.position = try container.decode(VehiclePosition.self, forKey: .position)
        self.turn = try container.decode(VehicleTurn.self, forKey: .turn)
        self.color = try container.decode(VehicleColor.self, forKey: .color)
        self.label = try container.decodeIfPresent(String.self, forKey: .label) ?? ""
        self.isUser = try container.decodeIfPresent(Bool.self, forKey: .isUser) ?? false
    }
}

public struct PedestrianInScenario: Codable, Identifiable {
    public var id: String
    public var position: VehiclePosition // which branch they are crossing
    public var isCrossing: Bool

    public init(id: String, position: VehiclePosition, isCrossing: Bool = true) {
        self.id = id
        self.position = position
        self.isCrossing = isCrossing
    }

    enum CodingKeys: String, CodingKey {
        case id, position, isCrossing
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        self.position = try container.decode(VehiclePosition.self, forKey: .position)
        self.isCrossing = try container.decodeIfPresent(Bool.self, forKey: .isCrossing) ?? true
    }
}

public struct VisualConfiguration: Codable {
    public var type: VisualType
    public var intersectionLayout: IntersectionLayout?
    public var prioritySetting: PrioritySetting?
    public var vehicles: [VehicleInScenario]?
    public var pedestrians: [PedestrianInScenario]?
    public var hasPedestrianCrossing: Bool?
    public var signType: String?
    public var trafficLightState: String? // "red", "yellow", "green"

    public init(
        type: VisualType,
        intersectionLayout: IntersectionLayout? = nil,
        prioritySetting: PrioritySetting? = nil,
        vehicles: [VehicleInScenario]? = nil,
        pedestrians: [PedestrianInScenario]? = nil,
        hasPedestrianCrossing: Bool? = nil,
        signType: String? = nil,
        trafficLightState: String? = nil
    ) {
        self.type = type
        self.intersectionLayout = intersectionLayout
        self.prioritySetting = prioritySetting
        self.vehicles = vehicles
        self.pedestrians = pedestrians
        self.hasPedestrianCrossing = hasPedestrianCrossing
        self.signType = signType
        self.trafficLightState = trafficLightState
    }
}
