import SwiftUI
import Combine

public final class LocalizationManager: ObservableObject {
    public static let shared = LocalizationManager()

    private let languageKey = "selected_app_language"
    private let hasChosenLanguageKey = "has_completed_initial_language_selection"

    @Published public var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: languageKey)
        }
    }

    @Published public var hasSelectedLanguageOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasSelectedLanguageOnboarding, forKey: hasChosenLanguageKey)
        }
    }

    private init() {
        let storedLang = UserDefaults.standard.string(forKey: languageKey)
        if let stored = storedLang, let lang = AppLanguage(rawValue: stored) {
            self.currentLanguage = lang
        } else {
            // Default to device language or English
            let preferred = Locale.preferredLanguages.first ?? ""
            if preferred.starts(with: "et") {
                self.currentLanguage = .estonian
            } else if preferred.starts(with: "ru") {
                self.currentLanguage = .russian
            } else {
                self.currentLanguage = .english
            }
        }

        self.hasSelectedLanguageOnboarding = UserDefaults.standard.bool(forKey: hasChosenLanguageKey)
    }

    public func setLanguage(_ language: AppLanguage) {
        withAnimation(.easeInOut(duration: 0.2)) {
            currentLanguage = language
            hasSelectedLanguageOnboarding = true
        }
    }

    public func t(_ key: LocalizationKey) -> String {
        key.localized(for: currentLanguage)
    }
}

public enum LocalizationKey {
    // Navigation / Tabs
    case tabHome
    case tabPractice
    case tabProgress
    case tabSettings

    // Home
    case appTitle
    case categoryB
    case examReadiness
    case questionsMastered
    case mockExamPerformance
    case weakTopics
    case continuePractice
    case resumeRecentTopic
    case mockExamTitle
    case mockExamSubtitle
    case practiceQuestionsTitle
    case practiceQuestionsSubtitle
    case myMistakesTitle
    case myMistakesSubtitle
    case roadSignsTitle
    case roadSignsSubtitle

    // Practice
    case allTopics
    case practiceCategories
    case totalQuestions(Int)
    case accuracyRate(Int)
    case masteredCount(Int)
    case mistakesRemaining(Int)
    case startPractice
    case reviewMistakes
    case practiceWeak

    // Quiz
    case question
    case questionOf(Int, Int)
    case whyExplanation
    case trafficActSource
    case nextQuestion
    case finishQuiz
    case quitQuiz
    case quitConfirmTitle
    case quitConfirmMessage
    case stay
    case quit
    case safetyQuestionBadge
    case wellDone
    case keepPracticing
    case quizCompleted
    case sessionSummary
    case sessionEndedEarly
    case questionsToReview
    case noMistakesInSession
    case practiceMistakesAction
    case exitAndReview
    case yourAnswerLabel
    case correctAnswerLabel
    case correctStat
    case mistakesStat
    case sessionEarlySubtitle(Int)

    // Mock Exam
    case mockExamRulesTitle
    case officialCategoryBRules
    case examDuration
    case passingRequirements
    case strictSafetyLimit
    case startExam
    case timeRemaining
    case submitExam
    case submitConfirmTitle
    case submitConfirmMessage
    case passed
    case notPassed
    case examScore
    case safetyErrors
    case reviewAllAnswers

    // Road Signs
    case learnSigns
    case practiceSigns
    case signQuiz
    case signCategoryAll
    case signCode(String)

    // Mistakes
    case noMistakesTitle
    case noMistakesSubtitle
    case activeMistakes(Int)
    case practiceMyMistakes

    // Progress
    case overallProgress
    case questionsAttempted
    case accuracy
    case recentExams
    case weakAreas
    case practiceWeakTopics
    case noExamsYet

    // Settings
    case language
    case chooseLanguage
    case premiumTitle
    case lifetimeUnlock
    case unlockAllFeatures
    case restorePurchases
    case appInfo
    case version
    case resetProgress
    case resetProgressConfirm
    case cancel
    case done
    case disclaimerTitle
    case disclaimerBody

    // Monetization & Paywall
    case unlockFullAccess
    case monthlyPremiumTitle
    case lifetimePremiumTitle
    case perMonth
    case oneTimePayment
    case billedMonthly
    case lifetimeSubtext
    case bestValueBadge
    case unlockButtonContinue
    case unlockButtonLifetime
    case unlockButtonMonthly
    case benefit500Questions
    case benefitUnlimitedMocks
    case benefitFullPractice
    case benefitRoadSignFlashcards
    case benefitRoadSignTests
    case benefitFullMistakes
    case benefitCompleteProgress
    case subscriptionDisclosure
    case oneFreeMockBadge
    case startFreeMock
    case mockExamCompletedTitle
    case mockExamCompletedDescription
    case unlockUnlimitedMocks
    case freeQuestionsAvailable(Int)
    case premiumLockedTopic
    case unlockAllTopicQuestions(Int)
    case flashcardsLockedTitle
    case flashcardsLockedSubtitle
    case signTestLockedTitle
    case signTestLockedSubtitle
    case unlockWithPremium
    case premiumActiveStatus
    case premiumLifetimeStatus
    case premiumMonthlyStatus
    case viewPremiumButton
    case termsOfService
    case privacyPolicy

    // Settings & Paywall Additions
    case unlockFullAccessSubtitle
    case purchasesUnavailable
    case loadingPurchases
    case retryLoading
    case benefitPracticeMistakes
    case benefitWeakTopics
    case benefitProgressReadiness
    case benefitDailyGoals
    case sectionPremium
    case proCardTitle
    case freePlan
    case freePlanDescription
    case upgradeToPro
    case premiumActive
    case lifetimeAccess
    case monthlyPremium
    case studyPreferences
    case dailyGoal
    case studyReminder
    case reminderTime
    case progress
    case resetProgressTitle
    case resetProgressMessage
    case about
    case appNameLabel
    case subtitleLabel
    case versionLabel
    case supportLabel
    case supportWebsiteLabel
    case privacyPolicyLabel
    case termsOfUseLabel
    case legal
    case disclaimerLabel
    case governmentDisclaimerText

    // MARK: - Daily Goal
    case dailyGoalTitle
    case dailyGoalCardLabel
    case dailyGoalCompleted
    case dailyGoalProgress(Int, Int)
    case chooseGoal
    case goal5
    case goal10
    case goal20
    case goal30
    case goalCustom
    case questionsPerDay(Int)

    // MARK: - Study Streak
    case studyStreak
    case streakDays(Int)
    case streakZero

    // MARK: - Exam Readiness (new)
    case examReadinessExplanation
    case examReadinessNotEnoughData
    case examReadinessInfoTitle

