//
//  JournalReminderSheet.swift
//  Bible v1
//
//  Spiritual Journal - Reminder Configuration
//

import SwiftUI

/// Sheet for configuring journal reminders
struct JournalReminderSheet: View {
    @ObservedObject private var notificationService = NotificationService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingPermissionAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header illustration
                        headerSection
                        
                        // Main toggle
                        mainToggleSection
                        
                        if notificationService.journalReminderEnabled {
                            // Time picker
                            timePickerSection
                            
                            // Day selector
                            daySelectorSection
                            
                            // Preview
                            previewSection
                        }
                        
                        // Benefits section
                        benefitsSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Journal Reminders")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert("Enable Notifications", isPresented: $showingPermissionAlert) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {
                    notificationService.journalReminderEnabled = false
                }
            } message: {
                Text("To receive journal reminders, please enable notifications in Settings.")
            }
            .onAppear {
                notificationService.checkAuthorization()
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [themeManager.accentColor, themeManager.accentColor.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.white)
            }
            
            Text("Never Miss a Moment")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(themeManager.textColor)
            
            Text("Set a daily reminder to capture your thoughts, prayers, and spiritual reflections.")
                .font(.subheadline)
                .foregroundColor(themeManager.secondaryTextColor)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical)
    }
    
    // MARK: - Main Toggle Section
    
    private var mainToggleSection: some View {
        VStack(spacing: 0) {
            Toggle(isOn: Binding(
                get: { notificationService.journalReminderEnabled },
                set: { newValue in
                    if newValue && !notificationService.isAuthorized {
                        Task {
                            let granted = await notificationService.requestAuthorization()
                            await MainActor.run {
                                if granted {
                                    notificationService.journalReminderEnabled = true
                                    notificationService.saveJournalReminderSettings()
                                } else {
                                    showingPermissionAlert = true
                                }
                            }
                        }
                    } else {
                        notificationService.journalReminderEnabled = newValue
                        notificationService.saveJournalReminderSettings()
                    }
                }
            )) {
                HStack(spacing: 12) {
                    Image(systemName: "bell.fill")
                        .font(.title2)
                        .foregroundColor(themeManager.accentColor)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Daily Reminder")
                            .font(.headline)
                            .foregroundColor(themeManager.textColor)
                        
                        Text("Get notified to write in your journal")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                }
            }
            .tint(themeManager.accentColor)
            .padding()
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(16)
        }
    }
    
    // MARK: - Time Picker Section
    
    private var timePickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reminder Time")
                .font(.headline)
                .foregroundColor(themeManager.textColor)
            
            HStack {
                Image(systemName: "clock.fill")
                    .font(.title3)
                    .foregroundColor(themeManager.accentColor)
                
                DatePicker(
                    "",
                    selection: Binding(
                        get: { notificationService.journalReminderTime },
                        set: { notificationService.updateJournalReminderTime($0) }
                    ),
                    displayedComponents: .hourAndMinute
                )
                .labelsHidden()
                
                Spacer()
                
                Text(timeDescription)
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            .padding()
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(12)
            
            // Quick time suggestions
            HStack(spacing: 8) {
                timeQuickButton(hour: 7, minute: 0, label: "Morning")
                timeQuickButton(hour: 12, minute: 0, label: "Noon")
                timeQuickButton(hour: 20, minute: 0, label: "Evening")
                timeQuickButton(hour: 22, minute: 0, label: "Night")
            }
        }
    }
    
    private func timeQuickButton(hour: Int, minute: Int, label: String) -> some View {
        Button {
            if let newTime = Calendar.current.date(from: DateComponents(hour: hour, minute: minute)) {
                notificationService.updateJournalReminderTime(newTime)
            }
        } label: {
            let isSelected = isTimeSelected(hour: hour, minute: minute)
            Text(label)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : themeManager.textColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? themeManager.accentColor : themeManager.cardBackgroundColor)
                )
        }
        .buttonStyle(.plain)
    }
    
    private func isTimeSelected(hour: Int, minute: Int) -> Bool {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: notificationService.journalReminderTime)
        return components.hour == hour && components.minute == minute
    }
    
    private var timeDescription: String {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: notificationService.journalReminderTime)
        
        switch hour {
        case 5..<12: return "Great for morning reflection"
        case 12..<17: return "Perfect for midday journaling"
        case 17..<21: return "Ideal for evening wind-down"
        default: return "Good for nighttime reflection"
        }
    }
    
    // MARK: - Day Selector Section
    
    private var daySelectorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Repeat")
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
                
                Spacer()
                
                if notificationService.journalReminderDays.count == 7 {
                    Text("Every day")
                        .font(.caption)
                        .foregroundColor(themeManager.accentColor)
                } else if notificationService.journalReminderDays.count == 5 &&
                          !notificationService.journalReminderDays.contains(.saturday) &&
                          !notificationService.journalReminderDays.contains(.sunday) {
                    Text("Weekdays")
                        .font(.caption)
                        .foregroundColor(themeManager.accentColor)
                }
            }
            
            HStack(spacing: 8) {
                ForEach(Weekday.allCases) { day in
                    dayButton(day)
                }
            }
            
            // Quick presets
            HStack(spacing: 8) {
                presetButton(title: "Every Day", days: Set(Weekday.allCases))
                presetButton(title: "Weekdays", days: Set([.monday, .tuesday, .wednesday, .thursday, .friday]))
                presetButton(title: "Weekends", days: Set([.saturday, .sunday]))
            }
        }
    }
    
    private func dayButton(_ day: Weekday) -> some View {
        Button {
            notificationService.toggleJournalReminderDay(day)
        } label: {
            let isSelected = notificationService.journalReminderDays.contains(day)
            Text(day.shortName)
                .font(.subheadline)
                .fontWeight(isSelected ? .bold : .regular)
                .foregroundColor(isSelected ? .white : themeManager.textColor)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(isSelected ? themeManager.accentColor : themeManager.cardBackgroundColor)
                )
        }
        .buttonStyle(.plain)
    }
    
    private func presetButton(title: String, days: Set<Weekday>) -> some View {
        Button {
            notificationService.updateJournalReminderDays(days)
        } label: {
            let isSelected = notificationService.journalReminderDays == days
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? themeManager.accentColor : themeManager.secondaryTextColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isSelected ? themeManager.accentColor : themeManager.secondaryTextColor.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Preview Section
    
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preview")
                .font(.headline)
                .foregroundColor(themeManager.textColor)
            
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "bell.badge.fill")
                    .font(.title2)
                    .foregroundColor(themeManager.accentColor)
                    .padding(10)
                    .background(themeManager.accentColor.opacity(0.15))
                    .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Time to Journal ✍️")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.textColor)
                    
                    Text("Take a moment to reflect on your day.")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    Text(formattedReminderSchedule)
                        .font(.caption2)
                        .foregroundColor(themeManager.accentColor)
                        .padding(.top, 2)
                }
                
                Spacer()
            }
            .padding()
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(12)
        }
    }
    
    private var formattedReminderSchedule: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let timeString = formatter.string(from: notificationService.journalReminderTime)
        
        let days = notificationService.journalReminderDays.sorted { $0.rawValue < $1.rawValue }
        
        if days.count == 7 {
            return "Every day at \(timeString)"
        } else if days.count == 5 && !days.contains(.saturday) && !days.contains(.sunday) {
            return "Weekdays at \(timeString)"
        } else if days.count == 2 && days.contains(.saturday) && days.contains(.sunday) {
            return "Weekends at \(timeString)"
        } else {
            let dayNames = days.map { $0.shortName }.joined(separator: ", ")
            return "\(dayNames) at \(timeString)"
        }
    }
    
    // MARK: - Benefits Section
    
    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Why Journal Daily?")
                .font(.headline)
                .foregroundColor(themeManager.textColor)
            
            VStack(spacing: 12) {
                benefitRow(
                    icon: "heart.fill",
                    color: .pink,
                    title: "Emotional Wellness",
                    description: "Express your feelings and find clarity"
                )
                
                benefitRow(
                    icon: "brain.head.profile",
                    color: .purple,
                    title: "Self-Reflection",
                    description: "Understand your spiritual journey better"
                )
                
                benefitRow(
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green,
                    title: "Track Growth",
                    description: "See how you've grown over time"
                )
                
                benefitRow(
                    icon: "hands.sparkles.fill",
                    color: .orange,
                    title: "Deepen Faith",
                    description: "Connect with God through written prayer"
                )
            }
        }
        .padding()
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(16)
    }
    
    private func benefitRow(icon: String, color: Color, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.15))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.textColor)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            Spacer()
        }
    }
}

#Preview {
    JournalReminderSheet()
}






