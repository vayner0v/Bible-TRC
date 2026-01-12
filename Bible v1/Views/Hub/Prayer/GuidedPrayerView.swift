//
//  GuidedPrayerView.swift
//  Bible v1
//
//  Fully Guided Prayer - Immersive, auto-progressing prayer sessions
//  "You Follow, God Leads"
//

import SwiftUI

struct GuidedPrayerView: View {
    @ObservedObject var viewModel: HubViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTheme: GuidedPrayerTheme = .gratitude
    @State private var selectedDuration: GuidedPrayerDuration = .fiveMinutes
    @State private var sessionState: SessionState = .setup
    
    enum SessionState {
        case setup
        case entering
        case active
        case completed
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Dynamic background based on state
                backgroundView
                    .ignoresSafeArea()
                
                switch sessionState {
                case .setup:
                    setupView
                        .transition(.opacity)
                case .entering:
                    EntryTransitionView(theme: selectedTheme) {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            sessionState = .active
                        }
                    }
                    .transition(.opacity)
                case .active:
                    GuidedSessionView(
                        theme: selectedTheme,
                        duration: selectedDuration,
                        onComplete: { notes in
                            viewModel.recordGuidedSession(
                                theme: selectedTheme,
                                duration: selectedDuration.seconds,
                                notes: notes
                            )
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                sessionState = .completed
                            }
                        },
                        onExit: {
                            withAnimation {
                                sessionState = .setup
                            }
                        }
                    )
                    .transition(.opacity)
                case .completed:
                    CompletionView(
                        theme: selectedTheme,
                        duration: selectedDuration,
                        onDone: { notes in
                            if let notes = notes, !notes.isEmpty {
                                // Update with notes if provided
                            }
                            dismiss()
                        },
                        onStartAnother: {
                            withAnimation(.spring(response: 0.4)) {
                                sessionState = .setup
                            }
                        }
                    )
                    .transition(.opacity)
                }
            }
            .navigationTitle(sessionState == .setup ? "Guided Prayer" : "")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if sessionState == .setup {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") { dismiss() }
                            .foregroundColor(themeManager.textColor)
                    }
                }
            }
        }
    }
    
    // MARK: - Background
    
    @ViewBuilder
    private var backgroundView: some View {
        switch sessionState {
        case .setup:
            themeManager.backgroundColor
        case .entering, .active, .completed:
            ThemeGradientBackground(theme: selectedTheme)
        }
    }
    
    // MARK: - Setup View
    
    private var setupView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 10) {
                    Image(systemName: "hands.sparkles")
                        .font(.system(size: 44))
                        .foregroundStyle(themeManager.accentGradient)
                    
                    Text("Guided Prayer")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.textColor)
                    
                    Text("Let God lead your prayer journey")
                        .font(.subheadline)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                .padding(.top, 16)
                
                // Theme Selection
                VStack(alignment: .leading, spacing: 10) {
                    Text("THEME")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.secondaryTextColor)
                        .tracking(1)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(GuidedPrayerTheme.allCases) { theme in
                            EnhancedThemeCard(
                                theme: theme,
                                isSelected: selectedTheme == theme
                            ) {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedTheme = theme
                                }
                            }
                        }
                    }
                }
                
                // Duration Selection
                VStack(alignment: .leading, spacing: 10) {
                    Text("DURATION")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.secondaryTextColor)
                        .tracking(1)
                    
                    HStack(spacing: 10) {
                        ForEach(GuidedPrayerDuration.allCases) { duration in
                            DurationCard(
                                duration: duration,
                                theme: selectedTheme,
                                isSelected: selectedDuration == duration
                            ) {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedDuration = duration
                                }
                            }
                        }
                    }
                }
                
                // Elegant session preview
                SessionPreviewCard(theme: selectedTheme, duration: selectedDuration)
                
                // Session stats (only show if there are any)
                if viewModel.guidedSessions.count > 0 {
                    SessionStatsRow(viewModel: viewModel)
                }
                
                // Start button
                Button {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        sessionState = .entering
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "play.fill")
                        Text("Begin Prayer")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [themeColor(for: selectedTheme), themeColor(for: selectedTheme).opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(14)
                    .shadow(color: themeColor(for: selectedTheme).opacity(0.3), radius: 8, y: 4)
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }
    
    private func themeColor(for theme: GuidedPrayerTheme) -> Color {
        switch theme {
        case .gratitude: return Color(red: 0.9, green: 0.4, blue: 0.5)
        case .repentance: return Color(red: 0.6, green: 0.4, blue: 0.8)
        case .guidance: return Color(red: 0.3, green: 0.5, blue: 0.9)
        case .peace: return Color(red: 0.2, green: 0.6, blue: 0.65)
        case .family: return Color(red: 0.9, green: 0.55, blue: 0.3)
        case .work: return Color(red: 0.6, green: 0.45, blue: 0.35)
        }
    }
}

