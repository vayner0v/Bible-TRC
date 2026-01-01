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
        StaticConfiguration(kind: kind, provider: VerseOfDayProvider()) { entry in
            VerseOfDayWidgetView(entry: entry)
        }
        .configurationDisplayName("Verse of the Day")
        .description("Daily scripture to inspire your day")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct VerseOfDayProvider: TimelineProvider {
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
        
        // Update at midnight for new verse
        let calendar = Calendar.current
        let tomorrow = calendar.startOfDay(for: Date().addingTimeInterval(86400))
        
        let timeline = Timeline(entries: [entry], policy: .after(tomorrow))
        completion(timeline)
    }
}

struct VerseOfDayWidgetView: View {
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
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundColor(theme.accentColor)
                
                Text("Verse of the Day")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.accentColor)
            }
            
            Spacer()
            
            Text(entry.data.verseOfDayText)
                .font(.system(size: 12, design: .serif))
                .foregroundColor(theme.textColor)
                .lineLimit(4)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            Text(entry.data.verseOfDayReference)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(theme.secondaryTextColor)
        }
        .padding(12)
        .widgetContainer(theme: theme)
    }
    
    // MARK: - Medium View
    
    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .foregroundColor(theme.accentColor)
                
                Text("Verse of the Day")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.accentColor)
                
                Spacer()
            }
            
            Spacer()
            
            Text(entry.data.verseOfDayText)
                .font(.system(size: 14, design: .serif))
                .foregroundColor(theme.textColor)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
            
            Text("— \(entry.data.verseOfDayReference)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(theme.secondaryTextColor)
        }
        .padding(16)
        .widgetContainer(theme: theme)
    }
    
    // MARK: - Large View
    
    private var largeView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(theme.accentColor.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "sparkles")
                        .font(.title3)
                        .foregroundColor(theme.accentColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Verse of the Day")
                        .font(.headline)
                        .foregroundColor(theme.textColor)
                    
                    Text(formattedDate)
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                }
                
                Spacer()
            }
            
            Divider()
                .background(theme.secondaryTextColor.opacity(0.3))
            
            Spacer()
            
            Image(systemName: "quote.opening")
                .font(.title2)
                .foregroundColor(theme.accentColor.opacity(0.5))
            
            Text(entry.data.verseOfDayText)
                .font(.system(size: 16, design: .serif))
                .foregroundColor(theme.textColor)
                .lineLimit(8)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            HStack {
                Spacer()
                
                Text("— \(entry.data.verseOfDayReference)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(theme.accentColor)
            }
        }
        .padding(16)
        .widgetContainer(theme: theme)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }
}

#Preview(as: .systemSmall) {
    VerseOfDayWidget()
} timeline: {
    BibleWidgetEntry.placeholder
}

#Preview(as: .systemMedium) {
    VerseOfDayWidget()
} timeline: {
    BibleWidgetEntry.placeholder
}

#Preview(as: .systemLarge) {
    VerseOfDayWidget()
} timeline: {
    BibleWidgetEntry.placeholder
}

