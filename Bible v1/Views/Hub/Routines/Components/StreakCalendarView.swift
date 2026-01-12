//
//  StreakCalendarView.swift
//  Bible v1
//
//  Visual streak calendar (GitHub-style contribution graph) for routine completions
//

import SwiftUI

// MARK: - Streak Calendar View

/// A GitHub-style contribution calendar showing routine completion history
struct StreakCalendarView: View {
    let completionData: [(date: Date, completions: [RoutineCompletion])]
    let mode: RoutineMode
    var cellSize: CGFloat = 16
    var cellSpacing: CGFloat = 4
    
    private let calendar = Calendar.current
    private let weekdays = ["S", "M", "T", "W", "T", "F", "S"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Weekday labels
            HStack(spacing: cellSpacing) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 10, design: .serif))
                        .foregroundColor(Color.Journal.mutedText)
                        .frame(width: cellSize)
                }
            }
            
            // Calendar grid
            LazyVGrid(
                columns: Array(repeating: GridItem(.fixed(cellSize), spacing: cellSpacing), count: 7),
                spacing: cellSpacing
            ) {
                ForEach(completionData.reversed(), id: \.date) { item in
                    CalendarCell(
                        date: item.date,
                        completions: item.completions,
                        mode: mode,
                        size: cellSize
                    )
                }
            }
            
            // Legend
            HStack(spacing: 8) {
                Text("Less")
                    .font(.system(.caption2, design: .serif))
                    .foregroundColor(Color.Journal.mutedText)
                
                ForEach(0..<4, id: \.self) { level in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(intensityColor(for: level, max: 3))
                        .frame(width: 12, height: 12)
                }
                
                Text("More")
                    .font(.system(.caption2, design: .serif))
                    .foregroundColor(Color.Journal.mutedText)
            }
        }
    }
    
    private func intensityColor(for count: Int, max: Int) -> Color {
        guard max > 0 else { return Color.Journal.sepia.opacity(0.1) }
        let intensity = Double(count) / Double(max)
        return mode.accentColor.opacity(0.2 + (intensity * 0.6))
    }
}

// MARK: - Calendar Cell

struct CalendarCell: View {
    let date: Date
    let completions: [RoutineCompletion]
    let mode: RoutineMode
    let size: CGFloat
    
    private let calendar = Calendar.current
    
    private var isToday: Bool {
        calendar.isDateInToday(date)
    }
    
    private var isFuture: Bool {
        date > Date()
    }
    
    private var completionCount: Int {
        completions.count
    }
    
    private var intensity: Double {
        switch completionCount {
        case 0: return 0
        case 1: return 0.3
        case 2: return 0.6
        default: return 1.0
        }
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(cellColor)
                .frame(width: size, height: size)
            
            if isToday {
                RoundedRectangle(cornerRadius: 3)
                    .strokeBorder(mode.accentColor, lineWidth: 1.5)
                    .frame(width: size, height: size)
            }
        }
        .opacity(isFuture ? 0.3 : 1)
    }
    
    private var cellColor: Color {
        if completionCount == 0 {
            return Color.Journal.sepia.opacity(0.1)
        }
        return mode.accentColor.opacity(0.2 + (intensity * 0.6))
    }
}

// MARK: - Streak Stats Card

/// A card showing streak statistics
struct StreakStatsCard: View {
    let streak: RoutineStreak
    let mode: RoutineMode
    
    var body: some View {
        RoutineJournalCard(mode: mode, padding: 16) {
            HStack(spacing: 20) {
                // Current streak
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.orange)
                        
                        Text("\(streak.currentStreak)")
                            .font(.system(size: 28, weight: .bold, design: .serif))
                            .foregroundColor(Color.Journal.inkBrown)
                    }
                    
                    Text("Current")
                        .font(.system(.caption, design: .serif))
                        .foregroundColor(Color.Journal.mutedText)
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                    .frame(height: 40)
                
                // Longest streak
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.yellow)
                        
                        Text("\(streak.longestStreak)")
                            .font(.system(size: 28, weight: .bold, design: .serif))
                            .foregroundColor(Color.Journal.inkBrown)
                    }
                    
                    Text("Best")
                        .font(.system(.caption, design: .serif))
                        .foregroundColor(Color.Journal.mutedText)
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                    .frame(height: 40)
                
                // Total completions
                VStack(spacing: 4) {
                    Text("\(streak.totalCompletions)")
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundColor(Color.Journal.inkBrown)
                    
                    Text("Total")
                        .font(.system(.caption, design: .serif))
                        .foregroundColor(Color.Journal.mutedText)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - Streak Milestone Banner

/// A banner showing streak milestones and achievements
struct StreakMilestoneBanner: View {
    let streak: RoutineStreak
    let mode: RoutineMode
    
    private var milestone: StreakMilestone? {
        StreakMilestone.currentMilestone(for: streak.currentStreak)
    }
    
    private var nextMilestone: StreakMilestone? {
        StreakMilestone.nextMilestone(for: streak.currentStreak)
    }
    
    var body: some View {
        if let milestone = milestone {
            RoutineJournalCard(mode: mode, padding: 16) {
                VStack(spacing: 12) {
                    HStack {
                        Text(milestone.emoji)
                            .font(.system(size: 32))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(milestone.title)
                                .font(.system(.headline, design: .serif))
                                .foregroundColor(Color.Journal.inkBrown)
                            
                            Text(milestone.message)
                                .font(.system(.caption, design: .serif))
                                .foregroundColor(Color.Journal.mutedText)
                        }
                        
                        Spacer()
                    }
                    
                    if let next = nextMilestone {
                        // Progress to next milestone
                        VStack(spacing: 6) {
                            HStack {
                                Text("\(next.daysRequired - streak.currentStreak) days to \(next.title)")
                                    .font(.system(.caption2, design: .serif))
                                    .foregroundColor(Color.Journal.mutedText)
                                
                                Spacer()
                                
                                Text(next.emoji)
                                    .font(.system(size: 14))
                            }
                            
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.Journal.sepia.opacity(0.1))
                                    
                                    Capsule()
                                        .fill(mode.accentColor)
                                        .frame(width: geo.size.width * progressToNext)
                                }
                            }
                            .frame(height: 6)
                        }
                    }
                }
            }
        }
    }
    
    private var progressToNext: Double {
        guard let next = nextMilestone, let current = milestone else { return 0 }
        let range = next.daysRequired - current.daysRequired
        let progress = streak.currentStreak - current.daysRequired
        return Double(progress) / Double(range)
    }
}