// MARK: - Theme Gradient Background (Improved Contrast)

struct ThemeGradientBackground: View {
    let theme: GuidedPrayerTheme
    
    @State private var animateGradient = false
    
    private var colors: [Color] {
        switch theme {
        case .gratitude:
            return [Color(red: 0.35, green: 0.15, blue: 0.2), Color(red: 0.2, green: 0.1, blue: 0.15), Color(red: 0.15, green: 0.08, blue: 0.1)]
        case .repentance:
            return [Color(red: 0.25, green: 0.15, blue: 0.35), Color(red: 0.15, green: 0.1, blue: 0.25), Color(red: 0.1, green: 0.08, blue: 0.18)]
        case .guidance:
            return [Color(red: 0.12, green: 0.2, blue: 0.35), Color(red: 0.08, green: 0.15, blue: 0.28), Color(red: 0.06, green: 0.1, blue: 0.2)]
        case .peace:
            return [Color(red: 0.1, green: 0.25, blue: 0.28), Color(red: 0.08, green: 0.18, blue: 0.22), Color(red: 0.05, green: 0.12, blue: 0.15)]
        case .family:
            return [Color(red: 0.35, green: 0.2, blue: 0.1), Color(red: 0.25, green: 0.15, blue: 0.08), Color(red: 0.18, green: 0.1, blue: 0.06)]
        case .work:
            return [Color(red: 0.25, green: 0.18, blue: 0.12), Color(red: 0.18, green: 0.13, blue: 0.1), Color(red: 0.12, green: 0.09, blue: 0.07)]
        }
    }
    
    private var accentColor: Color {
        switch theme {
        case .gratitude: return Color(red: 0.95, green: 0.5, blue: 0.55)
        case .repentance: return Color(red: 0.7, green: 0.5, blue: 0.9)
        case .guidance: return Color(red: 0.4, green: 0.65, blue: 1.0)
        case .peace: return Color(red: 0.4, green: 0.8, blue: 0.75)
        case .family: return Color(red: 1.0, green: 0.65, blue: 0.35)
        case .work: return Color(red: 0.85, green: 0.65, blue: 0.45)
        }
    }
    
    var body: some View {
        ZStack {
            // Base dark gradient
            LinearGradient(
                colors: colors,
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Animated accent glow
            RadialGradient(
                colors: [accentColor.opacity(0.15), .clear],
                center: animateGradient ? .topLeading : .bottomTrailing,
                startRadius: 50,
                endRadius: 400
            )
            
            // Subtle vignette for depth
            RadialGradient(
                colors: [.clear, Color.black.opacity(0.3)],
                center: .center,
                startRadius: 200,
                endRadius: 500
            )
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) {
                animateGradient = true
            }
        }
    }
}

// MARK: - Enhanced Theme Card

