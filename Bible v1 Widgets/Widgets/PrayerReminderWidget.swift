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
        AppIntentConfiguration(
            kind: kind,
            intent: PrayerReminderIntent.self,
            provider: PrayerReminderIntentProvider()
        ) { entry in
            PrayerReminderWidgetView(entry: entry)
        }
        .configurationDisplayName("Prayer Reminder")
        .description("Quick access to your prayers")
        .supportedFamilies([
            .systemSmall, .systemMedium, .systemLarge,
            .accessoryCircular, .accessoryRectangular, .accessoryInline
        ])
    }
}

struct PrayerReminderWidgetView: View {
    let entry: PrayerReminderEntry
    
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
        .widgetURL(URL(string: "biblev1://prayer"))
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
            
            if entry.configuration.showPrayerCount {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("\(entry.data.activePrayerCount)")
                                .font(.title2.bold())
                                .foregroundColor(styleConfig.textColor)
                            Text("Active")
                                .font(.caption2)
                                .foregroundColor(styleConfig.secondaryTextColor)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("\(entry.data.answeredPrayerCount)")
                                .font(.title2.bold())
                                .foregroundColor(.green)
                            Text("Answered")
                                .font(.caption2)
                                .foregroundColor(styleConfig.secondaryTextColor)
                        }
                    }
                }
            } else {
                Image(systemName: "hands.sparkles.fill")
                    .font(.largeTitle)
                    .foregroundColor(.teal)
                    .frame(maxWidth: .infinity)
            }
            
            Spacer()
            
            Text("Tap to pray")
                .font(.caption2)
                .foregroundColor(styleConfig.secondaryTextColor)
        }
        .padding(12)
        .containerBackground(for: .widget) {
            styleConfig.background
        }
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
                        .foregroundColor(styleConfig.textColor)
                }
                
                Spacer()
                
                Text("Your prayers matter")
                    .font(.caption)
                    .foregroundColor(styleConfig.secondaryTextColor)
            }
            
            Spacer()
            
            // Right side - stats
            if entry.configuration.showPrayerCount {
                HStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text("\(entry.data.activePrayerCount)")
                            .font(.title.bold())
                            .foregroundColor(styleConfig.textColor)
                        Text("Active")
                            .font(.caption)
                            .foregroundColor(styleConfig.secondaryTextColor)
                    }
                    
                    VStack(spacing: 4) {
                        Text("\(entry.data.answeredPrayerCount)")
                            .font(.title.bold())
                            .foregroundColor(.green)
                        Text("Answered")
                            .font(.caption)
                            .foregroundColor(styleConfig.secondaryTextColor)
                    }
                }
            }
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
                        .fill(Color.teal.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "hands.sparkles")
                        .font(.title3)
                        .foregroundColor(.teal)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Prayer Journal")
                        .font(.headline)
                        .foregroundColor(styleConfig.textColor)
                    
                    Text("Keep your prayers close")
                        .font(.caption)
                        .foregroundColor(styleConfig.secondaryTextColor)
                }
                
                Spacer()
            }
            
            Divider()
                .background(styleConfig.secondaryTextColor.opacity(0.3))
            
            // Stats cards
            HStack(spacing: 12) {
                PrayerStatCard(
                    title: "Active Prayers",
                    value: "\(entry.data.activePrayerCount)",
                    icon: "heart.fill",
                    color: .teal,
                    styleConfig: styleConfig
                )
                
                PrayerStatCard(
                    title: "Answered",
                    value: "\(entry.data.answeredPrayerCount)",
                    icon: "checkmark.circle.fill",
                    color: .green,
                    styleConfig: styleConfig
                )
            }
            
            Spacer()
            
            // Encouragement
            VStack(spacing: 8) {
                Image(systemName: "quote.opening")
                    .font(.caption)
                    .foregroundColor(styleConfig.accentColor.opacity(0.5))
                
                Text("\"Do not be anxious about anything, but in every situation, by prayer and petition, with thanksgiving, present your requests to God.\"")
                    .font(.system(size: 12, design: .serif))
                    .foregroundColor(styleConfig.textColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                
                Text("— Philippians 4:6")
                    .font(.caption2)
                    .foregroundColor(styleConfig.secondaryTextColor)
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
        .containerBackground(for: .widget) {
            styleConfig.background
        }
    }
    
    // MARK: - Lock Screen Views
    
    private var accessoryCircularView: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 0) {
                Image(systemName: "hands.sparkles.fill")
                    .font(.title3)
                Text("\(entry.data.activePrayerCount)")
                    .font(.caption2)
                    .fontWeight(.bold)
            }
        }
        .widgetAccentable()
        .containerBackground(for: .widget) { }
    }
    
    private var accessoryRectangularView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "hands.sparkles")
                    .font(.system(size: 14, weight: .bold))
                Text("Prayer Requests")
                    .font(.system(size: 15, weight: .bold))
            }
            .widgetAccentable()
            
            HStack(spacing: 0) {
                HStack(spacing: 4) {
                    Text("\(entry.data.activePrayerCount)")
                        .font(.system(size: 22, weight: .bold))
                    Text("active")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text("\(entry.data.answeredPrayerCount)")
                        .font(.system(size: 22, weight: .bold))
                    Text("answered")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(for: .widget) { }
    }
    
    private var accessoryInlineView: some View {
        Label("\(entry.data.activePrayerCount) Active Prayers", systemImage: "hands.sparkles")
            .containerBackground(for: .widget) { }
    }
}

struct PrayerStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let styleConfig: WidgetStyleConfig
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title.bold())
                .foregroundColor(styleConfig.textColor)
            
            Text(title)
                .font(.caption)
                .foregroundColor(styleConfig.secondaryTextColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(styleConfig.cardBackground)
        .cornerRadius(12)
    }
}

#Preview(as: .systemSmall) {
    PrayerReminderWidget()
} timeline: {
    PrayerReminderEntry(date: Date(), data: .placeholder, configuration: PrayerReminderIntent())
}

#Preview(as: .systemMedium) {
    PrayerReminderWidget()
} timeline: {
    PrayerReminderEntry(date: Date(), data: .placeholder, configuration: PrayerReminderIntent())
}

#Preview(as: .systemLarge) {
    PrayerReminderWidget()
} timeline: {
    PrayerReminderEntry(date: Date(), data: .placeholder, configuration: PrayerReminderIntent())
}

#Preview(as: .accessoryCircular) {
    PrayerReminderWidget()
} timeline: {
    PrayerReminderEntry(date: Date(), data: .placeholder, configuration: PrayerReminderIntent())
}

#Preview(as: .accessoryRectangular) {
    PrayerReminderWidget()
} timeline: {
    PrayerReminderEntry(date: Date(), data: .placeholder, configuration: PrayerReminderIntent())
}

#Preview(as: .accessoryInline) {
    PrayerReminderWidget()
} timeline: {
    PrayerReminderEntry(date: Date(), data: .placeholder, configuration: PrayerReminderIntent())
}
