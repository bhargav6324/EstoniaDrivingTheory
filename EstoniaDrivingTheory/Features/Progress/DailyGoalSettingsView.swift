import SwiftUI

/// Sheet for configuring the daily question goal and optional reminder.
struct DailyGoalSettingsView: View {
    @ObservedObject private var goalManager = DailyGoalManager.shared
    @ObservedObject private var localization = LocalizationManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTarget: Int
    @State private var customTarget: String = ""
    @State private var isCustom: Bool = false
    @State private var reminderEnabled: Bool
    @State private var reminderHour: Int
    @State private var reminderMinute: Int
    @State private var showPermissionAlert = false
    @State private var isSaving = false

    private let presetTargets = [5, 10, 20, 30]

    init() {
        let goal = DailyGoalManager.shared.goal
        _selectedTarget = State(initialValue: goal.targetQuestions)
        _reminderEnabled = State(initialValue: goal.reminderEnabled)
        _reminderHour = State(initialValue: goal.reminderHour)
        _reminderMinute = State(initialValue: goal.reminderMinute)
        _isCustom = State(initialValue: ![5, 10, 20, 30].contains(goal.targetQuestions))
        _customTarget = State(initialValue: "\(goal.targetQuestions)")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    goalPickerSection
                    reminderSection
                }
                .padding(20)
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle(localization.t(.dailyGoalTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(localization.t(.done)) {
                        saveAndDismiss()
                    }
                    .font(.headline)
                    .foregroundColor(AppColors.estoniaBlue)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(localization.t(.cancel)) {
                        dismiss()
                    }
                    .foregroundColor(AppColors.textSecondary)
                }
            }
            .alert(localization.t(.reminderPermissionDenied), isPresented: $showPermissionAlert) {
                Button(localization.t(.done)) {}
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            } message: {
                Text(localization.t(.reminderPermissionDeniedMessage))
            }
        }
    }

    // MARK: - Goal Picker

    private var goalPickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localization.t(.chooseGoal))
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)

            VStack(spacing: 8) {
                ForEach(presetTargets, id: \.self) { target in
                    goalOption(target: target)
                }
                customOption
            }
        }
        .appCard(padding: 16)
    }

    private func goalOption(target: Int) -> some View {
        let isSelected = !isCustom && selectedTarget == target
        return Button {
            withAnimation(.spring(response: 0.3)) {
                selectedTarget = target
                isCustom = false
            }
        } label: {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? AppColors.estoniaBlue : AppColors.textTertiary)
                    .font(.title3)

                Text(goalLabel(for: target))
                    .font(.subheadline)
                    .foregroundColor(AppColors.textPrimary)

                if target == 10 {
                    Spacer()
                    Text("★ \(localization.t(.bestValueBadge))")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(AppColors.estoniaBlue)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(AppColors.estoniaBlue.opacity(0.12))
                        .clipShape(Capsule())
                } else {
                    Spacer()
                }
            }
            .padding(12)
            .background(isSelected ? AppColors.estoniaBlue.opacity(0.08) : AppColors.cardBackgroundElevated)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isSelected ? AppColors.estoniaBlue.opacity(0.4) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    private var customOption: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isCustom = true
                }
            } label: {
                HStack {
                    Image(systemName: isCustom ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isCustom ? AppColors.estoniaBlue : AppColors.textTertiary)
                        .font(.title3)
                    Text(localization.t(.goalCustom))
                        .font(.subheadline)
                        .foregroundColor(AppColors.textPrimary)
                    Spacer()
                }
                .padding(12)
                .background(isCustom ? AppColors.estoniaBlue.opacity(0.08) : AppColors.cardBackgroundElevated)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(isCustom ? AppColors.estoniaBlue.opacity(0.4) : Color.clear, lineWidth: 1.5)
                )
            }
            .buttonStyle(.plain)

            if isCustom {
                HStack {
                    TextField("15", text: $customTarget)
                        .keyboardType(.numberPad)
                        .font(.system(.body, design: .rounded))
                        .padding(10)
                        .background(AppColors.cardBackgroundElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(AppColors.activeBorder, lineWidth: 1)
                        )
                    Text("questions / day")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding(.horizontal, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func goalLabel(for target: Int) -> String {
        switch target {
        case 5:  return localization.t(.goal5)
        case 10: return localization.t(.goal10)
        case 20: return localization.t(.goal20)
        case 30: return localization.t(.goal30)
        default: return localization.t(.questionsPerDay(target))
        }
    }

    // MARK: - Reminder Section

    private var reminderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bell.fill")
                    .foregroundColor(AppColors.estoniaBlue)
                VStack(alignment: .leading, spacing: 2) {
                    Text(localization.t(.dailyReminderTitle))
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)
                    Text(localization.t(.dailyReminderSubtitle))
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                Spacer()
                Toggle("", isOn: $reminderEnabled)
                    .labelsHidden()
                    .tint(AppColors.estoniaBlue)
                    .onChange(of: reminderEnabled) { _, newValue in
                        if newValue {
                            DailyGoalManager.shared.setReminderEnabled(true) { granted in
                                if !granted {
                                    reminderEnabled = false
                                    showPermissionAlert = true
                                }
                            }
                        } else {
                            DailyGoalManager.shared.setReminderEnabled(false) { _ in }
                        }
                    }
            }

            if reminderEnabled {
                Divider()

                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(AppColors.textSecondary)
                    Text(localization.t(.reminderTimeLabel))
                        .font(.subheadline)
                        .foregroundColor(AppColors.textPrimary)
                    Spacer()

                    // Time picker using wheels
                    DatePicker(
                        "",
                        selection: timeBinding,
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .tint(AppColors.estoniaBlue)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .appCard(padding: 16)
    }

    private var timeBinding: Binding<Date> {
        Binding(
            get: {
                var c = DateComponents()
                c.hour = reminderHour
                c.minute = reminderMinute
                return Calendar.current.date(from: c) ?? Date()
            },
            set: { newDate in
                let c = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                reminderHour = c.hour ?? 19
                reminderMinute = c.minute ?? 0
            }
        )
    }

    // MARK: - Save

    private func saveAndDismiss() {
        var target: Int
        if isCustom {
            target = max(1, Int(customTarget) ?? 10)
        } else {
            target = selectedTarget
        }

        DailyGoalManager.shared.updateGoal(targetQuestions: target)
        DailyGoalManager.shared.updateReminderTime(hour: reminderHour, minute: reminderMinute)
        dismiss()
    }
}