struct EnhancedThemeCard: View {
    let theme: GuidedPrayerTheme
    let isSelected: Bool
    let action: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    private var themeColor: Color {
        switch theme {
        case .gratitude: return Color(red: 0.9, green: 0.4, blue: 0.5)
        case .repentance: return Color(red: 0.6, green: 0.4, blue: 0.8)
        case .guidance: return Color(red: 0.3, green: 0.5, blue: 0.9)
        case .peace: return Color(red: 0.2, green: 0.6, blue: 0.65)
        case .family: return Color(red: 0.9, green: 0.55, blue: 0.3)
        case .work: return Color(red: 0.6, green: 0.45, blue: 0.35)
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: theme.icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : themeColor)
                
                Text(theme.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : themeManager.textColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(colors: [themeColor, themeColor.opacity(0.75)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    } else {
                        themeManager.cardBackgroundColor
                    }
                }
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : themeManager.dividerColor.opacity(0.5), lineWidth: 1)
            )
            .shadow(color: isSelected ? themeColor.opacity(0.25) : .clear, radius: 6, y: 3)
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

// MARK: - Duration Card (Enhanced)

struct DurationCard: View {
    let duration: GuidedPrayerDuration
    let theme: GuidedPrayerTheme
    let isSelected: Bool
    let action: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    private var themeColor: Color {
        switch theme {
        case .gratitude: return Color(red: 0.9, green: 0.4, blue: 0.5)
        case .repentance: return Color(red: 0.6, green: 0.4, blue: 0.8)
        case .guidance: return Color(red: 0.3, green: 0.5, blue: 0.9)
        case .peace: return Color(red: 0.2, green: 0.6, blue: 0.65)
        case .family: return Color(red: 0.9, green: 0.55, blue: 0.3)
        case .work: return Color(red: 0.6, green: 0.45, blue: 0.35)
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("\(duration.rawValue)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(isSelected ? .white : themeManager.textColor)
                
                Text("min")
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : themeManager.secondaryTextColor)
                
                Text("\(duration.phaseCount) phases")
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white.opacity(0.7) : themeManager.secondaryTextColor.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                Group {
                    if isSelected {
                        themeColor
                    } else {
                        themeManager.cardBackgroundColor
                    }
                }
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : themeManager.dividerColor.opacity(0.5), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

// MARK: - Session Preview Card (Elegant Redesign)

struct SessionPreviewCard: View {
    let theme: GuidedPrayerTheme
    let duration: GuidedPrayerDuration
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    private var themeColor: Color {
        switch theme {
        case .gratitude: return Color(red: 0.9, green: 0.4, blue: 0.5)
        case .repentance: return Color(red: 0.6, green: 0.4, blue: 0.8)
        case .guidance: return Color(red: 0.3, green: 0.5, blue: 0.9)
        case .peace: return Color(red: 0.2, green: 0.6, blue: 0.65)
        case .family: return Color(red: 0.9, green: 0.55, blue: 0.3)
        case .work: return Color(red: 0.6, green: 0.45, blue: 0.35)
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Stats row
            HStack(spacing: 16) {
                statItem(icon: "book.fill", value: "\(duration.phaseCount)", label: "Phases")
                
                Divider()
                    .frame(height: 30)
                
                statItem(icon: "clock.fill", value: "~\(duration.rawValue)", label: "Minutes")
                
                Divider()
                    .frame(height: 30)
                
                statItem(icon: "sparkles", value: "Auto", label: "Guided")
            }
            
            // Tagline
            Text(duration.tagline)
                .font(.caption)
                .foregroundColor(themeManager.secondaryTextColor)
                .italic()
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(themeManager.cardBackgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            LinearGradient(
                                colors: [themeColor.opacity(0.3), themeColor.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
    
    private func statItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(themeColor)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.textColor)
            }
            Text(label)
                .font(.caption2)
                .foregroundColor(themeManager.secondaryTextColor)
        }
    }
}

// MARK: - Session Stats Row

struct SessionStatsRow: View {
    @ObservedObject var viewModel: HubViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 8) {
            StatBox(
                value: "\(viewModel.totalPrayerMinutes)",
                label: "Total Minutes",
                color: themeManager.accentColor
            )
            
            StatBox(
                value: "\(viewModel.guidedSessions.count)",
                label: "Sessions",
                color: .indigo
            )
            
            StatBox(
                value: "\(viewModel.guidedSessionsThisWeek)",
                label: "This Week",
                color: .blue
            )
        }
    }
}

// MARK: - Stat Box

struct StatBox: View {
    let value: String
    let label: String
    let color: Color
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(themeManager.secondaryTextColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(10)
    }
}

// MARK: - Entry Transition View

struct EntryTransitionView: View {
    let theme: GuidedPrayerTheme
    let onComplete: () -> Void
    
    @State private var iconScale: CGFloat = 0.5
    @State private var iconOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var glowScale: CGFloat = 0.8
    @State private var glowOpacity: Double = 0
    
    private var themeColor: Color {
        switch theme {
        case .gratitude: return Color(red: 0.95, green: 0.5, blue: 0.55)
        case .repentance: return Color(red: 0.7, green: 0.5, blue: 0.9)
        case .guidance: return Color(red: 0.4, green: 0.65, blue: 1.0)
        case .peace: return Color(red: 0.4, green: 0.8, blue: 0.75)
        case .family: return Color(red: 1.0, green: 0.65, blue: 0.35)
        case .work: return Color(red: 0.85, green: 0.65, blue: 0.45)
        }
    }
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [themeColor.opacity(0.5), themeColor.opacity(0)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 120
                        )
                    )
                    .frame(width: 240, height: 240)
                    .scaleEffect(glowScale)
                    .opacity(glowOpacity)
                
                // Icon
                Image(systemName: theme.icon)
                    .font(.system(size: 70))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [themeColor, themeColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: themeColor.opacity(0.5), radius: 20)
                    .scaleEffect(iconScale)
                    .opacity(iconOpacity)
            }
            
