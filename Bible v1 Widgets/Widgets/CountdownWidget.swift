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
        AppIntentConfiguration(
            kind: kind,
            intent: CountdownIntent.self,
            provider: CountdownIntentProvider()
        ) { entry in
            CountdownWidgetView(entry: entry)
        }
        .configurationDisplayName("Countdown")
        .description("Days until your event or fasting end")
        .supportedFamilies([
            .systemSmall, .systemMedium, .systemLarge,
            .accessoryCircular, .accessoryRectangular, .accessoryInline
        ])
    }
}

struct CountdownWidgetView: View {
    let entry: CountdownEntry
    
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
        .widgetURL(URL(string: "biblev1://countdown"))
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
                .foregroundColor(styleConfig.textColor)
            
            Text("days")
                .font(.caption)
                .foregroundColor(styleConfig.secondaryTextColor)
            
            Spacer()
            
            Text(entry.data.countdownTitle)
                .font(.caption2)
                .foregroundColor(styleConfig.secondaryTextColor)
                .lineLimit(1)
        }
        .padding(12)
        .containerBackground(for: .widget) {
            styleConfig.background
        }
    }
    
    // MARK: - Medium View
    
    private var mediumView: some View {
        HStack(spacing: 20) {
            // Left side - countdown number
            VStack(spacing: 4) {
                Text("\(entry.data.daysRemaining)")
                    .font(.system(size: 50, weight: .bold))
                    .foregroundColor(styleConfig.textColor)
                
                Text("days remaining")
                    .font(.caption)
                    .foregroundColor(styleConfig.secondaryTextColor)
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
                        .foregroundColor(styleConfig.textColor)
                }
                
                Text(entry.data.countdownTitle)
                    .font(.headline)
                    .foregroundColor(styleConfig.textColor)
                    .lineLimit(2)
                
                Text(formattedDate)
                    .font(.caption)
                    .foregroundColor(styleConfig.secondaryTextColor)
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
        ZStack {
            VStack(spacing: 16) {
                // Header
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .font(.title3)
                        .foregroundColor(styleConfig.textColor.opacity(0.8))
                    
                    Text("Countdown")
                        .font(.headline)
                        .foregroundColor(styleConfig.textColor.opacity(0.9))
                    
                    Spacer()
                }
                
                Spacer()
                
                // Main countdown
                VStack(spacing: 8) {
                    Text("\(entry.data.daysRemaining)")
                        .font(.system(size: 80, weight: .bold))
                        .foregroundColor(styleConfig.textColor)
                    
                    Text("days remaining")
                        .font(.title3)
                        .foregroundColor(styleConfig.textColor.opacity(0.9))
                }
                
                Spacer()
                
                // Event details
                VStack(spacing: 8) {
                    Text(entry.data.countdownTitle)
                        .font(.title3.bold())
                        .foregroundColor(styleConfig.textColor)
                    
                    Text(formattedDate)
                        .font(.subheadline)
                        .foregroundColor(styleConfig.textColor.opacity(0.8))
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(styleConfig.cardBackground)
                .cornerRadius(12)
            }
            .padding(20)
        }
        .containerBackground(for: .widget) {
            styleConfig.background
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: entry.data.countdownDate)
    }
    
    // MARK: - Lock Screen Views
    
    private var accessoryCircularView: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 0) {
                Text("\(entry.data.daysRemaining)")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("days")
                    .font(.caption2)
            }
        }
        .widgetAccentable()
        .containerBackground(for: .widget) { }
    }
    
    private var accessoryRectangularView: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 14, weight: .bold))
                    Text(entry.data.countdownTitle)
                        .font(.system(size: 15, weight: .bold))
                        .lineLimit(1)
                }
                .widgetAccentable()
                
                Text("remaining")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(entry.data.daysRemaining)")
                    .font(.system(size: 34, weight: .bold))
                Text("days")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(for: .widget) { }
    }
    
    private var accessoryInlineView: some View {
        Label("\(entry.data.daysRemaining) days • \(entry.data.countdownTitle)", systemImage: "calendar.badge.clock")
            .containerBackground(for: .widget) { }
    }
}

#Preview(as: .systemSmall) {
    CountdownWidget()
} timeline: {
    CountdownEntry(date: Date(), data: .placeholder, configuration: CountdownIntent())
}

#Preview(as: .systemMedium) {
    CountdownWidget()
} timeline: {
    CountdownEntry(date: Date(), data: .placeholder, configuration: CountdownIntent())
}

#Preview(as: .systemLarge) {
    CountdownWidget()
} timeline: {
    CountdownEntry(date: Date(), data: .placeholder, configuration: CountdownIntent())
}

#Preview(as: .accessoryCircular) {
    CountdownWidget()
} timeline: {
    CountdownEntry(date: Date(), data: .placeholder, configuration: CountdownIntent())
}

#Preview(as: .accessoryRectangular) {
    CountdownWidget()
} timeline: {
    CountdownEntry(date: Date(), data: .placeholder, configuration: CountdownIntent())
}

#Preview(as: .accessoryInline) {
    CountdownWidget()
} timeline: {
    CountdownEntry(date: Date(), data: .placeholder, configuration: CountdownIntent())
}
