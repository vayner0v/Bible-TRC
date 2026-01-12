//
//  CustomInstructionsView.swift
//  Bible v1
//
//  TRC AI Bible Assistant - Custom Instructions Editor
//

import SwiftUI

/// Full-screen editor for custom AI instructions
struct CustomInstructionsView: View {
    @ObservedObject private var preferencesService = AIPreferencesService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var instructionsText: String = ""
    @State private var showingExamples: Bool = false
    @FocusState private var isTextFieldFocused: Bool
    
    private let characterLimit = 1000
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header explanation
                    headerSection
                    
                    // Text editor
                    editorSection
                    
                    // Character count
                    characterCountSection
                    
                    // Example prompts
                    examplesSection
                }
                .padding()
            }
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .navigationTitle("Custom Instructions")
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
                        saveInstructions()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.accentColor)
                }
                
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Done") {
                            isTextFieldFocused = false
                        }
                        .foregroundColor(themeManager.accentColor)
                    }
                }
            }
            .onAppear {
                instructionsText = preferencesService.preferences.customInstructions
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "text.quote")
                    .font(.title2)
                    .foregroundColor(themeManager.accentColor)
                    .frame(width: 44, height: 44)
                    .background(themeManager.accentColor.opacity(0.15))
                    .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Personal Guidance")
                        .font(.headline)
                        .foregroundColor(themeManager.textColor)
                    
                    Text("Tell TRC AI how you'd like it to respond")
                        .font(.subheadline)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
            
            Text("These instructions will be included in every conversation. Be specific about your preferences, needs, or context you want the AI to remember.")
                .font(.callout)
                .foregroundColor(themeManager.secondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(16)
    }
    
    // MARK: - Editor Section
    
    private var editorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your Instructions")
                .font(.subheadline.weight(.medium))
                .foregroundColor(themeManager.textColor)
            
            TextEditor(text: $instructionsText)
                .font(.body)
                .foregroundColor(themeManager.textColor)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 200)
                .padding(12)
                .background(themeManager.cardBackgroundColor)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isTextFieldFocused ? themeManager.accentColor : themeManager.secondaryTextColor.opacity(0.3), lineWidth: 1)
                )
                .focused($isTextFieldFocused)
                .onChange(of: instructionsText) { _, newValue in
                    // Limit character count
                    if newValue.count > characterLimit {
                        instructionsText = String(newValue.prefix(characterLimit))
                    }
                }
            
            if instructionsText.isEmpty {
                Text("Example: \"Always include practical applications. I'm a visual learner, so use metaphors. I'm going through a difficult time, so be extra encouraging.\"")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .italic()
            }
        }
    }
    
    // MARK: - Character Count
    
    private var characterCountSection: some View {
        HStack {
            Spacer()
            Text("\(instructionsText.count)/\(characterLimit)")
                .font(.caption)
                .foregroundColor(instructionsText.count >= characterLimit ? .red : themeManager.secondaryTextColor)
        }
    }
    
    // MARK: - Examples Section
    
    private var examplesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    showingExamples.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                    
                    Text("Example Instructions")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(themeManager.textColor)
                    
                    Spacer()
                    
                    Image(systemName: showingExamples ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                .padding()
                .background(themeManager.cardBackgroundColor)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            
            if showingExamples {
                VStack(spacing: 8) {
                    ExampleInstructionRow(
                        title: "New to Faith",
                        instruction: "I'm new to Christianity. Please explain things simply and avoid assuming I know theological terms.",
                        onTap: { applyExample($0) }
                    )
                    
                    ExampleInstructionRow(
                        title: "Seminary Student",
                        instruction: "I'm studying theology. Include Greek/Hebrew insights and reference scholarly sources when relevant.",
                        onTap: { applyExample($0) }
                    )
                    
                    ExampleInstructionRow(
                        title: "Struggling with Doubt",
                        instruction: "I'm going through a season of doubt. Be patient with hard questions and don't dismiss my concerns.",
                        onTap: { applyExample($0) }
                    )
                    
                    ExampleInstructionRow(
                        title: "Parent",
                        instruction: "I'm a parent teaching my kids about the Bible. Help me find kid-friendly explanations and applications.",
                        onTap: { applyExample($0) }
                    )
                    
                    ExampleInstructionRow(
                        title: "Practical Focus",
                        instruction: "Always end with a practical application or action step I can take today.",
                        onTap: { applyExample($0) }
                    )
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    // MARK: - Actions
    
    private func applyExample(_ instruction: String) {
        if instructionsText.isEmpty {
            instructionsText = instruction
        } else {
            instructionsText += "\n\n" + instruction
        }
        HapticManager.shared.lightImpact()
    }
    
    private func saveInstructions() {
        preferencesService.setCustomInstructions(instructionsText.trimmingCharacters(in: .whitespacesAndNewlines))
        HapticManager.shared.success()
        dismiss()
    }
}

// MARK: - Example Instruction Row

private struct ExampleInstructionRow: View {
    let title: String
    let instruction: String
    let onTap: (String) -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button {
            onTap(instruction)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(themeManager.accentColor)
                
                Text(instruction)
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .multilineTextAlignment(.leading)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(themeManager.backgroundColor)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(themeManager.secondaryTextColor.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    CustomInstructionsView()
}


