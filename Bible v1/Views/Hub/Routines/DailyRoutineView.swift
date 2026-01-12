//
//  DailyRoutineView.swift
//  Bible v1
//
//  Redesigned Daily Routine - Journaling-aesthetic spiritual practice
//  with customizable steps, streak tracking, and Hub integration
//

import SwiftUI

struct DailyRoutineView: View {
    @ObservedObject var viewModel: HubViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var accessibility = AccessibilityManager.shared
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    
    @State private var currentMode: RoutineMode = .current
    @State private var selectedConfiguration: RoutineConfiguration?
    @State private var currentStepIndex = 0
    @State private var showCompletion = false
    @State private var showStepEditor = false
    @State private var showModeSelector = false
    @State private var showRoutineManager = false
    @State private var routineStartTime: Date = Date()
    
    // Step-specific state
    @State private var intentionText = ""
    @State private var gratitudeItems: [String] = ["", "", ""]
    @State private var reflectionTexts: [UUID: String] = [:]  // Per-step reflection storage
    @State private var isBreathing = false
    @State private var breathPhase: BreathPhase = .inhale
    @State private var breathTimer: Timer?
    @State private var breathCycleCount = 0
    
    // Keyboard management
    @FocusState private var isAnyFieldFocused: Bool
    
    // Mood tracking
    @State private var moodAtStart: MoodLevel?
    @State private var moodAtEnd: MoodLevel?
    @State private var showStartMoodPicker = true
    
    // MARK: - Computed Properties
    
    private var configuration: RoutineConfiguration {
        selectedConfiguration ?? viewModel.getDefaultRoutine(for: currentMode) ?? RoutineStepLibrary.defaultMorningRoutine
    }
    
    private var enabledSteps: [RoutineStep] {
        configuration.enabledSteps
    }
    
    private var currentStep: RoutineStep? {
        guard currentStepIndex < enabledSteps.count else { return nil }
        return enabledSteps[currentStepIndex]
    }
    
    private var isRoutineComplete: Bool {
        viewModel.didCompleteRoutineToday(mode: currentMode)
    }
    
    private var routineStreak: RoutineStreak {
        viewModel.getRoutineStreak(for: currentMode)
    }
    
    private var progress: Double {
        guard !enabledSteps.isEmpty else { return 0 }
        return Double(currentStepIndex) / Double(enabledSteps.count)
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Journal-style gradient background
                journalBackground
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        hideKeyboard()
                    }
                
