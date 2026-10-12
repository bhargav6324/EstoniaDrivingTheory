import SwiftUI

public struct RoadSignsView: View {
    @ObservedObject private var signRepo = RoadSignRepository.shared
    @ObservedObject private var localization = LocalizationManager.shared
    @ObservedObject private var premium = PremiumAccessManager.shared
    @State private var selectedTab = 0 // 0 = Browse, 1 = Flashcards, 2 = Sign Test
    @State private var selectedCategory: RoadSignCategory? = nil
    @State private var flashcardIndex = 0
    @State private var isFlipped = false
    @State private var activeQuizConfig: QuizSessionConfig? = nil
    @State private var showPaywall = false

    private var filteredSigns: [RoadSign] {
        if let cat = selectedCategory {
            return signRepo.signs(for: cat)
        }
        return signRepo.signs
    }

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            // Segment Control with Lock Indicators for Free Users
            Picker("", selection: $selectedTab) {
                Text(localization.t(.learnSigns)).tag(0)
                Text(localization.t(.practiceSigns) + (premium.isPremium ? "" : " 🔒")).tag(1)
                Text(localization.t(.signQuiz) + (premium.isPremium ? "" : " 🔒")).tag(2)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .onChange(of: selectedTab) { newTab in
                if newTab != 0 && !premium.isPremium {
                    showPaywall = true
                }
            }

            if selectedTab == 0 {
                browseSignsView
            } else if selectedTab == 1 {
                if premium.isPremium {
                    flashcardsView
                } else {
                    lockedFeatureView(
                        icon: "rectangle.on.rectangle.angled",
                        title: localization.t(.flashcardsLockedTitle),
                        subtitle: localization.t(.flashcardsLockedSubtitle)
                    )
                }
            } else {
                if premium.isPremium {
                    signTestLauncher
                } else {
                    lockedFeatureView(
                        icon: "shield.checkered",
                        title: localization.t(.signTestLockedTitle),
                        subtitle: localization.t(.signTestLockedSubtitle)
                    )
                }
            }
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle(localization.t(.roadSignsTitle))
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $activeQuizConfig) { config in
            QuizView(mode: config.mode, questions: config.questions) {
                activeQuizConfig = nil
            }
        }
        .sheet(isPresented: $showPaywall) {
            PremiumPaywallView()
        }
    }

    // 1. Browse Signs View (100% Free)
    private var browseSignsView: some View {
        VStack(spacing: 12) {
            // Category Filter Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    categoryPill(title: localization.t(.signCategoryAll), isSelected: selectedCategory == nil) {
                        selectedCategory = nil
                    }

                    ForEach(RoadSignCategory.allCases) { cat in
                        categoryPill(title: cat.title(for: localization.currentLanguage), isSelected: selectedCategory == cat) {
                            selectedCategory = cat
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 4)
            }

            // Signs Grid
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                    ForEach(filteredSigns) { sign in
                        NavigationLink(destination: RoadSignDetailView(sign: sign)) {
                            VStack(spacing: 10) {
                                TrafficSignVectorView(
                                    shape: sign.shape,
                                    symbolType: sign.symbolType,
                                    speedValue: sign.speedValue,
                                    size: 64
                                )
                                .frame(height: 70)

                                Text(localization.t(.signCode(sign.code)))
                                    .font(.system(.caption2, design: .monospaced).bold())
                                    .foregroundColor(AppColors.estoniaBlue)

                                Text(sign.name(for: localization.currentLanguage))
                                    .font(.system(.subheadline, design: .rounded).bold())
                                    .foregroundColor(AppColors.textPrimary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                            }
                            .frame(maxWidth: .infinity)
                            .appCard(padding: 14)
                        }
                    }
                }
                .padding(20)
            }
        }
    }

    private func categoryPill(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(.caption, design: .rounded).bold())
                .foregroundColor(isSelected ? .white : AppColors.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? AppColors.estoniaBlue : AppColors.cardBackground)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(isSelected ? AppColors.estoniaBlue : AppColors.cardBorder, lineWidth: 1))
        }
    }

    // 2. Interactive Flashcards View (Premium)
    private var flashcardsView: some View {
        VStack(spacing: 24) {
            Spacer()

            if !signRepo.signs.isEmpty {
                let currentSign = signRepo.signs[flashcardIndex % signRepo.signs.count]

                // Flip Card
                ZStack {
                    if !isFlipped {
                        // Front: Big Vector Sign
                        VStack(spacing: 20) {
                            Text(localization.t(.signCode(currentSign.code)))
                                .font(.system(.title3, design: .monospaced).bold())
                                .foregroundColor(AppColors.estoniaBlue)

                            TrafficSignVectorView(
                                shape: currentSign.shape,
                                symbolType: currentSign.symbolType,
                                speedValue: currentSign.speedValue,
                                size: 120
                            )

                            Text("Tap to reveal meaning")
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }
                    } else {
                        // Back: Meaning & Legal Rule
                        VStack(spacing: 14) {
                            Text(currentSign.name(for: localization.currentLanguage))
                                .font(.system(.title3, design: .rounded).bold())
                                .foregroundColor(AppColors.textPrimary)
                                .multilineTextAlignment(.center)

                            Text(currentSign.meaning(for: localization.currentLanguage))
                                .font(.body)
                                .foregroundColor(AppColors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)

                            if let rule = currentSign.content(for: localization.currentLanguage).legalRule {
                                Text(rule)
                                    .font(.caption.bold())
                                    .foregroundColor(AppColors.estoniaBlue)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 320)
                .appCard(padding: 24)
                .padding(.horizontal, 24)
                .onTapGesture {
                    withAnimation(.spring()) {
                        isFlipped.toggle()
                    }
                }

                // Flashcard Controls
                HStack(spacing: 20) {
                    Button {
                        if flashcardIndex > 0 {
                            isFlipped = false
                            flashcardIndex -= 1
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(flashcardIndex > 0 ? AppColors.textPrimary : AppColors.textTertiary)
                            .frame(width: 54, height: 54)
                            .background(AppColors.cardBackground)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(AppColors.cardBorder, lineWidth: 1))
                    }
                    .disabled(flashcardIndex == 0)

                    Text("\(flashcardIndex + 1) / \(signRepo.signs.count)")
                        .font(.system(.subheadline, design: .rounded).bold())
                        .foregroundColor(AppColors.textSecondary)

                    Button {
                        if flashcardIndex < signRepo.signs.count - 1 {
                            isFlipped = false
                            flashcardIndex += 1
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.title2)
                            .foregroundColor(flashcardIndex < signRepo.signs.count - 1 ? AppColors.textPrimary : AppColors.textTertiary)
                            .frame(width: 54, height: 54)
                            .background(AppColors.cardBackground)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(AppColors.cardBorder, lineWidth: 1))
                    }
                    .disabled(flashcardIndex >= signRepo.signs.count - 1)
                }
            }

            Spacer()
        }
    }

    // 3. Sign Test Launcher (Premium)
    private var signTestLauncher: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "shield.checkered")
                    .font(.system(size: 56))
                    .foregroundColor(AppColors.estoniaBlue)

                Text(localization.t(.signQuiz))
                    .font(.system(.title2, design: .rounded).bold())
                    .foregroundColor(AppColors.textPrimary)

                Text("Test your knowledge of Estonian priority, prohibitory, and warning road signs.")
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()

            Button {
                let questions = QuestionRepository.shared.signTestQuestions()
                guard !questions.isEmpty else { return }
                activeQuizConfig = QuizSessionConfig(mode: .roadSigns, questions: questions)
            } label: {
                Text(localization.t(.startPractice))
                    .primaryButton()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }

    // 4. Locked Feature State
    private func lockedFeatureView(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(AppColors.warningAmber.opacity(0.15))
                        .frame(width: 80, height: 80)
                    Image(systemName: "lock.fill")
                        .font(.system(size: 36))
                        .foregroundColor(AppColors.warningAmber)
                }

                Text(title)
                    .font(.system(.title2, design: .rounded).bold())
                    .foregroundColor(AppColors.textPrimary)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            Button {
                showPaywall = true
            } label: {
                HStack {
                    Image(systemName: "crown.fill")
                    Text(localization.t(.unlockWithPremium))
                }
                .primaryButton()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
}
