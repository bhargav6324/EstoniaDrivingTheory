# Estonia Driving Theory Test (Category B) 🇪🇪 🚗

A modern, production-quality native iOS application built with **Swift** and **SwiftUI** to prepare learners for the **Estonian Category B Driving Theory Examination**.

---

## 🌟 Key Features

### 1. Trilingual Support (EN / ET / RU)
- **English 🇬🇧, Eesti 🇪🇪, and Русский 🇷🇺**.
- First launch language picker modal.
- Instant language switching across all screens from Settings without restarting the app.
- Question statements, 4 answer choices, "Why?" explanations, and Estonian Traffic Act legal references are fully localized in all 3 languages.

### 2. Clean Card-Based Native UI
- Follows modern iOS Human Interface Guidelines and the design philosophy of premium exam-prep apps.
- San Francisco native typography, rounded 16pt cards, and adaptive light/dark mode support.
- Custom Estonian blue palette (`#0072CE`) with high-contrast accessibility status badges.

### 3. Home Dashboard
- **Header**: "Estonia Driving Theory" • "Category B" with 1-tap language switch pill.
- **Exam Readiness Card**: Real-time readiness percentage gauge calculated from question mastery, recent mock exams, and weak topic performance.
- **Continue Practice Card**: Prominent one-tap action resuming your most recent topic.
- **Main Action Cards**:
  - 📋 **Mock Exam** (official Transpordiamet test simulation)
  - 📚 **Practice Questions** (study by curriculum topics)
  - ⚠️ **My Mistakes** (focused repetition of incorrectly answered questions with active mistake counter)
  - 🛡️ **Road Signs** (learn and test Estonian road signs)

### 4. Practice & Topic Taxonomy
Structured according to the official Estonian Category B curriculum:
- General Traffic Rules (*Liiklusreeglid*)
- Right of Way & Intersections (*Eesõigus ja ristmikud*)
- Speed & Safe Distance (*Kiirus ja pikivahe*)
- Overtaking & Manoeuvres (*Möödasõit ja manöövrid*)
- Stopping & Parking (*Peatumine ja parkimine*)
- Pedestrians & Cyclists (*Jalakäijad ja jalgratturid*)
- Road Signs & Markings (*Liiklusmärgid ja märgised*)
- Vehicle Safety & Maintenance (*Sõiduki ohutus ja korrashoid*)
- Driver Duties & Health (*Juhi kohustused ja tervis*)
- Hazards & Winter Conditions (*Ohud ja talvised teeolud*)
- Motorways & Special Roads (*Kiirteed ja eriolud*)
- Emergencies & First Aid (*Hädaolukorrad ja esmaabi*)

### 5. Interactive Quiz Engine
- Top progress tracker with clean animated progress bar.
- Critical safety question callout badge.
- Vector traffic diagrams & road signs rendered natively in SwiftUI.
- Large tappable answer cards (A, B, C, D) with distinct tap feedback.
- Instant feedback drawer:
  - Clear checkmark / cross indicator
  - **"Why?"** explanation detailing why the answer is correct
  - **Source Citation**: Direct legal reference to the Estonian Traffic Act (*Liiklusseadus*).

### 6. Visual Traffic Situations Engine
Pure vector SwiftUI components (no bloated raster PNGs):
- `IntersectionView`: 4-way crossroads, T-junctions, and roundabouts with road markings, centerlines, and zebra crossings.
- `VehicleVectorView`: Top-down car model with customizable colors, windshields, headlights, brake lights, and turn trajectory arrows.
- `TrafficSignVectorView`: Vector rendering of Priority Road (211), Give Way (221), Stop (222), Speed Limits (311), No Entry (331), Roundabout (421), and Pedestrian Crossings (543).
- `TrafficLightVectorView`: Realistic traffic light with active glowing state.

### 7. Road Signs Section
- **Browse Signs**: Filter by official categories (Warning, Priority, Prohibitory, Mandatory, Special Regulation).
- **Detail View**: High-resolution vector preview, official code (e.g. 111, 211, 221), name, description, and legal rules.
- **Flashcards Mode**: Interactive tap-to-flip cards to test recognition.
- **Sign Test**: Dedicated mixed sign quiz.

