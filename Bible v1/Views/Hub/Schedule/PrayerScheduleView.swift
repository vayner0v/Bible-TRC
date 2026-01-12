//
//  PrayerScheduleView.swift
//  Bible v1
//
//  Spiritual Hub - Prayer Schedule Management
//

import SwiftUI

struct PrayerScheduleView: View {
    @ObservedObject private var notificationService = NotificationService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var showAddSchedule = false
    @State private var selectedSchedule: PrayerSchedule?
    @State private var showAuthorizationAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Authorization warning if needed
                        if !notificationService.isAuthorized {
                            authorizationCard
                        }
                        
                        // Today's schedule
                        if !todaysSchedules.isEmpty {
                            todaysSection
                        }
                        
                        // All schedules
                        allSchedulesSection
                        
                        // Preset suggestions
                        if notificationService.prayerSchedules.isEmpty {
                            presetSuggestionsSection
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Prayer Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        selectedSchedule = nil
                        showAddSchedule = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddSchedule) {
                AddPrayerScheduleSheet(schedule: selectedSchedule)
            }
            .alert("Enable Notifications", isPresented: $showAuthorizationAlert) {
                Button("Settings", role: .none) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("To receive prayer reminders, please enable notifications in Settings.")
            }
            .onAppear {
                notificationService.checkAuthorization()
            }
        }
    }
    
    // MARK: - Today's Schedules
    
    private var todaysSchedules: [PrayerSchedule] {
        notificationService.prayerSchedules.filter { $0.isScheduledToday && $0.isEnabled }
            .sorted { $0.time < $1.time }
    }
    
    private var todaysSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sun.max.fill")
                    .foregroundColor(.orange)
                Text("Today's Prayer Times")
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
            }
            
            ForEach(todaysSchedules) { schedule in
                TodayScheduleCard(
                    schedule: schedule,
                    onComplete: {
                        notificationService.completeSchedule(id: schedule.id)
                    },
                    onSnooze: {
                        notificationService.snoozeSchedule(id: schedule.id)
                    }
                )
            }
        }
    }
    
    // MARK: - All Schedules
    
    private var allSchedulesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(themeManager.accentColor)
                Text("All Schedules")
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
                
                Spacer()
                
                Text("\(notificationService.prayerSchedules.count)")
                    .font(.subheadline)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            if notificationService.prayerSchedules.isEmpty {
                emptyStateCard
            } else {
                ForEach(notificationService.prayerSchedules.sorted { $0.time < $1.time }) { schedule in
                    ScheduleCard(schedule: schedule) {
                        selectedSchedule = schedule
                        showAddSchedule = true
                    } onToggle: {
                        notificationService.toggleSchedule(id: schedule.id)
                    } onDelete: {
                        notificationService.deleteSchedule(id: schedule.id)
                    }
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.badge")
                .font(.system(size: 48))
                .foregroundColor(themeManager.accentColor.opacity(0.5))
            
            Text("No Prayer Schedules")
                .font(.headline)
                .foregroundColor(themeManager.textColor)
            
            Text("Set up regular prayer times to build a consistent prayer habit")
                .font(.subheadline)
                .foregroundColor(themeManager.secondaryTextColor)
                .multilineTextAlignment(.center)
            
            Button {
                selectedSchedule = nil
                showAddSchedule = true
            } label: {
                Label("Add Schedule", systemImage: "plus")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(themeManager.accentColor)
                    .cornerRadius(12)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(16)
    }
    
    // MARK: - Authorization Card
    
    private var authorizationCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "bell.slash.fill")
                .font(.title2)
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Notifications Disabled")
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
                
                Text("Enable notifications to receive prayer reminders")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            Spacer()
            
            Button("Enable") {
                Task {
                    let granted = await notificationService.requestAuthorization()
                    if !granted {
                        showAuthorizationAlert = true
                    }
                }
            }
            .font(.subheadline.weight(.semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.orange)
            .cornerRadius(8)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Preset Suggestions
    
    private var presetSuggestionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.yellow)
                Text("Quick Start")
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
            }
            
            Text("Start with these common prayer times")
                .font(.subheadline)
                .foregroundColor(themeManager.secondaryTextColor)
            
            ForEach(PrayerSchedule.presets, id: \.name) { preset in
                PresetScheduleCard(schedule: preset) {
                    notificationService.addSchedule(preset)
                }
            }
        }
    }
}

