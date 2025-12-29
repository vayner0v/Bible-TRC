//
//  JournalEntryEditorView.swift
//  Bible v1
//
//  Spiritual Journal - Entry Editor with Rich Features
//

import SwiftUI
import PhotosUI

/// Full-featured journal entry editor
struct JournalEntryEditorView: View {
    @ObservedObject var viewModel: JournalViewModel
    @ObservedObject var favoritesViewModel: FavoritesViewModel
    @Binding var isPresented: Bool
    @ObservedObject private var themeManager = ThemeManager.shared
    
    @State private var showingMoodPicker = false
    @State private var showingTagPicker = false
    @State private var showingVerseLinking = false
    @State private var showingPhotoPicker = false
    @State private var showingPromptPicker = false
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var showDiscardAlert = false
    @State private var attributedContent = NSAttributedString()
    @State private var useRichEditor = true
    
    @FocusState private var isTitleFocused: Bool
    @FocusState private var isContentFocused: Bool
    
    private var isEditing: Bool {
        viewModel.editingEntry != nil
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Prompt banner (if using a prompt)
                        if let prompt = viewModel.draftPrompt {
                            promptBanner(prompt)
                        }
                        
                        // Mood selector row
                        moodSelectorRow
                        
                        // Title field
                        titleField
                        
                        // Rich text editor
                        contentEditor
                        
                        // Tags section
                        tagsSection
                        
                        // Linked verses section
                        linkedVersesSection
                        
                        // Photos section
                        photosSection
                        
                        // Bottom padding
                        Color.clear.frame(height: 100)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
            }
            .navigationTitle(isEditing ? "Edit Entry" : "New Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if viewModel.canSaveDraft {
                            showDiscardAlert = true
                        } else {
                            viewModel.cancelEditing()
                            isPresented = false
                        }
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.saveDraft()
                        isPresented = false
                    }
                    .fontWeight(.semibold)
                    .disabled(!viewModel.canSaveDraft)
                }
            }
            .sheet(isPresented: $showingMoodPicker) {
                MoodPickerSheet(selectedMood: $viewModel.draftMood)
            }
            .sheet(isPresented: $showingTagPicker) {
                TagPickerSheet(
                    selectedTags: $viewModel.draftTags,
                    allTags: viewModel.allTags,
                    onAddCustomTag: { name, color, icon in
                        viewModel.addCustomTag(name: name, colorName: color, icon: icon)
                    }
                )
            }
            .sheet(isPresented: $showingVerseLinking) {
                VerseLinkingSheet(
                    viewModel: viewModel,
                    favoritesViewModel: favoritesViewModel
                )
            }
            .sheet(isPresented: $showingPromptPicker) {
                PromptPickerSheet(
                    selectedPrompt: $viewModel.draftPrompt,
                    prompts: viewModel.allPrompts,
                    onSelect: { prompt in
                        if viewModel.draftContent.isEmpty {
                            viewModel.draftContent = prompt.text + "\n\n"
                        }
                    }
                )
            }
            .photosPicker(
                isPresented: $showingPhotoPicker,
                selection: $selectedPhotos,
                maxSelectionCount: 10,
                matching: .images
            )
            .onChange(of: selectedPhotos) { _, newItems in
                handlePhotoSelection(newItems)
            }
            .alert("Discard Changes?", isPresented: $showDiscardAlert) {
                Button("Discard", role: .destructive) {
                    viewModel.cancelEditing()
                    isPresented = false
                }
                Button("Keep Editing", role: .cancel) { }
            } message: {
                Text("Your changes will be lost.")
            }
        }
    }
    
    // MARK: - Components
    
    private func promptBanner(_ prompt: JournalPrompt) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: prompt.category.icon)
                    .foregroundColor(prompt.category.color)
                Text(prompt.category.displayName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(prompt.category.color)
                
                Spacer()
                
                Button {
                    viewModel.draftPrompt = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
            
            Text(prompt.text)
                .font(.subheadline)
                .foregroundColor(themeManager.textColor)
            
            if let verse = prompt.relatedVerse {
                Text(verse)
                    .font(.caption)
                    .italic()
                    .foregroundColor(themeManager.secondaryTextColor)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(prompt.category.color.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var moodSelectorRow: some View {
        Button {
            showingMoodPicker = true
        } label: {
            HStack {
                Text("How are you feeling?")
                    .font(.subheadline)
                    .foregroundColor(themeManager.secondaryTextColor)
                
                Spacer()
                
                if let mood = viewModel.draftMood {
                    HStack(spacing: 6) {
                        Image(systemName: mood.icon)
                        Text(mood.displayName)
                    }
                    .font(.subheadline)
                    .foregroundColor(mood.color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(mood.lightColor)
                    .cornerRadius(20)
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "face.smiling")
                        Text("Select mood")
                    }
                    .font(.subheadline)
                    .foregroundColor(themeManager.accentColor)
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            .padding()
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(12)
        }
    }
    
    private var titleField: some View {
        TextField("Entry title (optional)", text: $viewModel.draftTitle)
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundColor(themeManager.textColor)
            .focused($isTitleFocused)
            .padding()
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(12)
    }
    
    private var contentEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Editor toggle
            HStack {
                Text("Content")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.secondaryTextColor)
                
                Spacer()
                
                Toggle("", isOn: $useRichEditor)
                    .labelsHidden()
                    .scaleEffect(0.8)
                
                Text(useRichEditor ? "Rich" : "Plain")
                    .font(.caption2)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            .padding(.horizontal, 4)
            
            if useRichEditor {
                RichTextEditor(
                    text: $viewModel.draftContent,
                    attributedText: $attributedContent
                )
                .frame(minHeight: 200)
            } else {
                TextEditor(text: $viewModel.draftContent)
                    .font(.body)
                    .foregroundColor(themeManager.textColor)
                    .focused($isContentFocused)
                    .frame(minHeight: 200)
                    .scrollContentBackground(.hidden)
                    .padding()
                    .background(themeManager.cardBackgroundColor)
                    .cornerRadius(12)
            }
            
            HStack {
                Text("\(viewModel.draftContent.split(separator: " ").count) words")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
                
                Spacer()
                
                Button {
                    showingPromptPicker = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "lightbulb")
                        Text("Get Prompt")
                    }
                    .font(.caption)
                    .foregroundColor(themeManager.accentColor)
                }
            }
        }
    }
    
    
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Tags")
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
                
                Spacer()
                
                Button {
                    showingTagPicker = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Add")
                    }
                    .font(.subheadline)
                    .foregroundColor(themeManager.accentColor)
                }
            }
            
            if viewModel.draftTags.isEmpty {
                Text("No tags selected")
                    .font(.subheadline)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .italic()
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(viewModel.draftTags) { tag in
                        HStack(spacing: 6) {
                            Image(systemName: tag.icon)
                                .font(.caption)
                            Text(tag.name)
                                .font(.caption)
                            
                            Button {
                                viewModel.toggleTag(tag)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                            }
                        }
                        .foregroundColor(tag.color)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(tag.lightColor)
                        .cornerRadius(20)
                    }
                }
            }
        }
        .padding()
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(12)
    }
    
    private var linkedVersesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Linked Verses")
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
                
                Spacer()
                
                Button {
                    showingVerseLinking = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "link")
                        Text("Link")
                    }
                    .font(.subheadline)
                    .foregroundColor(themeManager.accentColor)
                }
            }
            
            if viewModel.draftLinkedVerses.isEmpty &&
               viewModel.draftLinkedHighlightIds.isEmpty &&
               viewModel.draftLinkedNoteIds.isEmpty {
                
                // Suggestion banner if user has saved items
                if !favoritesViewModel.favorites.isEmpty || 
                   !favoritesViewModel.highlights.isEmpty ||
                   !favoritesViewModel.notes.isEmpty {
                    suggestionBanner
                } else {
                    Text("No verses linked yet")
                        .font(.subheadline)
                        .foregroundColor(themeManager.secondaryTextColor)
                        .italic()
                }
            } else {
                VStack(spacing: 8) {
                    ForEach(viewModel.draftLinkedVerses) { verse in
                        LinkedVerseRow(verse: verse, themeManager: themeManager) {
                            viewModel.removeLinkedVerse(verse)
                        }
                    }
                }
            }
        }
        .padding()
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(12)
    }
    
    private var suggestionBanner: some View {
        Button {
            showingVerseLinking = true
        } label: {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(themeManager.accentColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Quick Add from Saved")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.textColor)
                    
                    Text("Link your favorites, highlights, or notes")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            .padding()
            .background(themeManager.accentColor.opacity(0.1))
            .cornerRadius(10)
        }
    }
    
    private var photosSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Photos")
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
                
                Spacer()
                
                Button {
                    showingPhotoPicker = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "photo.badge.plus")
                        Text("Add")
                    }
                    .font(.subheadline)
                    .foregroundColor(themeManager.accentColor)
                }
            }
            
            if viewModel.draftPhotoFileNames.isEmpty {
                Text("No photos attached")
                    .font(.subheadline)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .italic()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.draftPhotoFileNames, id: \.self) { fileName in
                            PhotoThumbnail(
                                fileName: fileName,
                                photoURL: viewModel.photoURL(for: fileName),
                                onRemove: { viewModel.removePhoto(fileName: fileName) }
                            )
                        }
                    }
                }
            }
        }
        .padding()
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // MARK: - Photo Handling
    
    private func handlePhotoSelection(_ items: [PhotosPickerItem]) {
        Task {
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    await MainActor.run {
                        viewModel.addPhoto(data: data)
                    }
                }
            }
            selectedPhotos = []
        }
    }
}

// MARK: - Linked Verse Row

struct LinkedVerseRow: View {
    let verse: LinkedVerse
    let themeManager: ThemeManager
    let onRemove: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(verse.shortReference)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.accentColor)
                
                Spacer()
                
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
            
            Text(verse.text)
                .font(.caption)
                .foregroundColor(themeManager.textColor)
                .lineLimit(2)
        }
        .padding()
        .background(themeManager.backgroundColor)
        .cornerRadius(10)
    }
}

// MARK: - Photo Thumbnail

struct PhotoThumbnail: View {
    let fileName: String
    let photoURL: URL?
    let onRemove: () -> Void
    
    @State private var image: UIImage?
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .overlay {
                        ProgressView()
                    }
            }
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.white)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }
            .offset(x: 6, y: -6)
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        guard let url = photoURL else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            if let data = try? Data(contentsOf: url),
               let loadedImage = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.image = loadedImage
                }
            }
        }
    }
}

// FlowLayout is defined in PrayerLibraryView.swift and reused here

#Preview {
    JournalEntryEditorView(
        viewModel: JournalViewModel(),
        favoritesViewModel: FavoritesViewModel(),
        isPresented: .constant(true)
    )
}

