import Foundation
import StoreKit

@MainActor
public struct MonetizationVerification {
    public static func runAllTests() -> [String: Bool] {
        var results: [String: Bool] = [:]
        let manager = PremiumAccessManager.shared

        let initialPremium = manager.isPremium
        let initialType = manager.subscriptionType
        let initialHasCompletedFreeMock = manager.hasCompletedFreeMock

        // Test A: New user state
        manager.setPremiumState(unlocked: false, type: nil)
        manager.setHasCompletedFreeMockForTesting(false)
        let isFree = !manager.isPremium
        results["A_isFreeByDefault"] = isFree

        // Test B: 40 Free Questions pool
        let poolCount = manager.freeQuestionIDs.count
        results["B_freeQuestionPoolIs40"] = (poolCount == 40)
        let accessibleFreeCount = manager.accessibleQuestions().count
        results["B_accessibleCountIs40"] = (accessibleFreeCount == 40)

        // Test C: Practice filtering
        var totalAcrossTopics = 0
        for topic in TopicCategory.allCases {
            totalAcrossTopics += manager.freeQuestionsCount(for: topic)
        }
        results["C_freePracticeDistributionEquals40"] = (totalAcrossTopics == 40)

        // Test D: Free Mock allowance & completion
        // Before completion
        let canTakeFirstMock = manager.canAccess(feature: .unlimitedMockExams)
        results["D_canTakeFirstFreeMock"] = canTakeFirstMock

        // Mark completed
        manager.markFreeMockCompleted()
        results["D_hasCompletedFreeMock"] = manager.hasCompletedFreeMock
        let canTakeSecondMock = manager.canAccess(feature: .unlimitedMockExams)
        results["D_secondMockIsBlockedWithoutPremium"] = (!canTakeSecondMock)

        // Test E: Road Signs Gating
        results["E_flashcardsLockedForFree"] = !manager.canAccess(feature: .roadSignFlashcards)
        results["E_signTestLockedForFree"] = !manager.canAccess(feature: .roadSignTest)

        // Test F: Mistake filtering
        let sampleFreeQ = manager.freeQuestionIDs.first!
        let samplePaidQ = QuestionRepository.shared.questions.first(where: { !manager.freeQuestionIDs.contains($0.id) })!.id
        let freeMistakeIds = Set(manager.accessibleQuestions().map { $0.id })
        results["F_freeMistakesIncludesFreeQ"] = freeMistakeIds.contains(sampleFreeQ)
        results["F_freeMistakesExcludesPaidQ"] = !freeMistakeIds.contains(samplePaidQ)

        // Test G: Premium Unlock (Lifetime)
        manager.setPremiumState(unlocked: true, type: .lifetime)
        results["G_lifetimeUnlocked"] = manager.isPremium
        results["G_lifetimeAccessAllQuestions"] = (manager.accessibleQuestions().count == QuestionRepository.shared.questions.count)
        results["G_lifetimeUnlocksMocks"] = manager.canAccess(feature: .unlimitedMockExams)
        results["G_lifetimeUnlocksFlashcards"] = manager.canAccess(feature: .roadSignFlashcards)
        results["G_lifetimeUnlocksSignTest"] = manager.canAccess(feature: .roadSignTest)

        // Test H: Premium Unlock (Monthly)
        manager.setPremiumState(unlocked: true, type: .monthly)
        results["H_monthlyUnlocked"] = manager.isPremium
        results["H_monthlySubscriptionType"] = (manager.subscriptionType == .monthly)

        // Test I: Subscription Expiration
        manager.setPremiumState(unlocked: false, type: nil)
        results["I_expiredSubscriptionReturnsToFree"] = (!manager.isPremium)
        results["I_poolRemainsPreservedAfterExpiration"] = (manager.freeQuestionIDs.count == 40)

        // Restore state after testing so it does not destroy user/testing session
        manager.setPremiumState(unlocked: initialPremium, type: initialType)
        manager.setHasCompletedFreeMockForTesting(initialHasCompletedFreeMock)

        // Log results
        print("\n=== MONETIZATION VERIFICATION SUITE RESULTS ===")
        for (testName, passed) in results.sorted(by: { $0.key < $1.key }) {
            print("  \(passed ? "✅ PASS" : "❌ FAIL"): \(testName)")
        }
        print("===============================================\n")

        return results
    }
}

