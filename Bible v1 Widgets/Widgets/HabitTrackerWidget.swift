//
//  HabitTrackerWidget.swift
//  Bible v1 Widgets
//
//  Daily habits tracker widget with S/M/L sizes
//

import WidgetKit
import SwiftUI

struct HabitTrackerWidget: Widget {
    let kind: String = "HabitTrackerWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HabitTrackerProvider()) { entry in
            HabitTrackerWidgetView(entry: entry)
        }
        .configurationDisplayName("Habit Tracker")
        .description("Monitor your daily spiritual habits")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct HabitTrackerProvider: TimelineProvider {
    func placeholder(in context: Context) -> BibleWidgetEntry {
        BibleWidgetEntry.placeholder
    }
    
    func getSnapshot(in context: Context, completion: @escaping (BibleWidgetEntry) -> Void) {
        let data = WidgetDataProvider.shared.fetchWidgetData()
        let entry = BibleWidgetEntry(date: Date(), data: data, configuration: nil)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<BibleWidgetEntry>) -> Void) {
        let data = WidgetDataProvider.shared.fetchWidgetData()
        let entry = BibleWidgetEntry(date: Date(), data: data, configuration: nil)
        
        // Update every hour
        let nextUpdate = Date().addingTimeInterval(3600)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct HabitTrackerWidgetView: View {
    let entry: BibleWidgetEntry
    
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme
    
    private var theme: WidgetTheme {
        colorScheme == .dark ? .dark : .light
    }
    
    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        case .systemLarge:
            largeView
        default:
            mediumView
        }
    }
    
    // MARK: - Small View
    
    private var smallView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)
                
                Text("Habits")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }
            
            Spacer()
            
            // Circular progress
            HStack {
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(theme.cardBackground, lineWidth: 6)
                        .frame(width: 55, height: 55)
                    
                    Circle()
                        .trim(from: 0, to: entry.data.todayHabitProgress)
                        .stroke(.green, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 55, height: 55)
                    
                    Text("\(entry.data.completedHabits)/\(entry.data.totalHabits)")
                        .font(.caption.bold())
                        .foregroundColor(theme.textColor)
                }
                
                Spacer()
            }
            
            Spacer()
            
            if entry.data.habitStreak > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .font(.caption2)
                    Text("\(entry.data.habitStreak) day streak")
                        .font(.caption2)
                }
                .foregroundColor(.orange)
            }
        }
        .padding(12)
        .widgetContainer(theme: theme)
    }
    
    // MARK: - Medium View
    
    private var mediumView: some View {
        HStack(spacing: 16) {
            // Left side - progress ring
            ZStack {
                Circle()
                    .stroke(theme.cardBackground, lineWidth: 8)
                    .frame(width: 70, height: 70)
                
                Circle()
                    .trim(from: 0, to: entry.data.todayHabitProgress)
                    .stroke(.green, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 70, height: 70)
                
                VStack(spacing: 0) {
                    Text("\(entry.data.completedHabits)")
                        .font(.title2.bold())
                        .foregroundColor(theme.textColor)
                    Text("of \(entry.data.totalHabits)")
                        .font(.caption2)
                        .foregroundColor(theme.secondaryTextColor)
                }
            }
            
            // Right side - details
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    
                    Text("Daily Habits")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.textColor)
                }
                
                Text(entry.data.todayHabitProgress >= 1.0 ? "All done! Great job!" : "Keep going, you're doing great!")
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)
                
                if entry.data.habitStreak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                        Text("\(entry.data.habitStreak) day streak")
                    }
                    .font(.caption)
                    .foregroundColor(.orange)
                }
            }
            
            Spacer()
        }
        .padding(16)
        .widgetContainer(theme: theme)
    }
    
    // MARK: - Large View
    
    private var largeView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.green)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Daily Habits")
                        .font(.headline)
                        .foregroundColor(theme.textColor)
                    
                    Text("Build consistency every day")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                }
                
                Spacer()
                
                if entry.data.habitStreak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                        Text("\(entry.data.habitStreak)")
                    }
                    .font(.subheadline.bold())
                    .foregroundColor(.orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.15))
                    .cornerRadius(12)
                }
            }
            
            Divider()
                .background(theme.secondaryTextColor.opacity(0.3))
            
            // Large progress ring
            HStack {
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(theme.cardBackground, lineWidth: 14)
                        .frame(width: 130, height: 130)
                    
                    Circle()
                        .trim(from: 0, to: entry.data.todayHabitProgress)
                        .stroke(.green, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 130, height: 130)
                    
                    VStack(spacing: 4) {
                        Text("\(entry.data.completedHabits)/\(entry.data.totalHabits)")
                            .font(.title.bold())
                            .foregroundColor(theme.textColor)
                        
                        Text("Complete")
                            .font(.caption)
                            .foregroundColor(theme.secondaryTextColor)
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 8)
            
            Spacer()
            
            // Status message
            HStack {
                Spacer()
                
                if entry.data.todayHabitProgress >= 1.0 {
                    Label("All habits completed!", systemImage: "star.fill")
                        .font(.subheadline)
                        .foregroundColor(.green)
                } else {
                    Text("\(entry.data.totalHabits - entry.data.completedHabits) habits remaining today")
                        .font(.subheadline)
                        .foregroundColor(theme.secondaryTextColor)
                }
                
                Spacer()
            }
            .padding(.vertical, 12)
            .background(theme.cardBackground)
            .cornerRadius(10)
        }
        .padding(16)
        .widgetContainer(theme: theme)
    }
}

#Preview(as: .systemSmall) {
    HabitTrackerWidget()
} timeline: {
    BibleWidgetEntry.placeholder
}

#Preview(as: .systemMedium) {
    HabitTrackerWidget()
} timeline: {
    BibleWidgetEntry.placeholder
}

#Preview(as: .systemLarge) {
    HabitTrackerWidget()
} timeline: {
    BibleWidgetEntry.placeholder
}

