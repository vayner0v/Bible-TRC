//
//  HubGridView.swift
//  Bible v1
//
//  Animated 50/50 grid layout for Hub feature tiles
//

import SwiftUI

/// Grid layout for Hub feature tiles with equal 50/50 proportions
struct HubGridView: View {
    @ObservedObject var viewModel: HubViewModel
    let onTileTap: (HubDestination) -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    private let spacing: CGFloat = 12
    
    var body: some View {
        VStack(spacing: 16) {
            // Main feature tiles in 50/50 grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: spacing),
                GridItem(.flexible(), spacing: spacing)
            ], spacing: 16) {
                ForEach(Array(tileConfigs.enumerated()), id: \.element.id) { index, config in
                    HubFeatureTile(
                        config: config,
                        animationDelay: Double(index) * 0.05
                    ) {
                        onTileTap(config.destination)
                    }
                }
            }
            
            // Secondary features section
            secondaryFeaturesSection
                .padding(.bottom, 16)
        }
    }
    
    /// Tile configurations based on viewModel data
    private var tileConfigs: [HubTileConfig] {
        [
            // Row 1: Prayer Journal + Daily Habits
            HubTileConfig(
                destination: .prayerJournal,
                badgeCount: viewModel.unansweredPrayers.count
            ),
            HubTileConfig(
                destination: .habitsTracker,
                progress: viewModel.todayHabitProgress,
                isCompleted: viewModel.todayHabitProgress >= 1.0,
                streak: viewModel.habitStreaks.map { $0.currentStreak }.max()
            ),
            
            // Row 2: Gratitude + Reading Plans
            HubTileConfig(
                destination: .gratitudeTracker,
                isCompleted: viewModel.hasCompletedTodayGratitude,
                streak: viewModel.gratitudeStreak
            ),
            HubTileConfig(
                destination: .readingPlans,
                progress: readingPlanProgress
            ),
            
            // Row 3: Daily Routine + Guided Prayer
            HubTileConfig(
                destination: .dailyRoutine,
                isCompleted: viewModel.didCompleteMorningRoutine || viewModel.didCompleteNightRoutine,
                streak: viewModel.bestRoutineStreak > 0 ? viewModel.bestRoutineStreak : nil
            ),
            HubTileConfig(
                destination: .guidedPrayer
            ),
            
            // Row 4: Fasting + Missions
            HubTileConfig(
                destination: .fasting
            ),
            HubTileConfig(
                destination: .missions
            ),
            
            // Row 5: Mood Check-in + Devotionals
            HubTileConfig(
                destination: .moodCheckIn,
                isCompleted: viewModel.hasCheckedInMoodToday
            ),
            HubTileConfig(
                destination: .devotionals
            )
        ]
    }
    
    /// Calculate reading plan progress
    private var readingPlanProgress: Double? {
        guard let plan = viewModel.activePlan,
              let progress = viewModel.activeProgress else { return nil }
        return progress.progressPercentage(totalDays: plan.days.count)
    }
    
    /// Secondary features in a styled 2-column grid matching main tiles
    private var secondaryFeaturesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("More Features")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.textColor)
                
                Spacer()
            }
            .padding(.top, 8)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: spacing),
                GridItem(.flexible(), spacing: spacing)
            ], spacing: 12) {
                HubSecondaryTile(destination: .prayerSchedule) {
                    onTileTap(.prayerSchedule)
                }
                
                HubSecondaryTile(destination: .audioPrayers) {
                    onTileTap(.audioPrayers)
                }
                
                HubSecondaryTile(destination: .scripturePrayer) {
                    onTileTap(.scripturePrayer)
                }
                
                HubSecondaryTile(destination: .prayerLibrary) {
                    onTileTap(.prayerLibrary)
                }
                
                HubSecondaryTile(destination: .weeklyRecap) {
                    onTileTap(.weeklyRecap)
                }
                
                HubSecondaryTile(destination: .widgets) {
                    onTileTap(.widgets)
                }
            }
        }
    }
}

/// Secondary tile that matches the main feature tile aesthetic
struct HubSecondaryTile: View {
    let destination: HubDestination
    let action: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var hasAppeared = false
    
    var body: some View {
        Button(action: {
            HapticManager.shared.lightImpact()
            action()
        }) {
            HStack(spacing: 12) {
                // Icon with glow
                ZStack {
                    Circle()
                        .fill(destination.color.opacity(0.2))
                        .frame(width: 44, height: 44)
                        .blur(radius: 6)
                    
                    Circle()
                        .fill(destination.color.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: destination.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(destination.color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(destination.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.textColor)
                        .lineLimit(1)
                    
                    Text(destination.subtitle)
                        .font(.caption2)
                        .foregroundColor(themeManager.secondaryTextColor)
                        .lineLimit(1)
                }
                
                Spacer(minLength: 0)
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.hubElevatedSurface)
                    .shadow(
                        color: themeManager.hubShadowColor,
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(destination.color.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(TilePressStyle())
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 15)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3)) {
                hasAppeared = true
            }
        }
    }
}

#Preview {
    ScrollView {
        HubGridView(viewModel: HubViewModel()) { destination in
            print("Tapped: \(destination)")
        }
        .padding()
    }
}
