import SwiftUI

@main
struct EstoniaDrivingTheoryApp: App {
    @StateObject private var localization = LocalizationManager.shared
    @StateObject private var progressStore = ProgressStore.shared
    @StateObject private var questionRepo = QuestionRepository.shared
    @StateObject private var signRepo = RoadSignRepository.shared
    @StateObject private var premium = PremiumAccessManager.shared
    @StateObject private var storeKit = StoreKitManager.shared
    @StateObject private var goalManager = DailyGoalManager.shared

    init() {
        #if DEBUG
        print("🚀 [APP STARTUP] Running Bundle ID: \(Bundle.main.bundleIdentifier ?? "UNKNOWN")")
        _ = MonetizationVerification.runAllTests()
        _ = QuizExitVerification.runAllTests()
        Task { @MainActor in
            _ = await StoreKitLiveVerification.runAllTests()
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(localization)
                .environmentObject(progressStore)
                .environmentObject(questionRepo)
                .environmentObject(signRepo)
                .environmentObject(premium)
                .environmentObject(storeKit)
                .environmentObject(goalManager)
        }
    }
}
