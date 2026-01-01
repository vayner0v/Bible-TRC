//
//  WidgetPreviewCard.swift
//  Bible v1
//
//  Live preview component for widget customization
//

import SwiftUI

/// Live preview of a widget configuration
struct WidgetPreviewCard: View {
    let config: WidgetConfig
    
    var body: some View {
        ZStack {
            // Background
            backgroundView
            
            // Pattern overlay (if applicable)
            patternOverlay
            
            // Content
            contentView
        }
        .frame(
            width: config.size.previewSize.width,
            height: config.size.previewSize.height
        )
        .clipShape(RoundedRectangle(cornerRadius: config.cornerStyle.radius))
        .shadow(
            color: config.showShadow ? Color.black.opacity(0.15) : Color.clear,
            radius: 10,
            x: 0,
            y: 5
        )
    }
    
    // MARK: - Background
    
    @ViewBuilder
    private var backgroundView: some View {
        switch config.background {
        case .solid(let color):
            RoundedRectangle(cornerRadius: config.cornerStyle.radius)
                .fill(color.color)
            
        case .gradient(let colors, let startPoint, let endPoint):
            RoundedRectangle(cornerRadius: config.cornerStyle.radius)
                .fill(
                    LinearGradient(
                        colors: colors.map { $0.color },
                        startPoint: startPoint.unitPoint,
                        endPoint: endPoint.unitPoint
                    )
                )
            
        case .pattern(_, let baseColor):
            RoundedRectangle(cornerRadius: config.cornerStyle.radius)
                .fill(baseColor.color)
            
        case .image(let imageName, let opacity):
            if let uiImage = UIImage(named: imageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .opacity(opacity)
                    .clipShape(RoundedRectangle(cornerRadius: config.cornerStyle.radius))
            } else {
                RoundedRectangle(cornerRadius: config.cornerStyle.radius)
                    .fill(Color.gray.opacity(0.3))
            }
        }
    }
    
    // MARK: - Pattern Overlay
    
    @ViewBuilder
    private var patternOverlay: some View {
        if case .pattern(let patternName, _) = config.background {
            PatternView(pattern: patternName, opacity: 0.1)
                .clipShape(RoundedRectangle(cornerRadius: config.cornerStyle.radius))
        }
    }
    
    // MARK: - Content
    
    @ViewBuilder
    private var contentView: some View {
        VStack(alignment: config.textAlignment.horizontalAlignment, spacing: 8) {
            switch config.widgetType {
            case .verseOfDay:
                verseOfDayContent
            case .readingProgress:
                readingProgressContent
            case .prayerReminder:
                prayerReminderContent
            case .habitTracker:
                habitTrackerContent
            case .scriptureQuote:
                scriptureQuoteContent
            case .countdown:
                countdownContent
            case .moodGratitude:
                moodGratitudeContent
            case .favorites:
                favoritesContent
            }
        }
        .padding(config.padding.value)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
    }
    
    private var alignment: Alignment {
        switch config.textAlignment {
        case .leading: return .topLeading
        case .center: return .top
        case .trailing: return .topTrailing
        }
    }
    
    // MARK: - Widget Content Views
    
    private var verseOfDayContent: some View {
        VStack(alignment: config.textAlignment.horizontalAlignment, spacing: 6) {
            // Title row
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: titleFontSize * 0.9))
                    .foregroundColor(config.titleStyle.color.color)
                
