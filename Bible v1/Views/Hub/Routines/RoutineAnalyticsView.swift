//
//  RoutineAnalyticsView.swift
//  Bible v1
//
//  Analytics dashboard for routine completions with history, patterns, and insights
//

import SwiftUI

struct RoutineAnalyticsView: View {
    @ObservedObject var viewModel: HubViewModel
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedPeriod: RoutineAnalytics.AnalyticsPeriod = .week
    @State private var selectedMode: RoutineMode? = nil
    
    private var analytics: RoutineAnalytics {
        viewModel.getRoutineAnalytics(period: selectedPeriod)
    }
    
    private var completionCalendar: [(date: Date, completions: [RoutineCompletion])] {
        viewModel.getRoutineCompletionCalendar(days: calendarDays)
    }
    
    private var calendarDays: Int {
        switch selectedPeriod {
        case .week: return 7
        case .month: return 30
        case .allTime: return 90
        }
    }
    
    private var primaryMode: RoutineMode {
        selectedMode ?? .morning
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient.journalGradient(for: primaryMode)
                    .opacity(0.4)
                    .ignoresSafeArea()
                
                Color.Journal.paper
                    .opacity(0.7)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Period selector
                        periodSelector
                        
                        // Streak section
                        streakSection
                        
                        // Overview stats
                        overviewSection
                        
                        // Calendar heatmap
                        calendarSection
                        
                        // Insights
                        insightsSection
                        
                        // Recent completions
                        recentCompletionsSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Routine Analytics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .font(.system(.body, design: .serif))
                }
            }
        }
    }
    
    // MARK: - Period Selector
    
    private var periodSelector: some View {
        HStack(spacing: 0) {
            ForEach([RoutineAnalytics.AnalyticsPeriod.week, .month, .allTime], id: \.self) { period in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedPeriod = period
                    }
                } label: {
                    Text(periodLabel(for: period))
                        .font(.system(.subheadline, design: .serif))
                        .fontWeight(selectedPeriod == period ? .semibold : .regular)
                        .foregroundColor(selectedPeriod == period ? .white : Color.Journal.mutedText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedPeriod == period ? primaryMode.accentColor : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.Journal.cardBackground)
        )
    }
    
    private func periodLabel(for period: RoutineAnalytics.AnalyticsPeriod) -> String {
        switch period {
        case .week: return "Week"
        case .month: return "Month"
        case .allTime: return "All Time"
        }
    }
    
    // MARK: - Streak Section
    
    private var streakSection: some View {
        VStack(spacing: 16) {
            // Streak stats
            StreakStatsCard(streak: viewModel.combinedRoutineStreak, mode: primaryMode)
            
            // Milestone banner
            StreakMilestoneBanner(streak: viewModel.combinedRoutineStreak, mode: primaryMode)
        }
    }
    
    // MARK: - Overview Section
    
    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            JournalSectionHeader(title: "Overview", icon: "chart.bar.fill", mode: primaryMode)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                RoutineStatCard(
                    title: "Completions",
                    value: "\(analytics.totalCompletions)",
                    icon: "checkmark.circle.fill",
                    color: primaryMode.accentColor
                )
                
                RoutineStatCard(
                    title: "Avg Duration",
                    value: analytics.formattedAverageDuration,
                    icon: "clock.fill",
                    color: .blue
                )
                
                RoutineStatCard(
                    title: "Morning",
                    value: "\(analytics.morningCompletions)",
                    icon: "sunrise.fill",
                    color: Color.Journal.Morning.primary
                )
                
                RoutineStatCard(
                    title: "Evening",
                    value: "\(analytics.eveningCompletions)",
                    icon: "moon.stars.fill",
                    color: Color.Journal.Evening.primary
                )
                
                RoutineStatCard(
                    title: "Gratitude Items",
                    value: "\(analytics.totalGratitudeItems)",
                    icon: "heart.fill",
                    color: .pink
                )
                
                RoutineStatCard(
                    title: "Intentions Set",
                    value: "\(analytics.totalIntentionsSet)",
                    icon: "target",
                    color: .green
                )
            }
        }
    }
    
    // MARK: - Calendar Section
    
    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            JournalSectionHeader(title: "Activity", icon: "calendar", mode: primaryMode)
            
            RoutineJournalCard(mode: primaryMode) {
                VStack(spacing: 16) {
                    // Week view
                    WeekActivityRow(completionData: completionCalendar, mode: primaryMode)
                    
                    JournalDivider(mode: primaryMode, style: .dotted)
                    
                    // Calendar heatmap
                    StreakCalendarView(
                        completionData: completionCalendar,
                        mode: primaryMode
                    )
                }
            }
        }
    }
    
    // MARK: - Insights Section
    
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            JournalSectionHeader(title: "Insights", icon: "lightbulb.fill", mode: primaryMode)
            
            VStack(spacing: 12) {
                // Completion rate
                InsightCard(
                    title: "Completion Rate",
                    value: "\(Int(analytics.completionRate * 100))%",
                    subtitle: "of routines fully completed",
                    icon: "chart.pie.fill",
                    color: analytics.completionRate >= 0.8 ? .green : (analytics.completionRate >= 0.5 ? .orange : .red),
                    mode: primaryMode
                )
                
                // Days with completion
                InsightCard(
                    title: "Active Days",
                    value: "\(analytics.daysWithCompletion)",
                    subtitle: "days with at least one routine",
                    icon: "calendar.badge.checkmark",
                    color: primaryMode.accentColor,
                    mode: primaryMode
                )
                
                // Mood improvement (if available)
                if let moodRate = analytics.moodImprovementRate {
                    InsightCard(
                        title: "Mood Improvement",
                        value: "\(Int(moodRate * 100))%",
                        subtitle: "of routines improved your mood",
                        icon: "face.smiling.fill",
                        color: moodRate >= 0.5 ? .green : .orange,
                        mode: primaryMode
                    )
                }
                
                // Best time insight
                bestTimeInsight
            }
        }
    }
    
    private var bestTimeInsight: some View {
        let morningCount = analytics.morningCompletions
        let eveningCount = analytics.eveningCompletions
        
        let bestTime: String
        let icon: String
        let color: Color
        
        if morningCount > eveningCount {
            bestTime = "Morning Person"
            icon = "sunrise.fill"
            color = Color.Journal.Morning.primary
        } else if eveningCount > morningCount {
            bestTime = "Night Owl"
            icon = "moon.stars.fill"
            color = Color.Journal.Evening.primary
        } else {
            bestTime = "Balanced"
            icon = "equal.circle.fill"
            color = Color.Journal.Anytime.primary
        }
        
        return InsightCard(
            title: "Your Style",
            value: bestTime,
            subtitle: morningCount > 0 || eveningCount > 0 ? "\(max(morningCount, eveningCount)) \(morningCount > eveningCount ? "morning" : "evening") routines" : "Start building your pattern",
            icon: icon,
            color: color,
            mode: primaryMode
        )
    }
    
    // MARK: - Recent Completions Section
    
    private var recentCompletionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            JournalSectionHeader(title: "Recent Completions", icon: "clock.arrow.circlepath", mode: primaryMode)
            
            if analytics.completions.isEmpty {
                RoutineJournalCard(mode: primaryMode) {
                    VStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 32))
                            .foregroundColor(Color.Journal.mutedText.opacity(0.5))
                        
                        Text("No completions yet")
                            .font(.system(.subheadline, design: .serif))
                            .foregroundColor(Color.Journal.mutedText)
                        
                        Text("Start a routine to see your history here")
                            .font(.system(.caption, design: .serif))
                            .foregroundColor(Color.Journal.mutedText.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            } else {
                ForEach(analytics.completions.prefix(5)) { completion in
                    CompletionHistoryCard(completion: completion)
                }
            }
        }
    }
}

