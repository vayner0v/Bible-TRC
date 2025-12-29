//
//  MoodChart.swift
//  Bible v1
//
//  Spiritual Journal - Mood Visualization Charts
//

import SwiftUI
import Charts

// MARK: - Mood Distribution Chart

/// Pie/Ring chart showing mood distribution
struct MoodDistributionChart: View {
    let moodCounts: [JournalMood: Int]
    @ObservedObject private var themeManager = ThemeManager.shared
    
    private var sortedMoods: [(mood: JournalMood, count: Int)] {
        moodCounts
            .map { (mood: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }
    
    private var totalCount: Int {
        moodCounts.values.reduce(0, +)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Mood Distribution")
                .font(.headline)
                .foregroundColor(themeManager.textColor)
            
            if totalCount > 0 {
                HStack(spacing: 20) {
                    // Chart
                    Chart(sortedMoods, id: \.mood) { item in
                        SectorMark(
                            angle: .value("Count", item.count),
                            innerRadius: .ratio(0.5),
                            angularInset: 2
                        )
                        .foregroundStyle(item.mood.color)
                        .cornerRadius(4)
                    }
                    .frame(width: 120, height: 120)
                    
                    // Legend
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(sortedMoods.prefix(5), id: \.mood) { item in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(item.mood.color)
                                    .frame(width: 10, height: 10)
                                
                                Text(item.mood.displayName)
                                    .font(.caption)
                                    .foregroundColor(themeManager.textColor)
                                
                                Spacer()
                                
                                Text("\(Int(Double(item.count) / Double(totalCount) * 100))%")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(themeManager.secondaryTextColor)
                            }
                        }
                    }
                }
            } else {
                Text("No mood data yet")
                    .font(.subheadline)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 30)
            }
        }
        .padding()
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(16)
    }
}

// MARK: - Mood Trend Chart

/// Line chart showing mood trends over time
struct MoodTrendChart: View {
    let entries: [JournalEntry]
    let days: Int
    @ObservedObject private var themeManager = ThemeManager.shared
    
    private struct MoodDataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let moodScore: Double
        let mood: JournalMood?
    }
    
    private var dataPoints: [MoodDataPoint] {
        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: Date())
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) else {
            return []
        }
        
        var points: [MoodDataPoint] = []
        var currentDate = startDate
        
        while currentDate <= endDate {
            let dayEntries = entries.filter { calendar.isDate($0.dateCreated, inSameDayAs: currentDate) }
            
            if let entry = dayEntries.first, let mood = entry.mood {
                let score = moodToScore(mood)
                points.append(MoodDataPoint(date: currentDate, moodScore: score, mood: mood))
            } else {
                // Use previous point's score or neutral
                let previousScore = points.last?.moodScore ?? 3.0
                points.append(MoodDataPoint(date: currentDate, moodScore: previousScore, mood: nil))
            }
            
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }
        
        return points
    }
    
    private func moodToScore(_ mood: JournalMood) -> Double {
        switch mood {
        case .joyful: return 5.0
        case .peaceful: return 4.5
        case .grateful: return 4.5
        case .hopeful: return 4.0
        case .reflective: return 3.5
        case .anxious: return 2.0
        case .struggling: return 1.0
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Mood Trend")
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
                
                Spacer()
                
                Text("Last \(days) days")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            if dataPoints.contains(where: { $0.mood != nil }) {
                Chart(dataPoints) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Mood", point.moodScore)
                    )
                    .foregroundStyle(themeManager.accentColor.gradient)
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Mood", point.moodScore)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [themeManager.accentColor.opacity(0.3), themeManager.accentColor.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                    
                    if point.mood != nil {
                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("Mood", point.moodScore)
                        )
                        .foregroundStyle(point.mood?.color ?? themeManager.accentColor)
                        .symbolSize(40)
                    }
                }
                .chartYScale(domain: 0...5.5)
                .chartYAxis {
                    AxisMarks(values: [1, 2, 3, 4, 5]) { value in
                        AxisValueLabel {
                            if let score = value.as(Int.self) {
                                Text(moodLabel(for: score))
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: max(1, days / 5))) { value in
                        AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                    }
                }
                .frame(height: 180)
            } else {
                Text("Start tracking your mood to see trends")
                    .font(.subheadline)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 50)
            }
        }
        .padding()
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(16)
    }
    
    private func moodLabel(for score: Int) -> String {
        switch score {
        case 5: return "😊"
        case 4: return "😌"
        case 3: return "🤔"
        case 2: return "😰"
        case 1: return "😔"
        default: return ""
        }
    }
}

// MARK: - Writing Frequency Chart

/// Bar chart showing entries per day/week
struct WritingFrequencyChart: View {
    let entriesPerDay: [(date: Date, count: Int)]
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Writing Frequency")
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
                
                Spacer()
                