    // MARK: - Mock Exam Chart
    case mockScoreTrend
    case mockScoreTrendEmpty
    case mockPassLabel
    case mockFailLabel

    // MARK: - Activity Calendar
    case activityCalendar
    case activityCalendarEmpty
    case activityNoData
    case activityLightLabel
    case activityMediumLabel
    case activityStrongLabel
    case activityDayDetail(Int, Int, Int)

    // MARK: - Topic Performance
    case topicPerformanceTitle
    case topicAccuracy(Int)
    case topicAttempted(Int)
    case topicMastered(Int)
    case topicStrong
    case topicWeak
    case topicNoData
    case weakTopicsSection

    // MARK: - Reminder
    case dailyReminderTitle
    case dailyReminderSubtitle
    case reminderEnabled
    case reminderDisabled
    case reminderTimeLabel
    case reminderPermissionDenied
    case reminderPermissionDeniedMessage

    // MARK: - Statistics
    case statsTitle
    case statsBestMockScore
    case statsMockExamsCompleted
    case statsMistakesRemaining

    public func localized(for lang: AppLanguage) -> String {
        switch lang {
        case .english:
            return englishString
        case .estonian:
            return estonianString
        case .russian:
            return russianString
        }
    }

    private var englishString: String {
        switch self {
        case .tabHome: return "Home"
        case .tabPractice: return "Practice"
        case .tabProgress: return "Progress"
        case .tabSettings: return "Settings"

        case .appTitle: return "Estonia Driving Theory"
        case .categoryB: return "Category B"
        case .examReadiness: return "Exam Readiness"
        case .questionsMastered: return "Mastered"
        case .mockExamPerformance: return "Recent Mock"
        case .weakTopics: return "Weak Topics"
        case .continuePractice: return "Continue Practice"
        case .resumeRecentTopic: return "Resume where you left off"
        case .mockExamTitle: return "Mock Exam"
        case .mockExamSubtitle: return "Simulate Estonian Category B test"
        case .practiceQuestionsTitle: return "Practice Questions"
        case .practiceQuestionsSubtitle: return "Study by official topics"
        case .myMistakesTitle: return "My Mistakes"
        case .myMistakesSubtitle: return "Repeat questions answered incorrectly"
        case .roadSignsTitle: return "Road Signs"
        case .roadSignsSubtitle: return "Learn and test Estonian road signs"

        case .allTopics: return "All Topics"
        case .practiceCategories: return "Official Curriculum Topics"
        case .totalQuestions(let c): return "\(c) questions"
        case .accuracyRate(let a): return "\(a)% accuracy"
        case .masteredCount(let m): return "\(m) mastered"
        case .mistakesRemaining(let r): return "\(r) mistakes"
        case .startPractice: return "Start Practice"
        case .reviewMistakes: return "Review Mistakes"
        case .practiceWeak: return "Practice Weak Questions"

        case .question: return "Question"
        case .questionOf(let current, let total): return "Question \(current) of \(total)"
        case .whyExplanation: return "Why?"
        case .trafficActSource: return "Traffic Act Reference"
        case .nextQuestion: return "Next Question"
        case .finishQuiz: return "Complete Quiz"
        case .quitQuiz: return "Exit Session"
        case .quitConfirmTitle: return "Exit session?"
        case .quitConfirmMessage: return "Your current progress will be recorded."
        case .stay: return "Continue"
        case .quit: return "Exit"
        case .safetyQuestionBadge: return "CRITICAL SAFETY QUESTION"
        case .wellDone: return "Excellent work!"
        case .keepPracticing: return "Keep practicing to improve!"
        case .quizCompleted: return "Quiz Completed"
        case .sessionSummary: return "Session Summary"
        case .sessionEndedEarly: return "Practice Ended Early"
        case .questionsToReview: return "Questions to Review"
        case .noMistakesInSession: return "Flawless session! No mistakes made."
        case .practiceMistakesAction: return "Practice These Mistakes"
        case .exitAndReview: return "Exit & View Summary"
        case .yourAnswerLabel: return "Your answer"
        case .correctAnswerLabel: return "Correct answer"
        case .correctStat: return "Correct"
        case .mistakesStat: return "Mistakes"
        case .sessionEarlySubtitle(let n): return "Here is your progress for the \(n) questions answered in this session."

        case .mockExamRulesTitle: return "Category B Mock Exam"
        case .officialCategoryBRules: return "Follows official Estonian Transpordiamet format"
        case .examDuration: return "30 minutes duration"
        case .passingRequirements: return "40 questions • Maximum 5 errors allowed"
        case .strictSafetyLimit: return "Max 1 error on safety questions"
        case .startExam: return "Start Exam"
        case .timeRemaining: return "Time Remaining"
        case .submitExam: return "Submit Exam"
        case .submitConfirmTitle: return "Submit your exam?"
        case .submitConfirmMessage: return "Are you ready to submit all answers for grading?"
        case .passed: return "PASSED"
        case .notPassed: return "NOT PASSED"
        case .examScore: return "Exam Score"
        case .safetyErrors: return "Safety Errors"
        case .reviewAllAnswers: return "Review Questions"

        case .learnSigns: return "Browse Signs"
        case .practiceSigns: return "Flashcards"
        case .signQuiz: return "Sign Test"
        case .signCategoryAll: return "All Categories"
        case .signCode(let c): return "Sign \(c)"

        case .noMistakesTitle: return "No mistakes yet!"
        case .noMistakesSubtitle: return "Questions you get wrong will appear here for focused practice."
        case .activeMistakes(let c): return "\(c) mistakes to review"
        case .practiceMyMistakes: return "Practice My Mistakes"

        case .overallProgress: return "Overall Progress"
        case .questionsAttempted: return "Attempted"
        case .accuracy: return "Accuracy"
        case .recentExams: return "Recent Mock Exams"
        case .weakAreas: return "Areas Needing Attention"
        case .practiceWeakTopics: return "Practice Weak Topics"
        case .noExamsYet: return "No mock exams completed yet"

        case .language: return "Language"
        case .chooseLanguage: return "Choose your language"
        case .premiumTitle: return "Premium Access"
        case .lifetimeUnlock: return "Lifetime Full Access"
        case .unlockAllFeatures: return "Unlock all 500+ questions, all road signs, and unlimited mock tests."
        case .restorePurchases: return "Restore Purchases"
        case .appInfo: return "About App"
        case .version: return "Version 1.0.0"
        case .resetProgress: return "Reset All Progress"
        case .resetProgressConfirm: return "This will reset all your statistics and mistake records. This cannot be undone."
        case .cancel: return "Cancel"
        case .done: return "Done"
        case .disclaimerTitle: return "Disclaimer"
        case .disclaimerBody: return "Estonia Driving Theory Test is an independent educational product designed to assist learners in preparing for the Category B driving examination. It is NOT affiliated with, sponsored by, or endorsed by the Estonian Transport Administration (Transpordiamet) or the Republic of Estonia."

        // Monetization & Paywall
        case .unlockFullAccess: return "Unlock Full Access"
        case .monthlyPremiumTitle: return "Monthly Premium"
        case .lifetimePremiumTitle: return "Lifetime Premium"
        case .perMonth: return "per month"
        case .oneTimePayment: return "one-time purchase"
        case .billedMonthly: return "Billed monthly • Cancel anytime"
        case .lifetimeSubtext: return "Pay once, enjoy forever. No recurring fees."
        case .bestValueBadge: return "BEST VALUE"
        case .unlockButtonContinue: return "Continue"
        case .unlockButtonLifetime: return "Unlock Lifetime Access"
        case .unlockButtonMonthly: return "Subscribe Monthly"
        case .benefit500Questions: return "500+ Category B practice questions"
        case .benefitUnlimitedMocks: return "Unlimited mock exams"
        case .benefitFullPractice: return "Full practice across all topics"
        case .benefitRoadSignFlashcards: return "Road sign flashcards"
        case .benefitRoadSignTests: return "Road sign tests"
        case .benefitFullMistakes: return "Practice My Mistakes"
        case .benefitCompleteProgress: return "Full progress and readiness insights"
        case .benefitPracticeMistakes: return "Practice My Mistakes"
        case .benefitWeakTopics: return "Weak-topic practice"
        case .benefitProgressReadiness: return "Full progress and readiness insights"
        case .benefitDailyGoals: return "Daily goals and progress tracking"
        case .subscriptionDisclosure: return "Monthly subscription renews automatically unless cancelled at least 24 hours before the end of the current period. Manage or cancel in your App Store Account Settings."
        case .oneFreeMockBadge: return "1 Free Mock Exam"
        case .startFreeMock: return "Start Free Mock Exam"
        case .mockExamCompletedTitle: return "Free Mock Exam Completed"
        case .mockExamCompletedDescription: return "You have completed your 1 free mock exam. Upgrade to Premium for unlimited mock exams, full 500+ question bank, and comprehensive analytics."
        case .unlockUnlimitedMocks: return "Unlock Unlimited Mock Exams"
        case .freeQuestionsAvailable(let count): return "\(count) free questions"
        case .premiumLockedTopic: return "Premium Only"
        case .unlockAllTopicQuestions(let count): return "Unlock all \(count) questions with Premium"
        case .flashcardsLockedTitle: return "Road Sign Flashcards"
        case .flashcardsLockedSubtitle: return "Master all Estonian road signs with interactive double-sided flashcards."
        case .signTestLockedTitle: return "Road Sign Knowledge Test"
        case .signTestLockedSubtitle: return "Test your ability to recognize priority, warning, and prohibitory signs."
        case .unlockWithPremium: return "Unlock with Premium"
        case .premiumActiveStatus: return "Active"
        case .premiumLifetimeStatus: return "Lifetime Access"
        case .premiumMonthlyStatus: return "Monthly Subscription"
        case .viewPremiumButton: return "View Premium"
        case .termsOfService: return "Terms of Use"
        case .privacyPolicy: return "Privacy Policy"

        // Settings & Paywall Additions
        case .unlockFullAccessSubtitle: return "Unlock the complete Estonia Driving Theory experience."
        case .purchasesUnavailable: return "Purchases are temporarily unavailable. Please try again later."
        case .loadingPurchases: return "Loading purchases..."
        case .retryLoading: return "Retry"
        case .sectionPremium: return "Premium"
        case .proCardTitle: return "Estonia Driving Theory Pro"
        case .freePlan: return "Free Plan"
        case .freePlanDescription: return "Unlock the full question bank, unlimited mock exams, road sign tests, and advanced progress insights."
        case .upgradeToPro: return "Upgrade to Pro"
        case .premiumActive: return "Premium Active"
        case .lifetimeAccess: return "Lifetime Access"
        case .monthlyPremium: return "Monthly Premium"
        case .studyPreferences: return "Study Preferences"
        case .dailyGoal: return "Daily Goal"
        case .studyReminder: return "Study Reminder"
        case .reminderTime: return "Reminder Time"
        case .progress: return "Progress"
        case .resetProgressTitle: return "Reset all progress?"
        case .resetProgressMessage: return "This will remove your practice history, mistakes, mock exam results, streaks, and goals. This cannot be undone."
        case .about: return "About"
        case .appNameLabel: return "App Name"
        case .subtitleLabel: return "Subtitle"
        case .versionLabel: return "Version"
        case .supportLabel: return "Support"
        case .supportWebsiteLabel: return "Support Website"
        case .privacyPolicyLabel: return "Privacy Policy"
        case .termsOfUseLabel: return "Terms of Use"
        case .legal: return "Legal"
        case .disclaimerLabel: return "Disclaimer"
        case .governmentDisclaimerText: return "Estonia Driving Theory is an independent educational product and is not affiliated with, sponsored by, or endorsed by the Estonian Transport Administration (Transpordiamet) or the Republic of Estonia."

        // Daily Goal
        case .dailyGoalTitle: return "Daily Study Goal"
        case .dailyGoalCardLabel: return "Today's Goal"
        case .dailyGoalCompleted: return "Daily Goal Complete ✓"
        case .dailyGoalProgress(let done, let target): return "\(done) / \(target) questions"
        case .chooseGoal: return "Choose Your Daily Goal"
        case .goal5: return "5 questions / day"
        case .goal10: return "10 questions / day"
        case .goal20: return "20 questions / day"
        case .goal30: return "30 questions / day"
        case .goalCustom: return "Custom"
        case .questionsPerDay(let n): return "\(n) questions / day"

        // Streak
        case .studyStreak: return "Study Streak"
        case .streakDays(let n): return n == 1 ? "1 day streak" : "\(n) day streak"
        case .streakZero: return "Start your streak today"

        // Readiness
        case .examReadinessExplanation: return "Readiness reflects your recent practice performance and topic coverage. It is not a guaranteed prediction of your official exam result."
        case .examReadinessNotEnoughData: return "Answer more questions to calculate your readiness."
        case .examReadinessInfoTitle: return "About Exam Readiness"

        // Mock Chart
        case .mockScoreTrend: return "Mock Exam Performance"
        case .mockScoreTrendEmpty: return "Complete a mock exam to see your score trend."
        case .mockPassLabel: return "Pass"
        case .mockFailLabel: return "Fail"

        // Activity Calendar
        case .activityCalendar: return "Study Activity"
        case .activityCalendarEmpty: return "Start practicing to build your study history."
        case .activityNoData: return "No activity"
        case .activityLightLabel: return "Light"
        case .activityMediumLabel: return "Medium"
        case .activityStrongLabel: return "Strong"
        case .activityDayDetail(let q, let acc, let mocks):
            var parts: [String] = []
            parts.append("\(q) questions answered")
            if q > 0 { parts.append("\(acc)% accuracy") }
            if mocks > 0 { parts.append("\(mocks) mock exam\(mocks > 1 ? "s" : "") completed") }
            return parts.joined(separator: "  •  ")

        // Topic Performance
        case .topicPerformanceTitle: return "Topic Performance"
        case .topicAccuracy(let a): return "\(a)% accuracy"
        case .topicAttempted(let n): return "\(n) attempted"
        case .topicMastered(let n): return "\(n) mastered"
        case .topicStrong: return "Strong"
        case .topicWeak: return "Needs work"
        case .topicNoData: return "Not started"
        case .weakTopicsSection: return "Weakest Topics"

        // Reminder
        case .dailyReminderTitle: return "Daily Study Reminder"
        case .dailyReminderSubtitle: return "A daily reminder can help you stay consistent with your study goal."
        case .reminderEnabled: return "On"
        case .reminderDisabled: return "Off"
        case .reminderTimeLabel: return "Reminder Time"
        case .reminderPermissionDenied: return "Notifications Not Allowed"
        case .reminderPermissionDeniedMessage: return "Enable notifications in Settings to use daily reminders."

        // Statistics
        case .statsTitle: return "Statistics"
        case .statsBestMockScore: return "Best Mock Score"
        case .statsMockExamsCompleted: return "Mock Exams"
        case .statsMistakesRemaining: return "Mistakes"
        }
    }

