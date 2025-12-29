//
//  HubQuickStats.swift
//  Bible v1
//
//  Quick stats bar for the Hub header
//

import SwiftUI

/// Single stat item data
struct HubStatItem: Identifiable {
    let id = UUID()
    let icon: String
    let value: String
    let label: String
    let color: Color
}

/// Quick stats bar displayed at the top of the Hub
struct HubQuickStats: View {
    let stats: [HubStatItem]
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var hasAppeared = false
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(stats.enumerated()), id: \.element.id) { index, stat in
                statItem(stat, delay: Double(index) * 0.05)
                
                if index < stats.count - 1 {
                    divider
                }
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.hubElevatedSurface)
                .shadow(
                    color: themeManager.hubShadowColor,
                    radius: 8,
                    x: 0,
                    y: 4
                )
        )
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 10)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) {
                hasAppeared = true
            }
        }
    }
    
    private func statItem(_ stat: HubStatItem, delay: Double) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: stat.icon)
                    .font(.caption)
                    .foregroundColor(stat.color)
                
                Text(stat.value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.textColor)
            }
            
            Text(stat.label)
                .font(.caption2)
                .foregroundColor(themeManager.secondaryTextColor)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var divider: some View {
        Rectangle()
            .fill(themeManager.dividerColor)
            .frame(width: 1, height: 36)
    }
}

/// Factory for creating stat items from ViewModel data
struct HubStatsFactory {
    static func createStats(from viewModel: HubViewModel) -> [HubStatItem] {
        var items: [HubStatItem] = []
        
        // Streak stat
        let maxStreak = viewModel.habitStreaks.map { $0.currentStreak }.max() ?? 0
        if maxStreak > 0 {
            items.append(HubStatItem(
                icon: "flame.fill",
                value: "\(maxStreak)",
                label: "Streak",
                color: .orange
            ))
        } else {
            items.append(HubStatItem(
                icon: "flame",
                value: "0",
                label: "Streak",
                color: .orange
            ))
        }
        
        // Prayers stat
        let activePrayers = viewModel.unansweredPrayers.count
        items.append(HubStatItem(
            icon: "hands.sparkles",
            value: "\(activePrayers)",
            label: "Prayers",
            color: ThemeManager.shared.accentColor
        ))
        
        // Habits completed today
        let habitsCompleted = viewModel.todayCompletedHabits.count
        let totalHabits = viewModel.trackedHabits.count
        items.append(HubStatItem(
            icon: "checkmark.circle.fill",
            value: "\(habitsCompleted)/\(totalHabits)",
            label: "Habits",
            color: .green
        ))
        
        return items
    }
}

#Preview {
    VStack {
        HubQuickStats(stats: [
            HubStatItem(icon: "flame.fill", value: "7", label: "Streak", color: .orange),
            HubStatItem(icon: "hands.sparkles", value: "12", label: "Prayers", color: .teal),
            HubStatItem(icon: "checkmark.circle.fill", value: "3/5", label: "Habits", color: .green)
        ])
        .padding()
    }
    .background(Color(.systemBackground))
}


