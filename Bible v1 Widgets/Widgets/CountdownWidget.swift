//
//  CountdownWidget.swift
//  Bible v1 Widgets
//
//  Countdown widget with S/M/L sizes
//

import WidgetKit
import SwiftUI

struct CountdownWidget: Widget {
    let kind: String = "CountdownWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CountdownProvider()) { entry in
            CountdownWidgetView(entry: entry)
        }
        .configurationDisplayName("Countdown")
        .description("Days until your event or fasting end")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct CountdownProvider: TimelineProvider {
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
        
        // Update at midnight
        let tomorrow = Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))
        let timeline = Timeline(entries: [entry], policy: .after(tomorrow))
        completion(timeline)
    }
}

struct CountdownWidgetView: View {
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
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "calendar.badge.clock")
                    .font(.caption)
                    .foregroundColor(.orange)
                
                Text("Countdown")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
            }
            
            Spacer()
            
            Text("\(entry.data.daysRemaining)")
                .font(.system(size: 42, weight: .bold))
                .foregroundColor(theme.textColor)
            
            Text("days")
                .font(.caption)
                .foregroundColor(theme.secondaryTextColor)
            
            Spacer()
            
            Text(entry.data.countdownTitle)
                .font(.caption2)
                .foregroundColor(theme.secondaryTextColor)
                .lineLimit(1)
        }
        .padding(12)
        .widgetContainer(theme: theme)
    }
    
    // MARK: - Medium View
    
    private var mediumView: some View {
        HStack(spacing: 20) {
            // Left side - countdown number
            VStack(spacing: 4) {
                Text("\(entry.data.daysRemaining)")
                    .font(.system(size: 50, weight: .bold))
                    .foregroundColor(theme.textColor)
                
                Text("days remaining")
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)
            }
            
            Divider()
                .frame(height: 60)
            
            // Right side - event details
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundColor(.orange)
                    
                    Text("Countdown")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.textColor)
                }
                
                Text(entry.data.countdownTitle)
                    .font(.headline)
                    .foregroundColor(theme.textColor)
                    .lineLimit(2)
                
                Text(formattedDate)
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)
            }
            
            Spacer()
        }
        .padding(16)
        .widgetContainer(theme: theme)
    }
    
    // MARK: - Large View
    
    private var largeView: some View {
        ZStack {
            WidgetGradients.sunrise
            
            VStack(spacing: 16) {
                // Header
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("Countdown")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.9))
                    
                    Spacer()
                }
                
                Spacer()
                
                // Main countdown
                VStack(spacing: 8) {
                    Text("\(entry.data.daysRemaining)")
                        .font(.system(size: 80, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("days remaining")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
                
                // Event details
                VStack(spacing: 8) {
                    Text(entry.data.countdownTitle)
                        .font(.title3.bold())
                        .foregroundColor(.white)
                    
                    Text(formattedDate)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(.white.opacity(0.2))
                .cornerRadius(12)
            }
            .padding(20)
        }
        .containerBackground(for: .widget) {
            WidgetGradients.sunrise
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: entry.data.countdownDate)
    }
}

#Preview(as: .systemSmall) {
    CountdownWidget()
} timeline: {
    BibleWidgetEntry.placeholder
}

#Preview(as: .systemMedium) {
    CountdownWidget()
} timeline: {
    BibleWidgetEntry.placeholder
}

#Preview(as: .systemLarge) {
    CountdownWidget()
} timeline: {
    BibleWidgetEntry.placeholder
}

