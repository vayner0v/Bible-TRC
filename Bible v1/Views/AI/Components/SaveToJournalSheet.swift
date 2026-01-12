//
//  SaveToJournalSheet.swift
//  Bible v1
//
//  TRC AI Bible Assistant - Journal Integration
//

import SwiftUI

/// Sheet for saving AI response to journal
struct SaveToJournalSheet: View {
    let content: String
    let citations: [AICitation]
    let onSave: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var editedContent: String = ""
    @State private var selectedMood: JournalMood?
    @State private var selectedTags: [JournalTag] = []
    @State private var showMoodPicker: Bool = false
    @State private var isSaving: Bool = false
    
    init(content: String, citations: [AICitation], onSave: @escaping () -> Void) {
        self.content = content
        self.citations = citations
        self.onSave = onSave
        self._editedContent = State(initialValue: content)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Title
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                        
                        TextField("Give this entry a title...", text: $title)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(themeManager.cardBackgroundColor)
                            .cornerRadius(12)
                    }
                    
                    // Content
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Content")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                        
                        TextEditor(text: $editedContent)
                            .frame(minHeight: 200)
                            .padding()
                            .background(themeManager.cardBackgroundColor)
                            .cornerRadius(12)
                            .scrollContentBackground(.hidden)
                    }
                    
                    // Linked Verses
                    if !citations.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Linked Verses")
                                .font(.caption)
                                .foregroundColor(themeManager.secondaryTextColor)
                            
                            FlowLayout(spacing: 8) {
                                ForEach(citations) { citation in
                                    HStack(spacing: 4) {
                                        Image(systemName: "book.fill")
                                            .font(.caption2)
                                        Text(citation.reference)
                                            .font(.caption)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(themeManager.accentColor.opacity(0.1))
                                    .foregroundColor(themeManager.accentColor)
                                    .cornerRadius(12)
                                }
                            }
                        }
                    }
                    
                    // Mood
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Mood (optional)")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                        
                        Button {
                            showMoodPicker = true
                        } label: {
                            HStack {
                                if let mood = selectedMood {
                                    Text(mood.emoji)
                                    Text(mood.displayName)
                                        .foregroundColor(themeManager.textColor)
                                } else {
                                    Text("Select mood...")
                                        .foregroundColor(themeManager.secondaryTextColor)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(themeManager.secondaryTextColor)
                            }
                            .padding()
                            .background(themeManager.cardBackgroundColor)
                            .cornerRadius(12)
                        }
                    }
                }
                .padding()
            }
            .background(themeManager.backgroundColor)
            .navigationTitle("Save to Journal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEntry()
                    }
                    .disabled(editedContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .sheet(isPresented: $showMoodPicker) {
                AIMoodPickerSheet(selectedMood: $selectedMood)
            }
        }
    }
    
    private func saveEntry() {
        isSaving = true
        
        // Build linked verses from citations
        let linkedVerses: [LinkedVerse] = citations.compactMap { citation -> LinkedVerse? in
            guard let bookId = citation.bookId,
                  let bookName = citation.bookName,
                  let chapter = citation.chapter,
                  let verse = citation.verseStart else { return nil }
            return LinkedVerse(
                translationId: citation.translationId,
                bookId: bookId,
                bookName: bookName,
                chapter: chapter,
                verse: verse,
                text: citation.text ?? ""
            )
        }
        
        // Create the journal entry directly
        let entry = JournalEntry(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty 
                ? "AI Insight" 
                : title.trimmingCharacters(in: .whitespacesAndNewlines),
            content: editedContent.trimmingCharacters(in: .whitespacesAndNewlines),
            mood: selectedMood,
            linkedVerses: linkedVerses,
            tags: selectedTags
        )
        
        // Use JournalStorageService.shared directly for persistence
        JournalStorageService.shared.addEntry(entry)
        
        onSave()
        HapticManager.shared.success()
        dismiss()
    }
}

// MARK: - AI Mood Picker Sheet (Renamed to avoid conflict with Journal's MoodPickerSheet)

struct AIMoodPickerSheet: View {
    @Binding var selectedMood: JournalMood?
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(JournalMood.allCases, id: \.self) { mood in
                        Button {
                            selectedMood = mood
                            dismiss()
                        } label: {
                            VStack(spacing: 8) {
                                Text(mood.emoji)
                                    .font(.largeTitle)
                                Text(mood.displayName)
                                    .font(.caption)
                                    .foregroundColor(themeManager.textColor)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                selectedMood == mood
                                ? themeManager.accentColor.opacity(0.2)
                                : themeManager.cardBackgroundColor
                            )
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        selectedMood == mood
                                        ? themeManager.accentColor
                                        : Color.clear,
                                        lineWidth: 2
                                    )
                            )
                        }
                    }
                }
                .padding()
            }
            .background(themeManager.backgroundColor)
            .navigationTitle("How are you feeling?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Quick Save Extension

extension TRCAIChatViewModel {
    
    /// Quick save to journal with minimal UI
    func quickSaveToJournal(_ message: ChatMessage) {
        // Format content
        var content = ""
        if let title = message.title {
            content += "## \(title)\n\n"
        }
        content += message.content
        
        // Add citations
        if !message.citations.isEmpty {
            content += "\n\n---\n**Verses:**\n"
            for citation in message.citations {
                content += "• \(citation.reference)\n"
            }
        }
        
        // Build linked verses from citations
        let linkedVerses: [LinkedVerse] = message.citations.compactMap { citation -> LinkedVerse? in
            guard let bookId = citation.bookId,
                  let bookName = citation.bookName,
                  let chapter = citation.chapter,
                  let verse = citation.verseStart else { return nil }
            return LinkedVerse(
                translationId: citation.translationId,
                bookId: bookId,
                bookName: bookName,
                chapter: chapter,
                verse: verse,
                text: citation.text ?? ""
            )
        }
        
        // Create entry directly with JournalStorageService
        let entry = JournalEntry(
            title: message.title ?? "AI Insight",
            content: content,
            linkedVerses: linkedVerses
        )
        
        JournalStorageService.shared.addEntry(entry)
        HapticManager.shared.success()
    }
}

// MARK: - Preview

#Preview {
    SaveToJournalSheet(
        content: "This is a sample AI response about John 3:16 and its meaning for our lives today.",
        citations: [
            AICitation(reference: "John 3:16", translationId: "engKJV", text: "For God so loved the world...")
        ],
        onSave: {}
    )
}