### 8. Category B Mock Exam Engine
Centralized `ExamConfiguration`:
- **40 questions**
- **30 minutes countdown timer**
- **Passing criteria**: Max 5 total errors (at least 35 / 40 correct)
- **Safety tolerance**: Max 1 error on critical safety questions
- Pre-exam briefing sheet
- Real-time exam navigator grid with question flags
- Post-exam score report: Passed / Not Passed banner, topic score breakdown, and "Review All Answers" sheet.

### 9. Local Progress & Mistakes Tracking
- 100% offline-ready.
- Local persistence using Apple-native `UserDefaults` and JSON storage.
- Tracks question attempts, correct count, consecutive correct answers, and mastery status.
- Automatically captures incorrect answers in **My Mistakes** and removes them once mastered.

### 10. StoreKit 2 Monetization Architecture
- Designed for StoreKit 2 with canonical **Lifetime Premium** (`com.estoniadrivingtheory.premium.lifetime`) and **Monthly Premium** (`com.estoniadrivingtheory.premium.monthly`).
- Built-in Restore Purchases via `AppStore.sync()` and verified entitlement management.

---

## 📁 Project Architecture

```
estonian driving exam/
├── EstoniaDrivingTheory.xcodeproj/     # Xcode Project
│   └── project.pbxproj
├── EstoniaDrivingTheory/
│   ├── App/
│   │   ├── EstoniaDrivingTheoryApp.swift
│   │   └── RootView.swift
│   ├── Models/
│   │   ├── Language.swift             # AppLanguage (EN, ET, RU)
│   │   ├── Topic.swift                # TopicCategory (12 curriculum topics)
│   │   ├── Question.swift             # Multilingual Question & LegalSource
│   │   ├── VisualScenario.swift       # Declarative Vector Traffic Models
│   │   ├── RoadSign.swift             # RoadSign & SignShape
│   │   ├── ExamConfiguration.swift    # Official B-Category Exam & Results
│   │   └── UserProgress.swift         # Mastery & Mistake Tracking
│   ├── Services/
│   │   ├── LocalizationManager.swift  # Trilingual UI Strings
│   │   ├── QuestionRepository.swift   # Question Bank & Exam Generator
│   │   ├── RoadSignRepository.swift   # Estonian Road Signs Database
│   │   ├── ProgressStore.swift        # Local Persistence & Analytics
│   │   └── StoreKitManager.swift      # StoreKit 2 In-App Purchases
│   ├── DesignSystem/
│   │   ├── AppColors.swift            # Estonian Blue & Semantic Palette
│   │   └── CardModifier.swift         # Native Card Styling & Buttons
│   ├── Components/
│   │   ├── CircularProgressView.swift # Gauge for Readiness & Scores
│   │   ├── ProgressBarView.swift      # Linear Progress Indicator
│   │   ├── StatCardView.swift         # Metric Cards
│   │   ├── AnswerOptionCard.swift     # Large Tappable Answer Cards
│   │   ├── LanguagePickerSheet.swift  # Language Switcher
│   │   └── VisualGraphics/
│   │       ├── IntersectionView.swift
│   │       ├── VehicleVectorView.swift
│   │       ├── TrafficSignVectorView.swift
│   │       └── TrafficLightVectorView.swift
│   ├── Features/
│   │   ├── Home/                      # Dashboard & Quick Actions
│   │   ├── Practice/                  # Curriculum Topics & Details
│   │   ├── Quiz/                      # Question presentation & Feedback
│   │   ├── MockExam/                  # Category B Exam Engine & Results
│   │   ├── RoadSigns/                 # Catalog, Flashcards, Sign Test
│   │   ├── Mistakes/                  # Mistake Repetition
│   │   ├── Progress/                  # Statistics & Weak Areas
│   │   └── Settings/                  # Language, Lifetime Unlock, Legal
│   └── Resources/
│       └── Assets.xcassets/
```

---

## 🚀 How to Run in Xcode

1. Open **Xcode** on your Mac.
2. Choose **Open Existing Project** and select:
   ```
   /Users/bhargavpatil/driving app/estonian driving exam/EstoniaDrivingTheory.xcodeproj
   ```
3. Select an **iPhone Simulator** (e.g., iPhone 16, iPhone 16 Pro) or a connected iPhone.
4. Press **⌘ + R** (Command + R) or click the **Play** button in the Xcode toolbar.
