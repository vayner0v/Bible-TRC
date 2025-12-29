//
//  DailyRoutineView.swift
//  Bible v1
//
//  Unified Daily Routine - Time-aware morning/evening spiritual practice
//  with customizable steps
//

import SwiftUI

struct DailyRoutineView: View {
    @ObservedObject var viewModel: HubViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    
    @State private var currentMode: RoutineMode = .current
    @State private var selectedConfiguration: RoutineConfiguration?
    @State private var currentStepIndex = 0
    @State private var showCompletion = false
    @State private var showStepEditor = false
    @State private var showModeSelector = false
    
    // Step-specific state
    @State private var intentionText = ""
    @State private var gratitudeItems: [String] = ["", "", ""]
    @State private var reflectionText = ""
    @State private var isBreathing = false
    @State private var breathPhase: BreathPhase = .inhale
    @State private var breathTimer: Timer?
    @State private var breathCycleCount = 0
    
    // MARK: - Computed Properties
    
    private var configuration: RoutineConfiguration {
        selectedConfiguration ?? (currentMode == .morning ? RoutineStepLibrary.defaultMorningRoutine : RoutineStepLibrary.defaultEveningRoutine)
    }
    
    private var enabledSteps: [RoutineStep] {
        configuration.enabledSteps
    }
    
    private var currentStep: RoutineStep? {
        guard currentStepIndex < enabledSteps.count else { return nil }
        return enabledSteps[currentStepIndex]
    }
    
    private var isRoutineComplete: Bool {
        currentMode == .morning ? viewModel.didCompleteMorningRoutine : viewModel.didCompleteNightRoutine
    }
    
    private var progress: Double {
        guard !enabledSteps.isEmpty else { return 0 }
        return Double(currentStepIndex) / Double(enabledSteps.count)
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Dynamic gradient background
                backgroundGradient
                    .ignoresSafeArea()
                
                if isRoutineComplete && !showCompletion {
                    alreadyCompletedView
                } else if showCompletion {
                    completionView
                } else {
                    routineContent
                }
            }
            .navigationTitle("Daily Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        breathTimer?.invalidate()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showModeSelector = true
                        } label: {
                            Label("Switch Mode", systemImage: "arrow.triangle.2.circlepath")
                        }
                        
