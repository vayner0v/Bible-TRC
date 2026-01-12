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
        AppIntentConfiguration(
            kind: kind,
            intent: HabitTrackerIntent.self,
            provider: HabitTrackerIntentProvider()
        ) { entry in
            HabitTrackerWidgetView(entry: entry)
        }
        .configurationDisplayName("Habit Tracker")
        .description("Monitor your daily spiritual habits")
        .supportedFamilies([
            .systemSmall, .systemMedium, .systemLarge,
            .accessoryCircular, .accessoryRectangular, .accessoryInline
        ])
    }
}

struct HabitTrackerWidgetView: View {
    let entry: HabitTrackerEntry
    
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme
    
    private var styleConfig: WidgetStyleConfig {
        WidgetStyleConfig(preset: entry.configuration.resolvedStylePreset, colorScheme: colorScheme)
    }
    
    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                smallView
            case .systemMedium:
                mediumView
            case .systemLarge:
                largeView
            case .accessoryCircular:
                accessoryCircularView
            case .accessoryRectangular:
                accessoryRectangularView
            case .accessoryInline:
                accessoryInlineView
            default:
                mediumView
            }
        }
        .widgetURL(URL(string: "biblev1://habits"))
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
            if entry.configuration.showCompletionRing {
                HStack {
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .stroke(styleConfig.cardBackground, lineWidth: 6)
                            .frame(width: 55, height: 55)
                        
                        Circle()
                            .trim(from: 0, to: entry.data.todayHabitProgress)
                            .stroke(.green, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .frame(width: 55, height: 55)
                        
                        Text("\(entry.data.completedHabits)/\(entry.data.totalHabits)")
                            .font(.caption.bold())
                            .foregroundColor(styleConfig.textColor)
                    }
                    
                    Spacer()
                }
            } else {
                VStack(alignment: .center, spacing: 4) {
                    Text("\(entry.data.completedHabits)/\(entry.data.totalHabits)")
                        .font(.title.bold())
                        .foregroundColor(styleConfig.textColor)
                    Text("completed")
                        .font(.caption2)
                        .foregroundColor(styleConfig.secondaryTextColor)
                }
                .frame(maxWidth: .infinity)
            }
            
            Spacer()
            
            if entry.configuration.showStreak && entry.data.habitStreak > 0 {
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
        .containerBackground(for: .widget) {
            styleConfig.background
        }
    }
    
    // MARK: - Medium View
    
    private var mediumView: some View {
        HStack(spacing: 16) {
            // Left side - progress ring
            if entry.configuration.showCompletionRing {
                ZStack {
                    Circle()
                        .stroke(styleConfig.cardBackground, lineWidth: 8)
                        .frame(width: 70, height: 70)
                    
                    Circle()
                        .trim(from: 0, to: entry.data.todayHabitProgress)
                        .stroke(.green, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 70, height: 70)
                    
                    VStack(spacing: 0) {
                        Text("\(entry.data.completedHabits)")
                            .font(.title2.bold())
                            .foregroundColor(styleConfig.textColor)
                        Text("of \(entry.data.totalHabits)")
                            .font(.caption2)
                            .foregroundColor(styleConfig.secondaryTextColor)
                    }
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
                        .foregroundColor(styleConfig.textColor)
                }
                
                Text(entry.data.todayHabitProgress >= 1.0 ? "All done! Great job!" : "Keep going, you're doing great!")
                    .font(.caption)
                    .foregroundColor(styleConfig.secondaryTextColor)
                
                if entry.configuration.showStreak && entry.data.habitStreak > 0 {
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
        .containerBackground(for: .widget) {
            styleConfig.background
        }
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
                        .foregroundColor(styleConfig.textColor)
                    
                    Text("Build consistency every day")
                        .font(.caption)
                        .foregroundColor(styleConfig.secondaryTextColor)
                }
                
                Spacer()
                
                if entry.configuration.showStreak && entry.data.habitStreak > 0 {
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
                .background(styleConfig.secondaryTextColor.opacity(0.3))
            
            // Large progress ring
            if entry.configuration.showCompletionRing {
                HStack {
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .stroke(styleConfig.cardBackground, lineWidth: 14)
                            .frame(width: 130, height: 130)
                        
                        Circle()
                            .trim(from: 0, to: entry.data.todayHabitProgress)
                            .stroke(.green, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .frame(width: 130, height: 130)
                        
                        VStack(spacing: 4) {
                            Text("\(entry.data.completedHabits)/\(entry.data.totalHabits)")
                                .font(.title.bold())
                                .foregroundColor(styleConfig.textColor)
                            
                            Text("Complete")
                                .font(.caption)
                                .foregroundColor(styleConfig.secondaryTextColor)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 8)
            }
            
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
                        .foregroundColor(styleConfig.secondaryTextColor)
                }
                
                Spacer()
            }
            .padding(.vertical, 12)
            .background(styleConfig.cardBackground)
            .cornerRadius(10)
        }
        .padding(16)
        .containerBackground(for: .widget) {
            styleConfig.background
        }
    }
    
    // MARK: - Lock Screen Views
    
    private var accessoryCircularView: some View {
        Gauge(value: entry.data.todayHabitProgress) {
            Image(systemName: "checkmark.circle.fill")
        } currentValueLabel: {
            Text("\(entry.data.completedHabits)")
                .font(.caption2)
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .widgetAccentable()
        .containerBackground(for: .widget) { }
    }
    
    private var accessoryRectangularView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14, weight: .bold))
                Text("\(entry.data.completedHabits)/\(entry.data.totalHabits) Habits")
                    .font(.system(size: 15, weight: .bold))
                Spacer()
                if entry.data.habitStreak > 0 {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 14, weight: .bold))
                    Text("\(entry.data.habitStreak)")
                        .font(.system(size: 15, weight: .bold))
                }
            }
            .widgetAccentable()
            
            Gauge(value: entry.data.todayHabitProgress) {
                EmptyView()
            }
            .gaugeStyle(.accessoryLinearCapacity)
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(for: .widget) { }
    }
    
    private var accessoryInlineView: some View {
        Label("\(entry.data.completedHabits)/\(entry.data.totalHabits) Habits", systemImage: "checkmark.circle.fill")
            .containerBackground(for: .widget) { }
    }
}

#Preview(as: .systemSmall) {
    HabitTrackerWidget()
} timeline: {
    HabitTrackerEntry(date: Date(), data: .placeholder, configuration: HabitTrackerIntent())
}

#Preview(as: .systemMedium) {
    HabitTrackerWidget()
} timeline: {
    HabitTrackerEntry(date: Date(), data: .placeholder, configuration: HabitTrackerIntent())
}

#Preview(as: .systemLarge) {
    HabitTrackerWidget()
} timeline: {
    HabitTrackerEntry(date: Date(), data: .placeholder, configuration: HabitTrackerIntent())
}

#Preview(as: .accessoryCircular) {
    HabitTrackerWidget()
} timeline: {
    HabitTrackerEntry(date: Date(), data: .placeholder, configuration: HabitTrackerIntent())
}

#Preview(as: .accessoryRectangular) {
    HabitTrackerWidget()
} timeline: {
    HabitTrackerEntry(date: Date(), data: .placeholder, configuration: HabitTrackerIntent())
}

#Preview(as: .accessoryInline) {
    HabitTrackerWidget()
} timeline: {
    HabitTrackerEntry(date: Date(), data: .placeholder, configuration: HabitTrackerIntent())
}
