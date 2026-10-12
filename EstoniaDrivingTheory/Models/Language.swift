import Foundation

public enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case english = "en"
    case estonian = "et"
    case russian = "ru"

    public var id: String { rawValue }

    public var flag: String {
        switch self {
        case .english: return "🇬🇧"
        case .estonian: return "🇪🇪"
        case .russian: return "🇷🇺"
        }
    }

    public var displayName: String {
        switch self {
        case .english: return "English"
        case .estonian: return "Eesti"
        case .russian: return "Русский"
        }
    }

    public var subtitle: String {
        switch self {
        case .english: return "English"
        case .estonian: return "Estonian"
        case .russian: return "Russian"
        }
    }
}
