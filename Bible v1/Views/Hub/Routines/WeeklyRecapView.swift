//
//  WeeklyRecapView.swift
//  Bible v1
//
//  Weekly Recap - Summary of spiritual activities for the week
//

import SwiftUI

struct WeeklyRecapView: View {
    @ObservedObject var viewModel: HubViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    private var stats: WeeklyStats {
        viewModel.weeklyStats ?? viewModel.getWeeklyStats()
    }
    
    private var moodSummary: WeeklyMoodSummary {
        viewModel.getWeeklyMoodSummary()
    }
    
    private var gratitudeSummary: WeeklyGratitudeSummary {
        viewModel.getWeeklyGratitudeSummary()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [themeManager.accentColor.opacity(0.1), themeManager.backgroundColor],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Main stats grid
                        statsGridSection
                        
                        // Prayer summary
                        prayerSummarySection
                        
                        // Habits summary
                        habitsSummarySection
                        
                        // Mood summary
                        moodSummarySection
                        
                        // Gratitude highlights
                        gratitudeHighlightsSection
                        
                        // Encouragement
                        encouragementSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Weekly Recap")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 50))
                .foregroundStyle(
                    LinearGradient(colors: [themeManager.accentColor, themeManager.accentColor.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            
            Text("Your Week in Review")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(themeManager.textColor)
            
            Text(weekDateRange)
                .font(.subheadline)
                .foregroundColor(themeManager.secondaryTextColor)
        }
        .padding(.vertical)
    }
    
    private var weekDateRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let today = Date()
        let weekAgo = Calendar.current.date(byAdding: .day, value: -6, to: today) ?? today
        return "\(formatter.string(from: weekAgo)) - \(formatter.string(from: today))"
    }
    
    // MARK: - Stats Grid Section
    
    private var statsGridSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                RecapStatCard(
                    value: "\(stats.prayersWritten)",
                    label: "Prayers",
                    icon: "hands.sparkles",
                    color: ThemeManager.shared.accentColor
                )
                
                RecapStatCard(
                    value: "\(stats.guidedSessionsCompleted)",
                    label: "Sessions",
                    icon: "timer",
                    color: .indigo
                )
                
                RecapStatCard(
                    value: "\(stats.habitDaysCompleted)",
                    label: "Habit Days",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
            }
            
            HStack(spacing: 12) {
                RecapStatCard(
                    value: "\(stats.gratitudeItemsWritten)",
                    label: "Gratitudes",
                    icon: "heart.fill",
                    color: .pink
                )
                
                RecapStatCard(
                    value: "\(stats.readingDaysCompleted)",
                    label: "Reading Days",
                    icon: "book.fill",
                    color: .blue
                )
                
                RecapStatCard(
                    value: "\(stats.prayersAnswered)",
                    label: "Answered",
                    icon: "checkmark.seal.fill",
                    color: .yellow
                )
            }
        }
    }
    
    // MARK: - Prayer Summary Section
    
    private var prayerSummarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "hands.sparkles")
                    .foregroundColor(ThemeManager.shared.accentColor)
                Text("Prayer Life")
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
                Spacer()
            }
            
            if stats.prayersWritten > 0 || stats.guidedSessionsCompleted > 0 {
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(stats.prayersWritten)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(ThemeManager.shared.accentColor)
                        Text("prayers written")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    
                    Divider()
                        .frame(height: 40)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(stats.guidedSessionsCompleted)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.indigo)
                        Text("guided sessions")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    
                    if stats.prayersAnswered > 0 {
                        Divider()
                            .frame(height: 40)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(stats.prayersAnswered)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                            Text("answered!")
                                .font(.caption)
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                    }
                    
                    Spacer()
                }
                
                if stats.prayersAnswered > 0 {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.yellow)
                        Text("God answered \(stats.prayersAnswered) prayer\(stats.prayersAnswered == 1 ? "" : "s") this week!")
                            .font(.subheadline)
                            .foregroundColor(themeManager.textColor)
                    }
                    .padding()
                    .background(Color.yellow.opacity(0.1))
                    .cornerRadius(10)
                }
            } else {
                Text("No prayer activity recorded this week. Start building your prayer life!")
                    .font(.subheadline)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .italic()
            }
        }
        .padding()
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(16)
    }
    
    // MARK: - Habits Summary Section
    
    private var habitsSummarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Spiritual Habits")
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
                Spacer()
            }
            
            // Progress visualization
            let trackedCount = viewModel.trackedHabits.count
            let maxDays = trackedCount * 7
            let progress = maxDays > 0 ? Double(stats.habitDaysCompleted) / Double(maxDays) : 0
            
            VStack(spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(themeManager.dividerColor)
                        
                        Capsule()
                            .fill(LinearGradient(colors: [.green, .teal], startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * progress)
                    }
                }
                .frame(height: 12)
                
                HStack {
                    Text("\(Int(progress * 100))% consistency")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                    Spacer()
                    Text("\(stats.habitDaysCompleted) / \(maxDays) possible")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
            
            // Top streaks
            let topStreaks = viewModel.habitStreaks
                .filter { $0.currentStreak > 0 }
                .sorted { $0.currentStreak > $1.currentStreak }
                .prefix(3)
            
            if !topStreaks.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Active Streaks")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    HStack(spacing: 12) {
                        ForEach(Array(topStreaks), id: \.id) { streak in
                            HStack(spacing: 6) {
                                Image(systemName: streak.habit.icon)
                                    .font(.caption)
                                    .foregroundColor(streak.habit.color)
                                
                                HStack(spacing: 2) {
                                    Image(systemName: "flame.fill")
                                        .font(.caption2)
                                    Text("\(streak.currentStreak)")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                }
                                .foregroundColor(.orange)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(themeManager.backgroundColor)
                            .cornerRadius(15)
                        }
                    }
                }
            }
        }
        .padding()
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(16)
    }
    
    // MARK: - Mood Summary Section
    
    private var moodSummarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "face.smiling")
                    .foregroundColor(.teal)
                Text("How You've Been Feeling")
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
                Spacer()
            }
            
            if moodSummary.daysCheckedIn > 0 {
                HStack(spacing: 20) {
                    // Average mood
                    VStack(spacing: 8) {
                        Text(moodSummary.averageMoodLevel.emoji)
                            .font(.system(size: 44))
                        
                        Text(moodSummary.averageMoodLevel.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(moodSummary.averageMoodLevel.color)
                        
                        Text("average")
                            .font(.caption2)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Divider()
                        .frame(height: 60)
                    
                    // Check-ins
                    VStack(spacing: 8) {
                        Text("\(moodSummary.daysCheckedIn)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.textColor)
                        
                        Text("check-ins")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                // Top factors
                if !moodSummary.topFactors.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Top influences:")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                        
                        HStack(spacing: 8) {
                            ForEach(moodSummary.topFactors, id: \.self) { factor in
                                HStack(spacing: 4) {
                                    Image(systemName: factor.icon)
                                        .font(.caption)
                                    Text(factor.rawValue)
                                        .font(.caption)
                                }
                                .foregroundColor(themeManager.textColor)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(themeManager.backgroundColor)
                                .cornerRadius(15)
                            }
                        }
                    }
                }
            } else {
                Text("No mood check-ins this week. Taking a moment to reflect on how you're feeling can help you grow.")
                    .font(.subheadline)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .italic()
            }
        }
        .padding()
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(16)
    }
    
    // MARK: - Gratitude Highlights Section
    
    private var gratitudeHighlightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.pink)
                Text("Gratitude Highlights")
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
                Spacer()
            }
            
            if !gratitudeSummary.allItems.isEmpty {
                Text("You expressed gratitude \(gratitudeSummary.totalItems) times this week!")
                    .font(.subheadline)
                    .foregroundColor(themeManager.textColor)
                
                // Sample items
                VStack(spacing: 8) {
                    ForEach(gratitudeSummary.allItems.prefix(5)) { item in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "heart.fill")
                                .font(.caption2)
                                .foregroundColor(.pink.opacity(0.6))
                            Text(item.text)
                                .font(.caption)
                                .foregroundColor(themeManager.textColor)
                                .lineLimit(2)
                            Spacer()
                        }
                    }
                    
                    if gratitudeSummary.totalItems > 5 {
                        Text("+ \(gratitudeSummary.totalItems - 5) more...")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                }
                .padding()
                .background(Color.pink.opacity(0.08))
                .cornerRadius(12)
            } else {
                Text("Start a gratitude practice to see your blessings compiled here each week.")
                    .font(.subheadline)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .italic()
            }
        }
        .padding()
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(16)
    }
    
    // MARK: - Encouragement Section
    
    private var encouragementSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.title)
                .foregroundColor(.yellow)
            
            Text(stats.encouragingMessage)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(themeManager.textColor)
                .multilineTextAlignment(.center)
            
            Text("\"Commit to the Lord whatever you do, and he will establish your plans.\" — Proverbs 16:3")
                .font(.caption)
                .italic()
                .foregroundColor(themeManager.secondaryTextColor)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [themeManager.accentColor.opacity(0.15), themeManager.accentColor.opacity(0.05)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(16)
    }
}

// MARK: - Recap Stat Card

struct RecapStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(themeManager.textColor)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(themeManager.secondaryTextColor)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(12)
    }
}

#Preview {
    WeeklyRecapView(viewModel: HubViewModel())
}


