import Foundation
import SwiftUI

public enum TopicCategory: String, CaseIterable, Identifiable, Codable {
    case trafficRules = "traffic_rules"
    case rightOfWay = "right_of_way"
    case roadSigns = "road_signs"
    case roadMarkings = "road_markings"
    case speedAndDistance = "speed_and_distance"
    case overtaking = "overtaking"
    case stoppingAndParking = "stopping_and_parking"
    case pedestriansAndCyclists = "pedestrians_and_cyclists"
    case vehicleSafety = "vehicle_safety"
    case driverResponsibilities = "driver_responsibilities"
    case hazards = "hazards"
    case motorways = "motorways"
    case emergency = "emergency"
    case railwayCrossings = "railway_crossings"
    case trafficLights = "traffic_lights"
    case laneSelection = "lane_selection"

    public var id: String { rawValue }

    public static var allCases: [TopicCategory] {
        [
            .rightOfWay,
            .trafficLights,
            .roadSigns,
            .roadMarkings,
            .speedAndDistance,
            .overtaking,
            .stoppingAndParking,
            .pedestriansAndCyclists,
            .laneSelection,
            .vehicleSafety,
            .driverResponsibilities,
            .hazards,
            .motorways,
            .emergency,
            .railwayCrossings
        ]
    }

    public init?(canonical: String) {
        let normalized = canonical
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "-", with: "_")
            .replacingOccurrences(of: " ", with: "_")

