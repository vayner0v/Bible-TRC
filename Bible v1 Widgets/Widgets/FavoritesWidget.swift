//
//  FavoritesWidget.swift
//  Bible v1 Widgets
//
//  Favorites quick access widget with M/L sizes
//

import WidgetKit
import SwiftUI

struct FavoritesWidget: Widget {
    let kind: String = "FavoritesWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FavoritesProvider()) { entry in
            FavoritesWidgetView(entry: entry)
        }
        .configurationDisplayName("Favorites")
        .description("Quick access to saved verses")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct FavoritesProvider: TimelineProvider {
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

struct FavoritesWidgetView: View {
    let entry: BibleWidgetEntry
    
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme
    
    private var theme: WidgetTheme {
        colorScheme == .dark ? .dark : .light
    }
    
    // Sample favorites for display
    private let sampleFavorites = [
        (reference: "John 3:16", text: "For God so loved the world..."),
        (reference: "Psalm 23:1", text: "The Lord is my shepherd..."),
        (reference: "Romans 8:28", text: "And we know that in all things..."),
        (reference: "Philippians 4:13", text: "I can do all things through Christ...")
    ]
    
    var body: some View {
        switch family {
        case .systemMedium:
            mediumView
        case .systemLarge:
            largeView
        default:
            mediumView
        }
    }
    
    // MARK: - Medium View
    
    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                
                Text("Favorites")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.textColor)
                
                Spacer()
                
                Text("\(sampleFavorites.count) verses")
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)
            }
            
            // Favorite items (show 2)
            VStack(spacing: 6) {
                ForEach(sampleFavorites.prefix(2), id: \.reference) { favorite in
                    FavoriteRow(
                        reference: favorite.reference,
                        text: favorite.text,
                        theme: theme,
                        compact: true
                    )
                }
            }
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
                        .fill(Color.yellow.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "star.fill")
                        .font(.title3)
                        .foregroundColor(.yellow)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Favorites")
                        .font(.headline)
                        .foregroundColor(theme.textColor)
                    
                    Text("\(sampleFavorites.count) saved verses")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                }
                
                Spacer()
            }
            
            Divider()
                .background(theme.secondaryTextColor.opacity(0.3))
            
            // Favorite items (show up to 4)
            VStack(spacing: 8) {
                ForEach(sampleFavorites.prefix(4), id: \.reference) { favorite in
                    FavoriteRow(
                        reference: favorite.reference,
                        text: favorite.text,
                        theme: theme,
                        compact: false
                    )
                }
            }
            
            Spacer()
            
            // Footer
            HStack {
                Spacer()
                
                Text("Tap to view all favorites")
                    .font(.caption)
                    .foregroundColor(theme.accentColor)
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(theme.accentColor)
                
                Spacer()
            }
            .padding(.vertical, 8)
            .background(theme.accentColor.opacity(0.1))
            .cornerRadius(8)
        }
        .padding(16)
        .widgetContainer(theme: theme)
    }
}

struct FavoriteRow: View {
    let reference: String
    let text: String
    let theme: WidgetTheme
    let compact: Bool
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "bookmark.fill")
                .font(.caption)
                .foregroundColor(.yellow)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(reference)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.textColor)
                
                if !compact {
                    Text(text)
                        .font(.caption2)
                        .foregroundColor(theme.secondaryTextColor)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundColor(theme.secondaryTextColor.opacity(0.5))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, compact ? 8 : 10)
        .background(theme.cardBackground)
        .cornerRadius(8)
    }
}

#Preview(as: .systemMedium) {
    FavoritesWidget()
} timeline: {
    BibleWidgetEntry.placeholder
}

#Preview(as: .systemLarge) {
    FavoritesWidget()
} timeline: {
    BibleWidgetEntry.placeholder
}

