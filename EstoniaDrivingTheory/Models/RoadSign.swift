import Foundation
import SwiftUI

public enum RoadSignCategory: String, CaseIterable, Identifiable, Codable {
    case warning = "warning"
    case priority = "priority"
    case prohibitory = "prohibitory"
    case mandatory = "mandatory"
    case specialRegulation = "special_regulation"
    case information = "information"
    case additionalPlate = "additional_plate"

    public var id: String { rawValue }

    public func title(for language: AppLanguage) -> String {
        switch language {
        case .english:
            switch self {
            case .warning: return "Warning Signs"
            case .priority: return "Priority Signs"
            case .prohibitory: return "Prohibitory Signs"
            case .mandatory: return "Mandatory Signs"
            case .specialRegulation: return "Special Regulation Signs"
            case .information: return "Information Signs"
            case .additionalPlate: return "Supplementary Plates"
            }
        case .estonian:
            switch self {
            case .warning: return "Hoiatusmärgid"
            case .priority: return "Eesõigusmärgid"
            case .prohibitory: return "Keelumärgid"
            case .mandatory: return "Kohustusmärgid"
            case .specialRegulation: return "Osutusmärgid"
            case .information: return "Juhatusmärgid"
            case .additionalPlate: return "Lisatahvlid"
            }
        case .russian:
            switch self {
            case .warning: return "Предупреждающие знаки"
            case .priority: return "Знаки приоритета"
            case .prohibitory: return "Запрещающие знаки"
            case .mandatory: return "Предписывающие знаки"
            case .specialRegulation: return "Знаки особых предписаний"
            case .information: return "Информационные знаки"
            case .additionalPlate: return "Таблички доп. информации"
            }
        }
    }
}

public enum SignShape: String, Codable {
    case triangleWarning // Upright red border, white inside
    case invertedTriangle // Give Way (221)
    case octagonStop // Stop sign (222)
    case diamondPriority // Priority Road (211)
    case circleProhibitory // Red border circle (311)
    case circleMandatory // Blue round circle (411)
    case squareBlue // Square blue information/special (543)
    case rectanglePlate // White/yellow supplementary plate
}

public struct LocalizedSignContent: Codable {
    public var name: String
    public var meaning: String
    public var legalRule: String?

    public init(name: String, meaning: String, legalRule: String? = nil) {
        self.name = name
        self.meaning = meaning
        self.legalRule = legalRule
    }
}

public struct RoadSign: Identifiable, Codable {
    public var id: String
    public var code: String // e.g. "111", "221", "311a"
    public var category: RoadSignCategory
    public var shape: SignShape
    public var symbolType: String // e.g. "curve_right", "give_way", "stop", "speed_50", "pedestrian_cross"
    public var speedValue: Int?
    public var translations: [String: LocalizedSignContent]

    public init(
        id: String,
        code: String,
        category: RoadSignCategory,
        shape: SignShape,
        symbolType: String,
        speedValue: Int? = nil,
        translations: [String: LocalizedSignContent]
    ) {
        self.id = id
        self.code = code
        self.category = category
        self.shape = shape
        self.symbolType = symbolType
        self.speedValue = speedValue
        self.translations = translations
    }

    public func content(for language: AppLanguage) -> LocalizedSignContent {
        if let direct = translations[language.rawValue] {
            return direct
        }
        if let english = translations[AppLanguage.english.rawValue] {
            return english
        }
        return LocalizedSignContent(name: "Sign \(code)", meaning: "")
    }

    public func name(for language: AppLanguage) -> String {
        content(for: language).name
    }

    public func meaning(for language: AppLanguage) -> String {
        content(for: language).meaning
    }
}
