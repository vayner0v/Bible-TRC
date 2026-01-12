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
        AppIntentConfiguration(
            kind: kind,
            intent: MoodGratitudeIntent.self,
            provider: MoodGratitudeIntentProvider()
        ) { entry in
            MoodGratitudeWidgetView(entry: entry)
        }
        .configurationDisplayName("Mood & Gratitude")
        .description("Check in with mood & gratitude")
        .supportedFamilies([
            .systemSmall, .systemMedium,
            .accessoryCircular, .accessoryRectangular, .accessoryInline
        ])
    }
}

struct MoodGratitudeWidgetView: View {
    let entry: MoodGratitudeEntry
    
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
        .widgetURL(URL(string: "biblev1://mood-gratitude"))
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
                } else if entry.configuration.showGratitudePrompt {
                    Text("Tap to check in")
                        .font(.caption2)
                        .foregroundColor(styleConfig.secondaryTextColor)
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
        .containerBackground(for: .widget) {
            styleConfig.background
        }
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
                    .foregroundColor(styleConfig.secondaryTextColor)
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
                        .foregroundColor(styleConfig.textColor)
                }
                
                if entry.data.todayGratitudeCompleted {
                    Label("Gratitude completed today!", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                } else if entry.configuration.showGratitudePrompt {
                    Text("What are you grateful for today?")
                        .font(.caption)
                        .foregroundColor(styleConfig.secondaryTextColor)
                }
                
                HStack(spacing: 8) {
                    // Mood history from actual data
                    if entry.configuration.showMoodHistory {
                        HStack(spacing: 4) {
                            ForEach(entry.data.moodHistory.prefix(5), id: \.self) { emoji in
                                Text(emoji)
                                    .font(.caption2)
                            }
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
        .containerBackground(for: .widget) {
            styleConfig.background
        }
    }
    
    // MARK: - Lock Screen Views
    
    private var accessoryCircularView: some View {
        ZStack {
            AccessoryWidgetBackground()
            Text(entry.data.lastMood)
                .font(.title)
        }
        .widgetAccentable()
        .containerBackground(for: .widget) { }
    }
    
    private var accessoryRectangularView: some View {
        HStack(spacing: 0) {
            Text(entry.data.lastMood)
                .font(.system(size: 44))
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("Today's Mood")
                    .font(.system(size: 15, weight: .bold))
                    .widgetAccentable()
                
                if entry.data.gratitudeStreak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 13))
                        Text("\(entry.data.gratitudeStreak) day streak")
                            .font(.system(size: 13))
                    }
                    .foregroundStyle(.secondary)
                } else if entry.data.todayGratitudeCompleted {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 13))
                        Text("Completed")
                            .font(.system(size: 13))
                    }
                    .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .containerBackground(for: .widget) { }
    }
    
    private var accessoryInlineView: some View {
        Text("\(entry.data.lastMood) \(entry.data.gratitudeStreak > 0 ? "• \(entry.data.gratitudeStreak) day streak" : "")")
            .containerBackground(for: .widget) { }
    }
}

#Preview(as: .systemSmall) {
    MoodGratitudeWidget()
} timeline: {
    MoodGratitudeEntry(date: Date(), data: .placeholder, configuration: MoodGratitudeIntent())
}

#Preview(as: .systemMedium) {
    MoodGratitudeWidget()
} timeline: {
    MoodGratitudeEntry(date: Date(), data: .placeholder, configuration: MoodGratitudeIntent())
}

#Preview(as: .accessoryCircular) {
    MoodGratitudeWidget()
} timeline: {
    MoodGratitudeEntry(date: Date(), data: .placeholder, configuration: MoodGratitudeIntent())
}

#Preview(as: .accessoryRectangular) {
    MoodGratitudeWidget()
} timeline: {
    MoodGratitudeEntry(date: Date(), data: .placeholder, configuration: MoodGratitudeIntent())
}

#Preview(as: .accessoryInline) {
    MoodGratitudeWidget()
} timeline: {
    MoodGratitudeEntry(date: Date(), data: .placeholder, configuration: MoodGratitudeIntent())
}