                if showStartMoodPicker && !isRoutineComplete {
                    moodCheckInView
                } else if isRoutineComplete && !showCompletion {
                    alreadyCompletedView
                } else if showCompletion {
                    completionView
                } else {
                    routineContent
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        breathTimer?.invalidate()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color.Journal.mutedText)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color.Journal.cardBackground))
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text(configuration.name)
                        .font(accessibility.headingFont(size: 17))
                        .foregroundColor(Color.Journal.inkBrown)
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        // Only show "Update Mood" when not already on mood picker and not completed
                        if !showStartMoodPicker && !showCompletion && !isRoutineComplete {
                            Button {
                                withAnimation(.spring(response: 0.4)) {
                                    showStartMoodPicker = true
                                }
                            } label: {
                                Label("Update Mood", systemImage: "face.smiling")
                            }
                            
                            Divider()
                        }
                        
                        Button {
                            showModeSelector = true
                        } label: {
                            Label("Switch Mode", systemImage: "arrow.triangle.2.circlepath")
                        }
                        
                        Button {
                            showRoutineManager = true
                        } label: {
                            Label("My Routines", systemImage: "list.bullet")
                        }
                        
                        Button {
                            showStepEditor = true
                        } label: {
                            Label("Customize Steps", systemImage: "slider.horizontal.3")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color.Journal.mutedText)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color.Journal.cardBackground))
                    }
                }
            }
            .onAppear {
                routineStartTime = Date()
            }
            .onDisappear {
                breathTimer?.invalidate()
            }
            .sheet(isPresented: $showStepEditor) {
                RoutineStepEditorView(
                    configuration: configuration,
                    mode: currentMode,
                    onSave: { newConfig in
                        selectedConfiguration = newConfig
                        viewModel.updateRoutineConfiguration(newConfig)
                    }
                )
            }
            .sheet(isPresented: $showRoutineManager) {
                RoutineManagerView(viewModel: viewModel, selectedConfiguration: $selectedConfiguration)
            }
            .confirmationDialog("Choose Routine", isPresented: $showModeSelector, titleVisibility: .visible) {
                Button("Morning Routine") {
                    withAnimation(.spring(response: 0.4)) {
                        currentMode = .morning
                        selectedConfiguration = viewModel.getDefaultRoutine(for: .morning)
                        currentStepIndex = 0
                    }
                }
                Button("Evening Routine") {
                    withAnimation(.spring(response: 0.4)) {
                        currentMode = .evening
                        selectedConfiguration = viewModel.getDefaultRoutine(for: .evening)
                        currentStepIndex = 0
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
    
    // MARK: - Background
    
    private var journalBackground: some View {
        ZStack {
            // Base paper color
            Color.Journal.paper
            
            // Mode-specific gradient
            LinearGradient.journalGradient(for: currentMode)
                .opacity(0.6)
            
            // Subtle texture
            GeometryReader { geo in
                Canvas { context, size in
                    // Add subtle noise pattern
                    for _ in 0..<100 {
                        let x = CGFloat.random(in: 0...size.width)
                        let y = CGFloat.random(in: 0...size.height)
                        let rect = CGRect(x: x, y: y, width: 1, height: 1)
                        context.fill(Path(ellipseIn: rect), with: .color(Color.Journal.sepia.opacity(0.02)))
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.5), value: currentMode)
    }
    
    // MARK: - Mood Check-In View
    
    private var moodCheckInView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Header - centered
            VStack(spacing: 8) {
                Image(systemName: "face.smiling")
                    .font(.system(size: 36))
                    .foregroundColor(currentMode.accentColor)
                
                Text("How are you feeling?")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.textColor)
                
                Text("Check in before starting")
                    .font(.subheadline)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            .frame(maxWidth: .infinity)
            
            // Mood options - centered grid
            HStack(spacing: 8) {
                ForEach(MoodLevel.allCases, id: \.self) { mood in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            moodAtStart = mood
                        }
                        HapticManager.shared.selection()
                    } label: {
                        VStack(spacing: 4) {
                            Text(mood.emoji)
                                .font(.system(size: 26))
                            
                            Text(mood.displayName)
                                .font(.caption2)
                                .fontWeight(moodAtStart == mood ? .semibold : .regular)
                                .foregroundColor(moodAtStart == mood ? currentMode.accentColor : themeManager.secondaryTextColor)
                        }
                        .frame(width: 58)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(moodAtStart == mood ? currentMode.accentColor.opacity(0.15) : themeManager.cardBackgroundColor)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .strokeBorder(moodAtStart == mood ? currentMode.accentColor : Color.clear, lineWidth: 1.5)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: moodAtStart)
                }
            }
            .padding(.horizontal, 16)
            
            Spacer()
            
            // Continue buttons
            VStack(spacing: 8) {
                Button {
                    HapticManager.shared.lightImpact()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showStartMoodPicker = false
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(moodAtStart != nil ? "Continue" : "Skip")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        if moodAtStart != nil {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 12, weight: .semibold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                moodAtStart != nil
                                    ? currentMode.accentColor
                                    : themeManager.secondaryTextColor.opacity(0.6)
                            )
                    )
                }
                .animation(.easeInOut(duration: 0.2), value: moodAtStart)
                
                if moodAtStart == nil {
                    Text("Update anytime from the menu")
                        .font(.caption2)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
    }
    
    // MARK: - Already Completed View
    
    private var alreadyCompletedView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Completion stamp
            JournalCompletionStamp(mode: currentMode)
            
            Text("\(currentMode.displayName) Routine Complete!")
                .font(accessibility.headingFont(size: 22))
                .foregroundColor(Color.Journal.inkBrown)
            
            Text(currentMode == .morning
                 ? "You've already completed your morning routine today. Come back tomorrow for a fresh start!"
                 : "You've already completed your evening reflection. Rest well and let tomorrow be a new day of grace.")
                .font(accessibility.bodyFont())
                .foregroundColor(Color.Journal.mutedText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if currentMode == .morning, let intention = viewModel.dailyIntention {
                intentionCard(intention)
            }
            
            // Streak info
            if routineStreak.currentStreak > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    
                    Text("\(routineStreak.currentStreak)-day streak!")
                        .font(accessibility.bodyFont(size: 15))
                        .fontWeight(.medium)
                        .foregroundColor(Color.Journal.inkBrown)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color.orange.opacity(0.1))
                )
            }
            
            Spacer()
            
            // Option to switch mode
            if !otherModeComplete {
                Button {
                    withAnimation(accessibility.standardAnimation ?? .spring(response: 0.4)) {
                        currentMode = currentMode == .morning ? .evening : .morning
                        selectedConfiguration = viewModel.getDefaultRoutine(for: currentMode)
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: currentMode == .morning ? "moon.stars.fill" : "sunrise.fill")
                        Text("Start \(currentMode == .morning ? "Evening" : "Morning") Routine")
                    }
                    .font(accessibility.bodyFont(size: 15))
                    .fontWeight(.medium)
                    .foregroundColor(currentMode == .morning ? Color.Journal.Evening.primary : Color.Journal.Morning.primary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill((currentMode == .morning ? Color.Journal.Evening.primary : Color.Journal.Morning.primary).opacity(0.1))
                    )
                }
            }
            
            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(accessibility.headingFont(size: 17))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(currentMode.accentColor)
                    )
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    private var otherModeComplete: Bool {
        currentMode == .morning ? viewModel.didCompleteRoutineToday(mode: .evening) : viewModel.didCompleteRoutineToday(mode: .morning)
    }
    
    private func intentionCard(_ intention: String) -> some View {
        RoutineJournalCard(mode: currentMode) {
            VStack(spacing: 8) {
                Text("Today's Intention")
                    .font(accessibility.captionFont())
                    .foregroundColor(Color.Journal.mutedText)
                
                Text("\"\(intention)\"")
                    .font(accessibility.headingFont(size: 17))
                    .foregroundColor(currentMode.accentColor)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 40)
    }
    
    // MARK: - Routine Content
    
    private var routineContent: some View {
        VStack(spacing: 0) {
            // Progress header
            RoutineProgressHeader(
                configuration: configuration,
                currentStepIndex: currentStepIndex,
                streak: routineStreak
            )
            .padding(.horizontal, 16)
            .padding(.top, 8)
            
            // Step content
            TabView(selection: $currentStepIndex) {
                ForEach(Array(enabledSteps.enumerated()), id: \.element.id) { index, step in
                    RoutineStepPage(
                        step: step,
                        stepNumber: index + 1,
                        totalSteps: enabledSteps.count,
                        mode: currentMode,
                        intentionText: $intentionText,
                        gratitudeItems: $gratitudeItems,
                        reflectionText: reflectionBinding(for: step.id),
                        isBreathing: $isBreathing,
                        breathPhase: $breathPhase,
                        breathCycleCount: $breathCycleCount,
                        onStartBreathing: {
                            if case .breathing(let inhale, let hold, let exhale, let cycles) = step.content {
                                startBreathing(inhale: inhale, hold: hold, exhale: exhale, cycles: cycles)
                            }
                        }
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        hideKeyboard()
                    }
                    .font(accessibility.bodyFont())
                    .fontWeight(.medium)
                }
            }
            
            // Navigation buttons
            RoutineNavigationButtons(
                currentStepIndex: currentStepIndex,
                totalSteps: enabledSteps.count,
                mode: currentMode,
                canProceed: true,
                onBack: {
                    withAnimation(.spring(response: 0.3)) {
                        currentStepIndex = max(0, currentStepIndex - 1)
                    }
                },
                onNext: {
                    withAnimation(.spring(response: 0.3)) {
                        currentStepIndex = min(enabledSteps.count - 1, currentStepIndex + 1)
                    }
                },
                onComplete: {
                    completeRoutine()
                }
            )
        }
    }
    
    // MARK: - Completion View
    
    private var completionView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Animated completion stamp
            JournalCompletionStamp(mode: currentMode)
                .padding(.bottom, 8)
            
            Text(currentMode == .morning ? "You're Ready!" : "Sweet Dreams")
                .font(accessibility.headingFont(size: 28))
                .foregroundColor(Color.Journal.inkBrown)
            
            Text(currentMode == .morning
                 ? "You've completed your morning routine. Go forth and shine God's light today!"
                 : "You've completed your evening routine. May God grant you peaceful, restful sleep.")
                .font(accessibility.bodyFont())
                .foregroundColor(Color.Journal.mutedText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Summary cards
            completionSummary
            
            // Updated streak
            if routineStreak.currentStreak > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    
                    Text("\(routineStreak.currentStreak + 1)-day streak!")
                        .font(accessibility.headingFont(size: 17))
                        .foregroundColor(Color.Journal.inkBrown)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(Color.orange.opacity(0.15))
                )
            }
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Text(currentMode == .morning ? "Start My Day" : "Good Night")
                    .font(accessibility.headingFont(size: 17))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                LinearGradient(
                                    colors: [currentMode.accentColor, currentMode.secondaryAccent],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    @ViewBuilder
    private var completionSummary: some View {
        VStack(spacing: 12) {
            if currentMode == .morning && !intentionText.isEmpty {
                RoutineJournalCard(mode: currentMode) {
                    VStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "target")
                                .foregroundColor(.green)
                            Text("Your Intention")
                                .font(accessibility.captionFont())
                                .foregroundColor(Color.Journal.mutedText)
                        }
                        
                        Text("\"\(intentionText)\"")
                            .font(accessibility.bodyFont(size: 15))
                            .fontWeight(.medium)
                            .foregroundColor(Color.Journal.inkBrown)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 40)
            }
            
            let filledGratitude = gratitudeItems.filter { !$0.isEmpty }
            if !filledGratitude.isEmpty {
                RoutineJournalCard(mode: currentMode) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.pink)
                            Text("Gratitude")
                                .font(accessibility.captionFont())
                                .foregroundColor(Color.Journal.mutedText)
                        }
                        
                        ForEach(filledGratitude, id: \.self) { item in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 8))
                                    .foregroundColor(.pink.opacity(0.6))
                                    .padding(.top, 5)
                                
                                Text(item)
                                    .font(accessibility.captionFont())
                                    .foregroundColor(Color.Journal.inkBrown)
                            }
                        }
                    }
                }
                .padding(.horizontal, 40)
            }
        }
    }
    
    // MARK: - Actions
    
    private func startBreathing(inhale: Int, hold: Int, exhale: Int, cycles: Int) {
        isBreathing = true
        breathCycleCount = 0
        breathPhase = .inhale
        
        let cycleDuration = Double(inhale + hold + exhale)
        var elapsed: Double = -1 // Start at -1 so first tick puts us at 0 (beginning of inhale)
        
        // Haptic feedback at start
        HapticManager.shared.mediumImpact()
        
        breathTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                elapsed += 1
                let positionInCycle = Int(elapsed) % Int(cycleDuration)
                
                let previousPhase = breathPhase
                
                // Determine current phase based on position in cycle
                if positionInCycle < inhale {
                    breathPhase = .inhale
                } else if positionInCycle < inhale + hold {
                    breathPhase = .hold
                } else {
                    breathPhase = .exhale
                }
                
                // Haptic on phase change for better guidance
                if previousPhase != breathPhase {
                    switch breathPhase {
                    case .inhale:
                        HapticManager.shared.mediumImpact()
                    case .hold:
                        HapticManager.shared.lightImpact()
                    case .exhale:
                        HapticManager.shared.softImpact()
                    }
                }
                
                // Track cycle completion
                if positionInCycle == 0 && elapsed > 0 {
                    breathCycleCount += 1
                    
                    // Check if all cycles are complete
                    if breathCycleCount >= cycles {
                        breathTimer?.invalidate()
                        breathTimer = nil
                        
                        // Brief delay before resetting to show completion
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            isBreathing = false
                            HapticManager.shared.success()
                        }
                    }
                }
            }
        }
        
        // Fire immediately to start the first phase
        breathTimer?.fire()
    }
    
    // Helper to create binding for per-step reflection text
    private func reflectionBinding(for stepId: UUID) -> Binding<String> {
        Binding(
            get: { reflectionTexts[stepId] ?? "" },
            set: { reflectionTexts[stepId] = $0 }
        )
    }
    
    // Combine all reflection texts into one string
    private var combinedReflectionNotes: String? {
        let allReflections = reflectionTexts.values.filter { !$0.isEmpty }
        return allReflections.isEmpty ? nil : allReflections.joined(separator: "\n\n")
    }
    
    private func completeRoutine() {
        breathTimer?.invalidate()
        
        // Record completion with full data sync
        viewModel.recordRoutineCompletion(
            configuration: configuration,
            startTime: routineStartTime,
            stepsCompleted: enabledSteps.count,
            intentionText: intentionText.isEmpty ? nil : intentionText,
            gratitudeItems: gratitudeItems.filter { !$0.isEmpty },
            reflectionNotes: combinedReflectionNotes,
            moodAtStart: moodAtStart,
            moodAtEnd: moodAtEnd
        )
        
        // Success haptic
        HapticManager.shared.success()
        
        withAnimation(.spring(response: 0.5)) {
            showCompletion = true
        }
    }
}

