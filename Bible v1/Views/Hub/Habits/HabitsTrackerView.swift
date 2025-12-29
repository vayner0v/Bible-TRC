//
//  HabitsTrackerView.swift
//  Bible v1
//
//  Habits Tracker - Daily spiritual habit check-ins
//

import SwiftUI

struct HabitsTrackerView: View {
    @ObservedObject var viewModel: HubViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var showHabitSettings = false
    @State private var selectedHabitForDetail: SpiritualHabit?
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Today's progress header
                        todayProgressCard
                        
                        // Habit list
                        habitsSection
                        
                        // Weekly overview
                        weeklyOverviewSection
                        
                        // Streaks section
                        streaksSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Daily Habits")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showHabitSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showHabitSettings) {
                HabitSettingsSheet(viewModel: viewModel)
            }
            .sheet(item: $selectedHabitForDetail) { habit in
                HabitDetailSheet(habit: habit, viewModel: viewModel)
            }
        }
    }
    
    // MARK: - Today's Progress Card
    
    private var todayProgressCard: some View {
        VStack(spacing: 16) {
            // Progress ring
            ZStack {
                Circle()
                    .stroke(themeManager.dividerColor, lineWidth: 12)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: viewModel.todayHabitProgress)
                    .stroke(
                        LinearGradient(
                            colors: progressColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6), value: viewModel.todayHabitProgress)
                
                VStack(spacing: 2) {
                    Text("\(Int(viewModel.todayHabitProgress * 100))%")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.textColor)
                    
                    Text("Complete")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
            
            // Stats row
            HStack(spacing: 30) {
                VStack(spacing: 4) {
                    Text("\(viewModel.todayCompletedHabits.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("Done")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                
                VStack(spacing: 4) {
                    Text("\(viewModel.trackedHabits.count - viewModel.todayCompletedHabits.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    Text("Remaining")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                
                VStack(spacing: 4) {
                    Text("\(viewModel.trackedHabits.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.accentColor)
                    Text("Total")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
        }
        .padding()
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(20)
    }
    
    private var progressColors: [Color] {
        let progress = viewModel.todayHabitProgress
        if progress >= 1.0 {
            return [.green, .mint]
        } else if progress >= 0.5 {
            return [.blue, .teal]
        } else {
            return [.orange, .yellow]
        }
    }
    
    // MARK: - Habits Section
    
    private var habitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Habits")
                .font(.headline)
                .foregroundColor(themeManager.textColor)
            
            ForEach(viewModel.trackedHabits, id: \.self) { habit in
                HabitRow(
                    habit: habit,
                    isCompleted: viewModel.isHabitCompletedToday(habit),
                    streak: viewModel.getStreak(for: habit),
                    onToggle: {
                        withAnimation(.spring(response: 0.3)) {
                            viewModel.toggleHabit(habit)
                        }
                    },
                    onDetail: {
                        selectedHabitForDetail = habit
                    }
                )
            }
        }
    }
    
    // MARK: - Weekly Overview
    
    private var weeklyOverviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.headline)
                .foregroundColor(themeManager.textColor)
            
            HStack(spacing: 8) {
                ForEach(0..<7, id: \.self) { dayOffset in
                    let date = Calendar.current.date(byAdding: .day, value: -6 + dayOffset, to: Date()) ?? Date()
                    WeekDayCell(
                        date: date,
                        completionRate: completionRateForDate(date),
                        isToday: dayOffset == 6
                    )
                }
            }
            .padding()
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(14)
        }
    }
    
    private func completionRateForDate(_ date: Date) -> Double {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        
        let entriesForDay = viewModel.habitEntries.filter {
            calendar.isDate($0.date, inSameDayAs: dayStart) && $0.isCompleted
        }
        
        let uniqueHabits = Set(entriesForDay.map { $0.habit })
        guard !viewModel.trackedHabits.isEmpty else { return 0 }
        
        return Double(uniqueHabits.count) / Double(viewModel.trackedHabits.count)
    }
    
    // MARK: - Streaks Section
    
    private var streaksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Streaks")
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
                
                Spacer()
                
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(viewModel.trackedHabits, id: \.self) { habit in
                    StreakCard(
                        habit: habit,
                        streak: viewModel.habitStreaks.first { $0.habit == habit }
                    )
                }
            }
        }
    }
}

// MARK: - Habit Row

struct HabitRow: View {
    let habit: SpiritualHabit
    let isCompleted: Bool
    let streak: Int
    let onToggle: () -> Void
    let onDetail: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 14) {
            // Checkbox
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .stroke(isCompleted ? Color.clear : habit.color.opacity(0.5), lineWidth: 2)
                        .frame(width: 28, height: 28)
                    
                    if isCompleted {
                        Circle()
                            .fill(habit.color)
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: "checkmark")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
            }
            .disabled(isCompleted)
            
            // Habit info
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.rawValue)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(isCompleted ? themeManager.secondaryTextColor : themeManager.textColor)
                    .strikethrough(isCompleted, color: themeManager.secondaryTextColor)
                
                Text(habit.defaultGoal)
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            Spacer()
            
            // Streak badge
            if streak > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.caption)
                    Text("\(streak)")
                        .font(.caption)
                        .fontWeight(.bold)
                }
                .foregroundColor(.orange)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.15))
                .cornerRadius(10)
            }
            
            // Detail button
            Button(action: onDetail) {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
        }
        .padding()
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(14)
    }
}

// MARK: - Week Day Cell

