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
        StaticConfiguration(kind: kind, provider: ScriptureQuoteProvider()) { entry in
            ScriptureQuoteWidgetView(entry: entry)
        }
        .configurationDisplayName("Scripture Quote")
        .description("Display your favorite verse")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct ScriptureQuoteProvider: TimelineProvider {
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
        
        // Static content, refresh daily
        let tomorrow = Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))
        let timeline = Timeline(entries: [entry], policy: .after(tomorrow))
        completion(timeline)
    }
}

struct ScriptureQuoteWidgetView: View {
    let entry: BibleWidgetEntry
    
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme
    
    private var theme: WidgetTheme {
        colorScheme == .dark ? .dark : .light
    }
    
    private let sampleVerse = "\"The Lord is my shepherd; I shall not want. He maketh me to lie down in green pastures: he leadeth me beside the still waters.\""
    private let sampleReference = "Psalm 23:1-2"
    
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
        ZStack {
            WidgetGradients.lavender
            
            VStack(spacing: 6) {
                Image(systemName: "quote.opening")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                
                Spacer()
                
                Text(sampleVerse)
                    .font(.system(size: 11, design: .serif))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                
                Spacer()
                
                Text(sampleReference)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(12)
        }
        .containerBackground(for: .widget) {
            WidgetGradients.lavender
        }
    }
    
    // MARK: - Medium View
    
    private var mediumView: some View {
        ZStack {
            WidgetGradients.lavender
            
            VStack(alignment: .center, spacing: 8) {
                Image(systemName: "quote.opening")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.6))
                
                Spacer()
                
                Text(sampleVerse)
                    .font(.system(size: 14, design: .serif))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                
                Spacer()
                
                Text("— \(sampleReference)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(16)
        }
        .containerBackground(for: .widget) {
            WidgetGradients.lavender
        }
    }
    
    // MARK: - Large View
    
    private var largeView: some View {
        ZStack {
            WidgetGradients.lavender
            
            VStack(spacing: 16) {
                Image(systemName: "quote.opening")
                    .font(.title)
                    .foregroundColor(.white.opacity(0.5))
                
                Spacer()
                
                Text(sampleVerse)
                    .font(.system(size: 18, weight: .regular, design: .serif))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(8)
                    .padding(.horizontal, 8)
                
                Spacer()
                
                Image(systemName: "quote.closing")
                    .font(.title)
                    .foregroundColor(.white.opacity(0.5))
                
                Text("— \(sampleReference)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.top, 8)
            }
            .padding(20)
        }
        .containerBackground(for: .widget) {
            WidgetGradients.lavender
        }
    }
}

#Preview(as: .systemSmall) {
    ScriptureQuoteWidget()
} timeline: {
    BibleWidgetEntry.placeholder
}

#Preview(as: .systemMedium) {
    ScriptureQuoteWidget()
} timeline: {
    BibleWidgetEntry.placeholder
}

#Preview(as: .systemLarge) {
    ScriptureQuoteWidget()
} timeline: {
    BibleWidgetEntry.placeholder
}