                Text("Verse of the Day")
                    .font(titleFont)
                    .foregroundColor(config.titleStyle.color.color)
            }
            
            if config.size != .small {
                Spacer()
            }
            
            // Verse text
            Text("\"For God so loved the world, that he gave his only Son...\"")
                .font(bodyFont)
                .foregroundColor(config.bodyStyle.color.color)
                .multilineTextAlignment(config.textAlignment.alignment)
                .lineLimit(config.size == .small ? 2 : (config.size == .medium ? 3 : 5))
            
            if config.size != .small {
                // Reference
                Text("— John 3:16")
                    .font(captionFont)
                    .foregroundColor(config.titleStyle.color.color.opacity(0.8))
            }
        }
    }
    
    private var readingProgressContent: some View {
        VStack(alignment: config.textAlignment.horizontalAlignment, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "book.fill")
                    .font(.system(size: titleFontSize * 0.9))
                    .foregroundColor(config.titleStyle.color.color)
                
                Text("Reading Progress")
                    .font(titleFont)
                    .foregroundColor(config.titleStyle.color.color)
            }
            
            if config.size != .small {
                Spacer()
            }
            
            // Progress ring or bar
            if config.size == .small {
                HStack {
                    Text("Day 12/30")
                        .font(bodyFont)
                        .foregroundColor(config.bodyStyle.color.color)
                    
                    if config.contentConfig.showStreak {
                        HStack(spacing: 2) {
                            Image(systemName: "flame.fill")
                                .font(.caption2)
                            Text("7")
                                .font(.caption2)
                        }
                        .foregroundColor(.orange)
                    }
                }
            } else {
                VStack(alignment: config.textAlignment.horizontalAlignment, spacing: 4) {
                    Text("Getting Started")
                        .font(bodyFont)
                        .foregroundColor(config.bodyStyle.color.color)
                    
                    if config.contentConfig.showPercentage {
                        ProgressView(value: 0.4)
                            .tint(config.titleStyle.color.color)
                        
                        Text("40% Complete")
                            .font(captionFont)
                            .foregroundColor(config.bodyStyle.color.color.opacity(0.7))
                    }
                    
                    if config.contentConfig.showStreak {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.orange)
                            Text("7 day streak")
                                .foregroundColor(config.bodyStyle.color.color)
                        }
                        .font(.caption)
                    }
                }
            }
        }
    }
    
    private var prayerReminderContent: some View {
        VStack(alignment: config.textAlignment.horizontalAlignment, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "hands.sparkles")
                    .font(.system(size: titleFontSize * 0.9))
                    .foregroundColor(config.titleStyle.color.color)
                
                Text("Prayer")
                    .font(titleFont)
                    .foregroundColor(config.titleStyle.color.color)
            }
            
            if config.size != .small {
                Spacer()
            }
            
            if config.contentConfig.showPrayerCount {
                VStack(alignment: config.textAlignment.horizontalAlignment, spacing: 4) {
                    HStack(spacing: 16) {
                        VStack {
                            Text("5")
                                .font(.title2.bold())
                                .foregroundColor(config.bodyStyle.color.color)
                            Text("Active")
                                .font(.caption2)
                                .foregroundColor(config.bodyStyle.color.color.opacity(0.7))
                        }
                        
                        if config.size != .small {
                            VStack {
                                Text("12")
                                    .font(.title2.bold())
                                    .foregroundColor(.green)
                                Text("Answered")
                                    .font(.caption2)
                                    .foregroundColor(config.bodyStyle.color.color.opacity(0.7))
                            }
                        }
                    }
                }
            }
            
            if config.size == .large {
                Text("Tap to add a prayer request")
                    .font(captionFont)
                    .foregroundColor(config.bodyStyle.color.color.opacity(0.6))
            }
        }
    }
    
    private var habitTrackerContent: some View {
        VStack(alignment: config.textAlignment.horizontalAlignment, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: titleFontSize * 0.9))
                    .foregroundColor(config.titleStyle.color.color)
                
                Text("Daily Habits")
                    .font(titleFont)
                    .foregroundColor(config.titleStyle.color.color)
            }
            
            if config.size != .small {
                Spacer()
            }
            
            if config.contentConfig.showCompletionRing {
                HStack(spacing: config.size == .small ? 8 : 16) {
                    // Completion ring visualization
                    ZStack {
                        Circle()
                            .stroke(config.bodyStyle.color.color.opacity(0.2), lineWidth: 4)
                            .frame(width: config.size == .small ? 30 : 50, height: config.size == .small ? 30 : 50)
                        
                        Circle()
                            .trim(from: 0, to: 0.6)
                            .stroke(Color.green, lineWidth: 4)
                            .rotationEffect(.degrees(-90))
                            .frame(width: config.size == .small ? 30 : 50, height: config.size == .small ? 30 : 50)
                        
                        Text("3/5")
                            .font(.caption2.bold())
                            .foregroundColor(config.bodyStyle.color.color)
                    }
                    
                    if config.size != .small {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("3 of 5 complete")
                                .font(bodyFont)
                                .foregroundColor(config.bodyStyle.color.color)
                            
                            Text("Keep going!")
                                .font(captionFont)
                                .foregroundColor(config.bodyStyle.color.color.opacity(0.7))
                        }
                    }
                }
            }
        }
    }
    
    private var scriptureQuoteContent: some View {
        VStack(alignment: config.textAlignment.horizontalAlignment, spacing: 6) {
            Image(systemName: "quote.opening")
                .font(.system(size: config.size == .small ? 14 : 20))
                .foregroundColor(config.titleStyle.color.color.opacity(0.5))
            
            if config.size != .small {
                Spacer()
            }
            
            Text(config.contentConfig.selectedVerseReference ?? "\"The Lord is my shepherd; I shall not want.\"")
                .font(bodyFont)
                .foregroundColor(config.bodyStyle.color.color)
                .multilineTextAlignment(config.textAlignment.alignment)
                .lineLimit(config.size == .small ? 2 : (config.size == .medium ? 3 : 6))
            
            if config.size != .small {
                Text("— Psalm 23:1")
                    .font(captionFont)
                    .foregroundColor(config.titleStyle.color.color.opacity(0.8))
            }
        }
    }
    
    private var countdownContent: some View {
        VStack(alignment: config.textAlignment.horizontalAlignment, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: titleFontSize * 0.9))
                    .foregroundColor(config.titleStyle.color.color)
                
                Text(config.contentConfig.countdownTitle ?? "Countdown")
                    .font(titleFont)
                    .foregroundColor(config.titleStyle.color.color)
                    .lineLimit(1)
            }
            
            if config.size != .small {
                Spacer()
            }
            
            // Days remaining
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text("14")
                    .font(.system(size: config.size == .small ? 28 : 40, weight: .bold))
                    .foregroundColor(config.bodyStyle.color.color)
                
                Text("days")
                    .font(bodyFont)
                    .foregroundColor(config.bodyStyle.color.color.opacity(0.7))
            }
            
            if config.size == .large {
                Text("until Easter Sunday")
                    .font(captionFont)
                    .foregroundColor(config.bodyStyle.color.color.opacity(0.6))
            }
        }
    }
    
    private var moodGratitudeContent: some View {
        VStack(alignment: config.textAlignment.horizontalAlignment, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "heart.fill")
                    .font(.system(size: titleFontSize * 0.9))
                    .foregroundColor(config.titleStyle.color.color)
                
                Text("Mood & Gratitude")
                    .font(titleFont)
                    .foregroundColor(config.titleStyle.color.color)
            }
            
            if config.size != .small {
                Spacer()
            }
            
            if config.contentConfig.showMoodHistory {
                // Mood emoji row
                HStack(spacing: 8) {
                    ForEach(["😊", "😌", "🙏", "😔", "😊"], id: \.self) { emoji in
                        Text(emoji)
                            .font(.caption)
                    }
                }
            }
            
            if config.contentConfig.showGratitudePrompt {
                VStack(alignment: config.textAlignment.horizontalAlignment, spacing: 4) {
                    Text("Today I'm grateful for...")
                        .font(bodyFont)
                        .foregroundColor(config.bodyStyle.color.color)
                    
                    if config.size == .medium {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.orange)
                            Text("5 day streak")
                        }
                        .font(.caption)
                        .foregroundColor(config.bodyStyle.color.color.opacity(0.7))
                    }
                }
            }
        }
    }
    
    private var favoritesContent: some View {
        VStack(alignment: config.textAlignment.horizontalAlignment, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .font(.system(size: titleFontSize * 0.9))
                    .foregroundColor(config.titleStyle.color.color)
                
                Text("Favorites")
                    .font(titleFont)
                    .foregroundColor(config.titleStyle.color.color)
            }
            
            Spacer()
            
            // Sample favorites list
            VStack(alignment: .leading, spacing: 6) {
                FavoritePreviewRow(reference: "John 3:16", config: config)
                FavoritePreviewRow(reference: "Psalm 23:1", config: config)
                
                if config.size == .large {
                    FavoritePreviewRow(reference: "Romans 8:28", config: config)
                    FavoritePreviewRow(reference: "Philippians 4:13", config: config)
                }
            }
        }
    }
    
    // MARK: - Font Helpers
    
    private var titleFontSize: CGFloat {
        switch config.size {
        case .small: return config.titleStyle.size.pointSize * 0.75
        case .medium: return config.titleStyle.size.pointSize * 0.85
        case .large: return config.titleStyle.size.pointSize
        }
    }
    
    private var titleFont: Font {
        config.titleStyle.family.font(
            size: titleFontSize,
            weight: config.titleStyle.weight.fontWeight
        )
    }
    
    private var bodyFont: Font {
        let size: CGFloat
        switch config.size {
        case .small: size = config.bodyStyle.size.pointSize * 0.75
        case .medium: size = config.bodyStyle.size.pointSize * 0.85
        case .large: size = config.bodyStyle.size.pointSize
        }
        
        return config.bodyStyle.family.font(
            size: size,
            weight: config.bodyStyle.weight.fontWeight
        )
    }
    
    private var captionFont: Font {
        .system(size: config.size == .small ? 9 : 11)
    }
}

