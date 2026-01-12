//
//  RoutineStepPage.swift
//  Bible v1
//
//  Full-screen journal page for individual routine steps
//

import SwiftUI

// MARK: - Routine Step Page

/// A full-screen journal page for displaying and interacting with routine steps
struct RoutineStepPage: View {
    let step: RoutineStep
    let stepNumber: Int
    let totalSteps: Int
    let mode: RoutineMode
    
    // Content bindings
    @Binding var intentionText: String
    @Binding var gratitudeItems: [String]
    @Binding var reflectionText: String
    
    // Breathing state
    @Binding var isBreathing: Bool
    @Binding var breathPhase: BreathPhase
    @Binding var breathCycleCount: Int
    
    // Actions
    var onStartBreathing: (() -> Void)?
    
    @State private var hasAppeared = false
    
    // Focus state for keyboard management
    @FocusState private var focusedField: RoutineFieldFocus?
    
    // Theme and Accessibility
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var accessibility = AccessibilityManager.shared
    
    enum RoutineFieldFocus: Hashable {
        case intention
        case gratitude(Int)
        case reflection
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    // Main content card - compact layout
                    RoutineJournalCard(mode: mode, elevated: false) {
                        VStack(spacing: 16) {
                            // Step header
                            stepHeader
                            
                            // Step-specific content
                            stepContent
                                .id("content")
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : 10)
                }
                .padding(.bottom, 100) // Space for navigation buttons
            }
            .scrollDismissesKeyboard(.interactively)
            .contentShape(Rectangle())
            .onTapGesture {
                focusedField = nil
                hideKeyboard()
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.3)) {
                    hasAppeared = true
                }
            }
            .onChange(of: focusedField) { _, newValue in
                // Auto-scroll to content when field is focused
                if newValue != nil {
                    withAnimation(accessibility.standardAnimation ?? .easeInOut(duration: 0.3)) {
                        proxy.scrollTo("content", anchor: .center)
                    }
                }
            }
        }
    }
    
    // MARK: - Step Header
    
    private var stepHeader: some View {
        HStack(spacing: 12) {
            // Icon - compact
            ZStack {
                Circle()
                    .fill(step.category.color.opacity(0.12))
                    .frame(width: 44, height: 44)
                
                Image(systemName: step.category.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(step.category.color)
            }
            
            // Title and description
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(step.title)
                        .font(.headline)
                        .foregroundColor(themeManager.textColor)
                    
                    Spacer()
                    
                    // Step indicator inline
                    Text("\(stepNumber)/\(totalSteps)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(mode.accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(mode.accentColor.opacity(0.1))
                        )
                }
                
                Text(step.description)
                    .font(.subheadline)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .lineLimit(2)
                
                // Duration badge inline
                if let duration = step.formattedDuration {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(duration)
                            .font(.caption)
                    }
                    .foregroundColor(themeManager.secondaryTextColor)
                }
            }
        }
        .padding(.bottom, 8)
    }
    
    // MARK: - Step Content
    
    @ViewBuilder
    private var stepContent: some View {
        switch step.content {
        case .prayerPrompts(let prompts):
            prayerPromptsContent(prompts)
            
        case .scripture(let reference, let text):
            JournalQuote(text: text, attribution: reference, mode: mode)
            
        case .breathing(let inhale, let hold, let exhale, let cycles):
            breathingContent(inhale: inhale, hold: hold, exhale: exhale, cycles: cycles)
            
        case .gratitudePrompt(let count):
            gratitudeContent(count: count)
            
        case .intentionSetter:
            intentionContent()
            
        case .reflectionQuestions(let questions):
            reflectionContent(questions: questions)
            
        case .text(let text):
            Text(text)
                .font(.subheadline)
                .foregroundColor(themeManager.textColor)
                .multilineTextAlignment(.center)
            
        case .custom(let instructions):
            customContent(instructions: instructions)
        }
    }
    
    // MARK: - Prayer Prompts Content
    
    private func prayerPromptsContent(_ prompts: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(prompts, id: \.self) { prompt in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 10))
                        .foregroundColor(mode.accentColor.opacity(0.7))
                        .padding(.top, 4)
                    Text(prompt)
                        .font(.subheadline)
                        .foregroundColor(themeManager.textColor)
                }
            }
        }
    }
    
    // MARK: - Breathing Content
    
    private func breathingContent(inhale: Int, hold: Int, exhale: Int, cycles: Int) -> some View {
        VStack(spacing: 20) {
            // Breathing circle - compact
            ZStack {
                // Outer ring - static guide
                Circle()
                    .stroke(themeManager.dividerColor, lineWidth: 1.5)
                    .frame(width: 140, height: 140)
                
                // Animated fill circle
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                mode.accentColor.opacity(0.35),
                                mode.accentColor.opacity(0.1)
                            ],
                            center: .center,
                            startRadius: 5,
                            endRadius: breathCircleSize / 2
                        )
                    )
                    .frame(width: breathCircleSize, height: breathCircleSize)
                    .animation(breathAnimation(inhale: inhale, hold: hold, exhale: exhale), value: breathPhase)
                
                // Center content
                VStack(spacing: 4) {
                    Text(isBreathing ? breathPhase.instruction : "Tap to Begin")
                        .font(.headline)
                        .foregroundColor(mode.accentColor)
                        .animation(.easeInOut(duration: 0.2), value: breathPhase)
                    
                    if isBreathing {
                        Text("\(breathCycleCount + 1)/\(cycles)")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                }
            }
            .frame(width: 140, height: 140)
            .contentShape(Circle())
            .onTapGesture {
                if !isBreathing {
                    onStartBreathing?()
                }
            }
            
            // Breathing pattern info - compact horizontal
            HStack(spacing: 16) {
                breathingPhaseLabel("Inhale", seconds: inhale, icon: "arrow.up", isActive: isBreathing && breathPhase == .inhale)
                breathingPhaseLabel("Hold", seconds: hold, icon: "pause.fill", isActive: isBreathing && breathPhase == .hold)
                breathingPhaseLabel("Exhale", seconds: exhale, icon: "arrow.down", isActive: isBreathing && breathPhase == .exhale)
            }
            
            // Scripture - compact
            VStack(spacing: 2) {
                Text("\"Be still, and know that I am God.\"")
                    .font(.caption)
                    .italic()
                    .foregroundColor(themeManager.secondaryTextColor)
                Text("— Psalm 46:10")
                    .font(.caption2)
                    .foregroundColor(mode.accentColor)
            }
            .padding(.top, 8)
        }
    }
    
    private func breathingPhaseLabel(_ label: String, seconds: Int, icon: String, isActive: Bool) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: isActive ? .bold : .regular))
            Text("\(seconds)s")
                .font(.caption)
                .fontWeight(isActive ? .bold : .regular)
        }
        .foregroundColor(isActive ? mode.accentColor : themeManager.secondaryTextColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(isActive ? mode.accentColor.opacity(0.15) : themeManager.cardBackgroundColor)
        )
        .animation(.easeInOut(duration: 0.2), value: isActive)
    }
    
    private var breathCircleSize: CGFloat {
        switch breathPhase {
        case .inhale: return 120
        case .hold: return 120
        case .exhale: return 50
        }
    }
    
    private func breathAnimation(inhale: Int, hold: Int, exhale: Int) -> Animation {
        switch breathPhase {
        case .inhale:
            return .easeIn(duration: Double(inhale))
        case .hold:
            return .easeInOut(duration: 0.3)
        case .exhale:
            return .easeOut(duration: Double(exhale))
        }
    }
    
    // MARK: - Gratitude Content
    
    private func gratitudeContent(count: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(0..<count, id: \.self) { index in
                HStack(spacing: 10) {
                    // Number badge - compact
                    Text("\(index + 1)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(Color.pink))
                    
                    // Text field
                    JournalTextField(
                        placeholder: "I'm grateful for...",
                        text: gratitudeBinding(for: index),
                        mode: mode,
                        isFocused: focusedField == .gratitude(index),
                        onFocus: { focusedField = .gratitude(index) }
                    )
                }
            }
        }
    }
    
    private func gratitudeBinding(for index: Int) -> Binding<String> {
        Binding(
            get: {
                index < gratitudeItems.count ? gratitudeItems[index] : ""
            },
            set: { newValue in
                while gratitudeItems.count <= index {
                    gratitudeItems.append("")
                }
                gratitudeItems[index] = newValue
            }
        )
    }
    
    // MARK: - Intention Content
    
    private func intentionContent() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            JournalTextEditor(
                placeholder: "e.g., 'Be patient with others' or 'Trust God's timing'",
                text: $intentionText,
                mode: mode,
                minHeight: 70,
                isFocused: focusedField == .intention,
                onFocus: { focusedField = .intention }
            )
        }
    }
    
    // MARK: - Reflection Content
    
    private func reflectionContent(questions: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Questions - compact list
            VStack(alignment: .leading, spacing: 8) {
                ForEach(questions, id: \.self) { question in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 5))
                            .foregroundColor(mode.accentColor)
                            .padding(.top, 6)
                        Text(question)
                            .font(.subheadline)
                            .foregroundColor(themeManager.textColor)
                    }
                }
            }
            
            // Reflection text area
            JournalTextEditor(
                placeholder: "Write your thoughts here...",
                text: $reflectionText,
                mode: mode,
                minHeight: 60,
                isFocused: focusedField == .reflection,
                onFocus: { focusedField = .reflection }
            )
        }
    }
    
    // MARK: - Custom Content
    
    private func customContent(instructions: String) -> some View {
        Text(instructions)
            .font(.subheadline)
            .foregroundColor(themeManager.textColor)
            .multilineTextAlignment(.center)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.cardBackgroundColor)
            )
    }
}

