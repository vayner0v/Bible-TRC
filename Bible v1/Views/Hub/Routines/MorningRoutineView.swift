//
//  MorningRoutineView.swift
//  Bible v1
//
//  Morning Routine - Guided morning spiritual practice
//

import SwiftUI

struct MorningRoutineView: View {
    @ObservedObject var viewModel: HubViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentStep = 0
    @State private var intentionText = ""
    @State private var breathCount = 0
    @State private var isBreathing = false
    @State private var breathTimer: Timer?
    @State private var showCompletion = false
    
    private let totalSteps = 4
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [.orange.opacity(0.15), themeManager.backgroundColor],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                if viewModel.didCompleteMorningRoutine && !showCompletion {
                    alreadyCompletedView
                } else if showCompletion {
                    completionView
                } else {
                    routineContent
                }
            }
            .navigationTitle("Morning Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        breathTimer?.invalidate()
                        dismiss()
                    }
                }
            }
            .onDisappear {
                breathTimer?.invalidate()
            }
        }
    }
    
    // MARK: - Already Completed View
    
    private var alreadyCompletedView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "sunrise.fill")
                .font(.system(size: 70))
                .foregroundStyle(
                    LinearGradient(colors: [.orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            
            Text("Morning Routine Complete!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(themeManager.textColor)
            
            Text("You've already completed your morning routine today. Come back tomorrow for a fresh start!")
                .font(.subheadline)
                .foregroundColor(themeManager.secondaryTextColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if let intention = viewModel.dailyIntention {
                VStack(spacing: 8) {
                    Text("Today's Intention")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    Text("\"\(intention)\"")
                        .font(.headline)
                        .foregroundColor(themeManager.accentColor)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(themeManager.cardBackgroundColor)
                .cornerRadius(12)
            }
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(themeManager.accentColor)
                    .cornerRadius(14)
            }
            .padding(.horizontal)
        }
        .padding()
    }
    
    // MARK: - Routine Content
    
    private var routineContent: some View {
        VStack(spacing: 0) {
            // Progress indicator
            HStack(spacing: 8) {
                ForEach(0..<totalSteps, id: \.self) { step in
                    Capsule()
                        .fill(step <= currentStep ? Color.orange : themeManager.dividerColor)
                        .frame(height: 4)
                }
            }
            .padding()
            
            // Step content
            TabView(selection: $currentStep) {
                prayerStep.tag(0)
                verseStep.tag(1)
                intentionStep.tag(2)
                breathingStep.tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // Navigation
            HStack(spacing: 16) {
                if currentStep > 0 {
                    Button {
                        withAnimation {
                            currentStep -= 1
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
                    if currentStep < totalSteps - 1 {
                        withAnimation {
                            currentStep += 1
                        }
                    } else {
                        completeRoutine()
                    }
                } label: {
                    HStack {
                        Text(currentStep < totalSteps - 1 ? "Next" : "Complete")
                        Image(systemName: currentStep < totalSteps - 1 ? "chevron.right" : "checkmark.circle.fill")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(12)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Step 1: Prayer
    
    private var prayerStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "hands.sparkles")
                    .font(.system(size: 50))
                    .foregroundColor(.orange)
                
                Text("Morning Prayer")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.textColor)
                
                Text("Take a moment to greet God and offer your day to Him.")
                    .font(.subheadline)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .multilineTextAlignment(.center)
                
                VStack(alignment: .leading, spacing: 16) {
                    PrayerPromptRow(text: "Thank God for the gift of a new day")
                    PrayerPromptRow(text: "Ask for His guidance in all you do today")
                    PrayerPromptRow(text: "Surrender any worries or anxieties")
                    PrayerPromptRow(text: "Ask for opportunities to serve others")
                }
                .padding()
                .background(themeManager.cardBackgroundColor)
                .cornerRadius(14)
                
                Text("\"This is the day the Lord has made; let us rejoice and be glad in it.\" — Psalm 118:24")
                    .font(.caption)
                    .italic()
                    .foregroundColor(themeManager.secondaryTextColor)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }
    
    // MARK: - Step 2: Verse
    
    private var verseStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "book.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                
                Text("Verse of the Day")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.textColor)
                
                Text("Meditate on God's Word to start your day")
                    .font(.subheadline)
                    .foregroundColor(themeManager.secondaryTextColor)
                
                VStack(spacing: 12) {
                    Text(viewModel.verseOfTheDay.text)
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.textColor)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                    
                    Text("— \(viewModel.verseOfTheDay.reference)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.accentColor)
                }
                .padding(24)
                .background(themeManager.accentColor.opacity(0.1))
                .cornerRadius(16)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Reflect:")
                        .font(.headline)
                        .foregroundColor(themeManager.textColor)
                    
                    Text("What does this verse mean for your day ahead? How can you apply it?")
                        .font(.subheadline)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(themeManager.cardBackgroundColor)
                .cornerRadius(14)
            }
            .padding()
        }
    }
    
    // MARK: - Step 3: Intention
    
    private var intentionStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "target")
                    .font(.system(size: 50))
                    .foregroundColor(.green)
                
                Text("Set Your Intention")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.textColor)
                
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
                
                Text("Daily Mission")
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.yellow)
                    Text(viewModel.dailyMission)
                        .font(.subheadline)
                        .foregroundColor(themeManager.textColor)
                }
                .padding()
                .background(Color.yellow.opacity(0.1))
                .cornerRadius(12)
            }
            .padding()
        }
    }
    
    // MARK: - Step 4: Breathing
    
    private var breathingStep: some View {
        VStack(spacing: 24) {
            Text("Centering Breath")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(themeManager.textColor)
            
            Text("Take 30 seconds to center yourself before starting your day")
                .font(.subheadline)
                .foregroundColor(themeManager.secondaryTextColor)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            // Breathing circle
            ZStack {
                Circle()
                    .stroke(themeManager.dividerColor, lineWidth: 4)
                    .frame(width: 180, height: 180)
                
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: isBreathing ? 180 : 100, height: isBreathing ? 180 : 100)
                    .animation(.easeInOut(duration: 4), value: isBreathing)
                
                VStack(spacing: 8) {
                    Text(isBreathing ? (breathCount % 2 == 0 ? "Breathe In" : "Breathe Out") : "Start")
                        .font(.headline)
                        .foregroundColor(.orange)
                    
                    if !isBreathing {
                        Text("Tap to begin")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                }
            }
            .onTapGesture {
                if !isBreathing {
                    startBreathing()
                }
            }
            
            // Breath count
            if breathCount > 0 {
                Text("\(breathCount / 2) breaths")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            Spacer()
            
            Text("\"Be still, and know that I am God.\" — Psalm 46:10")
                .font(.caption)
                .italic()
                .foregroundColor(themeManager.secondaryTextColor)
        }
        .padding()
    }
    
    // MARK: - Completion View
    
    private var completionView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "sun.max.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            
            Text("You're Ready!")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(themeManager.textColor)
            
            Text("You've completed your morning routine. Go forth and shine God's light today!")
                .font(.subheadline)
                .foregroundColor(themeManager.secondaryTextColor)
                .multilineTextAlignment(.center)
            
            if !intentionText.isEmpty {
                VStack(spacing: 8) {
                    Text("Your Intention")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    Text("\"\(intentionText)\"")
                        .font(.headline)
                        .foregroundColor(themeManager.accentColor)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(themeManager.cardBackgroundColor)
                .cornerRadius(12)
            }
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Text("Start My Day")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(colors: [.orange, .yellow], startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(14)
            }
            .padding(.horizontal)
        }
        .padding()
    }
    
    // MARK: - Actions
    
    private func startBreathing() {
        isBreathing = true
        breathTimer = Timer.scheduledTimer(withTimeInterval: 4, repeats: true) { _ in
            breathCount += 1
            isBreathing.toggle()
            
            if breathCount >= 8 {
                breathTimer?.invalidate()
            }
        }
    }
    
    private func completeRoutine() {
        breathTimer?.invalidate()
        viewModel.completeMorningRoutine()
        if !intentionText.isEmpty {
            viewModel.setDailyIntention(intentionText)
        }
        withAnimation {
            showCompletion = true
        }
    }
}

// MARK: - Prayer Prompt Row

struct PrayerPromptRow: View {
    let text: String
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "circle.fill")
                .font(.system(size: 6))
                .foregroundColor(.orange)
                .padding(.top, 6)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(themeManager.textColor)
        }
    }
}

#Preview {
    MorningRoutineView(viewModel: HubViewModel())
}



