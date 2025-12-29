//
//  NotificationPreferencesView.swift
//  Bible v1
//
//  Spiritual Hub - Notification Preferences
//  Enhanced with schedule preview and master style
//

import SwiftUI

struct NotificationPreferencesView: View {
    @ObservedObject private var notificationService = NotificationService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var settings = SettingsStore.shared
    
    @State private var showAuthorizationAlert = false
    
    var body: some View {
        Form {
            // Authorization Status
            if !notificationService.isAuthorized {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "bell.slash.fill")
                            .font(.title2)
                            .foregroundColor(.orange)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Notifications Disabled")
                                .font(.headline)
                            Text("Enable in Settings to receive reminders")
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
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                    }
                }
                .listRowBackground(Color.orange.opacity(0.1))
            }
            
            // Today's Schedule Preview
            if notificationService.preferences.isEnabled {
                Section {
                    TodaySchedulePreview(notificationService: notificationService, themeManager: themeManager)
                } header: {
                    Text("Today's Schedule")
                } footer: {
                    Text("Notifications scheduled for today based on your preferences")
                }
                .listRowBackground(themeManager.cardBackgroundColor)
            }
            
            // Master Toggle
            Section {
                Toggle(isOn: $notificationService.preferences.isEnabled) {
                    Label("Enable Notifications", systemImage: "bell.fill")
                }
                .tint(themeManager.accentColor)
            } footer: {
                Text("Master switch for all app notifications")
            }
            .listRowBackground(themeManager.cardBackgroundColor)
            
            // Notification Style (Master)
            Section {
                Picker(selection: $settings.notificationStyle) {
                    ForEach(NotificationStyle.allCases) { style in
                        VStack(alignment: .leading) {
                            Text(style.rawValue)
                            Text(style.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .tag(style)
                    }
                } label: {
                    Label("Notification Style", systemImage: "slider.horizontal.3")
                }
                .pickerStyle(.navigationLink)
            } header: {
                Text("Style")
            } footer: {
                Text("Controls the overall frequency and intensity of notifications")
            }
            .listRowBackground(themeManager.cardBackgroundColor)
            
            // Notification Types
            Section {
                Toggle(isOn: $notificationService.preferences.prayerRemindersEnabled) {
                    Label("Prayer Reminders", systemImage: "hands.sparkles")
                }
                
                Toggle(isOn: $notificationService.preferences.readingPlanRemindersEnabled) {
                    Label("Reading Plan", systemImage: "book.fill")
                }
                
                Toggle(isOn: $notificationService.preferences.verseOfDayEnabled) {
                    Label("Verse of the Day", systemImage: "text.quote")
                }
                
                Toggle(isOn: $notificationService.preferences.habitRemindersEnabled) {
                    Label("Habit Reminders", systemImage: "checkmark.circle.fill")
                }
                
                Toggle(isOn: $notificationService.preferences.missionRemindersEnabled) {
                    Label("Mission Reminders", systemImage: "flag.fill")
                }
                
                Toggle(isOn: $notificationService.preferences.encouragementEnabled) {
                    Label("Encouragement", systemImage: "heart.fill")
                }
                
                Toggle(isOn: $notificationService.preferences.weeklyRecapEnabled) {
                    Label("Weekly Recap", systemImage: "chart.bar.fill")
                }
            } header: {
                Text("Notification Types")
            }
            .listRowBackground(themeManager.cardBackgroundColor)
            .tint(themeManager.accentColor)
            .disabled(!notificationService.preferences.isEnabled)
            
            // Quiet Hours
            Section {
                Toggle(isOn: $notificationService.preferences.quietHoursEnabled) {
                    Label("Quiet Hours", systemImage: "moon.fill")
                }
                .tint(themeManager.accentColor)
                
                if notificationService.preferences.quietHoursEnabled {
                    HStack {
                        Text("Start")
                        Spacer()
                        Picker("", selection: $notificationService.preferences.quietHoursStart) {
                            ForEach(0..<24) { hour in
                                Text(formatHour(hour)).tag(hour)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    HStack {
                        Text("End")
                        Spacer()
                        Picker("", selection: $notificationService.preferences.quietHoursEnd) {
                            ForEach(0..<24) { hour in
                                Text(formatHour(hour)).tag(hour)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
            } header: {
                Text("Quiet Hours")
            } footer: {
                Text("No notifications will be sent during quiet hours")
            }
            .listRowBackground(themeManager.cardBackgroundColor)
            .disabled(!notificationService.preferences.isEnabled)
            
            // Smart Features
            Section {
                Toggle(isOn: $notificationService.preferences.adaptiveTimingEnabled) {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Adaptive Timing", systemImage: "brain.head.profile")
                        Text("Learn your patterns and suggest better times")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                }
                .tint(themeManager.accentColor)
                
                if notificationService.preferences.adaptiveTimingEnabled {
                    // Transparency panel
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How adaptive timing works")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text("We adjust notification times based on:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Your typical usage times", systemImage: "clock")
                                .font(.caption)
                            Label("Past notification responses", systemImage: "hand.tap")
                                .font(.caption)
                            Label("Current streak patterns", systemImage: "flame")
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                        
                        Button {
                            notificationService.resetLearnedTiming()
                            HapticManager.shared.success()
                        } label: {
                            Label("Reset learned timing", systemImage: "arrow.counterclockwise")
                                .font(.caption)
                        }
                        .padding(.top, 4)
                    }
                    .padding(.vertical, 4)
                    
                    // Show learned patterns
                    if let morningHour = notificationService.engagementData.recommendedMorningHour {
                        HStack {
                            Image(systemName: "sunrise.fill")
                                .foregroundColor(.orange)
                            Text("Best morning time")
                            Spacer()
                            Text(formatHour(morningHour))
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                    }
                    
                    if let eveningHour = notificationService.engagementData.recommendedEveningHour {
                        HStack {
                            Image(systemName: "sunset.fill")
                                .foregroundColor(ThemeManager.shared.accentColor)
                            Text("Best evening time")
                            Spacer()
                            Text(formatHour(eveningHour))
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                    }
                }
                
                Stepper(
                    "Max daily: \(notificationService.preferences.maxDailyNotifications)",
                    value: $notificationService.preferences.maxDailyNotifications,
                    in: 1...10
                )
            } header: {
                Text("Smart Features")
            } footer: {
                Text("The app learns when you're most likely to engage and adjusts notification timing accordingly")
            }
            .listRowBackground(themeManager.cardBackgroundColor)
            .disabled(!notificationService.preferences.isEnabled)
            
            // Engagement Stats
            if !notificationService.engagementData.notificationResponses.isEmpty {
                Section {
                    engagementStatsView
                } header: {
                    Text("Your Engagement")
                }
                .listRowBackground(themeManager.cardBackgroundColor)
            }
        }
        .scrollContentBackground(.hidden)
        .background(themeManager.backgroundColor.ignoresSafeArea())
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: notificationService.preferences) { _, _ in
            notificationService.savePreferences()
        }
        .alert("Enable Notifications", isPresented: $showAuthorizationAlert) {
            Button("Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please enable notifications in Settings to receive prayer reminders and other updates.")
        }
        .onAppear {
            notificationService.checkAuthorization()
        }
    }
    
    // MARK: - Engagement Stats
    
    private var engagementStatsView: some View {
        EngagementStatsContent(
            notificationService: notificationService,
            themeManager: themeManager
        )
    }
    
    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        var components = DateComponents()
        components.hour = hour
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return "\(hour):00"
    }
}

// MARK: - Engagement Stats Content

private struct EngagementStatsContent: View {
    let notificationService: NotificationService
    let themeManager: ThemeManager
    
    private var totalResponses: Int {
        notificationService.engagementData.notificationResponses.count
    }
    
    private var opened: Int {
        notificationService.engagementData.notificationResponses.filter { $0.wasOpened }.count
    }
    
    private var actedOn: Int {
        notificationService.engagementData.notificationResponses.filter { $0.wasActedOn }.count
    }
    
    private var openedPercentage: String {
        totalResponses > 0 ? "\(Int(Double(opened) / Double(totalResponses) * 100))%" : "0%"
    }
    
    private var actedOnPercentage: String {
        totalResponses > 0 ? "\(Int(Double(actedOn) / Double(totalResponses) * 100))%" : "0%"
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Response rate
            HStack(spacing: 20) {
                StatView(
                    value: "\(totalResponses)",
                    label: "Sent",
                    color: .blue
                )
                
                StatView(
                    value: openedPercentage,
                    label: "Opened",
                    color: .green
                )
                
                StatView(
                    value: actedOnPercentage,
                    label: "Acted On",
                    color: ThemeManager.shared.accentColor
                )
            }
            
            // Best times visualization
            Text("Best engagement times")
                .font(.caption)
                .foregroundColor(themeManager.secondaryTextColor)
            
            HStack(spacing: 2) {
                ForEach(0..<24, id: \.self) { hour in
                    let score = notificationService.engagementData.engagementScoreForHour(hour)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(scoreColor(score))
                        .frame(height: 20)
                }
            }
            .cornerRadius(4)
            
            HStack {
                Text("12 AM")
                    .font(.caption2)
                Spacer()
                Text("12 PM")
                    .font(.caption2)
                Spacer()
                Text("11 PM")
                    .font(.caption2)
            }
            .foregroundColor(themeManager.secondaryTextColor)
        }
    }
    
    private func scoreColor(_ score: Double) -> Color {
        if score > 0.7 {
            return .green
        } else if score > 0.4 {
            return .yellow
        } else if score > 0.2 {
            return .orange
        } else {
            return .red.opacity(0.3)
        }
    }
}

// MARK: - Stat View

struct StatView: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Today's Schedule Preview

struct TodaySchedulePreview: View {
    @ObservedObject var notificationService: NotificationService
    let themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            let scheduled = getScheduledNotificationsForToday()
            
            if scheduled.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "bell.slash")
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    Text("No notifications scheduled for today")
                        .font(.subheadline)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            } else {
                ForEach(scheduled, id: \.title) { notification in
                    HStack(spacing: 12) {
                        Image(systemName: notification.icon)
                            .foregroundColor(themeManager.accentColor)
                            .frame(width: 24)
                        
                        Text(notification.title)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text(notification.time, style: .time)
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                }
            }
        }
    }
    
    private func getScheduledNotificationsForToday() -> [(title: String, icon: String, time: Date)] {
        var scheduled: [(title: String, icon: String, time: Date)] = []
        let calendar = Calendar.current
        let today = Date()
        
        // Check each notification type and add if enabled
        if notificationService.preferences.verseOfDayEnabled {
            // Assume verse of day is at 8 AM
            if let time = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: today) {
                scheduled.append((title: "Verse of the Day", icon: "text.quote", time: time))
            }
        }
        
        if notificationService.preferences.prayerRemindersEnabled {
            // Prayer reminder at 7 AM
            if let time = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: today) {
                scheduled.append((title: "Morning Prayer", icon: "hands.sparkles", time: time))
            }
        }
        
        if notificationService.preferences.readingPlanRemindersEnabled {
            // Reading plan at 9 AM
            if let time = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: today) {
                scheduled.append((title: "Daily Reading", icon: "book.fill", time: time))
            }
        }
        
        if notificationService.preferences.habitRemindersEnabled {
            // Habit check at 10 AM
            if let time = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: today) {
                scheduled.append((title: "Habit Check-in", icon: "checkmark.circle.fill", time: time))
            }
        }
        
        if notificationService.preferences.encouragementEnabled {
            // Encouragement at 2 PM
            if let time = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: today) {
                scheduled.append((title: "Encouragement", icon: "heart.fill", time: time))
            }
        }
        
        // Sort by time
        return scheduled.sorted { $0.time < $1.time }
    }
}

// MARK: - NotificationService Extension

extension NotificationService {
    /// Reset learned timing data
    func resetLearnedTiming() {
        engagementData.notificationResponses = []
        saveEngagementData()
    }
    
    private func saveEngagementData() {
        // This would save to UserDefaults or other storage
        // Implementation depends on existing architecture
    }
}

#Preview {
    NavigationStack {
        NotificationPreferencesView()
    }
}
