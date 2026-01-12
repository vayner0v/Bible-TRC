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
        AppIntentConfiguration(
            kind: kind,
            intent: ReadingProgressIntent.self,
            provider: ReadingProgressIntentProvider()
        ) { entry in
            ReadingProgressWidgetView(entry: entry)
        }
        .configurationDisplayName("Reading Progress")
        .description("Track your Bible reading plan")
        .supportedFamilies([
            .systemSmall, .systemMedium, .systemLarge,
            .accessoryCircular, .accessoryRectangular, .accessoryInline
        ])
    }
}

struct ReadingProgressWidgetView: View {
    let entry: ReadingProgressEntry
    
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
        .widgetURL(URL(string: "biblev1://reading-plan"))
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
                    .stroke(styleConfig.cardBackground, lineWidth: 6)
                    .frame(width: 50, height: 50)
                
                Circle()
                    .trim(from: 0, to: entry.data.readingProgress)
                    .stroke(.blue, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 50, height: 50)
                
                if entry.configuration.showPercentage {
                    Text("\(Int(entry.data.readingProgress * 100))%")
                        .font(.caption.bold())
                        .foregroundColor(styleConfig.textColor)
                }
            }
            .frame(maxWidth: .infinity)
            
            Spacer()
            
            Text("Day \(entry.data.currentDay)/\(entry.data.totalDays)")
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
            // Left side - progress ring
            ZStack {
                Circle()
                    .stroke(styleConfig.cardBackground, lineWidth: 8)
                    .frame(width: 70, height: 70)
                
                Circle()
                    .trim(from: 0, to: entry.data.readingProgress)
                    .stroke(.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 70, height: 70)
                
                VStack(spacing: 0) {
                    Text("\(Int(entry.data.readingProgress * 100))")
                        .font(.title2.bold())
                        .foregroundColor(styleConfig.textColor)
                    Text("%")
                        .font(.caption2)
                        .foregroundColor(styleConfig.secondaryTextColor)
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
                        .foregroundColor(styleConfig.textColor)
                }
                
                Text(entry.data.readingPlanName)
                    .font(.headline)
                    .foregroundColor(styleConfig.textColor)
                    .lineLimit(1)
                
                HStack(spacing: 12) {
                    Label("Day \(entry.data.currentDay)", systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(styleConfig.secondaryTextColor)
                    
                    if entry.configuration.showStreak && entry.data.readingStreak > 0 {
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
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "book.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Reading Progress")
                        .font(.headline)
                        .foregroundColor(styleConfig.textColor)
                    
                    Text(entry.data.readingPlanName)
                        .font(.subheadline)
                        .foregroundColor(styleConfig.secondaryTextColor)
                }
                
                Spacer()
                
                if entry.configuration.showStreak && entry.data.readingStreak > 0 {
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
                .background(styleConfig.secondaryTextColor.opacity(0.3))
            
            // Large progress ring
            HStack {
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(styleConfig.cardBackground, lineWidth: 12)
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .trim(from: 0, to: entry.data.readingProgress)
                        .stroke(.blue, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 120, height: 120)
                    
                    VStack(spacing: 2) {
                        Text("\(Int(entry.data.readingProgress * 100))%")
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
            
            Spacer()
            
            // Stats row
            HStack(spacing: 0) {
                StatBox(title: "Current Day", value: "\(entry.data.currentDay)", icon: "calendar", styleConfig: styleConfig)
                StatBox(title: "Total Days", value: "\(entry.data.totalDays)", icon: "calendar.badge.checkmark", styleConfig: styleConfig)
                StatBox(title: "Remaining", value: "\(entry.data.totalDays - entry.data.currentDay + 1)", icon: "hourglass", styleConfig: styleConfig)
            }
        }
        .padding(16)
        .containerBackground(for: .widget) {
            styleConfig.background
        }
    }
    
    // MARK: - Lock Screen Views
    
    private var accessoryCircularView: some View {
        Gauge(value: entry.data.readingProgress) {
            Image(systemName: "book.fill")
        } currentValueLabel: {
            Text("\(Int(entry.data.readingProgress * 100))")
                .font(.caption2)
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .widgetAccentable()
        .containerBackground(for: .widget) { }
    }
    
    private var accessoryRectangularView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "book.fill")
                    .font(.system(size: 14, weight: .bold))
                Text("Day \(entry.data.currentDay)/\(entry.data.totalDays)")
                    .font(.system(size: 15, weight: .bold))
                Spacer()
                Text("\(Int(entry.data.readingProgress * 100))%")
                    .font(.system(size: 15, weight: .bold))
            }
            .widgetAccentable()
            
            Gauge(value: entry.data.readingProgress) {
                EmptyView()
            }
            .gaugeStyle(.accessoryLinearCapacity)
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(for: .widget) { }
    }
    
    private var accessoryInlineView: some View {
        Label("Day \(entry.data.currentDay) • \(Int(entry.data.readingProgress * 100))%", systemImage: "book.fill")
            .containerBackground(for: .widget) { }
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    let styleConfig: WidgetStyleConfig
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(styleConfig.secondaryTextColor)
            
            Text(value)
                .font(.title3.bold())
                .foregroundColor(styleConfig.textColor)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(styleConfig.secondaryTextColor)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview(as: .systemSmall) {
    ReadingProgressWidget()
} timeline: {
    ReadingProgressEntry(date: Date(), data: .placeholder, configuration: ReadingProgressIntent())
}

#Preview(as: .systemMedium) {
    ReadingProgressWidget()
} timeline: {
    ReadingProgressEntry(date: Date(), data: .placeholder, configuration: ReadingProgressIntent())
}

#Preview(as: .systemLarge) {
    ReadingProgressWidget()
} timeline: {
    ReadingProgressEntry(date: Date(), data: .placeholder, configuration: ReadingProgressIntent())
}

#Preview(as: .accessoryCircular) {
    ReadingProgressWidget()
} timeline: {
    ReadingProgressEntry(date: Date(), data: .placeholder, configuration: ReadingProgressIntent())
}

#Preview(as: .accessoryRectangular) {
    ReadingProgressWidget()
} timeline: {
    ReadingProgressEntry(date: Date(), data: .placeholder, configuration: ReadingProgressIntent())
}

#Preview(as: .accessoryInline) {
    ReadingProgressWidget()
} timeline: {
    ReadingProgressEntry(date: Date(), data: .placeholder, configuration: ReadingProgressIntent())
}