// MARK: - Routine Stat Card

struct RoutineStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        RoutineJournalCard(mode: .morning, padding: 14) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(color)
                    
                    Text(title)
                        .font(.system(.caption, design: .serif))
                        .foregroundColor(Color.Journal.mutedText)
                }
                
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .serif))
                    .foregroundColor(Color.Journal.inkBrown)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Insight Card

struct InsightCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    let mode: RoutineMode
    
    var body: some View {
        RoutineJournalCard(mode: mode, padding: 16) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(.caption, design: .serif))
                        .foregroundColor(Color.Journal.mutedText)
                    
                    Text(value)
                        .font(.system(.headline, design: .serif))
                        .foregroundColor(Color.Journal.inkBrown)
                    
                    Text(subtitle)
                        .font(.system(.caption2, design: .serif))
                        .foregroundColor(Color.Journal.mutedText.opacity(0.8))
                }
                
                Spacer()
            }
        }
    }
}

// MARK: - Completion History Card

struct CompletionHistoryCard: View {
    let completion: RoutineCompletion
    
    private var mode: RoutineMode {
        completion.mode
    }
    
    var body: some View {
        RoutineJournalCard(mode: mode, padding: 14) {
            HStack(spacing: 12) {
                // Mode icon
                ZStack {
                    Circle()
                        .fill(mode.accentColor.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: mode.icon)
                        .font(.system(size: 16))
                        .foregroundColor(mode.accentColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(completion.configurationName)
                        .font(.system(.subheadline, design: .serif))
                        .fontWeight(.medium)
                        .foregroundColor(Color.Journal.inkBrown)
                    
                    HStack(spacing: 8) {
                        Text(formattedDate)
                            .font(.system(.caption, design: .serif))
                            .foregroundColor(Color.Journal.mutedText)
                        
                        Circle()
                            .fill(Color.Journal.sepia.opacity(0.3))
                            .frame(width: 3, height: 3)
                        
                        Text(completion.formattedDuration)
                            .font(.system(.caption, design: .serif))
                            .foregroundColor(Color.Journal.mutedText)
                    }
                }
                
                Spacer()
                
                // Completion indicator
                VStack(spacing: 4) {
                    if completion.completionPercentage >= 1.0 {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Text("\(Int(completion.completionPercentage * 100))%")
                            .font(.system(.caption, design: .serif))
                            .fontWeight(.medium)
                            .foregroundColor(mode.accentColor)
                    }
                    
                    // Mood indicator
                    if let startMood = completion.moodAtStart, let endMood = completion.moodAtEnd {
                        HStack(spacing: 2) {
                            Text(startMood.emoji)
                                .font(.system(size: 12))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 8))
                                .foregroundColor(Color.Journal.mutedText)
                            Text(endMood.emoji)
                                .font(.system(size: 12))
                        }
                    }
                }
            }
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(completion.date) {
            formatter.dateFormat = "'Today at' h:mm a"
        } else if Calendar.current.isDateInYesterday(completion.date) {
            formatter.dateFormat = "'Yesterday at' h:mm a"
        } else {
            formatter.dateFormat = "MMM d, h:mm a"
        }
        return formatter.string(from: completion.date)
    }
}

#Preview {
    RoutineAnalyticsView(viewModel: HubViewModel())
}

