import SwiftUI
import Combine

public enum QuizMode {
    case topic(TopicCategory)
    case mistakes
    case weakQuestions
    case roadSigns
    case generalPractice
}

public struct QuizSessionConfig: Identifiable {
    public let id: UUID
    public let mode: QuizMode
    public let questions: [Question]

    public init(id: UUID = UUID(), mode: QuizMode, questions: [Question]) {
        self.id = id
        self.mode = mode
        self.questions = questions
    }
}

@MainActor
public final class QuizViewModel: ObservableObject {
    public let mode: QuizMode
    @Published public private(set) var questions: [Question]

    @Published public var currentIndex: Int = 0
    @Published public var selectedOptionIndex: Int? = nil
    @Published public var hasAnswered: Bool = false
    @Published public var sessionScore: Int = 0
    @Published public var isCompleted: Bool = false
    @Published public var isEndedEarly: Bool = false
    @Published public var userAnswers: [String: Int] = [:] // questionId -> chosen index

    public init(mode: QuizMode, questions: [Question]) {
        self.mode = mode
        self.questions = questions
    }

    public func reload(questions: [Question]) {
        guard !questions.isEmpty else { return }
        self.questions = questions
        self.currentIndex = 0
        self.selectedOptionIndex = nil
        self.hasAnswered = false
        self.sessionScore = 0
        self.isCompleted = false
        self.isEndedEarly = false
        self.userAnswers = [:]
    }

    public var currentQuestion: Question? {
        guard currentIndex >= 0 && currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }

    public var isLastQuestion: Bool {
        currentIndex == questions.count - 1
    }

    public var progressFraction: Double {
        guard !questions.isEmpty else { return 0 }
        return Double(currentIndex + 1) / Double(questions.count)
    }

    public var attemptedCount: Int {
        userAnswers.count
    }

    public var correctCount: Int {
        sessionScore
    }

    public var mistakesCount: Int {
        max(0, attemptedCount - correctCount)
    }

    public var accuracyPercentage: Int {
        guard attemptedCount > 0 else { return 0 }
        return Int(Double(correctCount) / Double(attemptedCount) * 100)
    }

    public var mistakeQuestions: [Question] {
        questions.filter { q in
            guard let chosen = userAnswers[q.id] else { return false }
            let correct = q.correctIndex(for: LocalizationManager.shared.currentLanguage)
            return chosen != correct
        }
    }

    public func selectOption(_ index: Int) {
        guard !hasAnswered else { return }
        selectedOptionIndex = index
        hasAnswered = true

        guard let q = currentQuestion else { return }
        userAnswers[q.id] = index

        let isCorrect = (index == q.correctIndex(for: LocalizationManager.shared.currentLanguage))
        if isCorrect {
            sessionScore += 1
        }

        // Record locally in progress store
        ProgressStore.shared.recordAnswer(questionId: q.id, topic: q.topic, isCorrect: isCorrect)
    }

    public func nextQuestion() {
        if isLastQuestion {
            isCompleted = true
        } else {
            currentIndex += 1
            selectedOptionIndex = nil
            hasAnswered = false
        }
    }

    public func endSessionEarly() {
        isEndedEarly = true
        isCompleted = true
    }

    public func restartWithMistakes() {
        let wrong = mistakeQuestions
        guard !wrong.isEmpty else { return }
        reload(questions: wrong)
    }
}