// MARK: - Streak Milestone

enum StreakMilestone: CaseIterable {
    case beginner
    case weekWarrior
    case twoWeeks
    case monthStrong
    case sixtyDays
    case ninetyDays
    case centurion
    case halfYear
    case yearMaster
    
    var daysRequired: Int {
        switch self {
        case .beginner: return 1
        case .weekWarrior: return 7
        case .twoWeeks: return 14
        case .monthStrong: return 30
        case .sixtyDays: return 60
        case .ninetyDays: return 90
        case .centurion: return 100
        case .halfYear: return 180
        case .yearMaster: return 365
        }
    }
    
    var title: String {
        switch self {
        case .beginner: return "Getting Started"
        case .weekWarrior: return "Week Warrior"
        case .twoWeeks: return "Two Weeks Strong"
        case .monthStrong: return "Month Strong"
        case .sixtyDays: return "60-Day Champion"
        case .ninetyDays: return "90-Day Hero"
        case .centurion: return "Centurion"
        case .halfYear: return "Half-Year Legend"
        case .yearMaster: return "Year Master"
        }
    }
    
    var emoji: String {
        switch self {
        case .beginner: return "🌱"
        case .weekWarrior: return "⭐️"
        case .twoWeeks: return "🌟"
        case .monthStrong: return "🏅"
        case .sixtyDays: return "💪"
        case .ninetyDays: return "🔥"
        case .centurion: return "💯"
        case .halfYear: return "🏆"
        case .yearMaster: return "👑"
        }
    }
    
    var message: String {
        switch self {
        case .beginner: return "Every journey begins with a single step!"
        case .weekWarrior: return "A full week of dedication!"
        case .twoWeeks: return "Building lasting habits!"
        case .monthStrong: return "A month of faithfulness!"
        case .sixtyDays: return "Your consistency is inspiring!"
        case .ninetyDays: return "This is who you are now!"
        case .centurion: return "100 days of spiritual growth!"
        case .halfYear: return "Half a year of devotion!"
        case .yearMaster: return "A full year of spiritual practice!"
        }
    }
    
    static func currentMilestone(for days: Int) -> StreakMilestone? {
        allCases.reversed().first { days >= $0.daysRequired }
    }
    
    static func nextMilestone(for days: Int) -> StreakMilestone? {
        allCases.first { days < $0.daysRequired }
    }
}

// MARK: - Week Activity Row

/// A row showing activity for each day of the current week
struct WeekActivityRow: View {
    let completionData: [(date: Date, completions: [RoutineCompletion])]
    let mode: RoutineMode
    
    private let calendar = Calendar.current
    private let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<7, id: \.self) { dayOffset in
                let date = calendar.date(byAdding: .day, value: dayOffset - 6, to: Date()) ?? Date()
                let dayData = completionData.first { calendar.isDate($0.date, inSameDayAs: date) }
                
                VStack(spacing: 6) {
                    Text(weekdays[calendar.component(.weekday, from: date) - 1])
                        .font(.system(.caption2, design: .serif))
                        .foregroundColor(Color.Journal.mutedText)
                    
                    ZStack {
                        Circle()
                            .fill(circleColor(for: dayData?.completions ?? []))
                            .frame(width: 32, height: 32)
                        
                        if calendar.isDateInToday(date) {
                            Circle()
                                .strokeBorder(mode.accentColor, lineWidth: 2)
                                .frame(width: 32, height: 32)
                        }
                        
                        if let completions = dayData?.completions, !completions.isEmpty {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    
                    Text("\(calendar.component(.day, from: date))")
                        .font(.system(.caption, design: .serif))
                        .fontWeight(calendar.isDateInToday(date) ? .bold : .regular)
                        .foregroundColor(calendar.isDateInToday(date) ? mode.accentColor : Color.Journal.inkBrown)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    private func circleColor(for completions: [RoutineCompletion]) -> Color {
        if completions.isEmpty {
            return Color.Journal.sepia.opacity(0.15)
        }
        return mode.accentColor
    }
}

// MARK: - Preview

#Preview("Streak Calendar") {
    ScrollView {
        VStack(spacing: 20) {
            StreakStatsCard(
                streak: RoutineStreak(currentStreak: 14, longestStreak: 30, totalCompletions: 45),
                mode: .morning
            )
            
            StreakMilestoneBanner(
                streak: RoutineStreak(currentStreak: 14, longestStreak: 30, totalCompletions: 45),
                mode: .morning
            )
            
            RoutineJournalCard(mode: .morning) {
                VStack(alignment: .leading, spacing: 12) {
                    JournalSectionHeader(title: "This Week", icon: "calendar", mode: .morning)
                    
                    WeekActivityRow(
                        completionData: [],
                        mode: .morning
                    )
                }
            }
        }
        .padding()
    }
    .background(Color.Journal.paper)
}



