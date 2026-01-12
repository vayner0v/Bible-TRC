//
//  AIUsageStatsView.swift
//  Bible v1
//
//  TRC AI Bible Assistant - Usage Statistics Dashboard
//

import SwiftUI

/// Dashboard showing AI usage statistics and insights
struct AIUsageStatsView: View {
    @ObservedObject private var storageService = ChatStorageService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    private var stats: AIUsageStatistics {
        storageService.usageStatistics
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Streak Section
                    streakCard
                    
                    // Quick Stats Grid
                    quickStatsGrid
                    
                    // Activity Chart
                    activitySection
                    
                    // Mode Breakdown
                    modeBreakdownSection
                    
                    // Top Verses
                    if !stats.topCitedBooks.isEmpty {
                        topBooksSection
                    }
                    
                    // Account Info
                    accountInfoSection
                }
                .padding()
            }
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .navigationTitle("Your Journey")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.accentColor)
                }
            }
        }
    }
    
    // MARK: - Streak Card
    
    private var streakCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                // Current Streak
                VStack(spacing: 8) {
                    Text("\(stats.currentStreak)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(stats.currentStreak > 0 ? .orange : themeManager.secondaryTextColor)
                    
                    Text("Day Streak")
                        .font(.subheadline)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                    .frame(height: 60)
                
                // Longest Streak
                VStack(spacing: 8) {
                    Text("\(stats.longestStreak)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.accentColor)
                    
                    Text("Best Streak")
                        .font(.subheadline)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                .frame(maxWidth: .infinity)
            }
            
            if stats.currentStreak > 0 {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("Keep going! You're on a roll!")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
        }
        .padding()
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(16)
    }
    
    // MARK: - Quick Stats Grid
    
    private var quickStatsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            AIStatCard(
                icon: "bubble.left.and.bubble.right.fill",
                value: "\(stats.totalConversations)",
                label: "Conversations",
                color: .blue
            )
            
            AIStatCard(
                icon: "text.bubble.fill",
                value: "\(stats.totalMessages)",
                label: "Messages",
                color: .green
            )
            
            AIStatCard(
                icon: "book.fill",
                value: "\(stats.totalCitations)",
                label: "Verses Cited",
                color: .purple
            )
            
            AIStatCard(
                icon: "chart.line.uptrend.xyaxis",
                value: String(format: "%.1f", stats.averageMessagesPerConversation),
                label: "Avg/Conversation",
                color: .orange
            )
        }
    }
    
    // MARK: - Activity Section
    
    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity")
                .font(.headline)
                .foregroundColor(themeManager.textColor)
            
            HStack(spacing: 16) {
                ActivityPill(
                    label: "Last 7 days",
                    value: stats.messagesLast7Days,
                    icon: "calendar"
                )
                
                ActivityPill(
                    label: "Last 30 days",
                    value: stats.messagesLast30Days,
                    icon: "calendar.badge.clock"
                )
            }
            
            if let mostActive = stats.mostActiveDay {
                HStack {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    Text("Most active on \(mostActive)s")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
            
            // Simple activity visualization
            activityChart
        }
        .padding()
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(16)
    }
    
    private var activityChart: some View {
        let last7Days = (0..<7).map { offset -> (date: Date, count: Int) in
            let date = Calendar.current.date(byAdding: .day, value: -offset, to: Date()) ?? Date()
            let dayStart = Calendar.current.startOfDay(for: date)
            let count = stats.messagesByDay[dayStart] ?? 0
            return (date: dayStart, count: count)
        }.reversed()
        
        let maxCount = max(last7Days.map { $0.count }.max() ?? 1, 1)
        
        return VStack(spacing: 8) {
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(last7Days.enumerated()), id: \.offset) { _, day in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(day.count > 0 ? themeManager.accentColor : themeManager.secondaryTextColor.opacity(0.3))
                            .frame(height: CGFloat(max(8, (Double(day.count) / Double(maxCount)) * 60)))
                        
                        Text(dayLabel(day.date))
                            .font(.caption2)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 80)
        }
        .padding(.top, 8)
    }
    
    private func dayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return String(formatter.string(from: date).prefix(1))
    }
    
    // MARK: - Mode Breakdown
    
    private var modeBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Conversation Modes")
                .font(.headline)
                .foregroundColor(themeManager.textColor)
            
            ForEach(AIMode.allCases) { mode in
                let count = stats.conversationsByMode[mode] ?? 0
                let percentage = stats.totalConversations > 0 
                    ? Double(count) / Double(stats.totalConversations) 
                    : 0
                
                HStack {
                    Image(systemName: mode.icon)
                        .foregroundColor(mode.accentColor)
                        .frame(width: 24)
                    
                    Text(mode.displayName)
                        .font(.subheadline)
                        .foregroundColor(themeManager.textColor)
                    
                    Spacer()
                    
                    Text("\(count)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(themeManager.secondaryTextColor.opacity(0.2))
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(mode.accentColor)
                            .frame(width: geo.size.width * percentage)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding()
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(16)
    }
    
    // MARK: - Top Books
    
    private var topBooksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Most Cited Books")
                .font(.headline)
                .foregroundColor(themeManager.textColor)
            
            ForEach(Array(stats.topCitedBooks.enumerated()), id: \.offset) { index, item in
                HStack {
                    Text("\(index + 1)")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(themeManager.accentColor)
                        .cornerRadius(12)
                    
                    Text(item.book)
                        .font(.subheadline)
                        .foregroundColor(themeManager.textColor)
                    
                    Spacer()
                    
                    Text("\(item.count) citations")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
        }
        .padding()
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(16)
    }
    
    // MARK: - Account Info
    
    private var accountInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Journey")
                .font(.headline)
                .foregroundColor(themeManager.textColor)
            
            if let firstDate = stats.firstConversationDate {
                HStack {
                    Image(systemName: "calendar.badge.plus")
                        .foregroundColor(themeManager.accentColor)
                    
                    VStack(alignment: .leading) {
                        Text("Started")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                        Text(firstDate, style: .date)
                            .font(.subheadline)
                            .foregroundColor(themeManager.textColor)
                    }
                    
                    Spacer()
                    
                    Text("\(stats.accountAgeDays) days ago")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
        }
        .padding()
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(16)
    }
}

// MARK: - Stat Card

private struct AIStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundColor(themeManager.textColor)
            
            Text(label)
                .font(.caption)
                .foregroundColor(themeManager.secondaryTextColor)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(12)
    }
}

// MARK: - Activity Pill

private struct ActivityPill: View {
    let label: String
    let value: Int
    let icon: String
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(themeManager.accentColor)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(value) messages")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(themeManager.textColor)
                
                Text(label)
                    .font(.caption2)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(themeManager.backgroundColor)
        .cornerRadius(20)
    }
}

// MARK: - Preview

#Preview {
    AIUsageStatsView()
}

