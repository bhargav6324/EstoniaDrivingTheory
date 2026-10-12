import Foundation

/// Centralized, weight-based exam readiness calculator.
/// Weights are defined as constants so they can be adjusted from one place.
public enum ExamReadinessCalculator {

    // MARK: - Weight Configuration (adjustable)
    /// Recent mock exam performance weight (0.0–1.0)
    static let mockWeight: Double = 0.35
    /// Practice session accuracy weight
    static let practiceWeight: Double = 0.30
    /// Topic coverage (breadth) weight
    static let topicWeight: Double = 0.20
    /// Mastery / mistake-clearing weight
    static let masteryWeight: Double = 0.15

    /// Minimum number of total question attempts before showing a percentage.
    /// Prevents a misleading 100% after only 1–2 correct answers.
    static let minimumAttemptsRequired: Int = 15

    // MARK: - Public API

    /// Calculate readiness from the given progress store.
    /// Returns a `ReadinessResult`. If there is not enough activity, `.percentage` is nil.
    public static func calculate(from store: ProgressStore) -> ReadinessResult {
        let totalAttempts = store.questionProgressMap.values.reduce(0) { $0 + $1.attempts }

        guard totalAttempts >= minimumAttemptsRequired else {
            return .notEnoughData
        }

        // --- 1. Recent practice accuracy (30%) ---
        let totalAtt = store.questionProgressMap.values.reduce(0) { $0 + $1.attempts }
        let correctAtt = store.questionProgressMap.values.reduce(0) { $0 + $1.correctAttempts }
        let practiceAccuracy = totalAtt > 0 ? Double(correctAtt) / Double(totalAtt) : 0.0
        let practiceScore = practiceAccuracy * practiceWeight * 100.0

        // --- 2. Recent mock exam performance (35%) ---
        let recentMocks = Array(store.mockExamHistory.prefix(5))
        let mockScore: Double
        if recentMocks.isEmpty {
            // No mock yet — this component is 0. That's fine; they may still pass.
            mockScore = 0
        } else {
            let avgMockPct = recentMocks.reduce(0.0) { acc, exam in
                acc + (Double(exam.score) / Double(max(1, exam.totalQuestions)))
            } / Double(recentMocks.count)
            mockScore = avgMockPct * mockWeight * 100.0
        }

        // --- 3. Topic coverage (20%) ---
        let allTopics = TopicCategory.allCases
        let topicsAttempted = allTopics.filter { topic in
            QuestionRepository.shared.questions(for: topic).contains { q in
                (store.questionProgressMap[q.id]?.attempts ?? 0) > 0
            }
        }.count
        let topicCoverage = allTopics.isEmpty ? 0.0 : Double(topicsAttempted) / Double(allTopics.count)
        let topicScore = topicCoverage * topicWeight * 100.0

        // --- 4. Mastery / mistake progress (15%) ---
        let totalQuestions = max(1, QuestionRepository.shared.questions.count)
        let mastered = store.totalQuestionsMastered
        let activeMistakes = store.activeMistakeCount

        // Mastery fraction minus a penalty for outstanding mistakes
        let masteryFraction = Double(mastered) / Double(totalQuestions)
        let mistakePenalty = min(0.3, Double(activeMistakes) / Double(totalQuestions) * 3.0)
        let masteryScore = max(0.0, (masteryFraction - mistakePenalty)) * masteryWeight * 100.0

        // --- Sum and clamp ---
        let total = practiceScore + mockScore + topicScore + masteryScore
        let clamped = Int(min(100.0, max(0.0, total)))

        return ReadinessResult(
            percentage: clamped,
            mockWeight: mockScore,
            practiceWeight: practiceScore,
            topicWeight: topicScore,
            masteryWeight: masteryScore
        )
    }
}