// MARK: - Breath Phase

enum BreathPhase: Equatable, Sendable {
    case inhale
    case hold
    case exhale
    
    var instruction: String {
        switch self {
        case .inhale: return "Breathe In"
        case .hold: return "Hold"
        case .exhale: return "Breathe Out"
        }
    }
}

// MARK: - Step Editor View (Updated)

struct RoutineStepEditorView: View {
    let configuration: RoutineConfiguration
    let mode: RoutineMode
    let onSave: (RoutineConfiguration) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var accessibility = AccessibilityManager.shared
    
    @State private var editedSteps: [RoutineStep]
    @State private var showAddStep = false
    
    init(configuration: RoutineConfiguration, mode: RoutineMode, onSave: @escaping (RoutineConfiguration) -> Void) {
        self.configuration = configuration
        self.mode = mode
        self.onSave = onSave
        self._editedSteps = State(initialValue: configuration.steps)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.Journal.paper.ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        hideKeyboard()
                    }
                
                List {
                    Section {
                        ForEach(editedSteps) { step in
                            stepRow(step)
                        }
                        .onMove(perform: moveStep)
                        .onDelete(perform: deleteStep)
                    } header: {
                        Text("Routine Steps")
                            .font(accessibility.captionFont())
                    } footer: {
                        Text("Drag to reorder, swipe to delete")
                            .font(accessibility.captionFont(size: 11))
                    }
                    
                    Section {
                        Button {
                            showAddStep = true
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Step")
                                    .font(accessibility.bodyFont())
                            }
                            .foregroundColor(mode.accentColor)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Customize Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .font(accessibility.bodyFont())
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveConfiguration()
                    }
                    .font(accessibility.bodyFont())
                    .fontWeight(.semibold)
                }
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                        .font(accessibility.bodyFont())
                }
            }
            .sheet(isPresented: $showAddStep) {
                AddStepView(mode: mode) { newStep in
                    var step = newStep
                    step.order = editedSteps.count
                    editedSteps.append(step)
                }
            }
        }
    }
    
    private func stepRow(_ step: RoutineStep) -> some View {
        HStack(spacing: 12) {
            Image(systemName: step.category.icon)
                .foregroundColor(step.category.color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(step.title)
                    .font(accessibility.bodyFont(size: 15))
                    .fontWeight(.medium)
                    .foregroundColor(Color.Journal.inkBrown)
                
                if let duration = step.formattedDuration {
                    Text(duration)
                        .font(accessibility.captionFont())
                        .foregroundColor(Color.Journal.mutedText)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { step.isEnabled },
                set: { newValue in
                    if let index = editedSteps.firstIndex(where: { $0.id == step.id }) {
                        editedSteps[index].isEnabled = newValue
                    }
                }
            ))
            .labelsHidden()
            .tint(mode.accentColor)
        }
        .listRowBackground(Color.Journal.cardBackground)
    }
    
    private func moveStep(from source: IndexSet, to destination: Int) {
        editedSteps.move(fromOffsets: source, toOffset: destination)
        for i in 0..<editedSteps.count {
            editedSteps[i].order = i
        }
    }
    
    private func deleteStep(at offsets: IndexSet) {
        editedSteps.remove(atOffsets: offsets)
    }
    
    private func saveConfiguration() {
        var newConfig = configuration
        newConfig.steps = editedSteps
        onSave(newConfig)
        dismiss()
    }
}