// MARK: - Today Schedule Card

struct TodayScheduleCard: View {
    let schedule: PrayerSchedule
    let onComplete: () -> Void
    let onSnooze: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 16) {
            // Time
            VStack(spacing: 2) {
                Text(schedule.formattedTime)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(schedule.isCompletedToday ? .green : themeManager.textColor)
                
                if schedule.isCompletedToday {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            .frame(width: 70)
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(schedule.name)
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
                
                HStack(spacing: 4) {
                    Image(systemName: schedule.prayerType.icon)
                        .font(.caption)
                    Text(schedule.prayerType.rawValue)
                        .font(.caption)
                }
                .foregroundColor(schedule.prayerType.color)
            }
            
            Spacer()
            
            // Actions
            if !schedule.isCompletedToday {
                HStack(spacing: 8) {
                    Button {
                        onSnooze()
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.title3)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    
                    Button {
                        onComplete()
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .padding()
        .background(
            schedule.isDueNow ?
            schedule.prayerType.color.opacity(0.15) :
            themeManager.cardBackgroundColor
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(schedule.isDueNow ? schedule.prayerType.color : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Schedule Card

struct ScheduleCard: View {
    let schedule: PrayerSchedule
    let onEdit: () -> Void
    let onToggle: () -> Void
    let onDelete: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: schedule.prayerType.icon)
                .font(.title2)
                .foregroundColor(schedule.isEnabled ? schedule.prayerType.color : themeManager.secondaryTextColor)
                .frame(width: 40)
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(schedule.name)
                    .font(.headline)
                    .foregroundColor(schedule.isEnabled ? themeManager.textColor : themeManager.secondaryTextColor)
                
                HStack(spacing: 8) {
                    Text(schedule.formattedTime)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("•")
                    
                    Text(schedule.formattedRepeatDays)
                        .font(.caption)
                }
                .foregroundColor(themeManager.secondaryTextColor)
                
                if schedule.currentStreak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                        Text("\(schedule.currentStreak) day streak")
                            .font(.caption)
                    }
                    .foregroundColor(.orange)
                }
            }
            
            Spacer()
            
            // Toggle
            Toggle("", isOn: Binding(
                get: { schedule.isEnabled },
                set: { _ in onToggle() }
            ))
            .labelsHidden()
            .tint(themeManager.accentColor)
        }
        .padding()
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(12)
        .contentShape(Rectangle())
        .onTapGesture { onEdit() }
        .contextMenu {
            Button {
                onEdit()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .confirmationDialog("Delete Schedule", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) { onDelete() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete '\(schedule.name)'?")
        }
    }
}

// MARK: - Preset Schedule Card

struct PresetScheduleCard: View {
    let schedule: PrayerSchedule
    let onAdd: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: schedule.prayerType.icon)
                .font(.title2)
                .foregroundColor(schedule.prayerType.color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(schedule.name)
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
                
                Text("\(schedule.formattedTime) • \(schedule.formattedRepeatDays)")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            Spacer()
            
            Button {
                onAdd()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(themeManager.accentColor)
            }
        }
        .padding()
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(12)
    }
}

// MARK: - Add/Edit Schedule Sheet

struct AddPrayerScheduleSheet: View {
    let schedule: PrayerSchedule?
    
    @ObservedObject private var notificationService = NotificationService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var time: Date = Date()
    @State private var selectedDays: Set<Weekday> = Set(Weekday.allCases)
    @State private var prayerType: ScheduledPrayerType = .free
    @State private var reminderOffset: ReminderOffset = .fiveMinutes
    @State private var duration: Int = 5
    
    var isEditing: Bool { schedule != nil }
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor.ignoresSafeArea()
                
                Form {
                    // Name
                    Section {
                        TextField("Schedule Name", text: $name)
                            .foregroundColor(themeManager.textColor)
                    } header: {
                        Text("Name")
                    }
                    .listRowBackground(themeManager.cardBackgroundColor)
                    
                    // Time
                    Section {
                        DatePicker("Prayer Time", selection: $time, displayedComponents: .hourAndMinute)
                            .foregroundColor(themeManager.textColor)
                    } header: {
                        Text("Time")
                    }
                    .listRowBackground(themeManager.cardBackgroundColor)
                    
                    // Repeat Days
                    Section {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                            ForEach(Weekday.allCases) { day in
                                DayToggleButton(
                                    day: day,
                                    isSelected: selectedDays.contains(day)
                                ) {
                                    if selectedDays.contains(day) {
                                        selectedDays.remove(day)
                                    } else {
                                        selectedDays.insert(day)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 8)
                        
                        // Quick select buttons
                        HStack {
                            Button("Every Day") {
                                selectedDays = Set(Weekday.allCases)
                            }
                            .font(.caption)
                            
                            Spacer()
                            
                            Button("Weekdays") {
                                selectedDays = [.monday, .tuesday, .wednesday, .thursday, .friday]
                            }
                            .font(.caption)
                            
                            Spacer()
                            
                            Button("Weekends") {
                                selectedDays = [.saturday, .sunday]
                            }
                            .font(.caption)
                        }
                        .foregroundColor(themeManager.accentColor)
                    } header: {
                        Text("Repeat")
                    }
                    .listRowBackground(themeManager.cardBackgroundColor)
                    
                    // Prayer Type
                    Section {
                        Picker("Prayer Type", selection: $prayerType) {
                            ForEach(ScheduledPrayerType.allCases) { type in
                                Label(type.rawValue, systemImage: type.icon)
                                    .tag(type)
                            }
                        }
                        .foregroundColor(themeManager.textColor)
                    } header: {
                        Text("Type")
                    } footer: {
                        Text(prayerType.description)
                    }
                    .listRowBackground(themeManager.cardBackgroundColor)
                    
                    // Duration
                    Section {
                        Stepper("\(duration) minutes", value: $duration, in: 1...60)
                            .foregroundColor(themeManager.textColor)
                    } header: {
                        Text("Duration")
                    }
                    .listRowBackground(themeManager.cardBackgroundColor)
                    
                    // Reminder
                    Section {
                        Picker("Reminder", selection: $reminderOffset) {
                            ForEach(ReminderOffset.allCases) { offset in
                                Text(offset.displayName).tag(offset)
                            }
                        }
                        .foregroundColor(themeManager.textColor)
                    } header: {
                        Text("Notification")
                    }
                    .listRowBackground(themeManager.cardBackgroundColor)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(isEditing ? "Edit Schedule" : "New Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSchedule()
                        dismiss()
                    }
                    .disabled(name.isEmpty || selectedDays.isEmpty)
                }
            }
            .onAppear {
                if let schedule = schedule {
                    name = schedule.name
                    time = schedule.time
                    selectedDays = schedule.repeatWeekdays
                    prayerType = schedule.prayerType
                    reminderOffset = schedule.reminderOffset
                    duration = schedule.duration
                }
            }
        }
    }
    
    private func saveSchedule() {
        if let existingSchedule = schedule {
            var updated = existingSchedule
            updated.name = name
            updated.time = time
            updated.repeatWeekdays = selectedDays
            updated.prayerType = prayerType
            updated.reminderOffset = reminderOffset
            updated.duration = duration
            notificationService.updateSchedule(updated)
        } else {
            let newSchedule = PrayerSchedule(
                name: name,
                time: time,
                repeatDays: selectedDays,
                reminderOffset: reminderOffset,
                prayerType: prayerType,
                duration: duration
            )
            notificationService.addSchedule(newSchedule)
        }
    }
}

// MARK: - Day Toggle Button

struct DayToggleButton: View {
    let day: Weekday
    let isSelected: Bool
    let action: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: action) {
            Text(day.shortName.prefix(1))
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(isSelected ? .white : themeManager.textColor)
                .frame(width: 36, height: 36)
                .background(isSelected ? themeManager.accentColor : themeManager.backgroundColor)
                .cornerRadius(18)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PrayerScheduleView()
}








