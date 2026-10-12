import SwiftUI
import Combine

public enum ExamQuestionStatus {
    case answered    // Green
    case flagged     // Yellow (Marked for Review)
    case unanswered  // Grey
}

@MainActor
public final class MockExamViewModel: ObservableObject {
    public let config: ExamConfiguration
    public let questions: [Question]

    @Published public var currentIndex: Int = 0
    @Published public var userAnswers: [String: Int] = [:] // questionId -> selectedIndex
    @Published public var flaggedQuestionIds: Set<String> = [] // session-only flags
    @Published public var secondsRemaining: Int
    @Published public var isExamSubmitted: Bool = false
    @Published public var isReviewing: Bool = false // controls dedicated Exam Review screen
    @Published public var examResult: ExamResult?

    private var timerCancellable: AnyCancellable?
    private let startTime: Date

    public init(config: ExamConfiguration = .estonianCategoryB) {
        self.config = config
        if PremiumAccessManager.shared.isPremium {
            self.questions = QuestionRepository.shared.randomExamQuestions(config: config)
        } else {
            self.questions = PremiumAccessManager.shared.freeMockQuestions()
        }
        self.secondsRemaining = config.durationSeconds
        self.startTime = Date()

        startTimer()
    }

    private func startTimer() {
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, !self.isExamSubmitted else { return }
                if self.secondsRemaining > 0 {
                    self.secondsRemaining -= 1
                } else {
                    self.submitExam()
                }
            }
    }

    public var currentQuestion: Question? {
        guard currentIndex >= 0 && currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }

    public var isLastQuestion: Bool {
        currentIndex == questions.count - 1
    }

    public var isFirstQuestion: Bool {
        currentIndex == 0
    }

    public var formattedTime: String {
        let mins = secondsRemaining / 60
        let secs = secondsRemaining % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    // MARK: - Central Status Model

    public func status(for index: Int) -> ExamQuestionStatus {
        guard index >= 0 && index < questions.count else { return .unanswered }
        let q = questions[index]
        let isFlagged = flaggedQuestionIds.contains(q.id)
        let isAnswered = userAnswers[q.id] != nil

        if isFlagged {
            // High priority: flagged questions are marked for review regardless of answered status
            return .flagged
        } else if isAnswered {
            return .answered
        } else {
            return .unanswered
        }
    }

    public func isFlagged(for index: Int) -> Bool {
        guard index >= 0 && index < questions.count else { return false }
        return flaggedQuestionIds.contains(questions[index].id)
    }

    public var answeredCount: Int {
        userAnswers.count
    }

    public var unansweredCount: Int {
        max(0, questions.count - answeredCount)
    }

    public var flaggedCount: Int {
        flaggedQuestionIds.count
    }

    // MARK: - Navigation & User Actions

    public func selectAnswer(_ answerIndex: Int, for questionId: String? = nil) {
        guard !isExamSubmitted else { return }
        let id = questionId ?? currentQuestion?.id
        guard let finalId = id else { return }
        userAnswers[finalId] = answerIndex
    }

    public func toggleFlag() {
        guard let q = currentQuestion else { return }
        if flaggedQuestionIds.contains(q.id) {
            flaggedQuestionIds.remove(q.id)
        } else {
            flaggedQuestionIds.insert(q.id)
        }
    }

    public func jumpToQuestion(_ index: Int) {
        guard index >= 0 && index < questions.count else { return }
        currentIndex = index
        isReviewing = false
    }

    public func goToNextQuestion() {
        if isLastQuestion {
            isReviewing = true
        } else {
            currentIndex += 1
        }
    }

    public func goToPreviousQuestion() {
        if currentIndex > 0 {
            currentIndex -= 1
        }
    }

    // MARK: - Session Termination (Abandon vs Submit)

    public func abandonExam() {
        timerCancellable?.cancel()
        timerCancellable = nil
        userAnswers.removeAll()
        flaggedQuestionIds.removeAll()
        examResult = nil
        isExamSubmitted = false
        isReviewing = false
        // Deliberately does NOT call ProgressStore.shared.recordMockExam
    }

    public func submitExam() {
        guard !isExamSubmitted else { return }
        timerCancellable?.cancel()
        timerCancellable = nil
        isExamSubmitted = true
        isReviewing = false

        let timeSpent = config.durationSeconds - secondsRemaining

        var totalScore = 0
        var safetyErrors = 0
        var topicBreakdownMap: [TopicCategory: (correct: Int, total: Int)] = [:]
        var records: [ExamQuestionRecord] = []

        for q in questions {
            let userChoice = userAnswers[q.id]
            let correctChoice = q.correctIndex(for: .english)
            let isCorrect = (userChoice == correctChoice)
            let wasFlagged = flaggedQuestionIds.contains(q.id)

            if isCorrect {
                totalScore += 1
            } else if q.isSafetyQuestion {
                safetyErrors += 1
            }

            var current = topicBreakdownMap[q.topic] ?? (0, 0)
            current.total += 1
            if isCorrect { current.correct += 1 }
            topicBreakdownMap[q.topic] = current

            records.append(
                ExamQuestionRecord(
                    questionId: q.id,
                    selectedAnswer: userChoice,
                    correctAnswer: correctChoice,
                    isCorrect: isCorrect,
                    wasMarkedForReview: wasFlagged,
                    topic: q.topic,
                    isSafetyQuestion: q.isSafetyQuestion
                )
            )
        }

        let totalErrors = questions.count - totalScore
        let passed = (totalErrors <= config.maxAllowedErrors) && (safetyErrors <= config.maxAllowedSafetyErrors)

        let topicSummaries = topicBreakdownMap.map { (topic, tuple) in
            TopicScoreSummary(topic: topic, correctCount: tuple.correct, totalCount: tuple.total)
        }.sorted { $0.topic.rawValue < $1.topic.rawValue }

        let result = ExamResult(
            score: totalScore,
            totalQuestions: questions.count,
            safetyErrors: safetyErrors,
            maxAllowedErrors: config.maxAllowedErrors,
            maxAllowedSafetyErrors: config.maxAllowedSafetyErrors,
            timeSpentSeconds: timeSpent,
            passed: passed,
            questionIds: questions.map { $0.id },
            userAnswers: userAnswers,
            flaggedQuestionIds: Array(flaggedQuestionIds),
            questionRecords: records,
            topicScores: topicSummaries
        )

        self.examResult = result
        ProgressStore.shared.recordMockExam(result)

        if !PremiumAccessManager.shared.isPremium {
            PremiumAccessManager.shared.markFreeMockCompleted()
        }
    }
}
