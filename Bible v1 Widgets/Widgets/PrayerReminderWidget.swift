//
//  PrayerReminderWidget.swift
//  Bible v1 Widgets
//
//  Prayer reminder widget with S/M/L sizes
//

import WidgetKit
import SwiftUI

struct PrayerReminderWidget: Widget {
    let kind: String = "PrayerReminderWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerReminderProvider()) { entry in
            PrayerReminderWidgetView(entry: entry)
        }
        .configurationDisplayName("Prayer Reminder")
        .description("Quick access to your prayers")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct PrayerReminderProvider: TimelineProvider {
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
        
        // Update every 30 minutes
        let nextUpdate = Date().addingTimeInterval(1800)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct PrayerReminderWidgetView: View {
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
                Image(systemName: "hands.sparkles")
                    .font(.caption)
                    .foregroundColor(.teal)
                
                Text("Prayer")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.teal)
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("\(entry.data.activePrayerCount)")
                            .font(.title2.bold())
                            .foregroundColor(theme.textColor)
                        Text("Active")
                            .font(.caption2)
                            .foregroundColor(theme.secondaryTextColor)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("\(entry.data.answeredPrayerCount)")
                            .font(.title2.bold())
                            .foregroundColor(.green)
                        Text("Answered")
                            .font(.caption2)
                            .foregroundColor(theme.secondaryTextColor)
                    }
                }
            }
            
            Spacer()
            
            Text("Tap to pray")
                .font(.caption2)
                .foregroundColor(theme.secondaryTextColor)
        }
        .padding(12)
        .widgetContainer(theme: theme)
    }
    
    // MARK: - Medium View
    
    private var mediumView: some View {
        HStack(spacing: 16) {
            // Left side - icon and title
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(Color.teal.opacity(0.15))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "hands.sparkles")
                            .foregroundColor(.teal)
                    }
                    
                    Text("Prayer")
                        .font(.headline)
                        .foregroundColor(theme.textColor)
                }
                
                Spacer()
                
                Text("Your prayers matter")
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)
            }
            
            Spacer()
            
            // Right side - stats
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("\(entry.data.activePrayerCount)")
                        .font(.title.bold())
                        .foregroundColor(theme.textColor)
                    Text("Active")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                }
                
                VStack(spacing: 4) {
                    Text("\(entry.data.answeredPrayerCount)")
                        .font(.title.bold())
                        .foregroundColor(.green)
                    Text("Answered")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                }
            }
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
                        .fill(Color.teal.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "hands.sparkles")
                        .font(.title3)
                        .foregroundColor(.teal)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Prayer Journal")
                        .font(.headline)
                        .foregroundColor(theme.textColor)
                    
                    Text("Keep your prayers close")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                }
                
                Spacer()
            }
            
            Divider()
                .background(theme.secondaryTextColor.opacity(0.3))
            
            // Stats cards
            HStack(spacing: 12) {
                PrayerStatCard(
                    title: "Active Prayers",
                    value: "\(entry.data.activePrayerCount)",
                    icon: "heart.fill",
                    color: .teal,
                    theme: theme
                )
                
                PrayerStatCard(
                    title: "Answered",
                    value: "\(entry.data.answeredPrayerCount)",
                    icon: "checkmark.circle.fill",
                    color: .green,
                    theme: theme
                )
            }
            
            Spacer()
            
            // Encouragement
            VStack(spacing: 8) {
                Image(systemName: "quote.opening")
                    .font(.caption)
                    .foregroundColor(theme.accentColor.opacity(0.5))
                
                Text("\"Do not be anxious about anything, but in every situation, by prayer and petition, with thanksgiving, present your requests to God.\"")
                    .font(.system(size: 12, design: .serif))
                    .foregroundColor(theme.textColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                
                Text("— Philippians 4:6")
                    .font(.caption2)
                    .foregroundColor(theme.secondaryTextColor)
            }
            .padding(.horizontal)
            
            Spacer()
            
            // CTA
            HStack {
                Spacer()
                
                Text("Tap to add a prayer")
                    .font(.caption)
                    .foregroundColor(.teal)
                
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.teal)
                
                Spacer()
            }
            .padding(.vertical, 10)
            .background(Color.teal.opacity(0.1))
            .cornerRadius(10)
        }
        .padding(16)
        .widgetContainer(theme: theme)
    }
}

struct PrayerStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let theme: WidgetTheme
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title.bold())
                .foregroundColor(theme.textColor)
            
            Text(title)
                .font(.caption)
                .foregroundColor(theme.secondaryTextColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(theme.cardBackground)
        .cornerRadius(12)
    }
}

#Preview(as: .systemSmall) {
    PrayerReminderWidget()
} timeline: {
    BibleWidgetEntry.placeholder
}

#Preview(as: .systemMedium) {
    PrayerReminderWidget()
} timeline: {
    BibleWidgetEntry.placeholder
}

#Preview(as: .systemLarge) {
    PrayerReminderWidget()
} timeline: {
    BibleWidgetEntry.placeholder
}

