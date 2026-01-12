//
//  RoutineProgressHeader.swift
//  Bible v1
//
//  Header component showing routine progress, greeting, and streak
//

import SwiftUI

// MARK: - Routine Progress Header

/// Header showing greeting, date, and streak information
struct RoutineProgressHeader: View {
    let configuration: RoutineConfiguration
    let currentStepIndex: Int
    let streak: RoutineStreak
    
    @State private var hasAppeared = false
    @ObservedObject private var themeManager = ThemeManager.shared
    
    private var mode: RoutineMode {
        configuration.mode
    }
    
    private var progress: Double {
        guard configuration.enabledSteps.count > 0 else { return 0 }
        return Double(currentStepIndex) / Double(configuration.enabledSteps.count)
    }
    
    var body: some View {
        VStack(spacing: 10) {
            // Top row: Greeting and streak - compact
            HStack {
                // Greeting section
                HStack(spacing: 6) {
                    Image(systemName: mode.icon)
                        .font(.system(size: 16))
                        .foregroundColor(mode.accentColor)
                    
                    Text(mode.greeting)
                        .font(.headline)
                        .foregroundColor(themeManager.textColor)
                }
                
                Spacer()
                
                // Streak badge inline
                if streak.currentStreak > 0 {
                    streakBadge
                }
            }
            
            // Progress bar - compact
            progressBar
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.cardBackgroundColor)
                .shadow(color: themeManager.textColor.opacity(0.06), radius: 6, x: 0, y: 2)
        )
        .opacity(hasAppeared ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                hasAppeared = true
            }
        }
    }
    
    // MARK: - Streak Badge
    
    private var streakBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .font(.system(size: 12))
                .foregroundColor(.orange)
            
            Text("\(streak.currentStreak)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(themeManager.textColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.orange.opacity(0.1))
        )
    }
    
    // MARK: - Progress Bar
    
    private var progressBar: some View {
        HStack(spacing: 6) {
            // Step dots - compact
            HStack(spacing: 4) {
                ForEach(0..<configuration.enabledSteps.count, id: \.self) { index in
                    Circle()
                        .fill(index <= currentStepIndex ? mode.accentColor : themeManager.dividerColor)
                        .frame(width: 6, height: 6)
                        .animation(.easeInOut(duration: 0.2), value: currentStepIndex)
                }
            }
            
            Spacer()
            
            // Progress text and duration inline
            HStack(spacing: 8) {
                Text("\(currentStepIndex + 1)/\(configuration.enabledSteps.count)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.secondaryTextColor)
                
                Text("•")
                    .font(.caption)
                    .foregroundColor(themeManager.dividerColor)
                
                HStack(spacing: 3) {
                    Image(systemName: "clock")
                        .font(.system(size: 9))
                    Text(configuration.formattedTotalDuration)
                        .font(.caption)
                }
                .foregroundColor(themeManager.secondaryTextColor)
            }
        }
    }
    
    // MARK: - Helpers
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }
}

// MARK: - Mode Selector

/// A styled mode selector for choosing morning/evening routine
struct RoutineModeSelectorBar: View {
    @Binding var selectedMode: RoutineMode
    let availableModes: [RoutineMode]
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(availableModes, id: \.self) { mode in
                Button {
                    HapticManager.shared.selection()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedMode = mode
                    }
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 18))
                        
                        Text(mode.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(selectedMode == mode ? mode.accentColor : themeManager.secondaryTextColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedMode == mode ? mode.accentColor.opacity(0.1) : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.cardBackgroundColor)
                .shadow(color: themeManager.textColor.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Navigation Buttons

/// Bottom navigation buttons for routine steps
struct RoutineNavigationButtons: View {
    let currentStepIndex: Int
    let totalSteps: Int
    let mode: RoutineMode
    let canProceed: Bool
    
    var onBack: () -> Void
    var onNext: () -> Void
    var onComplete: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    private var isLastStep: Bool {
        currentStepIndex >= totalSteps - 1
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Back button - compact
            if currentStepIndex > 0 {
                Button {
                    HapticManager.shared.lightImpact()
                    onBack()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Back")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(themeManager.textColor)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(themeManager.cardBackgroundColor)
                            .shadow(color: themeManager.textColor.opacity(0.06), radius: 4, x: 0, y: 2)
                    )
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
            
            // Next/Complete button - compact
            Button {
                if isLastStep {
                    HapticManager.shared.mediumImpact()
                    onComplete()
                } else {
                    HapticManager.shared.lightImpact()
                    onNext()
                }
            } label: {
                HStack(spacing: 6) {
                    Text(isLastStep ? "Complete" : "Next")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Image(systemName: isLastStep ? "checkmark.circle.fill" : "chevron.right")
                        .font(.system(size: isLastStep ? 14 : 12, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(mode.accentColor)
                        .shadow(color: mode.accentColor.opacity(0.25), radius: 4, x: 0, y: 2)
                )
            }
            .buttonStyle(.plain)
            .opacity(canProceed ? 1 : 0.6)
            .disabled(!canProceed)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [themeManager.backgroundColor.opacity(0), themeManager.backgroundColor],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

// MARK: - Preview

#Preview("Progress Header") {
    VStack(spacing: 20) {
        RoutineProgressHeader(
            configuration: RoutineStepLibrary.defaultMorningRoutine,
            currentStepIndex: 1,
            streak: RoutineStreak(currentStreak: 7, longestStreak: 14, lastCompletedDate: Date(), totalCompletions: 42)
        )
        
        RoutineModeSelectorBar(
            selectedMode: .constant(.morning),
            availableModes: [.morning, .evening]
        )
        
        Spacer()
        
        RoutineNavigationButtons(
            currentStepIndex: 1,
            totalSteps: 4,
            mode: .morning,
            canProceed: true,
            onBack: {},
            onNext: {},
            onComplete: {}
        )
    }
    .padding()
    .background(Color.Journal.paper)
}