@MainActor
public struct QuizExitVerification {
    public static func runAllTests() -> [String: Bool] {
        var results: [String: Bool] = [:]

        let savedProgress = ProgressStore.shared.questionProgressMap
        let savedMistakes = ProgressStore.shared.mistakesMap

        let sampleQuestions = Array(QuestionRepository.shared.questions.prefix(5))
        guard sampleQuestions.count >= 2 else {
            print("⚠️ Not enough questions to run QuizExitVerification")
            return [:]
        }

        let vm = QuizViewModel(mode: .generalPractice, questions: sampleQuestions)

        // 1. Initial State
        results["1_initialState"] = (vm.attemptedCount == 0 && vm.mistakesCount == 0 && vm.correctCount == 0 && !vm.isCompleted && !vm.isEndedEarly)

        // 2. Answer first question correctly
        let q1 = sampleQuestions[0]
        let correctChoice1 = q1.correctIndex(for: LocalizationManager.shared.currentLanguage)
        vm.selectOption(correctChoice1)
        results["2_answerCorrect"] = (vm.attemptedCount == 1 && vm.correctCount == 1 && vm.mistakesCount == 0 && vm.accuracyPercentage == 100)

        // 3. Move to next question and answer incorrectly
        vm.nextQuestion()
        let q2 = sampleQuestions[1]
        let correctChoice2 = q2.correctIndex(for: LocalizationManager.shared.currentLanguage)
        let wrongChoice2 = (correctChoice2 + 1) % max(1, q2.options(for: LocalizationManager.shared.currentLanguage).count)
        vm.selectOption(wrongChoice2)

        results["3_answerIncorrect"] = (vm.attemptedCount == 2 && vm.correctCount == 1 && vm.mistakesCount == 1 && vm.accuracyPercentage == 50)
        results["3_mistakeIdentified"] = (vm.mistakeQuestions.count == 1 && vm.mistakeQuestions.first?.id == q2.id)

        // 4. Exit midway
        vm.endSessionEarly()
        results["4_endedEarlyFlags"] = (vm.isEndedEarly && vm.isCompleted)
        results["4_attemptedCountPreserved"] = (vm.attemptedCount == 2)
        results["4_mistakesCountPreserved"] = (vm.mistakesCount == 1)

        // 5. Restart with mistakes
        vm.restartWithMistakes()
        results["5_restartPoolIsOnlyMistakes"] = (vm.questions.count == 1 && vm.questions.first?.id == q2.id)
        results["5_resetFlags"] = (!vm.isEndedEarly && !vm.isCompleted && vm.attemptedCount == 0)

        // Restore ProgressStore clean state
        ProgressStore.shared.restoreForTesting(progress: savedProgress, mistakes: savedMistakes)

        print("\n=== QUIZ EXIT & SUMMARY VERIFICATION RESULTS ===")
        for (testName, passed) in results.sorted(by: { $0.key < $1.key }) {
            print("  \(passed ? "✅ PASS" : "❌ FAIL"): \(testName)")
        }
        print("================================================\n")

        return results
    }
}

@MainActor
public struct StoreKitLiveVerification {
    public static func runAllTests() async -> [String: Bool] {
        var results: [String: Bool] = [:]
        let manager = PremiumAccessManager.shared

        await manager.loadProducts()

        let lifetime = manager.lifetimeProduct
        let monthly = manager.monthlyProduct

        results["SK_1_lifetimeProductLoaded"] = (lifetime != nil)
        results["SK_2_monthlyProductLoaded"] = (monthly != nil)
        results["SK_3_lifetimePriceNonEmpty"] = !(lifetime?.displayPrice.isEmpty ?? true)
        results["SK_4_monthlyPriceNonEmpty"] = !(monthly?.displayPrice.isEmpty ?? true)
        results["SK_5_storefrontNonEmpty"] = (await Storefront.current != nil)

        print("\n=== STOREKIT LIVE VERIFICATION RESULTS ===")
        print("  • Lifetime Product ID: \(lifetime?.id ?? "N/A") | Title: \(lifetime?.displayName ?? "N/A") | Price: \(lifetime?.displayPrice ?? "N/A")")
        print("  • Monthly Product ID: \(monthly?.id ?? "N/A") | Title: \(monthly?.displayName ?? "N/A") | Price: \(monthly?.displayPrice ?? "N/A")")
        for (testName, passed) in results.sorted(by: { $0.key < $1.key }) {
            print("  \(passed ? "✅ PASS" : "❌ FAIL"): \(testName)")
        }
        print("==========================================\n")

        return results
    }
}