                Text("\(entriesPerDay.reduce(0) { $0 + $1.count }) entries")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            Chart(entriesPerDay, id: \.date) { item in
                BarMark(
                    x: .value("Date", item.date, unit: .day),
                    y: .value("Entries", item.count)
                )
                .foregroundStyle(
                    item.count > 0 ? themeManager.accentColor : themeManager.secondaryTextColor.opacity(0.3)
                )
                .cornerRadius(4)
            }
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 3))
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: max(1, entriesPerDay.count / 7))) { value in
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                }
            }
            .frame(height: 120)
        }
        .padding()
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(16)
    }
}

// MARK: - Streak Display

/// Visual display of current and best streak
struct StreakDisplay: View {
    let currentStreak: Int
    let bestStreak: Int
    let totalEntries: Int
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 16) {
            // Current streak
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "flame.fill")
                        .font(.title)
                        .foregroundColor(.white)
                }
                
                Text("\(currentStreak)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.textColor)
                
                Text("Day Streak")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(16)
            
            // Best streak
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [themeManager.accentColor, themeManager.accentColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "trophy.fill")
                        .font(.title)
                        .foregroundColor(.white)
                }
                
                Text("\(bestStreak)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.textColor)
                
                Text("Best Streak")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(16)
            
            // Total entries
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.mint, .teal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "doc.text.fill")
                        .font(.title)
                        .foregroundColor(.white)
                }
                
                Text("\(totalEntries)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.textColor)
                
                Text("Total Entries")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(16)
        }
    }
}

// MARK: - Tag Usage Chart

/// Shows most used tags
struct TagUsageChart: View {
    let entries: [JournalEntry]
    @ObservedObject private var themeManager = ThemeManager.shared
    
    private var tagCounts: [(tag: JournalTag, count: Int)] {
        var counts: [UUID: (tag: JournalTag, count: Int)] = [:]
        
        for entry in entries {
            for tag in entry.tags {
                if let existing = counts[tag.id] {
                    counts[tag.id] = (tag: tag, count: existing.count + 1)
                } else {
                    counts[tag.id] = (tag: tag, count: 1)
                }
            }
        }
        
        return counts.values.sorted { $0.count > $1.count }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Top Tags")
                .font(.headline)
                .foregroundColor(themeManager.textColor)
            
            if tagCounts.isEmpty {
                Text("No tags used yet")
                    .font(.subheadline)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                let maxCount = tagCounts.first?.count ?? 1
                
                VStack(spacing: 12) {
                    ForEach(tagCounts.prefix(5), id: \.tag.id) { item in
                        HStack(spacing: 12) {
                            HStack(spacing: 6) {
                                Image(systemName: item.tag.icon)
                                    .font(.caption)
                                    .foregroundColor(item.tag.color)
                                
                                Text(item.tag.name)
                                    .font(.subheadline)
                                    .foregroundColor(themeManager.textColor)
                            }
                            .frame(width: 100, alignment: .leading)
                            
                            GeometryReader { geometry in
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(item.tag.color)
                                    .frame(width: geometry.size.width * CGFloat(item.count) / CGFloat(maxCount))
                            }
                            .frame(height: 20)
                            
                            Text("\(item.count)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(themeManager.secondaryTextColor)
                                .frame(width: 30, alignment: .trailing)
                        }
                    }
                }
            }
        }
        .padding()
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(16)
    }
}

// MARK: - Word Count Stats

/// Shows word count statistics
struct WordCountStats: View {
    let entries: [JournalEntry]
    @ObservedObject private var themeManager = ThemeManager.shared
    
    private var totalWords: Int {
        entries.reduce(0) { $0 + $1.wordCount }
    }
    
    private var averageWords: Int {
        guard !entries.isEmpty else { return 0 }
        return totalWords / entries.count
    }
    
    private var longestEntry: Int {
        entries.map { $0.wordCount }.max() ?? 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Writing Stats")
                .font(.headline)
                .foregroundColor(themeManager.textColor)
            
            HStack(spacing: 0) {
                statItem(value: "\(totalWords)", label: "Total Words", icon: "text.word.spacing")
                
                Divider()
                    .frame(height: 40)
                
                statItem(value: "\(averageWords)", label: "Avg/Entry", icon: "chart.bar")
                
                Divider()
                    .frame(height: 40)
                
                statItem(value: "\(longestEntry)", label: "Longest", icon: "doc.text")
            }
        }
        .padding()
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(16)
    }
    
    private func statItem(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(themeManager.accentColor)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(themeManager.textColor)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(themeManager.secondaryTextColor)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview("Mood Distribution") {
    MoodDistributionChart(moodCounts: [
        .joyful: 10,
        .peaceful: 8,
        .grateful: 6,
        .reflective: 4,
        .anxious: 2
    ])
    .padding()
}

#Preview("Streak Display") {
    StreakDisplay(currentStreak: 7, bestStreak: 14, totalEntries: 45)
        .padding()
}

