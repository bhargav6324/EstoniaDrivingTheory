import Foundation

public struct ExamConfiguration: Codable, Equatable {
    public var questionCount: Int
    public var durationMinutes: Int
    public var maxAllowedErrors: Int
    public var safetyQuestionCount: Int
    public var maxAllowedSafetyErrors: Int

    public static let estonianCategoryB = ExamConfiguration(
        questionCount: 40,
        durationMinutes: 30,
        maxAllowedErrors: 5,
        safetyQuestionCount: 10,
        maxAllowedSafetyErrors: 1
    )

    public var durationSeconds: Int {
        durationMinutes * 60
    }

    public var passingScoreMinimum: Int {
        questionCount - maxAllowedErrors
    }
}

public struct TopicScoreSummary: Codable, Identifiable {
    public var topic: TopicCategory
    public var correctCount: Int
    public var totalCount: Int

    public var id: String { topic.rawValue }

    public var percentage: Int {
        guard totalCount > 0 else { return 0 }
        return Int(Double(correctCount) / Double(totalCount) * 100)
    }
}

public struct ExamQuestionRecord: Identifiable, Codable {
    public var id: String { questionId }
    public var questionId: String
    public var selectedAnswer: Int?
    public var correctAnswer: Int
    public var isCorrect: Bool
    public var wasMarkedForReview: Bool
    public var topic: TopicCategory
    public var isSafetyQuestion: Bool

    public init(
        questionId: String,
        selectedAnswer: Int?,
        correctAnswer: Int,
        isCorrect: Bool,
        wasMarkedForReview: Bool,
        topic: TopicCategory,
        isSafetyQuestion: Bool
    ) {
        self.questionId = questionId
        self.selectedAnswer = selectedAnswer
        self.correctAnswer = correctAnswer
        self.isCorrect = isCorrect
        self.wasMarkedForReview = wasMarkedForReview
        self.topic = topic
        self.isSafetyQuestion = isSafetyQuestion
    }
}

public struct ExamResult: Identifiable, Codable {
    public var id: UUID
    public var date: Date
    public var score: Int
    public var totalQuestions: Int
    public var safetyErrors: Int
    public var maxAllowedErrors: Int
    public var maxAllowedSafetyErrors: Int
    public var timeSpentSeconds: Int
    public var passed: Bool
    public var questionIds: [String]
    public var userAnswers: [String: Int] // questionId -> selectedIndex
    public var flaggedQuestionIds: [String]
    public var questionRecords: [ExamQuestionRecord]
    public var topicScores: [TopicScoreSummary]

    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        score: Int,
        totalQuestions: Int,
        safetyErrors: Int,
        maxAllowedErrors: Int = 5,
        maxAllowedSafetyErrors: Int = 1,
        timeSpentSeconds: Int,
        passed: Bool,
        questionIds: [String],
        userAnswers: [String: Int],
        flaggedQuestionIds: [String] = [],
        questionRecords: [ExamQuestionRecord] = [],
        topicScores: [TopicScoreSummary] = []
    ) {
        self.id = id
        self.date = date
        self.score = score
        self.totalQuestions = totalQuestions
        self.safetyErrors = safetyErrors
        self.maxAllowedErrors = maxAllowedErrors
        self.maxAllowedSafetyErrors = maxAllowedSafetyErrors
        self.timeSpentSeconds = timeSpentSeconds
        self.passed = passed
        self.questionIds = questionIds
        self.userAnswers = userAnswers
        self.flaggedQuestionIds = flaggedQuestionIds
        self.questionRecords = questionRecords
        self.topicScores = topicScores
    }

    enum CodingKeys: String, CodingKey {
        case id, date, score, totalQuestions, safetyErrors
        case maxAllowedErrors, maxAllowedSafetyErrors, timeSpentSeconds
        case passed, questionIds, userAnswers, flaggedQuestionIds, questionRecords, topicScores
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        date = try container.decodeIfPresent(Date.self, forKey: .date) ?? Date()
        score = try container.decode(Int.self, forKey: .score)
        totalQuestions = try container.decode(Int.self, forKey: .totalQuestions)
        safetyErrors = try container.decode(Int.self, forKey: .safetyErrors)
        maxAllowedErrors = try container.decodeIfPresent(Int.self, forKey: .maxAllowedErrors) ?? 5
        maxAllowedSafetyErrors = try container.decodeIfPresent(Int.self, forKey: .maxAllowedSafetyErrors) ?? 1
        timeSpentSeconds = try container.decode(Int.self, forKey: .timeSpentSeconds)
        passed = try container.decode(Bool.self, forKey: .passed)
        questionIds = try container.decode([String].self, forKey: .questionIds)
        userAnswers = try container.decodeIfPresent([String: Int].self, forKey: .userAnswers) ?? [:]
        flaggedQuestionIds = try container.decodeIfPresent([String].self, forKey: .flaggedQuestionIds) ?? []
        questionRecords = try container.decodeIfPresent([ExamQuestionRecord].self, forKey: .questionRecords) ?? []
        topicScores = try container.decodeIfPresent([TopicScoreSummary].self, forKey: .topicScores) ?? []
    }

    public var percentage: Int {
        guard totalQuestions > 0 else { return 0 }
        return Int(Double(score) / Double(totalQuestions) * 100)
    }

    public var errorCount: Int {
        totalQuestions - score
    }

    public var formattedDuration: String {
        let mins = timeSpentSeconds / 60
        let secs = timeSpentSeconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