struct WeekDayCell: View {
    let date: Date
    let completionRate: Double
    let isToday: Bool
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    private var dayLetter: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return String(formatter.string(from: date).prefix(1))
    }
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(spacing: 6) {
            Text(dayLetter)
                .font(.caption2)
                .foregroundColor(themeManager.secondaryTextColor)
            
            ZStack {
                Circle()
                    .fill(isToday ? themeManager.accentColor.opacity(0.2) : Color.clear)
                    .frame(width: 36, height: 36)
                
                Circle()
                    .trim(from: 0, to: completionRate)
                    .stroke(completionColor, lineWidth: 3)
                    .frame(width: 30, height: 30)
                    .rotationEffect(.degrees(-90))
                
                Text(dayNumber)
                    .font(.caption)
                    .fontWeight(isToday ? .bold : .regular)
                    .foregroundColor(isToday ? themeManager.accentColor : themeManager.textColor)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private var completionColor: Color {
        if completionRate >= 1.0 {
            return .green
        } else if completionRate >= 0.5 {
            return .blue
        } else if completionRate > 0 {
            return .orange
        } else {
            return themeManager.dividerColor
        }
    }
}

// MARK: - Streak Card

struct StreakCard: View {
    let habit: SpiritualHabit
    let streak: HabitStreak?
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: habit.icon)
                    .foregroundColor(habit.color)
                Spacer()
                if let s = streak, s.currentStreak > 0 {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                }
            }
            
            Text(habit.rawValue)
                .font(.caption)
                .foregroundColor(themeManager.secondaryTextColor)
            
            HStack(alignment: .bottom, spacing: 4) {
                Text("\(streak?.currentStreak ?? 0)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.textColor)
                
                Text("days")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .padding(.bottom, 2)
            }
            
            if let s = streak, s.longestStreak > 0 {
                Text("Best: \(s.longestStreak)")
                    .font(.caption2)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
        }
        .padding()
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(12)
    }
}

// MARK: - Habit Settings Sheet

struct HabitSettingsSheet: View {
    @ObservedObject var viewModel: HubViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedHabits: Set<SpiritualHabit> = []
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Select the habits you want to track daily. You can change these anytime.")
                            .font(.subheadline)
                            .foregroundColor(themeManager.secondaryTextColor)
                        
                        ForEach(SpiritualHabit.allCases) { habit in
                            Button {
                                if selectedHabits.contains(habit) {
                                    selectedHabits.remove(habit)
                                } else {
                                    selectedHabits.insert(habit)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: habit.icon)
                                        .font(.title3)
                                        .foregroundColor(habit.color)
                                        .frame(width: 36)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(habit.rawValue)
                                            .font(.body)
                                            .foregroundColor(themeManager.textColor)
                                        Text(habit.description)
                                            .font(.caption)
                                            .foregroundColor(themeManager.secondaryTextColor)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: selectedHabits.contains(habit) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedHabits.contains(habit) ? habit.color : themeManager.secondaryTextColor)
                                }
                                .padding()
                                .background(themeManager.cardBackgroundColor)
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Habit Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        viewModel.setTrackedHabits(Array(selectedHabits))
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                selectedHabits = Set(viewModel.trackedHabits)
            }
        }
    }
}

// MARK: - Habit Detail Sheet

struct HabitDetailSheet: View {
    let habit: SpiritualHabit
    @ObservedObject var viewModel: HubViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    private var streak: HabitStreak? {
        viewModel.habitStreaks.first { $0.habit == habit }
    }
    
    private var recentEntries: [HabitEntry] {
        viewModel.habitEntries
            .filter { $0.habit == habit }
            .prefix(10)
            .map { $0 }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 12) {
                            Image(systemName: habit.icon)
                                .font(.system(size: 50))
                                .foregroundColor(habit.color)
                            
                            Text(habit.rawValue)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(themeManager.textColor)
                            
                            Text(habit.description)
                                .font(.subheadline)
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                        .padding(.top)
                        
                        // Stats
                        HStack(spacing: 20) {
                            HabitStatCard(
                                value: "\(streak?.currentStreak ?? 0)",
                                label: "Current Streak",
                                icon: "flame.fill",
                                color: .orange
                            )
                            
                            HabitStatCard(
                                value: "\(streak?.longestStreak ?? 0)",
                                label: "Best Streak",
                                icon: "trophy.fill",
                                color: .yellow
                            )
                            
                            HabitStatCard(
                                value: "\(streak?.totalCompletions ?? 0)",
                                label: "Total",
                                icon: "checkmark.circle.fill",
                                color: .green
                            )
                        }
                        
                        // Recent activity
                        if !recentEntries.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Recent Activity")
                                    .font(.headline)
                                    .foregroundColor(themeManager.textColor)
                                
                                ForEach(recentEntries) { entry in
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        
                                        Text(entry.formattedDate)
                                            .font(.subheadline)
                                            .foregroundColor(themeManager.textColor)
                                        
                                        Spacer()
                                        
                                        if let duration = entry.duration {
                                            Text("\(duration) min")
                                                .font(.caption)
                                                .foregroundColor(themeManager.secondaryTextColor)
                                        }
                                    }
                                    .padding()
                                    .background(themeManager.cardBackgroundColor)
                                    .cornerRadius(10)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Habit Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct HabitStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(themeManager.textColor)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(themeManager.secondaryTextColor)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(12)
    }
}

#Preview {
    HabitsTrackerView(viewModel: HubViewModel())
}