            VStack(spacing: 12) {
                Text("Prepare Your Heart")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
                
                Text("Take a deep breath...\nLet the world fade away")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .shadow(color: .black.opacity(0.2), radius: 1, y: 1)
            }
            .opacity(textOpacity)
            
            Spacer()
            Spacer()
        }
        .onAppear {
            startEntrySequence()
        }
    }
    
    private func startEntrySequence() {
        // Phase 1: Icon appears
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            iconScale = 1.0
            iconOpacity = 1.0
        }
        
        // Phase 2: Glow expands
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 1.0)) {
                glowScale = 1.5
                glowOpacity = 1.0
            }
        }
        
        // Phase 3: Text fades in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeOut(duration: 0.5)) {
                textOpacity = 1.0
            }
        }
        
        // Phase 4: Glow pulses
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 1.5).repeatCount(2, autoreverses: true)) {
                glowScale = 1.8
                glowOpacity = 0.6
            }
        }
        
        // Phase 5: Transition to session
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            onComplete()
        }
    }
}

// MARK: - Guided Session View (Auto-Progression)

struct GuidedSessionView: View {
    let theme: GuidedPrayerTheme
    let duration: GuidedPrayerDuration
    let onComplete: (String?) -> Void
    let onExit: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    @State private var currentPhaseIndex = 0
    @State private var timeRemaining: Int
    @State private var timer: Timer?
    @State private var showBreathing = false
    @State private var isPaused = false
    @State private var showExitConfirmation = false
    @State private var phaseProgress: Double = 0
    
    private var phases: [GuidedPrayerPhase] { theme.phases(for: duration) }
    private var currentPhase: GuidedPrayerPhase { phases[currentPhaseIndex] }
    
    private var themeColor: Color {
        switch theme {
        case .gratitude: return Color(red: 0.95, green: 0.5, blue: 0.55)
        case .repentance: return Color(red: 0.7, green: 0.5, blue: 0.9)
        case .guidance: return Color(red: 0.4, green: 0.65, blue: 1.0)
        case .peace: return Color(red: 0.4, green: 0.8, blue: 0.75)
        case .family: return Color(red: 1.0, green: 0.65, blue: 0.35)
        case .work: return Color(red: 0.85, green: 0.65, blue: 0.45)
        }
    }
    
    // Calculate phase durations based on weights
    private var phaseDurations: [Int] {
        let totalWeight = phases.reduce(0) { $0 + $1.durationWeight }
        let totalSeconds = duration.seconds
        return phases.map { phase in
            Int(Double(totalSeconds) * (phase.durationWeight / totalWeight))
        }
    }
    
    private var currentPhaseDuration: Int {
        phaseDurations[currentPhaseIndex]
    }
    
    init(theme: GuidedPrayerTheme, duration: GuidedPrayerDuration, onComplete: @escaping (String?) -> Void, onExit: @escaping () -> Void) {
        self.theme = theme
        self.duration = duration
        self.onComplete = onComplete
        self.onExit = onExit
        self._timeRemaining = State(initialValue: duration.seconds)
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Top bar with timer and controls
                sessionTopBar
                
                // Progress timeline
                ProgressTimeline(
                    phases: phases,
                    currentIndex: currentPhaseIndex,
                    phaseProgress: phaseProgress,
                    themeColor: themeColor
                )
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Main content
                ScrollView {
                    VStack(spacing: 20) {
                        // Phase content with animations
                        PhaseContentView(
                            phase: currentPhase,
                            themeColor: themeColor,
                            phaseIndex: currentPhaseIndex
                        )
                        .id(currentPhaseIndex) // Force view recreation for animation
                    }
                    .padding()
                }
                
                // Bottom controls
                sessionBottomBar
            }
            
