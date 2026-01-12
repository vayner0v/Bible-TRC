//
//  AIPreferencesView.swift
//  Bible v1
//
//  TRC AI Bible Assistant - User Preferences Settings
//

import SwiftUI

/// Settings view for AI personalization preferences
struct AIPreferencesView: View {
    @ObservedObject private var preferencesService = AIPreferencesService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingResetConfirmation: Bool = false
    @State private var showingPersonaPicker: Bool = false
    @State private var showingCustomInstructions: Bool = false
    @State private var showingUsageStats: Bool = false
    @State private var showingDataExport: Bool = false
    
    var body: some View {
        NavigationStack {
            List {
                // AI Persona Section
                Section {
                    personaRow
                    customInstructionsRow
                } header: {
                    Text("AI Personality")
                } footer: {
                    Text("Choose how TRC AI communicates and add your own personal guidance.")
                }
                
                // Response Style Section
                Section {
                    tonePickerRow
                    readingLevelPickerRow
                    responseLengthPickerRow
                } header: {
                    Text("Response Style")
                } footer: {
                    Text("These settings affect how TRC AI communicates with you.")
                }
                
                // Theological Perspective Section
                Section {
                    denominationPickerRow
                    controversialTopicsToggle
                } header: {
                    Text("Theological Perspective")
                } footer: {
                    Text("Choose a tradition to inform AI responses, or keep neutral for balanced perspectives.")
                }
                
                // Bible Translation Section
                Section {
                    translationRow
                } header: {
                    Text("Default Bible Translation")
                }
                
                // Memory Section
                Section {
                    memoryToggleRow
                    
                    if preferencesService.isMemoryEnabled {
                        NavigationLink {
                            MemoryManagementView()
                        } label: {
                            Label("Manage Memories", systemImage: "brain.head.profile")
                        }
                    }
                } header: {
                    Text("AI Memory")
                } footer: {
                    Text("When enabled, TRC AI remembers your prayer requests, favorite verses, and what's helped you before.")
                }
                
                // Insights & Data Section
                Section {
                    usageStatsRow
                    dataExportRow
                } header: {
                    Text("Insights & Data")
                }
                
                // Reset Section
                Section {
                    Button(role: .destructive) {
                        showingResetConfirmation = true
                    } label: {
                        Label("Reset to Defaults", systemImage: "arrow.counterclockwise")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(themeManager.backgroundColor)
            .tint(themeManager.accentColor)
            .navigationTitle("AI Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.accentColor)
                }
            }
            .alert("Reset Preferences?", isPresented: $showingResetConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    preferencesService.resetToDefaults()
                    HapticManager.shared.success()
                }
            } message: {
                Text("This will reset all AI preferences to their default values.")
            }
            .sheet(isPresented: $showingPersonaPicker) {
                AIPersonaPickerView()
            }
            .sheet(isPresented: $showingCustomInstructions) {
                CustomInstructionsView()
            }
            .sheet(isPresented: $showingUsageStats) {
                AIUsageStatsView()
            }
            .sheet(isPresented: $showingDataExport) {
                DataExportView()
            }
        }
    }
    
    // MARK: - Persona Row
    
    private var personaRow: some View {
        Button {
            showingPersonaPicker = true
        } label: {
            HStack {
                ZStack {
                    Circle()
                        .fill(preferencesService.preferences.selectedPersona.accentColor.opacity(0.2))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: preferencesService.preferences.selectedPersona.icon)
                        .font(.system(size: 14))
                        .foregroundColor(preferencesService.preferences.selectedPersona.accentColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("AI Voice")
                        .foregroundColor(themeManager.textColor)
                    Text(preferencesService.preferences.selectedPersona.displayName)
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
        }
    }
    
    // MARK: - Custom Instructions Row
    
    private var customInstructionsRow: some View {
        Button {
            showingCustomInstructions = true
        } label: {
            HStack {
                Image(systemName: "text.quote")
                    .foregroundColor(themeManager.accentColor)
                    .frame(width: 32, height: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Custom Instructions")
                        .foregroundColor(themeManager.textColor)
                    
                    if preferencesService.preferences.hasCustomInstructions {
                        Text(preferencesService.preferences.customInstructions.prefix(40) + "...")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                            .lineLimit(1)
                    } else {
                        Text("Add your personal guidance")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                }
                
                Spacer()
                
                if preferencesService.preferences.hasCustomInstructions {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
        }
    }
    
    // MARK: - Usage Stats Row
    
    private var usageStatsRow: some View {
        Button {
            showingUsageStats = true
        } label: {
            HStack {
                Label("Your Journey", systemImage: "chart.bar.fill")
                    .foregroundColor(themeManager.textColor)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
        }
    }
    
    // MARK: - Data Export Row
    
    private var dataExportRow: some View {
        Button {
            showingDataExport = true
        } label: {
            HStack {
                Label("Data Management", systemImage: "square.and.arrow.up.on.square")
                    .foregroundColor(themeManager.textColor)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
        }
    }
    
    // MARK: - Tone Picker
    
    private var tonePickerRow: some View {
        NavigationLink {
            TonePickerView(selectedTone: Binding(
                get: { preferencesService.preferences.responseTone },
                set: { preferencesService.setResponseTone($0) }
            ))
        } label: {
            HStack {
                Label("Tone", systemImage: preferencesService.preferences.responseTone.icon)
                Spacer()
                Text(preferencesService.preferences.responseTone.rawValue)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
        }
    }
    
    // MARK: - Reading Level Picker
    
    private var readingLevelPickerRow: some View {
        NavigationLink {
            ReadingLevelPickerView(selectedLevel: Binding(
                get: { preferencesService.preferences.readingLevel },
                set: { preferencesService.setReadingLevel($0) }
            ))
        } label: {
            HStack {
                Label("Reading Level", systemImage: preferencesService.preferences.readingLevel.icon)
                Spacer()
                Text(preferencesService.preferences.readingLevel.rawValue)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
        }
    }
    
    // MARK: - Response Length Picker
    
    private var responseLengthPickerRow: some View {
        NavigationLink {
            ResponseLengthPickerView(selectedLength: Binding(
                get: { preferencesService.preferences.preferredResponseLength },
                set: { preferencesService.setPreferredResponseLength($0) }
            ))
        } label: {
            HStack {
                Label("Response Length", systemImage: preferencesService.preferences.preferredResponseLength.icon)
                Spacer()
                Text(preferencesService.preferences.preferredResponseLength.rawValue)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
        }
    }
    
    // MARK: - Denomination Picker
    
    private var denominationPickerRow: some View {
        NavigationLink {
            DenominationPickerView(selectedLens: Binding(
                get: { preferencesService.preferences.denominationLens },
                set: { preferencesService.setDenominationLens($0) }
            ))
        } label: {
            HStack {
                Label("Tradition", systemImage: preferencesService.preferences.denominationLens.icon)
                Spacer()
                Text(preferencesService.preferences.denominationLens.rawValue)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
        }
    }
    
    // MARK: - Controversial Topics Toggle
    
    private var controversialTopicsToggle: some View {
        Toggle(isOn: Binding(
            get: { preferencesService.preferences.avoidControversialTopics },
            set: { preferencesService.setAvoidControversialTopics($0) }
        )) {
            Label("Avoid Controversial Topics", systemImage: "exclamationmark.shield")
        }
    }
    
    // MARK: - Translation Row
    
    private var translationRow: some View {
        HStack {
            Label("Translation", systemImage: "book")
            Spacer()
            Text(preferencesService.preferences.defaultTranslation.uppercased())
                .foregroundColor(themeManager.secondaryTextColor)
        }
    }
    
    // MARK: - Memory Toggle
    
    private var memoryToggleRow: some View {
        Toggle(isOn: $preferencesService.isMemoryEnabled) {
            Label("Enable Memory", systemImage: "brain")
        }
        .onChange(of: preferencesService.isMemoryEnabled) { _, newValue in
            preferencesService.setMemoryEnabled(newValue)
            HapticManager.shared.selection()
        }
    }
}

// MARK: - Tone Picker View

struct TonePickerView: View {
    @Binding var selectedTone: ResponseTone
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            ForEach(ResponseTone.allCases) { tone in
                Button {
                    selectedTone = tone
                    HapticManager.shared.selection()
                    dismiss()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: tone.icon)
                                    .foregroundColor(themeManager.accentColor)
                                Text(tone.rawValue)
                                    .font(.headline)
                                    .foregroundColor(themeManager.textColor)
                            }
                            Text(tone.description)
                                .font(.caption)
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                        
                        Spacer()
                        
                        if selectedTone == tone {
                            Image(systemName: "checkmark")
                                .foregroundColor(themeManager.accentColor)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(themeManager.backgroundColor)
        .navigationTitle("Response Tone")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Reading Level Picker View

struct ReadingLevelPickerView: View {
    @Binding var selectedLevel: ReadingLevel
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            ForEach(ReadingLevel.allCases) { level in
                Button {
                    selectedLevel = level
                    HapticManager.shared.selection()
                    dismiss()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: level.icon)
                                    .foregroundColor(themeManager.accentColor)
                                Text(level.rawValue)
                                    .font(.headline)
                                    .foregroundColor(themeManager.textColor)
                            }
                            Text(level.description)
                                .font(.caption)
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                        
                        Spacer()
                        
                        if selectedLevel == level {
                            Image(systemName: "checkmark")
                                .foregroundColor(themeManager.accentColor)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(themeManager.backgroundColor)
        .navigationTitle("Reading Level")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Response Length Picker View

struct ResponseLengthPickerView: View {
    @Binding var selectedLength: ResponseLength
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            ForEach(ResponseLength.allCases) { length in
                Button {
                    selectedLength = length
                    HapticManager.shared.selection()
                    dismiss()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: length.icon)
                                    .foregroundColor(themeManager.accentColor)
                                Text(length.rawValue)
                                    .font(.headline)
                                    .foregroundColor(themeManager.textColor)
                            }
                            Text(length.description)
                                .font(.caption)
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                        
                        Spacer()
                        
                        if selectedLength == length {
                            Image(systemName: "checkmark")
                                .foregroundColor(themeManager.accentColor)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(themeManager.backgroundColor)
        .navigationTitle("Response Length")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Denomination Picker View

struct DenominationPickerView: View {
    @Binding var selectedLens: DenominationLens
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            ForEach(DenominationLens.allCases) { lens in
                Button {
                    selectedLens = lens
                    HapticManager.shared.selection()
                    dismiss()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: lens.icon)
                                    .foregroundColor(themeManager.accentColor)
                                Text(lens.rawValue)
                                    .font(.headline)
                                    .foregroundColor(themeManager.textColor)
                            }
                            Text(lens.description)
                                .font(.caption)
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                        
                        Spacer()
                        
                        if selectedLens == lens {
                            Image(systemName: "checkmark")
                                .foregroundColor(themeManager.accentColor)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(themeManager.backgroundColor)
        .navigationTitle("Theological Tradition")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview {
    AIPreferencesView()
}