    private var estonianString: String {
        switch self {
        case .tabHome: return "Avaleht"
        case .tabPractice: return "Harjutamine"
        case .tabProgress: return "Areng"
        case .tabSettings: return "Seaded"

        case .appTitle: return "Eesti Liiklusteooria"
        case .categoryB: return "B-kategooria"
        case .examReadiness: return "Eksami valmisolek"
        case .questionsMastered: return "Omandatud"
        case .mockExamPerformance: return "Viimane proovieksam"
        case .weakTopics: return "Nõrgad teemad"
        case .continuePractice: return "Jätka harjutamist"
        case .resumeRecentTopic: return "Jätka sealt, kus pooleli jäid"
        case .mockExamTitle: return "Proovieksam"
        case .mockExamSubtitle: return "Transpordiameti B-kat teooriaeksami simulatsioon"
        case .practiceQuestionsTitle: return "Harjutusküsimused"
        case .practiceQuestionsSubtitle: return "Õpi ametlike teemade kaupa"
        case .myMistakesTitle: return "Minu vead"
        case .myMistakesSubtitle: return "Korda valesti vastatud küsimusi"
        case .roadSignsTitle: return "Liiklusmärgid"
        case .roadSignsSubtitle: return "Õpi ja testi Eesti liiklusmärke"

        case .allTopics: return "Kõik teemad"
        case .practiceCategories: return "B-kategooria õppekava teemad"
        case .totalQuestions(let c): return "\(c) küsimust"
        case .accuracyRate(let a): return "\(a)% täpsus"
        case .masteredCount(let m): return "\(m) omandatud"
        case .mistakesRemaining(let r): return "\(r) viga"
        case .startPractice: return "Alusta harjutamist"
        case .reviewMistakes: return "Korda vigu"
        case .practiceWeak: return "Harjuta nõrku küsimusi"

        case .question: return "Küsimus"
        case .questionOf(let current, let total): return "Küsimus \(current) / \(total)"
        case .whyExplanation: return "Miks?"
        case .trafficActSource: return "Liiklusseaduse viide"
        case .nextQuestion: return "Järgmine küsimus"
        case .finishQuiz: return "Lõpeta harjutus"
        case .quitQuiz: return "Katkesta"
        case .quitConfirmTitle: return "Kas soovid väljuda?"
        case .quitConfirmMessage: return "Sinu senine vastuste progress salvestatakse."
        case .stay: return "Jätka"
        case .quit: return "Välju"
        case .safetyQuestionBadge: return "KRIITILINE OHUTUSKÜSIMUS"
        case .wellDone: return "Väga tubli!"
        case .keepPracticing: return "Jätka harjutamist täiusliku tulemuseni!"
        case .quizCompleted: return "Harjutus sooritatud"
        case .sessionSummary: return "Sessiooni kokkuvõte"
        case .sessionEndedEarly: return "Harjutus lõpetati varem"
        case .questionsToReview: return "Ülevaatamist vajavad küsimused"
        case .noMistakesInSession: return "Suurepärane! Ühtegi viga ei tehtud."
        case .practiceMistakesAction: return "Harjuta neid vigu"
        case .exitAndReview: return "Lõpeta ja vaata kokkuvõtet"
        case .yourAnswerLabel: return "Sinu vastus"
        case .correctAnswerLabel: return "Õige vastus"
        case .correctStat: return "Õige"
        case .mistakesStat: return "Vigu"
        case .sessionEarlySubtitle(let n): return "Sinu tulemus \(n) vastatud küsimuse põhjal."

        case .mockExamRulesTitle: return "B-kategooria proovieksam"
        case .officialCategoryBRules: return "Transpordiameti ametliku eksami formaat"
        case .examDuration: return "Aeg: 30 minutit"
        case .passingRequirements: return "40 küsimust • Lubatud maksimaalselt 5 viga"
        case .strictSafetyLimit: return "Ohutusküsimustes lubatud max 1 viga"
        case .startExam: return "Alusta eksamit"
        case .timeRemaining: return "Aega jäänud"
        case .submitExam: return "Esita eksam"
        case .submitConfirmTitle: return "Kas oled valmis esitama?"
        case .submitConfirmMessage: return "Pärast esitamist hinnatakse kõiki sinu vastuseid."
        case .passed: return "SOORITATUD"
        case .notPassed: return "LÄBI KUKKUNUD"
        case .examScore: return "Eksami tulemus"
        case .safetyErrors: return "Ohutusvead"
        case .reviewAllAnswers: return "Vaata vastused üle"

        case .learnSigns: return "Märkide nimekiri"
        case .practiceSigns: return "Mälukaardid"
        case .signQuiz: return "Märgitest"
        case .signCategoryAll: return "Kõik kategooriad"
        case .signCode(let c): return "Märk \(c)"

        case .noMistakesTitle: return "Vigu pole veel!"
        case .noMistakesSubtitle: return "Valesti vastatud küsimused ilmuvad siia kordamiseks."
        case .activeMistakes(let c): return "\(c) kordamist vajavat viga"
        case .practiceMyMistakes: return "Harjuta minu vigu"

        case .overallProgress: return "Üldine areng"
        case .questionsAttempted: return "Vastatud"
        case .accuracy: return "Täpsus"
        case .recentExams: return "Viimased proovieksamid"
        case .weakAreas: return "Tähelepanu vajavad teemad"
        case .practiceWeakTopics: return "Harjuta nõrku teemasid"
        case .noExamsYet: return "Ühtegi proovieksamit pole veel tehtud"

        case .language: return "Keel"
        case .chooseLanguage: return "Vali oma keel"
        case .premiumTitle: return "Täisversioon"
        case .lifetimeUnlock: return "Eluaegne ligipääs"
        case .unlockAllFeatures: return "Ava kõik küsimused, liiklusmärgid ja piiramatud proovieksamid."
        case .restorePurchases: return "Taasta ostud"
        case .appInfo: return "Rakendusest"
        case .version: return "Versioon 1.0.0"
        case .resetProgress: return "Lähtesta kogu progress"
        case .resetProgressConfirm: return "See kustutab kõik sinu statistika ja vead. Tegevust ei saa tagasi võtta."
        case .cancel: return "Tühista"
        case .done: return "Valmis"
        case .disclaimerTitle: return "Õigusalane teade"
        case .disclaimerBody: return "Eesti Liiklusteooria on iseseisev õpperakendus B-kategooria eksamiks valmistumiseks. See ei ole Transpordiameti ega Eesti Vabariigi ametlik toode ega ole nendega seotud."

        // Monetization & Paywall
        case .unlockFullAccess: return "Ava täisversioon"
        case .monthlyPremiumTitle: return "Kuumaksega Premium"
        case .lifetimePremiumTitle: return "Eluaegne Premium"
        case .perMonth: return "kuus"
        case .oneTimePayment: return "ühekordne ost"
        case .billedMonthly: return "Kuumaksega • Tühista igal ajal"
        case .lifetimeSubtext: return "Maksad korra, kasutad igavesti ilma kuutasuta."
        case .bestValueBadge: return "SOODSAIM VALIK"
        case .unlockButtonContinue: return "Jätka"
        case .unlockButtonLifetime: return "Osta eluaegne ligipääs"
        case .unlockButtonMonthly: return "Telli kuumaksega"
        case .benefit500Questions: return "500+ B-kategooria harjutusküsimust"
        case .benefitUnlimitedMocks: return "Piiramatud proovieksamid"
        case .benefitFullPractice: return "Täielik harjutamine kõigil teemadel"
        case .benefitRoadSignFlashcards: return "Liiklusmärkide mälukaardid"
        case .benefitRoadSignTests: return "Liiklusmärkide testid"
        case .benefitFullMistakes: return "Minu vigade harjutamine"
        case .benefitCompleteProgress: return "Põhjalik edenemise ja valmiduse analüütika"
        case .benefitPracticeMistakes: return "Minu vigade harjutamine"
        case .benefitWeakTopics: return "Nõrkade teemade harjutamine"
        case .benefitProgressReadiness: return "Põhjalik edenemise ja valmiduse analüütika"
        case .benefitDailyGoals: return "Igapäevased eesmärgid ja edenemise jälgimine"
        case .subscriptionDisclosure: return "Kuumaksega tellimus uueneb automaatselt, kui seda ei tühistata vähemalt 24 tundi enne kehtiva perioodi lõppu oma App Store konto seadetes."
        case .oneFreeMockBadge: return "1 tasuta proovieksam"
        case .startFreeMock: return "Alusta tasuta proovieksamit"
        case .mockExamCompletedTitle: return "Tasuta proovieksam tehtud"
        case .mockExamCompletedDescription: return "Oled kasutanud oma tasuta proovieksami. Ava Premium, et teha piiramatult proovieksameid ja harjutada kõiki 500+ küsimust."
        case .unlockUnlimitedMocks: return "Ava piiramatud proovieksamid"
        case .freeQuestionsAvailable(let count): return "\(count) tasuta küsimust"
        case .premiumLockedTopic: return "Ainult Premium"
        case .unlockAllTopicQuestions(let count): return "Ava kõik \(count) küsimust Premiumiga"
        case .flashcardsLockedTitle: return "Liiklusmärkide mälukaardid"
        case .flashcardsLockedSubtitle: return "Õpi selgeks kõik Eesti liiklusmärgid mugavate pööratavate mälukaartidega."
        case .signTestLockedTitle: return "Liiklusmärkide test"
        case .signTestLockedSubtitle: return "Kontrolli oma teadmisi eesõiguse, hoiatus- ja keelumärkide osas."
        case .unlockWithPremium: return "Ava Premiumiga"
        case .premiumActiveStatus: return "Aktiivne"
        case .premiumLifetimeStatus: return "Eluaegne ligipääs"
        case .premiumMonthlyStatus: return "Kuumaksega tellimus"
        case .viewPremiumButton: return "Vaata Premiumi"
        case .termsOfService: return "Kasutustingimused"
        case .privacyPolicy: return "Privaatsuspoliitika"

        // Settings & Paywall Additions
        case .unlockFullAccessSubtitle: return "Ava täielik Estonia Driving Theory õppekogemus."
        case .purchasesUnavailable: return "Ostud on ajutiselt kättesaamatud. Palun proovige hiljem uuesti."
        case .loadingPurchases: return "Ostude laadimine..."
        case .retryLoading: return "Proovi uuesti"
        case .sectionPremium: return "Premium"
        case .proCardTitle: return "Estonia Driving Theory Pro"
        case .freePlan: return "Tasuta pakett"
        case .freePlanDescription: return "Ava täielik küsimustepank, piiramatud proovieksamid, liiklusmärkide testid ja põhjalik analüütika."
        case .upgradeToPro: return "Uuenda Pro paketile"
        case .premiumActive: return "Premium aktiivne"
        case .lifetimeAccess: return "Eluaegne juurdepääs"
        case .monthlyPremium: return "Kuumaksega Premium"
        case .studyPreferences: return "Õppimise eelistused"
        case .dailyGoal: return "Päevane eesmärk"
        case .studyReminder: return "Õppimise meeldetuletus"
        case .reminderTime: return "Meeldetuletuse aeg"
        case .progress: return "Edenemine"
        case .resetProgressTitle: return "Lähtesta kogu edenemine?"
        case .resetProgressMessage: return "See eemaldab teie harjutamise ajaloo, vead, proovieksamite tulemused, järjepidevuse ja eesmärgid. Seda ei saa tagasi võtta."
        case .about: return "Teave"
        case .appNameLabel: return "Rakenduse nimi"
        case .subtitleLabel: return "Alamnimi"
        case .versionLabel: return "Versioon"
        case .supportLabel: return "Klienditugi"
        case .supportWebsiteLabel: return "Klienditoe veebileht"
        case .privacyPolicyLabel: return "Privaatsuspoliitika"
        case .termsOfUseLabel: return "Kasutustingimused"
        case .legal: return "Õiguslik teave"
        case .disclaimerLabel: return "Lahtiütlus"
        case .governmentDisclaimerText: return "Estonia Driving Theory on sõltumatu õpperakendus ega ole seotud, sponsoreeritud ega heaks kiidetud Transpordiameti ega Eesti Vabariigi poolt."

        // Daily Goal
        case .dailyGoalTitle: return "Igapäevane õppeeesmärk"
        case .dailyGoalCardLabel: return "Tänane eesmärk"
        case .dailyGoalCompleted: return "Päevane eesmärk täidetud ✓"
        case .dailyGoalProgress(let done, let target): return "\(done) / \(target) küsimust"
        case .chooseGoal: return "Vali oma igapäevane eesmärk"
        case .goal5: return "5 küsimust / päevas"
        case .goal10: return "10 küsimust / päevas"
        case .goal20: return "20 küsimust / päevas"
        case .goal30: return "30 küsimust / päevas"
        case .goalCustom: return "Kohandatud"
        case .questionsPerDay(let n): return "\(n) küsimust / päevas"

        // Streak
        case .studyStreak: return "Õpistreak"
        case .streakDays(let n): return n == 1 ? "1 päeva streak" : "\(n) päeva streak"
        case .streakZero: return "Alusta oma streaki täna"

        // Readiness
        case .examReadinessExplanation: return "Eksamivalmidus kajastab su hiljutist harjutustulemust ja teemade katvust. See ei ole ametliku eksami tulemuse garanteeritud ennustus."
        case .examReadinessNotEnoughData: return "Valmiduse arvutamiseks vasta rohkematele küsimustele."
        case .examReadinessInfoTitle: return "Mis on eksamivalmidus?"

        // Mock Chart
        case .mockScoreTrend: return "Proovieksami tulemused"
        case .mockScoreTrendEmpty: return "Soorita proovieksam, et näha oma tulemuste trendi."
        case .mockPassLabel: return "Läbitud"
        case .mockFailLabel: return "Mitte läbitud"

        // Activity Calendar
        case .activityCalendar: return "Õppetegevus"
        case .activityCalendarEmpty: return "Alusta harjutamist, et näha oma õppimise ajalugu."
        case .activityNoData: return "Tegevust pole"
        case .activityLightLabel: return "Kerge"
        case .activityMediumLabel: return "Keskmine"
        case .activityStrongLabel: return "Tugev"
        case .activityDayDetail(let q, let acc, let mocks):
            var parts: [String] = []
            parts.append("\(q) küsimust vastatud")
            if q > 0 { parts.append("\(acc)% täpsus") }
            if mocks > 0 { parts.append("\(mocks) proovieksam\(mocks > 1 ? "i" : "") sooritatud") }
            return parts.joined(separator: "  •  ")

        // Topic Performance
        case .topicPerformanceTitle: return "Teemade tulemuslikkus"
        case .topicAccuracy(let a): return "\(a)% täpsus"
        case .topicAttempted(let n): return "\(n) vastatud"
        case .topicMastered(let n): return "\(n) omandatud"
        case .topicStrong: return "Tugev"
        case .topicWeak: return "Vajab tööd"
        case .topicNoData: return "Alustamata"
        case .weakTopicsSection: return "Nõrgimad teemad"

        // Reminder
        case .dailyReminderTitle: return "Igapäevane meeldetuletus"
        case .dailyReminderSubtitle: return "Igapäevane meeldetuletus aitab sul oma eesmärgiga järjepidev olla."
        case .reminderEnabled: return "Sees"
        case .reminderDisabled: return "Väljas"
        case .reminderTimeLabel: return "Meeldetuletuse kellaaeg"
        case .reminderPermissionDenied: return "Teatised pole lubatud"
        case .reminderPermissionDeniedMessage: return "Igapäevaste meeldetuletuste kasutamiseks luba teatised Seadetes."

        // Statistics
        case .statsTitle: return "Statistika"
        case .statsBestMockScore: return "Parim tulemus"
        case .statsMockExamsCompleted: return "Proovieksamid"
        case .statsMistakesRemaining: return "Vead"
        }
    }