// MARK: - Step Progress Timeline

/// A vertical timeline showing step progress
struct StepProgressTimeline: View {
    let steps: [RoutineStep]
    let currentStepIndex: Int
    let mode: RoutineMode
    
    @ObservedObject private var accessibility = AccessibilityManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                HStack(spacing: 12) {
                    // Timeline node
                    VStack(spacing: 0) {
                        if index > 0 {
                            Rectangle()
                                .fill(index <= currentStepIndex ? mode.accentColor : Color.Journal.sepia.opacity(0.2))
                                .frame(width: 2, height: 20)
                        }
                        
                        ZStack {
                            Circle()
                                .fill(index < currentStepIndex ? mode.accentColor : Color.Journal.cardBackground)
                                .frame(width: 24, height: 24)
                            
                            Circle()
                                .strokeBorder(
                                    index <= currentStepIndex ? mode.accentColor : Color.Journal.sepia.opacity(0.3),
                                    lineWidth: index == currentStepIndex ? 2 : 1
                                )
                                .frame(width: 24, height: 24)
                            
                            if index < currentStepIndex {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                            } else {
                                Text("\(index + 1)")
                                    .font(accessibility.captionFont(size: 10))
                                    .foregroundColor(index == currentStepIndex ? mode.accentColor : Color.Journal.mutedText)
                            }
                        }
                        
                        if index < steps.count - 1 {
                            Rectangle()
                                .fill(index < currentStepIndex ? mode.accentColor : Color.Journal.sepia.opacity(0.2))
                                .frame(width: 2, height: 20)
                        }
                    }
                    
                    // Step info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(step.title)
                            .font(accessibility.captionFont())
                            .fontWeight(index == currentStepIndex ? .semibold : .regular)
                            .foregroundColor(index == currentStepIndex ? Color.Journal.inkBrown : Color.Journal.mutedText)
                        
                        if let duration = step.formattedDuration {
                            Text(duration)
                                .font(accessibility.captionFont(size: 11))
                                .foregroundColor(Color.Journal.mutedText.opacity(0.7))
                        }
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 4)
            }
        }
    }
}

// MARK: - Preview

#Preview("Step Page") {
    RoutineStepPage(
        step: RoutineStepLibrary.morningPrayer,
        stepNumber: 1,
        totalSteps: 4,
        mode: .morning,
        intentionText: .constant(""),
        gratitudeItems: .constant(["", "", ""]),
        reflectionText: .constant(""),
        isBreathing: .constant(false),
        breathPhase: .constant(.inhale),
        breathCycleCount: .constant(0)
    )
    .background(LinearGradient.journalGradient(for: .morning))
}

