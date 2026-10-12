import Foundation

public struct QuestionProgress: Codable, Identifiable {
    public var id: String { questionId }
    public var questionId: String
    public var attempts: Int
    public var correctAttempts: Int
    public var incorrectAttempts: Int
    public var lastAnsweredAt: Date?
    public var lastAnswerCorrect: Bool
    public var consecutiveCorrect: Int
    public var isMastered: Bool

    public init(
        questionId: String,
        attempts: Int = 0,
        correctAttempts: Int = 0,
        incorrectAttempts: Int = 0,
        lastAnsweredAt: Date? = nil,
        lastAnswerCorrect: Bool = false,
        consecutiveCorrect: Int = 0,
        isMastered: Bool = false
    ) {
        self.questionId = questionId
        self.attempts = attempts
        self.correctAttempts = correctAttempts
        self.incorrectAttempts = incorrectAttempts
        self.lastAnsweredAt = lastAnsweredAt
        self.lastAnswerCorrect = lastAnswerCorrect
        self.consecutiveCorrect = consecutiveCorrect
        self.isMastered = isMastered
    }

    public var accuracyPercentage: Int {
        guard attempts > 0 else { return 0 }
        return Int(Double(correctAttempts) / Double(attempts) * 100)
    }

    public mutating func recordAnswer(isCorrect: Bool) {
        attempts += 1
        lastAnsweredAt = Date()
        lastAnswerCorrect = isCorrect

        if isCorrect {
            correctAttempts += 1
            consecutiveCorrect += 1
            if consecutiveCorrect >= 2 && accuracyPercentage >= 65 {
                isMastered = true
            }
        } else {
            incorrectAttempts += 1
            consecutiveCorrect = 0
            isMastered = false
        }
    }
}

public struct MistakeRecord: Codable, Identifiable {
    public var id: String { questionId }
    public var questionId: String
    public var topic: TopicCategory
    public var mistakeCount: Int
    public var lastMistakeDate: Date
    public var resolvedCount: Int
    public var isResolved: Bool

    public init(
        questionId: String,
        topic: TopicCategory,
        mistakeCount: Int = 1,
        lastMistakeDate: Date = Date(),
        resolvedCount: Int = 0,
        isResolved: Bool = false
    ) {
        self.questionId = questionId
        self.topic = topic
        self.mistakeCount = mistakeCount
        self.lastMistakeDate = lastMistakeDate
        self.resolvedCount = resolvedCount
        self.isResolved = isResolved
    }
}