    private var russianString: String {
        switch self {
        case .tabHome: return "Главная"
        case .tabPractice: return "Практика"
        case .tabProgress: return "Прогресс"
        case .tabSettings: return "Настройки"

        case .appTitle: return "Теория вождения Эстонии"
        case .categoryB: return "Категория B"
        case .examReadiness: return "Готовность к экзамену"
        case .questionsMastered: return "Освоено"
        case .mockExamPerformance: return "Пробный экзамен"
        case .weakTopics: return "Слабые темы"
        case .continuePractice: return "Продолжить"
        case .resumeRecentTopic: return "Продолжить с того же места"
        case .mockExamTitle: return "Пробный экзамен"
        case .mockExamSubtitle: return "Симуляция экзамена Transpordiamet кат. B"
        case .practiceQuestionsTitle: return "Вопросы по темам"
        case .practiceQuestionsSubtitle: return "Изучение по официальной программе"
        case .myMistakesTitle: return "Мои ошибки"
        case .myMistakesSubtitle: return "Повторение неверно отвеченных вопросов"
        case .roadSignsTitle: return "Дорожные знаки"
        case .roadSignsSubtitle: return "Изучение и тест дорожных знаков Эстонии"

        case .allTopics: return "Все темы"
        case .practiceCategories: return "Темы программы категории B"
        case .totalQuestions(let c): return "\(c) вопросов"
        case .accuracyRate(let a): return "\(a)% точность"
        case .masteredCount(let m): return "\(m) освоено"
        case .mistakesRemaining(let r): return "\(r) ошибок"
        case .startPractice: return "Начать практику"
        case .reviewMistakes: return "Повторить ошибки"
        case .practiceWeak: return "Слабые вопросы"

        case .question: return "Вопрос"
        case .questionOf(let current, let total): return "Вопрос \(current) из \(total)"
        case .whyExplanation: return "Почему?"
        case .trafficActSource: return "Закон о дорожном движении"
        case .nextQuestion: return "Следующий вопрос"
        case .finishQuiz: return "Завершить тест"
        case .quitQuiz: return "Выйти"
        case .quitConfirmTitle: return "Выйти из тренировки?"
        case .quitConfirmMessage: return "Ваш текущий прогресс будет сохранен."
        case .stay: return "Остаться"
        case .quit: return "Выйти"
        case .safetyQuestionBadge: return "КРИТИЧЕСКИЙ ВОПРОС БЕЗОПАСНОСТИ"
        case .wellDone: return "Отличный результат!"
        case .keepPracticing: return "Продолжайте тренироваться!"
        case .quizCompleted: return "Тест завершен"
        case .sessionSummary: return "Итоги сессии"
        case .sessionEndedEarly: return "Тренировка завершена досрочно"
        case .questionsToReview: return "Вопросы для повторения"
        case .noMistakesInSession: return "Отлично! Ни одной ошибки."
        case .practiceMistakesAction: return "Потренировать эти ошибки"
        case .exitAndReview: return "Завершить и посмотреть итоги"
        case .yourAnswerLabel: return "Ваш ответ"
        case .correctAnswerLabel: return "Правильный ответ"
        case .correctStat: return "Верно"
        case .mistakesStat: return "Ошибки"
        case .sessionEarlySubtitle(let n): return "Ваш результат за \(n) отвеченных вопросов."

        case .mockExamRulesTitle: return "Пробный экзамен кат. B"
        case .officialCategoryBRules: return "Формат официального экзамена Transpordiamet"
        case .examDuration: return "Время: 30 минут"
        case .passingRequirements: return "40 вопросов • Максимум 5 ошибок"
        case .strictSafetyLimit: return "В вопросах безопасности макс. 1 ошибка"
        case .startExam: return "Начать экзамен"
        case .timeRemaining: return "Осталось времени"
        case .submitExam: return "Завершить экзамен"
        case .submitConfirmTitle: return "Сдать экзамен?"
        case .submitConfirmMessage: return "Вы готовы отправить все ответы на проверку?"
        case .passed: return "СДАНО"
        case .notPassed: return "НЕ СДАНО"
        case .examScore: return "Результат экзамена"
        case .safetyErrors: return "Ошибки безопасности"
        case .reviewAllAnswers: return "Просмотр ответов"

        case .learnSigns: return "Каталог знаков"
        case .practiceSigns: return "Карточки"
        case .signQuiz: return "Тест по знакам"
        case .signCategoryAll: return "Все категории"
        case .signCode(let c): return "Знак \(c)"

        case .noMistakesTitle: return "Ошибок пока нет!"
        case .noMistakesSubtitle: return "Вопросы с неверными ответами появятся здесь для работы над ошибками."
        case .activeMistakes(let c): return "\(c) ошибок для повторения"
        case .practiceMyMistakes: return "Тренировать ошибки"

        case .overallProgress: return "Общий прогресс"
        case .questionsAttempted: return "Пройдено"
        case .accuracy: return "Точность"
        case .recentExams: return "Недавние пробные экзамены"
        case .weakAreas: return "Темы, требующие внимания"
        case .practiceWeakTopics: return "Тренировать слабые темы"
        case .noExamsYet: return "Пока нет завершенных пробных экзаменов"

        case .language: return "Язык"
        case .chooseLanguage: return "Выберите ваш язык"
        case .premiumTitle: return "Премиум доступ"
        case .lifetimeUnlock: return "Бессрочный доступ"
        case .unlockAllFeatures: return "Все 500+ вопросов, знаки и неограниченные экзамены."
        case .restorePurchases: return "Восстановить покупки"
        case .appInfo: return "О приложении"
        case .version: return "Версия 1.0.0"
        case .resetProgress: return "Сбросить весь прогресс"
        case .resetProgressConfirm: return "Это действие удалит всю статистику и сохраненные ошибки. Отменить невозможно."
        case .cancel: return "Отмена"
        case .done: return "Готово"
        case .disclaimerTitle: return "Правовая информация"
        case .disclaimerBody: return "Estonia Driving Theory Test является независимым образовательным приложением для подготовки к экзамену категории B. Оно не связано с Департаментом транспорта Эстонии (Transpordiamet) и не одобрено государственными органами."

        // Monetization & Paywall
        case .unlockFullAccess: return "Открыть полный доступ"
        case .monthlyPremiumTitle: return "Месячная подписка"
        case .lifetimePremiumTitle: return "Бессрочный доступ"
        case .perMonth: return "в месяц"
        case .oneTimePayment: return "разовый платеж"
        case .billedMonthly: return "Ежемесячно • Отмена в любой момент"
        case .lifetimeSubtext: return "Один платеж навсегда. Никаких регулярных списаний."
        case .bestValueBadge: return "ВЫГОДНЫЙ ВЫБОР"
        case .unlockButtonContinue: return "Продолжить"
        case .unlockButtonLifetime: return "Купить бессрочный доступ"
        case .unlockButtonMonthly: return "Оформить подписку"
        case .benefit500Questions: return "500+ тренировочных вопросов категории B"
        case .benefitUnlimitedMocks: return "Неограниченные пробные экзамены"
        case .benefitFullPractice: return "Полная тренировка по всем темам"
        case .benefitRoadSignFlashcards: return "Карточки дорожных знаков"
        case .benefitRoadSignTests: return "Тесты по дорожным знакам"
        case .benefitFullMistakes: return "Работа над ошибками"
        case .benefitCompleteProgress: return "Полная статистика прогресса и готовности"
        case .benefitPracticeMistakes: return "Работа над ошибками"
        case .benefitWeakTopics: return "Тренировка слабых тем"
        case .benefitProgressReadiness: return "Полная статистика прогресса и готовности"
        case .benefitDailyGoals: return "Ежедневные цели и отслеживание прогресса"
        case .subscriptionDisclosure: return "Подписка продлевается автоматически, если не отключена как минимум за 24 часа до окончания текущего периода в настройках учетной записи App Store."
        case .oneFreeMockBadge: return "1 бесплатный экзамен"
        case .startFreeMock: return "Начать бесплатный экзамен"
        case .mockExamCompletedTitle: return "Бесплатный экзамен завершен"
        case .mockExamCompletedDescription: return "Вы завершили свой бесплатный пробный экзамен. Перейдите на Премиум для неограниченных экзаменов и доступа ко всем 500+ вопросам."
        case .unlockUnlimitedMocks: return "Разблокировать экзамены"
        case .freeQuestionsAvailable(let count): return "\(count) бесплатных вопросов"
        case .premiumLockedTopic: return "Только Премиум"
        case .unlockAllTopicQuestions(let count): return "Открыть все \(count) вопросов в Премиум"
        case .flashcardsLockedTitle: return "Карточки дорожных знаков"
        case .flashcardsLockedSubtitle: return "Изучайте все дорожные знаки Эстонии с помощью интерактивных карточек."
        case .signTestLockedTitle: return "Тест по дорожным знакам"
        case .signTestLockedSubtitle: return "Проверьте знание знаков приоритета, предупреждающих и запрещающих знаков."
        case .unlockWithPremium: return "Открыть с Премиум"
        case .premiumActiveStatus: return "Активен"
        case .premiumLifetimeStatus: return "Бессрочный доступ"
        case .premiumMonthlyStatus: return "Месячная подписка"
        case .viewPremiumButton: return "Перейти на Премиум"
        case .termsOfService: return "Условия использования"
        case .privacyPolicy: return "Политика конфиденциальности"

        // Settings & Paywall Additions
        case .unlockFullAccessSubtitle: return "Откройте все возможности для подготовки к экзамену Estonia Driving Theory."
        case .purchasesUnavailable: return "Покупки временно недоступны. Пожалуйста, попробуйте позже."
        case .loadingPurchases: return "Загрузка покупок..."
        case .retryLoading: return "Повторить"
        case .sectionPremium: return "Премиум"
        case .proCardTitle: return "Estonia Driving Theory Pro"
        case .freePlan: return "Бесплатный план"
        case .freePlanDescription: return "Откройте полную базу вопросов, неограниченные экзамены, тесты дорожных знаков и детальную аналитику."
        case .upgradeToPro: return "Перейти на Pro"
        case .premiumActive: return "Премиум активен"
        case .lifetimeAccess: return "Бессрочный доступ"
        case .monthlyPremium: return "Ежемесячный Премиум"
        case .studyPreferences: return "Настройки обучения"
        case .dailyGoal: return "Ежедневная цель"
        case .studyReminder: return "Напоминание об учебе"
        case .reminderTime: return "Время напоминания"
        case .progress: return "Прогресс"
        case .resetProgressTitle: return "Сбросить весь прогресс?"
        case .resetProgressMessage: return "Это удалит историю тренировок, ошибки, результаты пробных экзаменов, серии занятий и цели. Это действие нельзя отменить."
        case .about: return "О приложении"
        case .appNameLabel: return "Название приложения"
        case .subtitleLabel: return "Подзаголовок"
        case .versionLabel: return "Версия"
        case .supportLabel: return "Поддержка"
        case .supportWebsiteLabel: return "Сайт поддержки"
        case .privacyPolicyLabel: return "Политика конфиденциальности"
        case .termsOfUseLabel: return "Условия использования"
        case .legal: return "Правовая информация"
        case .disclaimerLabel: return "Отказ от ответственности"
        case .governmentDisclaimerText: return "Estonia Driving Theory — это независимое образовательное приложение, которое не связано с Департаментом транспорта Эстонии (Transpordiamet) или Эстонской Республикой, не спонсируется и не одобряется ими."

        // Daily Goal
        case .dailyGoalTitle: return "Ежедневная цель"
        case .dailyGoalCardLabel: return "Цель на сегодня"
        case .dailyGoalCompleted: return "Дневная цель выполнена ✓"
        case .dailyGoalProgress(let done, let target): return "\(done) / \(target) вопросов"
        case .chooseGoal: return "Выберите ежедневную цель"
        case .goal5: return "5 вопросов / день"
        case .goal10: return "10 вопросов / день"
        case .goal20: return "20 вопросов / день"
        case .goal30: return "30 вопросов / день"
        case .goalCustom: return "Произвольно"
        case .questionsPerDay(let n): return "\(n) вопросов / день"

        // Streak
        case .studyStreak: return "Серия занятий"
        case .streakDays(let n): return n == 1 ? "1 день подряд" : "\(n) дн. подряд"
        case .streakZero: return "Начните серию сегодня"

        // Readiness
        case .examReadinessExplanation: return "Готовность отражает вашу недавнюю успеваемость и охват тем. Это не гарантированный прогноз результата официального экзамена."
        case .examReadinessNotEnoughData: return "Ответьте на больше вопросов, чтобы рассчитать готовность."
        case .examReadinessInfoTitle: return "О готовности к экзамену"

        // Mock Chart
        case .mockScoreTrend: return "Результаты пробных экзаменов"
        case .mockScoreTrendEmpty: return "Пройдите пробный экзамен, чтобы увидеть динамику результатов."
        case .mockPassLabel: return "Сдано"
        case .mockFailLabel: return "Не сдано"

        // Activity Calendar
        case .activityCalendar: return "Активность занятий"
        case .activityCalendarEmpty: return "Начните практику, чтобы увидеть историю занятий."
        case .activityNoData: return "Нет активности"
        case .activityLightLabel: return "Лёгкая"
        case .activityMediumLabel: return "Средняя"
        case .activityStrongLabel: return "Высокая"
        case .activityDayDetail(let q, let acc, let mocks):
            var parts: [String] = []
            parts.append("\(q) вопросов отвечено")
            if q > 0 { parts.append("\(acc)% точность") }
            if mocks > 0 { parts.append("\(mocks) пробн. экз.") }
            return parts.joined(separator: "  •  ")

        // Topic Performance
        case .topicPerformanceTitle: return "Успеваемость по темам"
        case .topicAccuracy(let a): return "\(a)% точность"
        case .topicAttempted(let n): return "\(n) попыток"
        case .topicMastered(let n): return "\(n) освоено"
        case .topicStrong: return "Хорошо"
        case .topicWeak: return "Требует работы"
        case .topicNoData: return "Не начато"
        case .weakTopicsSection: return "Слабые темы"

        // Reminder
        case .dailyReminderTitle: return "Ежедневное напоминание"
        case .dailyReminderSubtitle: return "Ежедневное напоминание помогает придерживаться цели."
        case .reminderEnabled: return "Вкл."
        case .reminderDisabled: return "Выкл."
        case .reminderTimeLabel: return "Время напоминания"
        case .reminderPermissionDenied: return "Уведомления не разрешены"
        case .reminderPermissionDeniedMessage: return "Разрешите уведомления в Настройках, чтобы использовать напоминания."

        // Statistics
        case .statsTitle: return "Статистика"
        case .statsBestMockScore: return "Лучший результат"
        case .statsMockExamsCompleted: return "Экзамены"
        case .statsMistakesRemaining: return "Ошибки"
        }
    }
}