            // Breathing overlay
            if showBreathing {
                BreathingOverlay(themeColor: themeColor) {
                    withAnimation {
                        showBreathing = false
                    }
                }
            }
        }
        .onAppear {
            startSession()
        }
        .onDisappear {
            timer?.invalidate()
        }
        .alert("End Prayer Session?", isPresented: $showExitConfirmation) {
            Button("Continue Prayer", role: .cancel) { }
            Button("End Session", role: .destructive) {
                timer?.invalidate()
                onExit()
            }
        } message: {
            Text("Your progress will not be saved.")
        }
    }
    
    // MARK: - Top Bar
    
    private var sessionTopBar: some View {
        HStack {
            // Exit button
            Button {
                showExitConfirmation = true
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.white.opacity(0.15)).background(.ultraThinMaterial, in: Circle()))
            }
            
            Spacer()
            
            // Timer
            Text(timeString)
                .font(.system(size: 20, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 2)
            
            Spacer()
            
            // Pause button
            Button {
                togglePause()
            } label: {
                Image(systemName: isPaused ? "play.fill" : "pause.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.white.opacity(0.15)).background(.ultraThinMaterial, in: Circle()))
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    // MARK: - Bottom Bar
    
    private var sessionBottomBar: some View {
        HStack {
            Spacer()
            
            // Breathing toggle
            Button {
                withAnimation(.spring(response: 0.3)) {
                    showBreathing = true
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "wind")
                    Text("Breathe")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Capsule().fill(Color.white.opacity(0.15)).background(.ultraThinMaterial, in: Capsule()))
            }
            
            Spacer()
        }
        .padding()
        .padding(.bottom, 8)
    }
    
    private var timeString: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - Session Logic
    
    private func startSession() {
        phaseProgress = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            guard !isPaused else { return }
            
            if timeRemaining > 0 {
                timeRemaining -= 1
                updatePhaseProgress()
                checkPhaseTransition()
            } else {
                finishSession()
            }
        }
    }
    
    private func updatePhaseProgress() {
        let elapsedInPhase = currentPhaseDuration - getRemainingTimeInPhase()
        phaseProgress = Double(elapsedInPhase) / Double(currentPhaseDuration)
    }
    
    private func getRemainingTimeInPhase() -> Int {
        var remaining = timeRemaining
        for i in (currentPhaseIndex + 1)..<phases.count {
            remaining -= phaseDurations[i]
        }
        return max(0, min(remaining, currentPhaseDuration))
    }
    
    private func checkPhaseTransition() {
        let remainingTimeInPhase = getRemainingTimeInPhase()
        
        if remainingTimeInPhase <= 0 && currentPhaseIndex < phases.count - 1 {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                currentPhaseIndex += 1
                phaseProgress = 0
            }
        }
    }
    
    private func togglePause() {
        isPaused.toggle()
    }
    
    private func finishSession() {
        timer?.invalidate()
        onComplete(nil)
    }
}

// MARK: - Progress Timeline

struct ProgressTimeline: View {
    let phases: [GuidedPrayerPhase]
    let currentIndex: Int
    let phaseProgress: Double
    let themeColor: Color
    
