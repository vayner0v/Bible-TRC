//
//  MoodCheckInView.swift
//  Bible v1
//
//  Mood Check-in - Quick daily wellness check with suggested prayers/verses
//

import SwiftUI

struct MoodCheckInView: View {
    @ObservedObject var viewModel: HubViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedMood: MoodLevel?
    @State private var selectedFactors: Set<MoodFactor> = []
    @State private var note: String = ""
    @State private var showCompletion = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor.ignoresSafeArea()
                
                if showCompletion, let mood = selectedMood {
                    completionView(mood: mood)
                } else if let existingMood = viewModel.todayMood {
                    alreadyCheckedInView(existingMood)
                } else {
                    checkInView
                }
            }
            .navigationTitle("Check In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    // MARK: - Check In View
    
    private var checkInView: some View {
        ScrollView {
            VStack(spacing: 28) {
                // Header
                VStack(spacing: 8) {
                    Text("How are you feeling?")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.textColor)
                    
                    Text("Take a moment to check in with yourself")
                        .font(.subheadline)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                .padding(.top)
                
                // Mood selector
                HStack(spacing: 12) {
                    ForEach(MoodLevel.allCases) { mood in
                        MoodButton(
                            mood: mood,
                            isSelected: selectedMood == mood
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                selectedMood = mood
                            }
                        }
                    }
                }
                
                // Selected mood encouragement
                if let mood = selectedMood {
                    VStack(spacing: 8) {
                        Text(mood.encouragement)
                            .font(.subheadline)
                            .foregroundColor(themeManager.textColor)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(mood.color.opacity(0.1))
                            .cornerRadius(12)
                    }
                    .transition(.opacity.combined(with: .scale))
                }
                
                // Factors section
                if selectedMood != nil {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What's influencing your day? (Optional)")
                            .font(.headline)
                            .foregroundColor(themeManager.textColor)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(MoodFactor.allCases) { factor in
                                FactorPill(
                                    factor: factor,
                                    isSelected: selectedFactors.contains(factor)
                                ) {
                                    if selectedFactors.contains(factor) {
                                        selectedFactors.remove(factor)
                                    } else {
                                        selectedFactors.insert(factor)
                                    }
                                }
                            }
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
                
                // Note section
                if selectedMood != nil {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Any thoughts? (Optional)")
                            .font(.headline)
                            .foregroundColor(themeManager.textColor)
                        
                        TextEditor(text: $note)
                            .frame(height: 80)
                            .padding(8)
                            .background(themeManager.cardBackgroundColor)
                            .cornerRadius(10)
                            .scrollContentBackground(.hidden)
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
                
                // Submit button
                if selectedMood != nil {
                    Button {
                        submitCheckIn()
                    } label: {
                        Text("Save Check-in")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedMood?.color ?? themeManager.accentColor)
                            .cornerRadius(14)
                    }
                    .padding(.top)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Already Checked In View
    
    private func alreadyCheckedInView(_ entry: MoodEntry) -> some View {
        VStack(spacing: 24) {
            Spacer()
            
            Text(entry.mood.emoji)
                .font(.system(size: 80))
            
            Text("You've checked in today")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(themeManager.textColor)
            
            VStack(spacing: 8) {
                Text("You're feeling \(entry.mood.displayName.lowercased())")
                    .font(.headline)
                    .foregroundColor(entry.mood.color)
                
                Text("Checked in at \(entry.timeOfDay)")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            // Show factors if any
            if !entry.factors.isEmpty {
                VStack(spacing: 8) {
                    Text("Factors:")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    HStack(spacing: 8) {
                        ForEach(entry.factors, id: \.self) { factor in
                            HStack(spacing: 4) {
                                Image(systemName: factor.icon)
                                Text(factor.rawValue)
                            }
                            .font(.caption)
                            .foregroundColor(themeManager.textColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(themeManager.cardBackgroundColor)
                            .cornerRadius(15)
                        }
                    }
                }
            }
            
            // Show note if any
            if let noteText = entry.note, !noteText.isEmpty {
                Text("\"\(noteText)\"")
                    .font(.subheadline)
                    .italic()
                    .foregroundColor(themeManager.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(themeManager.cardBackgroundColor)
                    .cornerRadius(12)
            }
            
            // Suggested verse for mood
            VStack(spacing: 8) {
                Text("Today's Verse for You")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
                
                VStack(spacing: 4) {
                    Text(entry.mood.suggestedVerse.text)
                        .font(.subheadline)
                        .italic()
                        .foregroundColor(themeManager.textColor)
                        .multilineTextAlignment(.center)
                    
                    Text("— \(entry.mood.suggestedVerse.reference)")
                        .font(.caption)
                        .foregroundColor(themeManager.accentColor)
                }
                .padding()
                .background(themeManager.accentColor.opacity(0.1))
                .cornerRadius(12)
            }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Completion View
    
    private func completionView(mood: MoodLevel) -> some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 70))
                .foregroundColor(.green)
            
            Text("Check-in Complete")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(themeManager.textColor)
            
            Text(mood.encouragement)
                .font(.subheadline)
                .foregroundColor(themeManager.secondaryTextColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Suggested action
            VStack(spacing: 16) {
                Text("Based on how you're feeling:")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
                
                // Suggested verse
                VStack(spacing: 8) {
                    Text(mood.suggestedVerse.reference)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.accentColor)
                    
                    Text(mood.suggestedVerse.text)
                        .font(.subheadline)
                        .foregroundColor(themeManager.textColor)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(themeManager.cardBackgroundColor)
                .cornerRadius(12)
                
                // Suggested prayer theme
                HStack {
                    Image(systemName: "hands.sparkles")
                        .foregroundColor(themeManager.accentColor)
                    Text("Try a \(mood.suggestedPrayerTheme.rawValue) guided prayer")
                        .font(.subheadline)
                        .foregroundColor(themeManager.textColor)
                }
                .padding()
                .background(themeManager.accentColor.opacity(0.1))
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
    
    // MARK: - Actions
    
    private func submitCheckIn() {
        guard let mood = selectedMood else { return }
        viewModel.recordMood(
            mood,
            note: note.isEmpty ? nil : note,
            factors: Array(selectedFactors)
        )
        
        withAnimation {
            showCompletion = true
        }
    }
}

// MARK: - Mood Button

struct MoodButton: View {
    let mood: MoodLevel
    let isSelected: Bool
    let action: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(mood.emoji)
                    .font(.system(size: isSelected ? 44 : 36))
                    .animation(.spring(response: 0.3), value: isSelected)
                
                Text(mood.displayName)
                    .font(.caption2)
                    .foregroundColor(isSelected ? mood.color : themeManager.secondaryTextColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? mood.color.opacity(0.15) : Color.clear)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? mood.color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Factor Pill

struct FactorPill: View {
    let factor: MoodFactor
    let isSelected: Bool
    let action: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: factor.icon)
                    .font(.caption)
                Text(factor.rawValue)
                    .font(.caption)
            }
            .foregroundColor(isSelected ? .white : themeManager.textColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? themeManager.accentColor : themeManager.cardBackgroundColor)
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MoodCheckInView(viewModel: HubViewModel())
}



