//
//  AIPersonaPickerView.swift
//  Bible v1
//
//  TRC AI Bible Assistant - AI Persona Selection
//

import SwiftUI

/// Visual picker for AI persona/voice selection
struct AIPersonaPickerView: View {
    @ObservedObject private var preferencesService = AIPreferencesService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedPersona: AIPersona
    @State private var previewText: String = ""
    @State private var showingPreview: Bool = false
    
    init() {
        _selectedPersona = State(initialValue: AIPreferencesService.shared.preferences.selectedPersona)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerSection
                    
                    // Persona cards
                    personaCardsSection
                    
                    // Preview section
                    if showingPreview {
                        previewSection
                    }
                }
                .padding()
            }
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .navigationTitle("AI Voice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.accentColor)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSelection()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.accentColor)
                    .disabled(selectedPersona == preferencesService.preferences.selectedPersona)
                }
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            // Selected persona icon with animation
            ZStack {
                Circle()
                    .fill(selectedPersona.accentColor.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: selectedPersona.icon)
                    .font(.system(size: 32))
                    .foregroundColor(selectedPersona.accentColor)
            }
            .animation(.spring(response: 0.4), value: selectedPersona)
            
            Text("Choose Your AI Voice")
                .font(.title3.weight(.semibold))
                .foregroundColor(themeManager.textColor)
            
            Text("Select a persona that matches how you'd like TRC AI to communicate with you")
                .font(.subheadline)
                .foregroundColor(themeManager.secondaryTextColor)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 8)
    }
    
    // MARK: - Persona Cards
    
    private var personaCardsSection: some View {
        VStack(spacing: 12) {
            ForEach(AIPersona.allCases) { persona in
                PersonaCard(
                    persona: persona,
                    isSelected: selectedPersona == persona,
                    onSelect: {
                        withAnimation(.spring(response: 0.3)) {
                            selectedPersona = persona
                            showingPreview = true
                            previewText = persona.sampleGreeting
                        }
                        HapticManager.shared.selection()
                    }
                )
            }
        }
    }
    
    // MARK: - Preview Section
    
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "quote.opening")
                    .foregroundColor(selectedPersona.accentColor)
                
                Text("Preview")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(themeManager.textColor)
            }
            
            Text(previewText)
                .font(.body)
                .foregroundColor(themeManager.textColor)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(themeManager.cardBackgroundColor)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(selectedPersona.accentColor.opacity(0.3), lineWidth: 1)
                )
        }
        .padding(.top, 8)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
    
    // MARK: - Actions
    
    private func saveSelection() {
        preferencesService.setSelectedPersona(selectedPersona)
        HapticManager.shared.success()
        dismiss()
    }
}

// MARK: - Persona Card

private struct PersonaCard: View {
    let persona: AIPersona
    let isSelected: Bool
    let onSelect: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(persona.accentColor.opacity(isSelected ? 0.2 : 0.1))
                        .frame(width: 52, height: 52)
                    
                    Image(systemName: persona.icon)
                        .font(.system(size: 22))
                        .foregroundColor(persona.accentColor)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(persona.displayName)
                        .font(.headline)
                        .foregroundColor(isSelected ? persona.accentColor : themeManager.textColor)
                    
                    Text(persona.description)
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(persona.accentColor)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.cardBackgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? persona.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

// MARK: - Compact Persona Picker (for inline use)

struct PersonaPickerCompact: View {
    @Binding var selectedPersona: AIPersona
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(AIPersona.allCases) { persona in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedPersona = persona
                        }
                        HapticManager.shared.selection()
                    } label: {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(persona.accentColor.opacity(selectedPersona == persona ? 0.25 : 0.1))
                                    .frame(width: 48, height: 48)
                                
                                Image(systemName: persona.icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(persona.accentColor)
                            }
                            
                            Text(persona.displayName)
                                .font(.caption)
                                .foregroundColor(selectedPersona == persona ? persona.accentColor : themeManager.secondaryTextColor)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Preview

#Preview {
    AIPersonaPickerView()
}