    var body: some View {
        VStack(spacing: 6) {
            // Phase indicator
            HStack {
                Text("Phase \(currentIndex + 1) of \(phases.count)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
                
                Text(phases[currentIndex].title)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            // Progress bar with glow
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 10)
                    
                    // Phase segments
                    HStack(spacing: 3) {
                        ForEach(0..<phases.count, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(segmentColor(for: index))
                                .frame(height: 8)
                                .shadow(color: index == currentIndex ? themeColor.opacity(0.5) : .clear, radius: 4)
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
            .frame(height: 10)
        }
    }
    
    private func segmentColor(for index: Int) -> Color {
        if index < currentIndex {
            return themeColor
        } else if index == currentIndex {
            return themeColor.opacity(0.5 + phaseProgress * 0.5)
        } else {
            return Color.white.opacity(0.08)
        }
    }
}

// MARK: - Phase Content View (Glass Cards)

struct PhaseContentView: View {
    let phase: GuidedPrayerPhase
    let themeColor: Color
    let phaseIndex: Int
    
    @State private var contentOpacity: Double = 0
    @State private var contentOffset: CGFloat = 30
    
    var body: some View {
        VStack(spacing: 20) {
            // Scripture card with glass effect
            VStack(spacing: 10) {
                Image(systemName: "book.fill")
                    .font(.title3)
                    .foregroundColor(themeColor)
                
                Text("\"\(phase.scriptureText)\"")
                    .font(.callout)
                    .italic()
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .shadow(color: .black.opacity(0.2), radius: 1)
                
                Text("— \(phase.scriptureReference)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(themeColor)
            }
            .padding(18)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [themeColor.opacity(0.4), themeColor.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            
            // Main prompt
            Text(phase.prompt)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
                .padding(.vertical, 8)
            
            // Guidance tip with glass effect
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "lightbulb.fill")
                    .font(.subheadline)
                    .foregroundColor(.yellow)
                    .shadow(color: .yellow.opacity(0.5), radius: 4)
                
                Text(phase.tip)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial.opacity(0.7))
            )
        }
        .opacity(contentOpacity)
        .offset(y: contentOffset)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                contentOpacity = 1
                contentOffset = 0
            }
        }
    }
}

// MARK: - Breathing Overlay

struct BreathingOverlay: View {
    let themeColor: Color
    let onDismiss: () -> Void
    
    @State private var breathPhase: BreathPhase = .inhale
    @State private var circleScale: CGFloat = 0.6
    @State private var timer: Timer?
    
    enum BreathPhase: String {
        case inhale = "Breathe In"
        case hold = "Hold"
        case exhale = "Breathe Out"
        
        var duration: Double {
            switch self {
            case .inhale: return 4
            case .hold: return 4
            case .exhale: return 4
            }
        }
        
        var targetScale: CGFloat {
            switch self {
            case .inhale: return 1.0
            case .hold: return 1.0
            case .exhale: return 0.6
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture {
                    timer?.invalidate()
                    onDismiss()
                }
            
            VStack(spacing: 40) {
                // Close button
                HStack {
                    Spacer()
                    Button {
                        timer?.invalidate()
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(Color.white.opacity(0.2)))
                    }
                }
                .padding()
                
                Spacer()
                
                // Breathing circle
                ZStack {
                    // Outer ring
                    Circle()
                        .stroke(themeColor.opacity(0.3), lineWidth: 4)
                        .frame(width: 200, height: 200)
                    
                    // Animated inner circle
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [themeColor.opacity(0.6), themeColor.opacity(0.2)],
                                center: .center,
                                startRadius: 0,
                                endRadius: 100
                            )
                        )
                        .frame(width: 180, height: 180)
                        .scaleEffect(circleScale)
                        .shadow(color: themeColor.opacity(0.4), radius: 20)
                    
                    // Phase text
                    Text(breathPhase.rawValue)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2)
                }
                
                Text("Breathe slowly and center yourself\nin God's presence")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                
                Spacer()
                Spacer()
            }
        }
        .onAppear {
            startBreathingCycle()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func startBreathingCycle() {
        animatePhase(.inhale)
        
        timer = Timer.scheduledTimer(withTimeInterval: 4, repeats: true) { _ in
            switch breathPhase {
            case .inhale:
                animatePhase(.hold)
            case .hold:
                animatePhase(.exhale)
            case .exhale:
                animatePhase(.inhale)
            }
        }
    }
    
    private func animatePhase(_ phase: BreathPhase) {
        breathPhase = phase
        withAnimation(.easeInOut(duration: phase.duration)) {
            circleScale = phase.targetScale
        }
    }
}

// MARK: - Completion View

struct CompletionView: View {
    let theme: GuidedPrayerTheme
    let duration: GuidedPrayerDuration
    let onDone: (String?) -> Void
    let onStartAnother: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    @State private var checkmarkScale: CGFloat = 0
    @State private var checkmarkOpacity: Double = 0
    @State private var contentOpacity: Double = 0
    @State private var showNotes = false
    @State private var sessionNotes = ""
    @State private var particleOpacity: Double = 0
    @State private var ringScale: CGFloat = 0.8
    
