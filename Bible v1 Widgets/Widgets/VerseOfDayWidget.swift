//
//  VerseOfDayWidget.swift
//  Bible v1 Widgets
//
//  Daily verse widget with S/M/L sizes
//

import WidgetKit
import SwiftUI

struct VerseOfDayWidget: Widget {
    let kind: String = "VerseOfDayWidget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: VerseOfDayIntent.self,
            provider: VerseOfDayIntentProvider()
        ) { entry in
            VerseOfDayWidgetView(entry: entry)
        }
        .configurationDisplayName("Verse of the Day")
        .description("Daily scripture to inspire your day")
        .supportedFamilies([
            .systemSmall, .systemMedium, .systemLarge,
            .accessoryCircular, .accessoryRectangular, .accessoryInline
        ])
    }
}

struct VerseOfDayWidgetView: View {
    let entry: VerseOfDayEntry
    
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme
    
    private var styleConfig: WidgetStyleConfig {
        // If user has selected a saved widget design, try to load its style
        if let savedWidget = entry.savedWidget,
           let customConfig = WidgetProjectLoader.shared.loadStyleConfig(for: savedWidget.id) {
            return customConfig
        }
        // Fall back to preset
        return WidgetStyleConfig(preset: entry.stylePreset, colorScheme: colorScheme)
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
        .widgetURL(URL(string: "biblev1://verse-of-day"))
    }
    
    // MARK: - Small View
    
    private var smallView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundColor(styleConfig.accentColor)
                
                Text("Verse of the Day")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(styleConfig.accentColor)
            }
            
            Spacer()
            
            Text(entry.data.verseOfDayText)
                .font(.system(size: 12, design: .serif))
                .foregroundColor(styleConfig.textColor)
                .lineLimit(4)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            Text(entry.data.verseOfDayReference)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(styleConfig.secondaryTextColor)
        }
        .padding(12)
        .containerBackground(for: .widget) {
            styleConfig.background
        }
    }
    
    // MARK: - Medium View
    
    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .foregroundColor(styleConfig.accentColor)
                
                Text("Verse of the Day")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(styleConfig.accentColor)
                
                Spacer()
            }
            
            Spacer()
            
            Text(entry.data.verseOfDayText)
                .font(.system(size: 14, design: .serif))
                .foregroundColor(styleConfig.textColor)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
            
            Text("— \(entry.data.verseOfDayReference)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(styleConfig.secondaryTextColor)
        }
        .padding(16)
        .containerBackground(for: .widget) {
            styleConfig.background
        }
    }
    
    // MARK: - Large View
    
    private var largeView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(styleConfig.accentColor.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "sparkles")
                        .font(.title3)
                        .foregroundColor(styleConfig.accentColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Verse of the Day")
                        .font(.headline)
                        .foregroundColor(styleConfig.textColor)
                    
                    Text(formattedDate)
                        .font(.caption)
                        .foregroundColor(styleConfig.secondaryTextColor)
                }
                
                Spacer()
            }
            
            Divider()
                .background(styleConfig.secondaryTextColor.opacity(0.3))
            
            Spacer()
            
            Image(systemName: "quote.opening")
                .font(.title2)
                .foregroundColor(styleConfig.accentColor.opacity(0.5))
            
            Text(entry.data.verseOfDayText)
                .font(.system(size: 16, design: .serif))
                .foregroundColor(styleConfig.textColor)
                .lineLimit(8)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            HStack {
                Spacer()
                
                Text("— \(entry.data.verseOfDayReference)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(styleConfig.accentColor)
            }
        }
        .padding(16)
        .containerBackground(for: .widget) {
            styleConfig.background
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }
    
    // MARK: - Lock Screen Views
    
    private var accessoryCircularView: some View {
        ZStack {
            AccessoryWidgetBackground()
            Image(systemName: "book.fill")
                .font(.title2)
        }
        .widgetAccentable()
        .containerBackground(for: .widget) { }
    }
    
    private var accessoryRectangularView: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "sparkles")
                    .font(.system(size: 10, weight: .semibold))
                Text(entry.data.verseOfDayReference)
                    .font(.system(size: 11, weight: .semibold))
            }
            .widgetAccentable()
            
            Text(entry.data.verseOfDayText)
                .font(.system(size: 12))
                .lineLimit(4)
                .minimumScaleFactor(0.9)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(for: .widget) { }
    }
    
    private var accessoryInlineView: some View {
        Label(entry.data.verseOfDayReference, systemImage: "book.fill")
            .containerBackground(for: .widget) { }
    }
}

#Preview(as: .systemSmall) {
    VerseOfDayWidget()
} timeline: {
    VerseOfDayEntry(date: Date(), data: .placeholder, stylePreset: .system, savedWidget: nil)
}

#Preview(as: .systemMedium) {
    VerseOfDayWidget()
} timeline: {
    VerseOfDayEntry(date: Date(), data: .placeholder, stylePreset: .system, savedWidget: nil)
}

#Preview(as: .systemLarge) {
    VerseOfDayWidget()
} timeline: {
    VerseOfDayEntry(date: Date(), data: .placeholder, stylePreset: .system, savedWidget: nil)
}

#Preview(as: .accessoryCircular) {
    VerseOfDayWidget()
} timeline: {
    VerseOfDayEntry(date: Date(), data: .placeholder, stylePreset: .system, savedWidget: nil)
}

#Preview(as: .accessoryRectangular) {
    VerseOfDayWidget()
} timeline: {
    VerseOfDayEntry(date: Date(), data: .placeholder, stylePreset: .system, savedWidget: nil)
}

#Preview(as: .accessoryInline) {
    VerseOfDayWidget()
} timeline: {
    VerseOfDayEntry(date: Date(), data: .placeholder, stylePreset: .system, savedWidget: nil)
}