// MARK: - Supporting Views

struct FavoritePreviewRow: View {
    let reference: String
    let config: WidgetConfig
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "bookmark.fill")
                .font(.caption2)
                .foregroundColor(config.titleStyle.color.color.opacity(0.6))
            
            Text(reference)
                .font(.caption)
                .foregroundColor(config.bodyStyle.color.color)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundColor(config.bodyStyle.color.color.opacity(0.4))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(config.bodyStyle.color.color.opacity(0.08))
        )
    }
}

struct PatternView: View {
    let pattern: String
    let opacity: Double
    
    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                let spacing: CGFloat = 20
                
                switch pattern {
                case "crosses":
                    for x in stride(from: 0, to: size.width, by: spacing) {
                        for y in stride(from: 0, to: size.height, by: spacing) {
                            let rect = CGRect(x: x, y: y, width: 8, height: 8)
                            context.stroke(
                                Path { path in
                                    path.move(to: CGPoint(x: rect.midX, y: rect.minY))
                                    path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
                                    path.move(to: CGPoint(x: rect.minX, y: rect.midY))
                                    path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
                                },
                                with: .color(.white.opacity(opacity)),
                                lineWidth: 1
                            )
                        }
                    }
                    
                case "dots":
                    for x in stride(from: 0, to: size.width, by: spacing) {
                        for y in stride(from: 0, to: size.height, by: spacing) {
                            context.fill(
                                Circle().path(in: CGRect(x: x, y: y, width: 4, height: 4)),
                                with: .color(.white.opacity(opacity))
                            )
                        }
                    }
                    
                case "lines":
                    for y in stride(from: 0, to: size.height, by: spacing) {
                        context.stroke(
                            Path { path in
                                path.move(to: CGPoint(x: 0, y: y))
                                path.addLine(to: CGPoint(x: size.width, y: y))
                            },
                            with: .color(.white.opacity(opacity)),
                            lineWidth: 1
                        )
                    }
                    
                case "waves":
                    for y in stride(from: 0, to: size.height, by: spacing * 1.5) {
                        context.stroke(
                            Path { path in
                                path.move(to: CGPoint(x: 0, y: y))
                                for x in stride(from: 0, to: size.width, by: 20) {
                                    let controlY = y + (x.truncatingRemainder(dividingBy: 40) == 0 ? -8 : 8)
                                    path.addQuadCurve(
                                        to: CGPoint(x: x + 20, y: y),
                                        control: CGPoint(x: x + 10, y: controlY)
                                    )
                                }
                            },
                            with: .color(.white.opacity(opacity)),
                            lineWidth: 1
                        )
                    }
                    
                default:
                    break
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        WidgetPreviewCard(
            config: WidgetConfig(
                widgetType: .verseOfDay,
                size: .medium,
                background: .gradient(
                    colors: [
                        CodableColor(red: 0.6, green: 0.7, blue: 0.9),
                        CodableColor(red: 0.8, green: 0.7, blue: 0.9)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                titleStyle: WidgetFontStyle(
                    family: .system,
                    size: .medium,
                    weight: .bold,
                    color: CodableColor(red: 1, green: 1, blue: 1, opacity: 0.9)
                ),
                bodyStyle: WidgetFontStyle(
                    family: .serif,
                    size: .medium,
                    weight: .medium,
                    color: CodableColor(red: 1, green: 1, blue: 1)
                )
            )
        )
        
        WidgetPreviewCard(
            config: WidgetConfig(
                widgetType: .habitTracker,
                size: .small,
                background: .solid(color: CodableColor(color: .white))
            )
        )
    }
    .padding()
    .background(Color.gray.opacity(0.2))
}

