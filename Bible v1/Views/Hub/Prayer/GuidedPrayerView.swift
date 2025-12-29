//
//  GuidedPrayerView.swift
//  Bible v1
//
//  Guided Prayer - Timed prayer sessions with themed prompts
//

import SwiftUI

struct GuidedPrayerView: View {
    @ObservedObject var viewModel: HubViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTheme: GuidedPrayerTheme = .gratitude
    @State private var selectedDuration: GuidedPrayerDuration = .fiveMinutes
    @State private var isSessionActive = false
    @State private var sessionNotes: String = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor.ignoresSafeArea()
                
                if isSessionActive {
                    GuidedPrayerSessionView(
                        theme: selectedTheme,
                        duration: selectedDuration,
                        onComplete: { notes in
                            viewModel.recordGuidedSession(
                                theme: selectedTheme,
                                duration: selectedDuration.seconds,
                                notes: notes
                            )
                            isSessionActive = false
                        },
                        onCancel: {
                            isSessionActive = false
                        }
                    )
                } else {
                    setupView
                }
            }
            .navigationTitle("Guided Prayer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !isSessionActive {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") { dismiss() }
                    }
                }
            }
        }
    }
    
    private var setupView: some View {
        ScrollView {
            VStack(spacing: 28) {
                // Header illustration
                VStack(spacing: 12) {
                    Image(systemName: "hands.sparkles")
                        .font(.system(size: 50))
                        .foregroundStyle(themeManager.accentGradient)
                    
                    Text("Find Your Peace")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.textColor)
                    
                    Text("Choose a theme and duration for your guided prayer time")
                        .font(.subheadline)
                        .foregroundColor(themeManager.secondaryTextColor)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Theme Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Prayer Theme")
                        .font(.headline)
                        .foregroundColor(themeManager.textColor)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(GuidedPrayerTheme.allCases) { theme in
                            ThemeCard(
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
                VStack(alignment: .leading, spacing: 12) {
                    Text("Duration")
                        .font(.headline)
                        .foregroundColor(themeManager.textColor)
                    
                    HStack(spacing: 12) {
                        ForEach(GuidedPrayerDuration.allCases) { duration in
                            DurationPill(
                                duration: duration,
                                isSelected: selectedDuration == duration
                            ) {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedDuration = duration
                                }
                            }
                        }
                    }
                }
                
                // Session stats
                VStack(spacing: 8) {
                    HStack {
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
                
                // Start button
                Button {
                    withAnimation {
                        isSessionActive = true
                    }
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Begin Prayer")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(themeManager.accentGradient)
                    .cornerRadius(16)
                }
                .padding(.top, 8)
            }
            .padding()
        }
    }
}

// MARK: - Theme Card

struct ThemeCard: View {
    let theme: GuidedPrayerTheme
    let isSelected: Bool
    let action: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: theme.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : themeColor)
                
                Text(theme.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : themeManager.textColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                isSelected
                    ? AnyShapeStyle(LinearGradient(colors: [themeColor, themeColor.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    : AnyShapeStyle(themeManager.cardBackgroundColor)
            )
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.clear : themeManager.dividerColor, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var themeColor: Color {
        switch theme {
        case .gratitude: return .pink
        case .repentance: return .teal
        case .guidance: return ThemeManager.shared.accentColor
        case .peace: return .teal
        case .family: return .orange
        case .work: return .brown
        }
    }
}

// MARK: - Duration Pill

struct DurationPill: View {
    let duration: GuidedPrayerDuration
    let isSelected: Bool
    let action: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: action) {
            Text(duration.displayName)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : themeManager.textColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(isSelected ? themeManager.accentColor : themeManager.cardBackgroundColor)
                .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Stat Box

struct StatBox: View {
    let value: String
    let label: String
    let color: Color
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(themeManager.secondaryTextColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(10)
    }
}

// MARK: - Guided Prayer Session View

struct GuidedPrayerSessionView: View {
    let theme: GuidedPrayerTheme
    let duration: GuidedPrayerDuration
    let onComplete: (String?) -> Void
    let onCancel: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    @State private var currentPromptIndex = 0
    @State private var timeRemaining: Int
    @State private var isBreathing = false
    @State private var breathPhase: BreathPhase = .inhale
    @State private var sessionNotes = ""
    @State private var showCompletion = false
    @State private var timer: Timer?
    @State private var breathTimer: Timer?
    
    enum BreathPhase {
        case inhale, hold, exhale
        
        var instruction: String {
            switch self {
            case .inhale: return "Breathe In"
            case .hold: return "Hold"
            case .exhale: return "Breathe Out"
            }
        }
        
        var duration: Double {
            switch self {
            case .inhale: return 4
            case .hold: return 4
            case .exhale: return 4
            }
        }
    }
    
    init(theme: GuidedPrayerTheme, duration: GuidedPrayerDuration, onComplete: @escaping (String?) -> Void, onCancel: @escaping () -> Void) {
        self.theme = theme
        self.duration = duration
        self.onComplete = onComplete
        self.onCancel = onCancel
        self._timeRemaining = State(initialValue: duration.seconds)
    }
    
    private var prompts: [String] { theme.prompts }
    private var promptInterval: Int {
        max(duration.seconds / prompts.count, 20)
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [themeColor.opacity(0.2), themeManager.backgroundColor],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            if showCompletion {
                completionView
            } else {
                sessionView
            }
        }
        .onAppear {
            startSession()
        }
        .onDisappear {
            timer?.invalidate()
            breathTimer?.invalidate()
        }
    }
    
    private var sessionView: some View {
        VStack(spacing: 30) {
            // Timer
            HStack {
                Button {
                    timer?.invalidate()
                    breathTimer?.invalidate()
                    onCancel()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                
                Spacer()
                
                Text(timeString)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.textColor)
                    .monospacedDigit()
                
                Spacer()
                
                // Breathing toggle
                Button {
                    withAnimation {
                        isBreathing.toggle()
                        if isBreathing {
                            startBreathingExercise()
                        } else {
                            breathTimer?.invalidate()
                        }
                    }
                } label: {
                    Image(systemName: isBreathing ? "wind.circle.fill" : "wind.circle")
                        .font(.title2)
                        .foregroundColor(isBreathing ? themeColor : themeManager.secondaryTextColor)
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Breathing indicator or prompt
            if isBreathing {
                breathingView
            } else {
                promptView
            }
            
            Spacer()
            
            // Progress dots
            HStack(spacing: 8) {
                ForEach(0..<prompts.count, id: \.self) { index in
                    Circle()
                        .fill(index <= currentPromptIndex ? themeColor : themeManager.dividerColor)
                        .frame(width: 8, height: 8)
                }
            }
            
            // Navigation buttons
            HStack(spacing: 20) {
                if currentPromptIndex > 0 {
                    Button {
                        withAnimation {
                            currentPromptIndex -= 1
                        }
                    } label: {
                        Image(systemName: "chevron.left.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                }
                
                Spacer()
                
                if currentPromptIndex < prompts.count - 1 {
                    Button {
                        withAnimation {
                            currentPromptIndex += 1
                        }
                    } label: {
                        Image(systemName: "chevron.right.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(themeColor)
                    }
                } else {
                    Button {
                        finishSession()
                    } label: {
                        Text("Finish")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 14)
                            .background(themeColor)
                            .cornerRadius(25)
                    }
                }
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 20)
        }
    }
    
    private var promptView: some View {
        VStack(spacing: 20) {
            Image(systemName: theme.icon)
                .font(.system(size: 50))
                .foregroundColor(themeColor)
            
            Text(prompts[currentPromptIndex])
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(themeManager.textColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
                .transition(.opacity.combined(with: .scale))
                .id(currentPromptIndex)
        }
    }
    
    private var breathingView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(themeColor.opacity(0.3), lineWidth: 4)
                    .frame(width: 150, height: 150)
                
                Circle()
                    .fill(themeColor.opacity(0.2))
                    .frame(width: breathPhase == .inhale ? 150 : (breathPhase == .hold ? 130 : 100), height: breathPhase == .inhale ? 150 : (breathPhase == .hold ? 130 : 100))
                    .animation(.easeInOut(duration: breathPhase.duration), value: breathPhase)
                
                Text(breathPhase.instruction)
                    .font(.headline)
                    .foregroundColor(themeColor)
            }
            
            Text("Breathe slowly and center yourself in God's presence")
                .font(.subheadline)
                .foregroundColor(themeManager.secondaryTextColor)
                .multilineTextAlignment(.center)
        }
    }
    
    private var completionView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 70))
                .foregroundStyle(
                    LinearGradient(colors: [.green, .teal], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            
            Text("Prayer Complete")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(themeManager.textColor)
            
            Text("You spent \(duration.rawValue) minutes in prayer. Well done!")
                .font(.subheadline)
                .foregroundColor(themeManager.secondaryTextColor)
                .multilineTextAlignment(.center)
            
            // Notes field
            VStack(alignment: .leading, spacing: 8) {
                Text("Any reflections? (Optional)")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
                
                TextEditor(text: $sessionNotes)
                    .frame(height: 100)
                    .padding(8)
                    .background(themeManager.cardBackgroundColor)
                    .cornerRadius(10)
                    .scrollContentBackground(.hidden)
            }
            .padding(.horizontal)
            
            Button {
                onComplete(sessionNotes.isEmpty ? nil : sessionNotes)
            } label: {
                Text("Done")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(themeColor)
                    .cornerRadius(14)
            }
            .padding(.horizontal)
        }
        .padding()
    }
    
    private var themeColor: Color {
        switch theme {
        case .gratitude: return .pink
        case .repentance: return .teal
        case .guidance: return ThemeManager.shared.accentColor
        case .peace: return .teal
        case .family: return .orange
        case .work: return .brown
        }
    }
    
    private var timeString: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func startSession() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
                
                // Auto-advance prompts
                let elapsed = duration.seconds - timeRemaining
                let newIndex = min(elapsed / promptInterval, prompts.count - 1)
                if newIndex != currentPromptIndex {
                    withAnimation {
                        currentPromptIndex = newIndex
                    }
                }
            } else {
                finishSession()
            }
        }
    }
    
    private func startBreathingExercise() {
        breathPhase = .inhale
        breathTimer = Timer.scheduledTimer(withTimeInterval: 4, repeats: true) { _ in
            withAnimation {
                switch breathPhase {
                case .inhale: breathPhase = .hold
                case .hold: breathPhase = .exhale
                case .exhale: breathPhase = .inhale
                }
            }
        }
    }
    
    private func finishSession() {
        timer?.invalidate()
        breathTimer?.invalidate()
        withAnimation {
            showCompletion = true
        }
    }
}

#Preview {
    GuidedPrayerView(viewModel: HubViewModel())
}