        switch normalized {
        case "right_of_way", "priority", "intersections":
            self = .rightOfWay
        case "road_signs", "signs":
            self = .roadSigns
        case "road_markings", "markings":
            self = .roadMarkings
        case "speed_and_distance", "speed_distance", "speed":
            self = .speedAndDistance
        case "overtaking", "overtake":
            self = .overtaking
        case "stopping_and_parking", "stopping_parking", "parking":
            self = .stoppingAndParking
        case "pedestrians_and_cyclists", "pedestrians_cyclists", "pedestrians":
            self = .pedestriansAndCyclists
        case "vehicle_safety", "safety", "vehicle":
            self = .vehicleSafety
        case "driver_responsibilities", "alcohol_and_responsibility", "driver_duties_health", "driver":
            self = .driverResponsibilities
        case "hazards", "hazard_awareness", "hazards_winter_conditions", "hazard_perception":
            self = .hazards
        case "motorways", "motorway_driving", "motorways_special_roads", "motorway":
            self = .motorways
        case "emergency", "emergencies", "emergency_situations", "emergencies_first_aid":
            self = .emergency
        case "railway_crossings", "railway", "railway_crossing":
            self = .railwayCrossings
        case "traffic_lights", "traffic_lights_signals", "traffic_light":
            self = .trafficLights
        case "lane_selection", "lane_selection_positioning", "lane":
            self = .laneSelection
        case "traffic_rules":
            self = .trafficRules
        default:
            if let direct = TopicCategory(rawValue: normalized) {
                self = direct
            } else {
                return nil
            }
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        if let match = TopicCategory(canonical: raw) {
            self = match
        } else if let direct = TopicCategory(rawValue: raw) {
            self = direct
        } else {
            self = .rightOfWay
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    public var iconName: String {
        switch self {
        case .trafficRules: return "arrow.triangle.swap"
        case .rightOfWay: return "triangle.fill"
        case .roadSigns: return "shield.fill"
        case .roadMarkings: return "road.lanes.curved.right"
        case .speedAndDistance: return "gauge.with.needle"
        case .overtaking: return "arrow.left.and.right"
        case .stoppingAndParking: return "parkingsign.circle.fill"
        case .pedestriansAndCyclists: return "figure.walk"
        case .vehicleSafety: return "car.side.fill"
        case .driverResponsibilities: return "person.badge.shield.checkmark.fill"
        case .hazards: return "cloud.snow.fill"
        case .motorways: return "road.lanes"
        case .emergency: return "cross.case.fill"
        case .railwayCrossings: return "tram.fill"
        case .trafficLights: return "light.beacon.max.fill"
        case .laneSelection: return "arrow.triangle.branch"
        }
    }

    public func title(for language: AppLanguage) -> String {
        switch language {
        case .english:
            switch self {
            case .trafficRules: return "General Traffic Rules"
            case .rightOfWay: return "Right of Way & Intersections"
            case .roadSigns: return "Road Signs"
            case .roadMarkings: return "Road Markings"
            case .speedAndDistance: return "Speed & Safe Distance"
            case .overtaking: return "Overtaking & Manoeuvres"
            case .stoppingAndParking: return "Stopping & Parking"
            case .pedestriansAndCyclists: return "Pedestrians & Cyclists"
            case .vehicleSafety: return "Vehicle Safety & Maintenance"
            case .driverResponsibilities: return "Driver Duties & Health"
            case .hazards: return "Hazards & Winter Conditions"
            case .motorways: return "Motorways & Special Roads"
            case .emergency: return "Emergencies & First Aid"
            case .railwayCrossings: return "Railway Crossings"
            case .trafficLights: return "Traffic Lights & Signals"
            case .laneSelection: return "Lane Selection & Positioning"
            }
        case .estonian:
            switch self {
            case .trafficRules: return "Üldised liiklusreeglid"
            case .rightOfWay: return "Eesõigus ja ristmikud"
            case .roadSigns: return "Liiklusmärgid"
            case .roadMarkings: return "Teekattemärgised"
            case .speedAndDistance: return "Kiirus ja pikivahe"
            case .overtaking: return "Möödasõit ja manöövrid"
            case .stoppingAndParking: return "Peatumine ja parkimine"
            case .pedestriansAndCyclists: return "Jalakäijad ja jalgratturid"
            case .vehicleSafety: return "Sõiduki ohutus ja korrashoid"
            case .driverResponsibilities: return "Juhi kohustused ja tervis"
            case .hazards: return "Ohud ja talvised teeolud"
            case .motorways: return "Kiirteed ja eriolud"
            case .emergency: return "Hädaolukorrad ja esmaabi"
            case .railwayCrossings: return "Raudteeülesõidukohad"
            case .trafficLights: return "Foorid ja reguleerija märguanded"
            case .laneSelection: return "Sõiduraja valik ja paiknemine"
            }
        case .russian:
            switch self {
            case .trafficRules: return "Общие правила движения"
            case .rightOfWay: return "Преимущество и перекрестки"
            case .roadSigns: return "Дорожные знаки"
            case .roadMarkings: return "Дорожная разметка"
            case .speedAndDistance: return "Скорость и дистанция"
            case .overtaking: return "Обгон и маневрирование"
            case .stoppingAndParking: return "Остановка и стоянка"
            case .pedestriansAndCyclists: return "Пешеходы и велосипедисты"
            case .vehicleSafety: return "Безопасность автомобиля"
            case .driverResponsibilities: return "Обязанности и состояние водителя"
            case .hazards: return "Опасности и зимние условия"
            case .motorways: return "Автомагистрали и особые дороги"
            case .emergency: return "Аварийные ситуации и первая помощь"
            case .railwayCrossings: return "Железнодорожные переезды"
            case .trafficLights: return "Светофоры и регулировщик"
            case .laneSelection: return "Выбор полосы и расположение"
            }
        }
    }

    public func description(for language: AppLanguage) -> String {
        switch language {
        case .english:
            switch self {
            case .trafficRules: return "Basic principles, signals, and road usage obligations."
            case .rightOfWay: return "Unregulated and regulated intersections, roundabout rules."
            case .roadSigns: return "Warning, prohibitory, mandatory and priority signs."
            case .roadMarkings: return "Lines, arrows, zebra markings, hatched safety islands."
            case .speedAndDistance: return "Speed limits, braking distances, reaction times."
            case .overtaking: return "Safe passing, lane changing, turning and reversing."
            case .stoppingAndParking: return "Permitted and forbidden zones, parking discs."
            case .pedestriansAndCyclists: return "Zebra crossings, shared paths, cyclist priority."
            case .vehicleSafety: return "Tires, lights, braking system, seatbelts, child seats."
            case .driverResponsibilities: return "Alcohol limits, fatigue, documents, medical kit."
            case .hazards: return "Aquaplaning, ice, fog, twilight, wildlife hazards."
            case .motorways: return "Higher speed limits, entry/exit slips, towing rules."
            case .emergency: return "Warning triangle, accident reporting, CPR, calling 112."
            case .railwayCrossings: return "Barriers, flashing lights, stopping rules, stalls on tracks."
            case .trafficLights: return "Signal lights, green arrows, traffic controller gestures."
            case .laneSelection: return "Lane discipline, turning lanes, zipper merging."
            }
        case .estonian:
            switch self {
            case .trafficRules: return "Liikluse põhialused, märguanded ja üldised kohustused."
            case .rightOfWay: return "Reguleerimata ja reguleeritud ristmikud, ringristmikud."
            case .roadSigns: return "Hoiatus-, keelu-, kohustus- ja eesõigusmärgid."
            case .roadMarkings: return "Jooned, nooled, ülekäigurajad ja ohutussaared."
            case .speedAndDistance: return "Lubatud piirkiirused, pidurdusteekond, pikivahe."
            case .overtaking: return "Ohutu möödasõit, ümberreastumine, tagasipööre."
            case .stoppingAndParking: return "Lubatud ja keelatud kohad, parkimiskell."
            case .pedestriansAndCyclists: return "Ülekäigurajad, kergliiklusteed, jalgratturite eesõigus."
            case .vehicleSafety: return "Rehvid, valgustus, pidurid, turvavöö, laste turvatoolid."
            case .driverResponsibilities: return "Alkoholipiirang, väsimus, dokumendid, auto apteek."
            case .hazards: return "Vesiliug, must jää, udu, hämarus, metsloomad teel."
            case .motorways: return "Suuremad kiirused, kiirendusrajad, pukseerimine."
            case .emergency: return "Ohukolmnurk, õnnetuse vormistamine, elustamine, 112."
            case .railwayCrossings: return "Tõkkepuud, foorid, peatumisnõuded, oht raudteel."
            case .trafficLights: return "Foorituled, noolsektsioonid, reguleerija märguanded."
            case .laneSelection: return "Sõiduraja valik, paiknemine, tõmblukureegel."
            }
        case .russian:
            switch self {
            case .trafficRules: return "Основы движения, сигналы и общие обязанности водителя."
            case .rightOfWay: return "Регулируемые и нерегулируемые перекрестки, круговые развязки."
            case .roadSigns: return "Предупреждающие, запрещающие, предписывающие знаки."
            case .roadMarkings: return "Линии, стрелы, разметка переходов, островки безопасности."
            case .speedAndDistance: return "Скоростные режимы, тормозной путь, безопасная дистанция."
            case .overtaking: return "Безопасный обгон, перестроение, развороты и маневры."
            case .stoppingAndParking: return "Разрешенные и запрещенные места, парковочные часы."
            case .pedestriansAndCyclists: return "Пешеходные переходы, велодорожки, приоритет велосипедистов."
            case .vehicleSafety: return "Шины, освещение, тормоза, ремни безопасности, детские кресла."
            case .driverResponsibilities: return "Нормы алкоголя, усталость, документы, аптечка."
            case .hazards: return "Аквапланирование, гололед, туман, сумерки, лесные животные."
            case .motorways: return "Скоростные шоссе, полосы разгона, буксировка."
            case .emergency: return "Знак аварийной остановки, оформление ДТП, первая помощь, 112."
            case .railwayCrossings: return "Шлагбаумы, световая сигнализация, правила остановки."
            case .trafficLights: return "Сигналы светофора, стрелочные секции, сигналы регулировщика."
            case .laneSelection: return "Рядность движения, поворотные полосы, принцип молнии."
            }
        }
    }
}

// MARK: - Topic Icon View
public struct TopicIconView: View {
    public var topic: TopicCategory
    public var size: CGFloat
    public var color: Color

    public init(topic: TopicCategory, size: CGFloat = 20, color: Color = AppColors.estoniaBlue) {
        self.topic = topic
        self.size = size
        self.color = color
    }

    public var body: some View {
        if topic == .trafficLights {
            trafficLightIcon
        } else {
            Image(systemName: topic.iconName)
                .font(.system(size: size, weight: .semibold))
                .foregroundColor(color)
        }
    }

    private var trafficLightIcon: some View {
        VStack(spacing: size * 0.10) {
            Circle()
                .fill(color)
                .frame(width: size * 0.28, height: size * 0.28)
            Circle()
                .fill(color)
                .frame(width: size * 0.28, height: size * 0.28)
            Circle()
                .fill(color)
                .frame(width: size * 0.28, height: size * 0.28)
        }
        .padding(.vertical, size * 0.14)
        .padding(.horizontal, size * 0.12)
        .background(
            RoundedRectangle(cornerRadius: size * 0.26, style: .continuous)
                .stroke(color, lineWidth: max(1.2, size * 0.08))
        )
    }
}
