import SwiftUI

public struct RootView: View {
    @ObservedObject private var localization = LocalizationManager.shared
    @State private var selectedTab: Int = 0

    public init() {}

    public var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label(localization.t(.tabHome), systemImage: "house.fill")
                }
                .tag(0)

            PracticeView()
                .tabItem {
                    Label(localization.t(.tabPractice), systemImage: "square.grid.2x2.fill")
                }
                .tag(1)

            ProgressView()
                .tabItem {
                    Label(localization.t(.tabProgress), systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label(localization.t(.tabSettings), systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .accentColor(AppColors.estoniaBlue)
        .sheet(isPresented: Binding(
            get: { !localization.hasSelectedLanguageOnboarding },
            set: { _ in }
        )) {
            LanguagePickerSheet(isDismissable: false)
        }
    }
}