                        Button {
                            showStepEditor = true
                        } label: {
                            Label("Customize Steps", systemImage: "slider.horizontal.3")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(currentMode.accentColor)
                    }
                }
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
                    }
                )
            }
            .confirmationDialog("Choose Routine", isPresented: $showModeSelector, titleVisibility: .visible) {
                Button("Morning Routine") {
                    withAnimation { currentMode = .morning }
                }
                Button("Evening Routine") {
                    withAnimation { currentMode = .evening }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: currentMode.gradient + [themeManager.backgroundColor],
            startPoint: .top,
            endPoint: .bottom
        )
        .animation(.easeInOut(duration: 0.5), value: currentMode)
    }
    
    // MARK: - Already Completed View
    
    private var alreadyCompletedView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: currentMode == .morning ? "sunrise.fill" : "moon.stars.fill")
                .font(.system(size: 70))
                .foregroundStyle(
                    LinearGradient(
                        colors: currentMode == .morning ? [.orange, .yellow] : [.indigo, .teal],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("\(currentMode.displayName) Routine Complete!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(themeManager.textColor)
            
            Text(currentMode == .morning
                 ? "You've already completed your morning routine today. Come back tomorrow for a fresh start!"
                 : "You've already completed your evening reflection. Rest well and let tomorrow be a new day of grace.")
                .font(.subheadline)
                .foregroundColor(themeManager.secondaryTextColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if currentMode == .morning, let intention = viewModel.dailyIntention {
                intentionCard(intention)
            }
            
            Spacer()
            
            // Option to switch mode
            if !otherModeComplete {
                Button {
                    withAnimation {
                        currentMode = currentMode == .morning ? .evening : .morning
                    }
                } label: {
                    HStack {
                        Image(systemName: currentMode == .morning ? "moon.stars.fill" : "sunrise.fill")
                        Text("Start \(currentMode == .morning ? "Evening" : "Morning") Routine")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(currentMode.accentColor)
                    .padding()
                    .background(currentMode.accentColor.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding(.bottom, 8)
            }
            
            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(currentMode.accentColor)
                    .cornerRadius(14)
            }
            .padding(.horizontal)
        }
        .padding()
    }
    
    private var otherModeComplete: Bool {
        currentMode == .morning ? viewModel.didCompleteNightRoutine : viewModel.didCompleteMorningRoutine
    }
    
    private func intentionCard(_ intention: String) -> some View {
        VStack(spacing: 8) {
            Text("Today's Intention")
                .font(.caption)
                .foregroundColor(themeManager.secondaryTextColor)
            
            Text("\"\(intention)\"")
                .font(.headline)
                .foregroundColor(currentMode.accentColor)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // MARK: - Routine Content
    
    private var routineContent: some View {
        VStack(spacing: 0) {
            // Mode indicator & progress
            routineHeader
            
            // Progress ring and step content
            stepContentArea
            
            // Navigation buttons
            navigationButtons
        }
    }
    
    private var routineHeader: some View {
        VStack(spacing: 12) {
            // Mode badge
            HStack {
                Image(systemName: currentMode.icon)
                Text(currentMode.displayName)
                    .fontWeight(.medium)
            }
            .font(.subheadline)
            .foregroundColor(currentMode.accentColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(currentMode.accentColor.opacity(0.15))
            .cornerRadius(20)
            
            // Progress indicator
            HStack(spacing: 8) {
                ForEach(0..<enabledSteps.count, id: \.self) { index in
                    Capsule()
                        .fill(index <= currentStepIndex ? currentMode.accentColor : themeManager.dividerColor)
                        .frame(height: 4)
                }
            }
            .padding(.horizontal)
        }
        .padding(.top, 8)
        .padding(.bottom, 16)
    }
    
    private var stepContentArea: some View {
        GeometryReader { geometry in
            TabView(selection: $currentStepIndex) {
                ForEach(Array(enabledSteps.enumerated()), id: \.element.id) { index, step in
                    stepView(for: step)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }
    
    @ViewBuilder
    private func stepView(for step: RoutineStep) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Step icon with glow
                ZStack {
                    Circle()
                        .fill(step.category.color.opacity(0.2))
                        .frame(width: 90, height: 90)
                        .blur(radius: 20)
                    
                    Circle()
                        .fill(step.category.color.opacity(0.15))
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: step.category.icon)
                        .font(.system(size: 32))
                        .foregroundColor(step.category.color)
                }
                
                // Title and description
                VStack(spacing: 8) {
                    Text(step.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.textColor)
                    
                    Text(step.description)
                        .font(.subheadline)
                        .foregroundColor(themeManager.secondaryTextColor)
                        .multilineTextAlignment(.center)
                    
                    if let duration = step.formattedDuration {
                        Text(duration)
                            .font(.caption)
                            .foregroundColor(step.category.color)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(step.category.color.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                
                // Step-specific content
                stepContent(for: step)
            }
            .padding()
            .padding(.bottom, 100)
        }
    }
    
    @ViewBuilder
    private func stepContent(for step: RoutineStep) -> some View {
        switch step.content {
        case .prayerPrompts(let prompts):
            prayerPromptsContent(prompts, color: step.category.color)
            
        case .scripture(let reference, let text):
            scriptureContent(reference: reference, text: text)
            
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
                .font(.body)
                .foregroundColor(themeManager.textColor)
                .multilineTextAlignment(.center)
            
        case .custom(let instructions):
            customContent(instructions: instructions)
        }
    }
    
    // MARK: - Step Content Views
    
    private func prayerPromptsContent(_ prompts: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(prompts, id: \.self) { prompt in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 6))
                        .foregroundColor(color)
                        .padding(.top, 6)
                    
                    Text(prompt)
                        .font(.subheadline)
                        .foregroundColor(themeManager.textColor)
                }
            }
        }
        .padding()
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(14)
    }
    
    private func scriptureContent(reference: String, text: String) -> some View {
        VStack(spacing: 16) {
            Text(text)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(themeManager.textColor)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
            
            Text("— \(reference)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(currentMode.accentColor)
        }
        .padding(24)
        .background(currentMode.accentColor.opacity(0.1))
        .cornerRadius(16)
    }
    
    private func breathingContent(inhale: Int, hold: Int, exhale: Int, cycles: Int) -> some View {
        VStack(spacing: 24) {
            // Breathing circle
            ZStack {
                Circle()
                    .stroke(themeManager.dividerColor, lineWidth: 4)
                    .frame(width: 180, height: 180)
                
                Circle()
                    .fill(currentMode.accentColor.opacity(0.2))
                    .frame(width: breathCircleSize, height: breathCircleSize)
                    .animation(.easeInOut(duration: Double(currentBreathDuration)), value: breathPhase)
                
                VStack(spacing: 8) {
                    Text(isBreathing ? breathPhase.instruction : "Start")
                        .font(.headline)
                        .foregroundColor(currentMode.accentColor)
                    
                    if !isBreathing {
                        Text("Tap to begin")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                    } else {
                        Text("\(breathCycleCount)/\(cycles)")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                }
            }
            .onTapGesture {
                if !isBreathing {
                    startBreathing(inhale: inhale, hold: hold, exhale: exhale, cycles: cycles)
                }
            }
        }
    }
    
    private var breathCircleSize: CGFloat {
        switch breathPhase {
        case .inhale: return 180
        case .hold: return 180
        case .exhale: return 100
        }
    }
    
    private var currentBreathDuration: Int {
        switch breathPhase {
        case .inhale: return 4
        case .hold: return 4
        case .exhale: return 4
        }
    }
    
    private func gratitudeContent(count: Int) -> some View {
        VStack(spacing: 12) {
            ForEach(0..<count, id: \.self) { index in
                HStack(spacing: 12) {
                    Text("\(index + 1)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(Color.pink)
                        .clipShape(Circle())
                    
                    TextField("I'm grateful for...", text: gratitudeBinding(for: index))
                        .textFieldStyle(.plain)
                        .padding()
                        .background(themeManager.cardBackgroundColor)
                        .cornerRadius(10)
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
    
    private func intentionContent() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What is one thing you want to focus on today?")
                .font(.subheadline)
                .foregroundColor(themeManager.secondaryTextColor)
            
            TextEditor(text: $intentionText)
                .frame(height: 100)
                .padding()
                .background(themeManager.cardBackgroundColor)
                .cornerRadius(14)
                .scrollContentBackground(.hidden)
                .overlay(
                    Group {
                        if intentionText.isEmpty {
                            Text("e.g., 'Be patient with others' or 'Trust God's timing'")
                                .font(.subheadline)
                                .foregroundColor(themeManager.secondaryTextColor.opacity(0.5))
                                .padding(.leading, 20)
                                .padding(.top, 24)
                        }
                    },
                    alignment: .topLeading
                )
        }
    }
    
    private func reflectionContent(questions: [String]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(questions, id: \.self) { question in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 6))
                        .foregroundColor(.indigo)
                        .padding(.top, 6)
                    
                    Text(question)
                        .font(.subheadline)
                        .foregroundColor(themeManager.textColor)
                }
            }
            
            TextEditor(text: $reflectionText)
                .frame(height: 80)
                .padding()
                .background(themeManager.cardBackgroundColor)
                .cornerRadius(12)
                .scrollContentBackground(.hidden)
        }
        .padding()
        .background(themeManager.cardBackgroundColor.opacity(0.5))
        .cornerRadius(14)
    }
    
    private func customContent(instructions: String) -> some View {
        Text(instructions)
            .font(.body)
            .foregroundColor(themeManager.textColor)
            .padding()
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(14)
    }
    
    // MARK: - Navigation
    
    private var navigationButtons: some View {
        HStack(spacing: 16) {
            if currentStepIndex > 0 {
                Button {
                    withAnimation {
                        currentStepIndex -= 1
                    }
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
                    .padding()
                    .background(themeManager.cardBackgroundColor)
                    .cornerRadius(12)
                }
            }
            
            Spacer()
            
            Button {
                if currentStepIndex < enabledSteps.count - 1 {
                    withAnimation {
                        currentStepIndex += 1
                    }
                } else {
                    completeRoutine()
                }
            } label: {
                HStack {
                    Text(currentStepIndex < enabledSteps.count - 1 ? "Next" : "Complete")
                    Image(systemName: currentStepIndex < enabledSteps.count - 1 ? "chevron.right" : "checkmark.circle.fill")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(currentMode.accentColor)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(
            themeManager.backgroundColor
                .opacity(0.95)
                .ignoresSafeArea(edges: .bottom)
        )
    }
    
    // MARK: - Completion View
    
    private var completionView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: currentMode == .morning ? "sun.max.fill" : "moon.zzz.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: currentMode == .morning ? [.yellow, .orange] : [.indigo, .teal],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text(currentMode == .morning ? "You're Ready!" : "Sweet Dreams")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(themeManager.textColor)
            
            Text(currentMode == .morning
                 ? "You've completed your morning routine. Go forth and shine God's light today!"
                 : "You've completed your evening routine. May God grant you peaceful, restful sleep.")
                .font(.subheadline)
                .foregroundColor(themeManager.secondaryTextColor)
                .multilineTextAlignment(.center)
            
            // Summary cards
            completionSummary
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Text(currentMode == .morning ? "Start My Day" : "Good Night")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: currentMode == .morning ? [.orange, .yellow] : [.indigo, .teal],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(14)
            }
            .padding(.horizontal)
        }
        .padding()
    }
    
    @ViewBuilder
    private var completionSummary: some View {
        VStack(spacing: 12) {
            if currentMode == .morning && !intentionText.isEmpty {
                summaryCard(title: "Your Intention", content: intentionText, icon: "target", color: .green)
            }
            
            let filledGratitude = gratitudeItems.filter { !$0.isEmpty }
            if !filledGratitude.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.pink)
                        Text("Gratitude")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    
                    ForEach(filledGratitude, id: \.self) { item in
                        HStack(spacing: 6) {
                            Image(systemName: "heart.fill")
                                .font(.caption2)
                                .foregroundColor(.pink.opacity(0.6))
                            Text(item)
                                .font(.caption)
                                .foregroundColor(themeManager.textColor)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(themeManager.cardBackgroundColor)
                .cornerRadius(12)
            }
        }
    }
    
    private func summaryCard(title: String, content: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            Text("\"\(content)\"")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(themeManager.textColor)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // MARK: - Actions
    
    private func startBreathing(inhale: Int, hold: Int, exhale: Int, cycles: Int) {
        isBreathing = true
        breathCycleCount = 0
        breathPhase = .inhale
        
        let cycleDuration = Double(inhale + hold + exhale)
        var elapsed: Double = 0
        
        breathTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsed += 1
            let positionInCycle = Int(elapsed) % Int(cycleDuration)
            
            if positionInCycle < inhale {
                breathPhase = .inhale
            } else if positionInCycle < inhale + hold {
                breathPhase = .hold
            } else {
                breathPhase = .exhale
            }
            
            if positionInCycle == 0 && elapsed > 0 {
                breathCycleCount += 1
            }
            
            if breathCycleCount >= cycles {
                breathTimer?.invalidate()
                isBreathing = false
            }
        }
    }
    
    private func completeRoutine() {
        breathTimer?.invalidate()
        
        if currentMode == .morning {
            viewModel.completeMorningRoutine()
            if !intentionText.isEmpty {
                viewModel.setDailyIntention(intentionText)
            }
        } else {
            viewModel.completeNightRoutine()
        }
        
        // Save gratitude items
        for item in gratitudeItems where !item.isEmpty {
            viewModel.addGratitudeItem(item, category: .general)
        }
        
        withAnimation {
            showCompletion = true
        }
    }
}

// MARK: - Breath Phase

enum BreathPhase {
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

// MARK: - Step Editor View

struct RoutineStepEditorView: View {
    let configuration: RoutineConfiguration
    let mode: RoutineMode
    let onSave: (RoutineConfiguration) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var themeManager = ThemeManager.shared
    
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
            List {
                Section {
                    ForEach(editedSteps) { step in
                        stepRow(step)
                    }
                    .onMove(perform: moveStep)
                    .onDelete(perform: deleteStep)
                } header: {
                    Text("Routine Steps")
                } footer: {
                    Text("Drag to reorder, swipe to delete")
                        .font(.caption)
                }
                
                Section {
                    Button {
                        showAddStep = true
                    } label: {
                        Label("Add Step", systemImage: "plus.circle.fill")
                            .foregroundColor(mode.accentColor)
                    }
                }
            }
            .navigationTitle("Customize Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveConfiguration()
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
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
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let duration = step.formattedDuration {
                    Text(duration)
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
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
        }
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

// MARK: - Add Step View

struct AddStepView: View {
    let mode: RoutineMode
    let onAdd: (RoutineStep) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var availableSteps: [RoutineStep] {
        mode == .morning ? RoutineStepLibrary.morningSteps : RoutineStepLibrary.eveningSteps
    }
    
    var body: some View {
        NavigationStack {
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
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(themeManager.textColor)
                                
                                Text(step.description)
                                    .font(.caption)
                                    .foregroundColor(themeManager.secondaryTextColor)
                            }
                            
                            Spacer()
                            
                            if let duration = step.formattedDuration {
                                Text(duration)
                                    .font(.caption)
                                    .foregroundColor(step.category.color)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Step")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    DailyRoutineView(viewModel: HubViewModel())
}


