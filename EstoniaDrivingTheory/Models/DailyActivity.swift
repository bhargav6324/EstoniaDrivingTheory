import Foundation

// MARK: - Daily Activity Record

/// Stores a summary of study activity for a single calendar day.
public struct DailyActivity: Codable, Identifiable {
    public var id: String { dateKey }

    /// ISO date string "yyyy-MM-dd" used as stable key
    public var dateKey: String
    public var questionsAnswered: Int
    public var correctAnswers: Int
    public var mockExamsCompleted: Int

    public init(dateKey: String, questionsAnswered: Int = 0, correctAnswers: Int = 0, mockExamsCompleted: Int = 0) {
        self.dateKey = dateKey
        self.questionsAnswered = questionsAnswered
        self.correctAnswers = correctAnswers
        self.mockExamsCompleted = mockExamsCompleted
    }

    /// Accuracy 0–100 for the day; 0 if no questions answered.
    public var accuracyPercentage: Int {
        guard questionsAnswered > 0 else { return 0 }
        return Int(Double(correctAnswers) / Double(questionsAnswered) * 100)
    }

    /// Activity intensity level based on questions answered.
    public var intensityLevel: ActivityIntensity {
        switch questionsAnswered {
        case 0:       return .none
        case 1...9:   return .light
        case 10...24: return .medium
        default:      return .strong
        }
    }
}

public enum ActivityIntensity: Int, Codable {
    case none   = 0
    case light  = 1
    case medium = 2
    case strong = 3
}

// MARK: - Daily Goal Settings

/// User-configured daily study goal, stored locally.
public struct DailyGoal: Codable {
    public var targetQuestions: Int
    public var reminderEnabled: Bool
    /// Hour (0-23) for the local daily reminder
    public var reminderHour: Int
    /// Minute (0-59) for the local daily reminder
    public var reminderMinute: Int

    public static let `default` = DailyGoal(
        targetQuestions: 10,
        reminderEnabled: false,
        reminderHour: 19,
        reminderMinute: 0
    )

    public init(targetQuestions: Int, reminderEnabled: Bool, reminderHour: Int, reminderMinute: Int) {
        self.targetQuestions = targetQuestions
        self.reminderEnabled = reminderEnabled
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
    }

    public var reminderTime: DateComponents {
        var c = DateComponents()
        c.hour = reminderHour
        c.minute = reminderMinute
        return c
    }

    /// Human-readable reminder time string, e.g. "7:00 PM"
    public var formattedReminderTime: String {
        var c = DateComponents()
        c.hour = reminderHour
        c.minute = reminderMinute
        guard let date = Calendar.current.date(from: c) else { return "\(reminderHour):\(String(format: "%02d", reminderMinute))" }
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return f.string(from: date)
    }
}

// MARK: - Exam Readiness Result

/// The output of a centralized readiness calculation.
public struct ReadinessResult {
    /// nil means "not enough data yet"
    public var percentage: Int?
    public var hasEnoughData: Bool { percentage != nil }
    public var mockWeight: Double
    public var practiceWeight: Double
    public var topicWeight: Double
    public var masteryWeight: Double

    public static let notEnoughData = ReadinessResult(percentage: nil, mockWeight: 0, practiceWeight: 0, topicWeight: 0, masteryWeight: 0)

    public init(percentage: Int?, mockWeight: Double, practiceWeight: Double, topicWeight: Double, masteryWeight: Double) {
        self.percentage = percentage
        self.mockWeight = mockWeight
        self.practiceWeight = practiceWeight
        self.topicWeight = topicWeight
        self.masteryWeight = masteryWeight
    }
}
