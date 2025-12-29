//
//  JournalStatsView.swift
//  Bible v1
//
//  Spiritual Journal - Statistics & Insights Dashboard
//

import SwiftUI
import Charts

/// Statistics and insights dashboard for journal entries
struct JournalStatsView: View {
    @ObservedObject var viewModel: JournalViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTimeRange: TimeRange = .month
    
    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
        case all = "All Time"
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .year: return 365
            case .all: return 9999
            }
        }
    }
    
    private var filteredEntries: [JournalEntry] {
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -selectedTimeRange.days, to: Date()) ?? Date()
        return viewModel.entries.filter { $0.dateCreated >= cutoffDate }
    }
    
    private var moodCounts: [JournalMood: Int] {
        var counts: [JournalMood: Int] = [:]
        for entry in filteredEntries {
            if let mood = entry.mood {
                counts[mood, default: 0] += 1
            }
        }
        return counts
    }
    
    private var bestStreak: Int {
        calculateBestStreak()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Time range picker
                        timeRangePicker
                        
                        // Streak display
                        StreakDisplay(
                            currentStreak: viewModel.currentStreak,
                            bestStreak: bestStreak,
                            totalEntries: filteredEntries.count
                        )
                        
                        // Mood distribution
                        MoodDistributionChart(moodCounts: moodCounts)
                        
                        // Mood trend
                        MoodTrendChart(
                            entries: filteredEntries,
                            days: min(selectedTimeRange.days, 30)
                        )
                        
                        // Writing frequency
                        WritingFrequencyChart(
                            entriesPerDay: entriesPerDay(days: min(selectedTimeRange.days, 30))
                        )
                        
                        // Word count stats
                        WordCountStats(entries: filteredEntries)
                        
                        // Tag usage
                        TagUsageChart(entries: filteredEntries)
                        
                        // Insights section
                        insightsSection
                        
                        // Bottom padding
                        Color.clear.frame(height: 20)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Journal Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    // MARK: - Time Range Picker
    
    private var timeRangePicker: some View {
        HStack(spacing: 0) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTimeRange = range
                    }
                } label: {
                    Text(range.rawValue)
                        .font(.subheadline)
                        .fontWeight(selectedTimeRange == range ? .semibold : .regular)
                        .foregroundColor(selectedTimeRange == range ? .white : themeManager.textColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedTimeRange == range ? themeManager.accentColor : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // MARK: - Insights Section
    
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Insights")
                .font(.headline)
                .foregroundColor(themeManager.textColor)
            
            VStack(spacing: 12) {
                // Dominant mood insight
                if let dominantMood = viewModel.moodStats.dominantMood {
                    insightCard(
                        icon: dominantMood.icon,
                        iconColor: dominantMood.color,
                        title: "Most Common Mood",
                        description: "You've felt \(dominantMood.displayName.lowercased()) most often during this period."
                    )
                }
                
                // Positivity rate
                let positivityRate = viewModel.moodStats.positivityRate
                insightCard(
                    icon: positivityRate > 0.6 ? "sun.max.fill" : positivityRate > 0.3 ? "cloud.sun.fill" : "cloud.fill",
                    iconColor: positivityRate > 0.6 ? .yellow : positivityRate > 0.3 ? .orange : .gray,
                    title: "Positivity Rate",
                    description: "\(Int(positivityRate * 100))% of your entries have positive moods."
                )
                
                // Trend insight
                let trend = viewModel.moodStats.trend
                insightCard(
                    icon: trend.icon,
                    iconColor: trend.color,
                    title: "Mood Trend",
                    description: trend.description
                )
                
                // Consistency insight
                if viewModel.currentStreak > 0 {
                    insightCard(
                        icon: "flame.fill",
                        iconColor: .orange,
                        title: "Keep it Up!",
                        description: "You've journaled for \(viewModel.currentStreak) days in a row. Great consistency!"
                    )
                }
                
                // Writing suggestion
                if filteredEntries.isEmpty {
                    insightCard(
                        icon: "lightbulb.fill",
                        iconColor: .yellow,
                        title: "Get Started",
                        description: "Start journaling to see your mood patterns and insights over time."
                    )
                }
            }
        }
        .padding()
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(16)
    }
    
    private func insightCard(icon: String, iconColor: Color, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(iconColor)
                .frame(width: 32, height: 32)
                .background(iconColor.opacity(0.15))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.textColor)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            Spacer()
        }
        .padding()
        .background(themeManager.backgroundColor)
        .cornerRadius(12)
    }
    
    // MARK: - Helpers
    
    private func entriesPerDay(days: Int) -> [(date: Date, count: Int)] {
        let calendar = Calendar.current
        var result: [(date: Date, count: Int)] = []
        
        for dayOffset in 0..<days {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) ?? Date()
            let startOfDay = calendar.startOfDay(for: date)
            let count = viewModel.entries.filter { calendar.isDate($0.dateCreated, inSameDayAs: startOfDay) }.count
            result.append((date: startOfDay, count: count))
        }
        
        return result.reversed()
    }
    
    private func calculateBestStreak() -> Int {
        let calendar = Calendar.current
        let sortedDates = viewModel.entries
            .map { calendar.startOfDay(for: $0.dateCreated) }
            .sorted()
        
        guard !sortedDates.isEmpty else { return 0 }
        
        let uniqueDates = Array(Set(sortedDates)).sorted()
        var bestStreak = 1
        var currentStreak = 1
        
        for i in 1..<uniqueDates.count {
            let previousDate = uniqueDates[i - 1]
            let currentDate = uniqueDates[i]
            
            if let daysBetween = calendar.dateComponents([.day], from: previousDate, to: currentDate).day,
               daysBetween == 1 {
                currentStreak += 1
                bestStreak = max(bestStreak, currentStreak)
            } else {
                currentStreak = 1
            }
        }
        
        return bestStreak
    }
}

#Preview {
    JournalStatsView(viewModel: JournalViewModel())
}

