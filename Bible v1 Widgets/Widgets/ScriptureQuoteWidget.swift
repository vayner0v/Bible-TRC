//
//  ScriptureQuoteWidget.swift
//  Bible v1 Widgets
//
//  Custom scripture quote widget with S/M/L sizes
//

import WidgetKit
import SwiftUI

struct ScriptureQuoteWidget: Widget {
    let kind: String = "ScriptureQuoteWidget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ScriptureQuoteIntent.self,
            provider: ScriptureQuoteIntentProvider()
        ) { entry in
            ScriptureQuoteWidgetView(entry: entry)
        }
        .configurationDisplayName("Scripture Quote")
        .description("Display your favorite verse")
        .supportedFamilies([
            .systemSmall, .systemMedium, .systemLarge,
            .accessoryCircular, .accessoryRectangular, .accessoryInline
        ])
    }
}

struct ScriptureQuoteWidgetView: View {
    let entry: ScriptureQuoteEntry
    
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme
    
    private var styleConfig: WidgetStyleConfig {
        WidgetStyleConfig(preset: entry.configuration.resolvedStylePreset, colorScheme: colorScheme)
    }
    
    // Use verse of the day if configured, otherwise use first favorite or default
    private var verseText: String {
        if entry.configuration.useVerseOfDay {
            return entry.data.verseOfDayText
        } else if let firstFavorite = entry.data.favoriteVerses.first {
            return firstFavorite.text
        }
        return entry.data.verseOfDayText
    }
    
    private var verseReference: String {
        if entry.configuration.useVerseOfDay {
            return entry.data.verseOfDayReference
        } else if let firstFavorite = entry.data.favoriteVerses.first {
            return firstFavorite.reference
        }
        return entry.data.verseOfDayReference
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
        .widgetURL(URL(string: "biblev1://scripture-quote"))
    }
    
    // MARK: - Small View
    
    private var smallView: some View {
        ZStack {
            VStack(spacing: 6) {
                Image(systemName: "quote.opening")
                    .font(.caption)
                    .foregroundColor(styleConfig.textColor.opacity(0.6))
                
                Spacer()
                
                Text(verseText)
                    .font(.system(size: 11, design: .serif))
                    .foregroundColor(styleConfig.textColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                
                Spacer()
                
                Text(verseReference)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(styleConfig.textColor.opacity(0.8))
            }
            .padding(12)
        }
        .containerBackground(for: .widget) {
            styleConfig.background
        }
    }
    
    // MARK: - Medium View
    
    private var mediumView: some View {
        ZStack {
            VStack(alignment: .center, spacing: 8) {
                Image(systemName: "quote.opening")
                    .font(.title3)
                    .foregroundColor(styleConfig.textColor.opacity(0.6))
                
                Spacer()
                
                Text(verseText)
                    .font(.system(size: 14, design: .serif))
                    .foregroundColor(styleConfig.textColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                
                Spacer()
                
                Text("— \(verseReference)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(styleConfig.textColor.opacity(0.9))
            }
            .padding(16)
        }
        .containerBackground(for: .widget) {
            styleConfig.background
        }
    }
    
    // MARK: - Large View
    
    private var largeView: some View {
        ZStack {
            VStack(spacing: 16) {
                Image(systemName: "quote.opening")
                    .font(.title)
                    .foregroundColor(styleConfig.textColor.opacity(0.5))
                
                Spacer()
                
                Text(verseText)
                    .font(.system(size: 18, weight: .regular, design: .serif))
                    .foregroundColor(styleConfig.textColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(8)
                    .padding(.horizontal, 8)
                
                Spacer()
                
                Image(systemName: "quote.closing")
                    .font(.title)
                    .foregroundColor(styleConfig.textColor.opacity(0.5))
                
                Text("— \(verseReference)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(styleConfig.textColor)
                    .padding(.top, 8)
            }
            .padding(20)
        }
        .containerBackground(for: .widget) {
            styleConfig.background
        }
    }
    
    // MARK: - Lock Screen Views
    
    private var accessoryCircularView: some View {
        ZStack {
            AccessoryWidgetBackground()
            Image(systemName: "text.quote")
                .font(.title2)
        }
        .widgetAccentable()
        .containerBackground(for: .widget) { }
    }
    
    private var accessoryRectangularView: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "text.quote")
                    .font(.system(size: 10, weight: .semibold))
                Text(verseReference)
                    .font(.system(size: 11, weight: .semibold))
            }
            .widgetAccentable()
            
            Text(verseText)
                .font(.system(size: 12))
                .lineLimit(4)
                .minimumScaleFactor(0.9)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(for: .widget) { }
    }
    
    private var accessoryInlineView: some View {
        Label(verseReference, systemImage: "text.quote")
            .containerBackground(for: .widget) { }
    }
}

#Preview(as: .systemSmall) {
    ScriptureQuoteWidget()
} timeline: {
    ScriptureQuoteEntry(date: Date(), data: .placeholder, configuration: ScriptureQuoteIntent())
}

#Preview(as: .systemMedium) {
    ScriptureQuoteWidget()
} timeline: {
    ScriptureQuoteEntry(date: Date(), data: .placeholder, configuration: ScriptureQuoteIntent())
}

#Preview(as: .systemLarge) {
    ScriptureQuoteWidget()
} timeline: {
    ScriptureQuoteEntry(date: Date(), data: .placeholder, configuration: ScriptureQuoteIntent())
}

#Preview(as: .accessoryCircular) {
    ScriptureQuoteWidget()
} timeline: {
    ScriptureQuoteEntry(date: Date(), data: .placeholder, configuration: ScriptureQuoteIntent())
}

#Preview(as: .accessoryRectangular) {
    ScriptureQuoteWidget()
} timeline: {
    ScriptureQuoteEntry(date: Date(), data: .placeholder, configuration: ScriptureQuoteIntent())
}

#Preview(as: .accessoryInline) {
    ScriptureQuoteWidget()
} timeline: {
    ScriptureQuoteEntry(date: Date(), data: .placeholder, configuration: ScriptureQuoteIntent())
}
