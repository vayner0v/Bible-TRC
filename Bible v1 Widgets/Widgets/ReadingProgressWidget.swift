//
//  ReadingProgressWidget.swift
//  Bible v1 Widgets
//
//  Reading plan progress widget with S/M/L sizes
//

import WidgetKit
import SwiftUI

struct ReadingProgressWidget: Widget {
    let kind: String = "ReadingProgressWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ReadingProgressProvider()) { entry in
            ReadingProgressWidgetView(entry: entry)
        }
        .configurationDisplayName("Reading Progress")
        .description("Track your Bible reading plan")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct ReadingProgressProvider: TimelineProvider {
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

struct ReadingProgressWidgetView: View {
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
                Image(systemName: "book.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Text("Reading")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            // Circular progress
            ZStack {
                Circle()
                    .stroke(theme.cardBackground, lineWidth: 6)
                    .frame(width: 50, height: 50)
                
                Circle()
                    .trim(from: 0, to: entry.data.readingProgress)
                    .stroke(.blue, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 50, height: 50)
                
                Text("\(Int(entry.data.readingProgress * 100))%")
                    .font(.caption.bold())
                    .foregroundColor(theme.textColor)
            }
            .frame(maxWidth: .infinity)
            
            Spacer()
            
            Text("Day \(entry.data.currentDay)/\(entry.data.totalDays)")
                .font(.caption2)
                .foregroundColor(theme.secondaryTextColor)
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
                    .trim(from: 0, to: entry.data.readingProgress)
                    .stroke(.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 70, height: 70)
                
                VStack(spacing: 0) {
                    Text("\(Int(entry.data.readingProgress * 100))")
                        .font(.title2.bold())
                        .foregroundColor(theme.textColor)
                    Text("%")
                        .font(.caption2)
                        .foregroundColor(theme.secondaryTextColor)
                }
            }
            
            // Right side - details
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "book.fill")
                        .foregroundColor(.blue)
                    
                    Text("Reading Progress")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.textColor)
                }
                
                Text(entry.data.readingPlanName)
                    .font(.headline)
                    .foregroundColor(theme.textColor)
                    .lineLimit(1)
                
                HStack(spacing: 12) {
                    Label("Day \(entry.data.currentDay)", systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                    
                    if entry.data.readingStreak > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "flame.fill")
                            Text("\(entry.data.readingStreak)")
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
    
    // MARK: - Large View
    
    private var largeView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "book.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Reading Progress")
                        .font(.headline)
                        .foregroundColor(theme.textColor)
                    
                    Text(entry.data.readingPlanName)
                        .font(.subheadline)
                        .foregroundColor(theme.secondaryTextColor)
                }
                
                Spacer()
                
                if entry.data.readingStreak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                        Text("\(entry.data.readingStreak)")
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
                        .stroke(theme.cardBackground, lineWidth: 12)
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .trim(from: 0, to: entry.data.readingProgress)
                        .stroke(.blue, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 120, height: 120)
                    
                    VStack(spacing: 2) {
                        Text("\(Int(entry.data.readingProgress * 100))%")
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
            
            // Stats row
            HStack(spacing: 0) {
                StatBox(title: "Current Day", value: "\(entry.data.currentDay)", icon: "calendar", theme: theme)
                StatBox(title: "Total Days", value: "\(entry.data.totalDays)", icon: "calendar.badge.checkmark", theme: theme)
                StatBox(title: "Remaining", value: "\(entry.data.totalDays - entry.data.currentDay + 1)", icon: "hourglass", theme: theme)
            }
        }
        .padding(16)
        .widgetContainer(theme: theme)
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    let theme: WidgetTheme
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(theme.secondaryTextColor)
            
            Text(value)
                .font(.title3.bold())
                .foregroundColor(theme.textColor)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(theme.secondaryTextColor)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview(as: .systemSmall) {
    ReadingProgressWidget()
} timeline: {
    BibleWidgetEntry.placeholder
}

#Preview(as: .systemMedium) {
    ReadingProgressWidget()
} timeline: {
    BibleWidgetEntry.placeholder
}

#Preview(as: .systemLarge) {
    ReadingProgressWidget()
} timeline: {
    BibleWidgetEntry.placeholder
}

