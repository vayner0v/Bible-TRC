//
//  MoodGratitudeWidget.swift
//  Bible v1 Widgets
//
//  Mood and gratitude widget with S/M sizes
//

import WidgetKit
import SwiftUI

struct MoodGratitudeWidget: Widget {
    let kind: String = "MoodGratitudeWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MoodGratitudeProvider()) { entry in
            MoodGratitudeWidgetView(entry: entry)
        }
        .configurationDisplayName("Mood & Gratitude")
        .description("Check in with mood & gratitude")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct MoodGratitudeProvider: TimelineProvider {
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

struct MoodGratitudeWidgetView: View {
    let entry: BibleWidgetEntry
    
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme
    
    private var theme: WidgetTheme {
        colorScheme == .dark ? .dark : .light
    }
    
    private let moodEmojis = ["😊", "😌", "🙏", "😔", "😊"]
    
    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        default:
            mediumView
        }
    }
    
    // MARK: - Small View
    
    private var smallView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "heart.fill")
                    .font(.caption)
                    .foregroundColor(.pink)
                
                Text("Mood")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.pink)
            }
            
            Spacer()
            
            // Today's mood
            VStack(spacing: 6) {
                Text(entry.data.lastMood)
                    .font(.system(size: 36))
                
                if entry.data.todayGratitudeCompleted {
                    Label("Gratitude done", systemImage: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.green)
                } else {
                    Text("Tap to check in")
                        .font(.caption2)
                        .foregroundColor(theme.secondaryTextColor)
                }
            }
            .frame(maxWidth: .infinity)
            
            Spacer()
            
            if entry.data.gratitudeStreak > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .font(.caption2)
                    Text("\(entry.data.gratitudeStreak)")
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
            // Left side - mood check
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.pink.opacity(0.15))
                        .frame(width: 60, height: 60)
                    
                    Text(entry.data.lastMood)
                        .font(.system(size: 30))
                }
                
                Text("Today's Mood")
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)
            }
            
            Divider()
                .frame(height: 60)
            
            // Right side - gratitude
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.pink)
                    
                    Text("Mood & Gratitude")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.textColor)
                }
                
                if entry.data.todayGratitudeCompleted {
                    Label("Gratitude completed today!", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Text("What are you grateful for today?")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                }
                
                HStack(spacing: 8) {
                    // Mood history
                    HStack(spacing: 4) {
                        ForEach(moodEmojis, id: \.self) { emoji in
                            Text(emoji)
                                .font(.caption2)
                        }
                    }
                    
                    Spacer()
                    
                    if entry.data.gratitudeStreak > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "flame.fill")
                            Text("\(entry.data.gratitudeStreak)")
                        }
                        .font(.caption)
                        .foregroundColor(.orange)
                    }
                }
            }
            
            Spacer()
        }
        .padding(16)
        .widgetContainer(theme: theme)
    }
}

#Preview(as: .systemSmall) {
    MoodGratitudeWidget()
} timeline: {
    BibleWidgetEntry.placeholder
}

#Preview(as: .systemMedium) {
    MoodGratitudeWidget()
} timeline: {
    BibleWidgetEntry.placeholder
}

