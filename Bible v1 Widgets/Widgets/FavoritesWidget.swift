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
        AppIntentConfiguration(
            kind: kind,
            intent: FavoritesIntent.self,
            provider: FavoritesIntentProvider()
        ) { entry in
            FavoritesWidgetView(entry: entry)
        }
        .configurationDisplayName("Favorites")
        .description("Quick access to saved verses")
        .supportedFamilies([
            .systemMedium, .systemLarge,
            .accessoryCircular, .accessoryRectangular, .accessoryInline
        ])
    }
}

struct FavoritesWidgetView: View {
    let entry: FavoritesEntry
    
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme
    
    private var styleConfig: WidgetStyleConfig {
        WidgetStyleConfig(preset: entry.configuration.resolvedStylePreset, colorScheme: colorScheme)
    }
    
    // Use actual favorites from data
    private var displayFavorites: [FavoriteVerseStorage] {
        let maxToShow = entry.configuration.maxVersesToShow
        return Array(entry.data.favoriteVerses.prefix(maxToShow))
    }
    
    var body: some View {
        Group {
            switch family {
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
        .widgetURL(URL(string: "biblev1://favorites"))
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
                    .foregroundColor(styleConfig.textColor)
                
                Spacer()
                
                Text("\(entry.data.favoriteVerses.count) verses")
                    .font(.caption)
                    .foregroundColor(styleConfig.secondaryTextColor)
            }
            
            // Favorite items
            if displayFavorites.isEmpty {
                VStack(spacing: 4) {
                    Image(systemName: "star")
                        .font(.title2)
                        .foregroundColor(styleConfig.secondaryTextColor)
                    Text("No favorites yet")
                        .font(.caption)
                        .foregroundColor(styleConfig.secondaryTextColor)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 6) {
                    ForEach(displayFavorites.prefix(2), id: \.reference) { favorite in
                        FavoriteRow(
                            reference: favorite.reference,
                            text: favorite.text,
                            styleConfig: styleConfig,
                            compact: true
                        )
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
                        .fill(Color.yellow.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "star.fill")
                        .font(.title3)
                        .foregroundColor(.yellow)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Favorites")
                        .font(.headline)
                        .foregroundColor(styleConfig.textColor)
                    
                    Text("\(entry.data.favoriteVerses.count) saved verses")
                        .font(.caption)
                        .foregroundColor(styleConfig.secondaryTextColor)
                }
                
                Spacer()
            }
            
            Divider()
                .background(styleConfig.secondaryTextColor.opacity(0.3))
            
            // Favorite items
            if displayFavorites.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "star")
                        .font(.largeTitle)
                        .foregroundColor(styleConfig.secondaryTextColor)
                    Text("No favorites yet")
                        .font(.subheadline)
                        .foregroundColor(styleConfig.secondaryTextColor)
                    Text("Tap to add your first favorite verse")
                        .font(.caption)
                        .foregroundColor(styleConfig.secondaryTextColor)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 8) {
                    ForEach(displayFavorites.prefix(4), id: \.reference) { favorite in
                        FavoriteRow(
                            reference: favorite.reference,
                            text: favorite.text,
                            styleConfig: styleConfig,
                            compact: false
                        )
                    }
                }
            }
            
            Spacer()
            
            // Footer
            HStack {
                Spacer()
                
                Text("Tap to view all favorites")
                    .font(.caption)
                    .foregroundColor(styleConfig.accentColor)
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(styleConfig.accentColor)
                
                Spacer()
            }
            .padding(.vertical, 8)
            .background(styleConfig.accentColor.opacity(0.1))
            .cornerRadius(8)
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
                Image(systemName: "star.fill")
                    .font(.title3)
                Text("\(entry.data.favoriteVerses.count)")
                    .font(.caption2)
                    .fontWeight(.bold)
            }
        }
        .widgetAccentable()
        .containerBackground(for: .widget) { }
    }
    
    private var accessoryRectangularView: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.system(size: 10, weight: .semibold))
                if let firstFavorite = entry.data.favoriteVerses.first {
                    Text(firstFavorite.reference)
                        .font(.system(size: 11, weight: .semibold))
                } else {
                    Text("Favorites")
                        .font(.system(size: 11, weight: .semibold))
                }
            }
            .widgetAccentable()
            
            if let firstFavorite = entry.data.favoriteVerses.first {
                Text(firstFavorite.text)
                    .font(.system(size: 12))
                    .lineLimit(4)
                    .minimumScaleFactor(0.9)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else {
                Text("No favorites yet")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(for: .widget) { }
    }
    
    private var accessoryInlineView: some View {
        Label(
            entry.data.favoriteVerses.first?.reference ?? "\(entry.data.favoriteVerses.count) Favorites",
            systemImage: "star.fill"
        )
        .containerBackground(for: .widget) { }
    }
}

struct FavoriteRow: View {
    let reference: String
    let text: String
    let styleConfig: WidgetStyleConfig
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
                    .foregroundColor(styleConfig.textColor)
                
                if !compact {
                    Text(text)
                        .font(.caption2)
                        .foregroundColor(styleConfig.secondaryTextColor)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundColor(styleConfig.secondaryTextColor.opacity(0.5))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, compact ? 8 : 10)
        .background(styleConfig.cardBackground)
        .cornerRadius(8)
    }
}

#Preview(as: .systemMedium) {
    FavoritesWidget()
} timeline: {
    FavoritesEntry(date: Date(), data: .placeholder, configuration: FavoritesIntent())
}

#Preview(as: .systemLarge) {
    FavoritesWidget()
} timeline: {
    FavoritesEntry(date: Date(), data: .placeholder, configuration: FavoritesIntent())
}

#Preview(as: .accessoryCircular) {
    FavoritesWidget()
} timeline: {
    FavoritesEntry(date: Date(), data: .placeholder, configuration: FavoritesIntent())
}

#Preview(as: .accessoryRectangular) {
    FavoritesWidget()
} timeline: {
    FavoritesEntry(date: Date(), data: .placeholder, configuration: FavoritesIntent())
}

#Preview(as: .accessoryInline) {
    FavoritesWidget()
} timeline: {
    FavoritesEntry(date: Date(), data: .placeholder, configuration: FavoritesIntent())
}
