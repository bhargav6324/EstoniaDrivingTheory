import Foundation
import Combine

public final class ProgressStore: ObservableObject {
    public static let shared = ProgressStore()

    private let questionProgressKey = "estonia_driving_question_progress_v1"
    private let mistakesKey = "estonia_driving_mistakes_v1"
    private let mockExamsKey = "estonia_driving_mock_exams_v1"
    private let recentTopicKey = "estonia_driving_recent_topic"

    @Published public private(set) var questionProgressMap: [String: QuestionProgress] = [:]
    @Published public private(set) var mistakesMap: [String: MistakeRecord] = [:]
    @Published public private(set) var mockExamHistory: [ExamResult] = []
    @Published public var recentTopic: TopicCategory?

    private init() {
        loadData()
    }

    private func loadData() {
        // Load question progress
        if let data = UserDefaults.standard.data(forKey: questionProgressKey),
           let decoded = try? JSONDecoder().decode([String: QuestionProgress].self, from: data) {
            self.questionProgressMap = decoded
        }

        // Load mistakes
        if let data = UserDefaults.standard.data(forKey: mistakesKey),
           let decoded = try? JSONDecoder().decode([String: MistakeRecord].self, from: data) {
            self.mistakesMap = decoded
        }

        // Load mock exams
        if let data = UserDefaults.standard.data(forKey: mockExamsKey),
           let decoded = try? JSONDecoder().decode([ExamResult].self, from: data) {
            self.mockExamHistory = decoded
        }

        // Load recent topic
        if let topicRaw = UserDefaults.standard.string(forKey: recentTopicKey),
           let topic = TopicCategory(rawValue: topicRaw) {
            self.recentTopic = topic
        }
    }

    private func saveData() {
        if let data = try? JSONEncoder().encode(questionProgressMap) {
            UserDefaults.standard.set(data, forKey: questionProgressKey)
        }
        if let data = try? JSONEncoder().encode(mistakesMap) {
            UserDefaults.standard.set(data, forKey: mistakesKey)
        }
        if let data = try? JSONEncoder().encode(mockExamHistory) {
            UserDefaults.standard.set(data, forKey: mockExamsKey)
        }
        if let recent = recentTopic {
            UserDefaults.standard.set(recent.rawValue, forKey: recentTopicKey)
        }
    }

    // Record an answer during practice or topic study
    public func recordAnswer(questionId: String, topic: TopicCategory, isCorrect: Bool) {
        var progress = questionProgressMap[questionId] ?? QuestionProgress(questionId: questionId)
        progress.recordAnswer(isCorrect: isCorrect)
        questionProgressMap[questionId] = progress

        // Track mistake
        if !isCorrect {
            var mistake = mistakesMap[questionId] ?? MistakeRecord(questionId: questionId, topic: topic)
            mistake.mistakeCount += 1
            mistake.lastMistakeDate = Date()
            mistake.isResolved = false
            mistakesMap[questionId] = mistake
        } else {
            // If answered correctly and was in mistakes
            if var mistake = mistakesMap[questionId] {
                mistake.resolvedCount += 1
                if mistake.resolvedCount >= 2 {
                    mistake.isResolved = true
                }
                mistakesMap[questionId] = mistake
            }
        }

        // Track daily activity
        DailyGoalManager.shared.recordAnswer(isCorrect: isCorrect)

        self.recentTopic = topic
        saveData()
    }

    // Record mock exam completion
    public func recordMockExam(_ result: ExamResult) {
        mockExamHistory.insert(result, at: 0)

        // Track daily activity
        DailyGoalManager.shared.recordMockExamCompleted()

        // Also update question answers
        for (qId, selectedIdx) in result.userAnswers {
            if let question = QuestionRepository.shared.question(with: qId) {
                let isCorrect = selectedIdx == question.correctIndex(for: .english)
                recordAnswer(questionId: qId, topic: question.topic, isCorrect: isCorrect)
            }
        }

        saveData()
    }

    // Computed Stats
    public var totalQuestionsAttempted: Int {
        questionProgressMap.values.filter { $0.attempts > 0 }.count
    }

    public var totalQuestionsMastered: Int {
        questionProgressMap.values.filter { $0.isMastered }.count
    }

    public var overallAccuracyPercentage: Int {
        let totalAttempts = questionProgressMap.values.reduce(0) { $0 + $1.attempts }
        guard totalAttempts > 0 else { return 0 }
        let correctAttempts = questionProgressMap.values.reduce(0) { $0 + $1.correctAttempts }
        return Int(Double(correctAttempts) / Double(totalAttempts) * 100)
    }

    public var activeMistakeCount: Int {
        mistakesMap.values.filter { !$0.isResolved }.count
    }

    public func activeMistakeCount(filteredBy accessibleIDs: Set<String>?) -> Int {
        guard let ids = accessibleIDs else { return activeMistakeCount }
        return mistakesMap.values.filter { !$0.isResolved && ids.contains($0.questionId) }.count
    }

    public var activeMistakes: [MistakeRecord] {
        mistakesMap.values.filter { !$0.isResolved }.sorted { $0.lastMistakeDate > $1.lastMistakeDate }
    }

    public func activeMistakes(filteredBy accessibleIDs: Set<String>?) -> [MistakeRecord] {
        guard let ids = accessibleIDs else { return activeMistakes }
        return mistakesMap.values
            .filter { !$0.isResolved && ids.contains($0.questionId) }
            .sorted { $0.lastMistakeDate > $1.lastMistakeDate }
    }

    /// Centralized readiness result. Returns nil percentage if not enough data.
    public var examReadiness: ReadinessResult {
        ExamReadinessCalculator.calculate(from: self)
    }

    /// Convenience: percentage for backward-compatible views (returns 0 if not enough data)
    public var examReadinessPercentage: Int {
        examReadiness.percentage ?? 0
    }

    public func topicStats(for topic: TopicCategory) -> (total: Int, attempted: Int, mastered: Int, accuracy: Int, mistakes: Int) {
        let topicQuestions = QuestionRepository.shared.questions(for: topic)
        let total = topicQuestions.count
        var attempted = 0
        var mastered = 0
        var totalAttempts = 0
        var correctAttempts = 0

        for q in topicQuestions {
            if let p = questionProgressMap[q.id], p.attempts > 0 {
                attempted += 1
                if p.isMastered { mastered += 1 }
                totalAttempts += p.attempts
                correctAttempts += p.correctAttempts
            }
        }

        let accuracy = totalAttempts > 0 ? Int(Double(correctAttempts) / Double(totalAttempts) * 100) : 0
        let mistakes = mistakesMap.values.filter { $0.topic == topic && !$0.isResolved }.count

        return (total, attempted, mastered, accuracy, mistakes)
    }

    public func weakTopics() -> [TopicCategory] {
        return TopicCategory.allCases.filter { topic in
            let stats = topicStats(for: topic)
            return (stats.attempted > 0 && stats.accuracy < 75) || stats.mistakes > 0
        }
    }

    public func resetAllProgress() {
        questionProgressMap.removeAll()
        mistakesMap.removeAll()
        mockExamHistory.removeAll()
        recentTopic = nil
        UserDefaults.standard.removeObject(forKey: questionProgressKey)
        UserDefaults.standard.removeObject(forKey: mistakesKey)
        UserDefaults.standard.removeObject(forKey: mockExamsKey)
        UserDefaults.standard.removeObject(forKey: recentTopicKey)
    }

    public func restoreForTesting(progress: [String: QuestionProgress], mistakes: [String: MistakeRecord]) {
        self.questionProgressMap = progress
        self.mistakesMap = mistakes
        saveData()
    }
}