// MARK: - Add Step View (Updated)

struct AddStepView: View {
    let mode: RoutineMode
    let onAdd: (RoutineStep) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var accessibility = AccessibilityManager.shared
    
    var availableSteps: [RoutineStep] {
        mode == .morning ? RoutineStepLibrary.morningSteps : RoutineStepLibrary.eveningSteps
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.Journal.paper.ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        hideKeyboard()
                    }
                
                List {
                    ForEach(availableSteps) { step in
                        Button {
                            onAdd(step)
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: step.category.icon)
                                    .foregroundColor(step.category.color)
                                    .frame(width: 30)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(step.title)
                                        .font(accessibility.bodyFont(size: 15))
                                        .fontWeight(.medium)
                                        .foregroundColor(Color.Journal.inkBrown)
                                    
                                    Text(step.description)
                                        .font(accessibility.captionFont())
                                        .foregroundColor(Color.Journal.mutedText)
                                        .lineLimit(2)
                                }
                                
                                Spacer()
                                
                                if let duration = step.formattedDuration {
                                    JournalBadge(text: duration, mode: mode)
                                }
                            }
                        }
                        .listRowBackground(Color.Journal.cardBackground)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Add Step")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .font(accessibility.bodyFont())
                }
            }
        }
    }
}

#Preview {
    DailyRoutineView(viewModel: HubViewModel())
}
