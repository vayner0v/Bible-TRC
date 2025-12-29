//
//  HubFeatureTile.swift
//  Bible v1
//
//  Reusable animated tile component for Hub grid
//

import SwiftUI

/// Configuration for a Hub feature tile
struct HubTileConfig: Identifiable, Equatable {
    let id: String
    let destination: HubDestination
    let progress: Double?
    let badgeCount: Int?
    let isCompleted: Bool
    let streak: Int?
    
    init(
        destination: HubDestination,
        progress: Double? = nil,
        badgeCount: Int? = nil,
        isCompleted: Bool = false,
        streak: Int? = nil
    ) {
        self.id = destination.rawValue
        self.destination = destination
        self.progress = progress
        self.badgeCount = badgeCount
        self.isCompleted = isCompleted
        self.streak = streak
    }
}

/// Animated feature tile for the Hub grid with standardized 50/50 sizing
struct HubFeatureTile: View {
    let config: HubTileConfig
    let animationDelay: Double
    let action: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var isPressed = false
    @State private var hasAppeared = false
    
    private let tileHeight: CGFloat = 140
    
    var body: some View {
        Button(action: {
            HapticManager.shared.lightImpact()
            action()
        }) {
            tileContent
        }
        .buttonStyle(TilePressStyle())
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 20)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(animationDelay)) {
                hasAppeared = true
            }
        }
    }
    
    private var tileContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row with icon and badges
            HStack(alignment: .top) {
                // Icon with glow
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(config.destination.color.opacity(0.25))
                        .frame(width: 48, height: 48)
                        .blur(radius: 8)
                    
                    // Icon background
                    Circle()
                        .fill(config.destination.color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    // Icon
                    Image(systemName: config.destination.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(config.destination.color)
                }
                
                Spacer()
                
                // Badges
                HStack(spacing: 6) {
                    if config.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    
                    if let streak = config.streak, streak > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "flame.fill")
                                .font(.caption2)
                            Text("\(streak)")
                                .font(.caption2)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.orange.opacity(0.15))
                        .cornerRadius(8)
                    }
                    
                    if let count = config.badgeCount, count > 0 {
                        Text("\(count)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(minWidth: 18, minHeight: 18)
                            .background(config.destination.color)
                            .cornerRadius(9)
                    }
                }
            }
            
            Spacer(minLength: 0)
            
            // Title and subtitle
            VStack(alignment: .leading, spacing: 4) {
                Text(config.destination.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.textColor)
                    .lineLimit(1)
                
                Text(config.destination.subtitle)
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .lineLimit(1)
            }
            
            // Progress indicator (if applicable)
            if let progress = config.progress {
                ProgressView(value: progress)
                    .tint(config.destination.color)
                    .scaleEffect(y: 0.8)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: tileHeight)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(themeManager.hubElevatedSurface)
                .shadow(
                    color: themeManager.hubShadowColor,
                    radius: 12,
                    x: 0,
                    y: 6
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    config.destination.color.opacity(0.1),
                    lineWidth: 1
                )
        )
    }
}

/// Custom button style for tile press animation
struct TilePressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Compact tile for secondary features (legacy - kept for compatibility)
struct HubCompactTile: View {
    let destination: HubDestination
    let action: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: {
            HapticManager.shared.lightImpact()
            action()
        }) {
            VStack(spacing: 10) {
                Image(systemName: destination.icon)
                    .font(.title2)
                    .foregroundColor(destination.color)
                    .frame(width: 44, height: 44)
                    .background(destination.color.opacity(0.12))
                    .cornerRadius(12)
                
                Text(destination.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.textColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(14)
        }
        .buttonStyle(TilePressStyle())
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                HubFeatureTile(
                    config: HubTileConfig(
                        destination: .prayerJournal,
                        badgeCount: 3
                    ),
                    animationDelay: 0,
                    action: {}
                )
                
                HubFeatureTile(
                    config: HubTileConfig(
                        destination: .habitsTracker,
                        progress: 0.6,
                        streak: 7
                    ),
                    animationDelay: 0.1,
                    action: {}
                )
            }
            
            HStack(spacing: 12) {
                HubCompactTile(destination: .audioPrayers, action: {})
                HubCompactTile(destination: .fasting, action: {})
            }
        }
        .padding()
    }
}