    private var themeColor: Color {
        switch theme {
        case .gratitude: return Color(red: 0.95, green: 0.5, blue: 0.55)
        case .repentance: return Color(red: 0.7, green: 0.5, blue: 0.9)
        case .guidance: return Color(red: 0.4, green: 0.65, blue: 1.0)
        case .peace: return Color(red: 0.4, green: 0.8, blue: 0.75)
        case .family: return Color(red: 1.0, green: 0.65, blue: 0.35)
        case .work: return Color(red: 0.85, green: 0.65, blue: 0.45)
        }
    }
    
    private var closingVerse: (reference: String, text: String) {
        theme.closingVerse(for: duration)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 40)
                
                // Celebration animation
                ZStack {
                    // Animated ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [themeColor, themeColor.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 120, height: 120)
                        .scaleEffect(ringScale)
                        .opacity(particleOpacity)
                    
                    // Checkmark
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 70))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 0.3, green: 0.8, blue: 0.5), Color(red: 0.2, green: 0.7, blue: 0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color(red: 0.3, green: 0.8, blue: 0.5).opacity(0.5), radius: 15)
                        .scaleEffect(checkmarkScale)
                        .opacity(checkmarkOpacity)
                }
                .frame(height: 120)
                
                VStack(spacing: 8) {
                    Text("Prayer Complete")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2)
                    
                    Text("You spent \(duration.rawValue) minutes in \(theme.rawValue.lowercased()) prayer")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .opacity(contentOpacity)
                
                // Verse to carry - glass card
                VStack(spacing: 14) {
                    HStack {
                        Image(systemName: "bookmark.fill")
                            .foregroundColor(themeColor)
                        Text("Verse to Carry")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white.opacity(0.7))
                            .textCase(.uppercase)
                            .tracking(1)
                    }
                    
                    VStack(spacing: 10) {
                        Text("\"\(closingVerse.text)\"")
                            .font(.callout)
                            .italic()
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("— \(closingVerse.reference)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(themeColor)
                    }
                }
                .padding(18)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    LinearGradient(
                                        colors: [themeColor.opacity(0.4), themeColor.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                )
                .opacity(contentOpacity)
                
                // Notes toggle
                VStack(spacing: 12) {
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            showNotes.toggle()
                        }
                    } label: {
                        HStack {
                            Image(systemName: showNotes ? "chevron.down" : "chevron.right")
                                .font(.caption)
                            Text("Add Reflection Notes (Optional)")
                                .font(.subheadline)
                        }
                        .foregroundColor(.white.opacity(0.7))
                    }
                    
                    if showNotes {
                        TextEditor(text: $sessionNotes)
                            .frame(height: 100)
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                            .scrollContentBackground(.hidden)
                            .foregroundColor(.white)
                    }
                }
                .opacity(contentOpacity)
                
                // Action buttons
                VStack(spacing: 12) {
                    Button {
                        onDone(sessionNotes.isEmpty ? nil : sessionNotes)
                    } label: {
                        Text("Done")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(themeColor)
                            .cornerRadius(14)
                            .shadow(color: themeColor.opacity(0.4), radius: 8, y: 4)
                    }
                    
                    Button {
                        onStartAnother()
                    } label: {
                        Text("Start Another Prayer")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .opacity(contentOpacity)
                .padding(.top, 8)
                
                Spacer(minLength: 40)
            }
            .padding()
        }
        .onAppear {
            startCompletionAnimation()
        }
    }
    
    private func startCompletionAnimation() {
        // Checkmark springs in
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            checkmarkScale = 1.0
            checkmarkOpacity = 1.0
        }
        
        // Ring expands
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeOut(duration: 0.8)) {
                ringScale = 1.3
                particleOpacity = 1.0
            }
        }
        
        // Ring fades
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeOut(duration: 0.5)) {
                particleOpacity = 0
            }
        }
        
        // Content fades in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeOut(duration: 0.4)) {
                contentOpacity = 1.0
            }
        }
    }
}

// MARK: - Preview

#Preview {
    GuidedPrayerView(viewModel: HubViewModel())
}
