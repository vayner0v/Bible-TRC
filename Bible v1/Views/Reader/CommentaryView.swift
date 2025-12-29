//
//  CommentaryView.swift
//  Bible v1
//
//  Advanced Bible Reader App - Phase 3
//

import SwiftUI

/// View for displaying Bible commentaries
struct CommentaryView: View {
    @ObservedObject var bibleViewModel: BibleViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    
    @State private var commentaries: [Commentary] = []
    @State private var selectedCommentary: Commentary?
    @State private var commentaryContent: CommentaryChapter?
    @State private var isLoading = false
    @State private var showCommentaryPicker = false
    @State private var error: BibleError?
    
    private let apiService = BibleAPIService.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Commentary selector
                    Button {
                        showCommentaryPicker = true
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(selectedCommentary?.name ?? "Select Commentary")
                                    .font(.headline)
                                
                                if let chapter = bibleViewModel.currentChapter {
                                    Text(chapter.reference)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.down")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                    }
                    .buttonStyle(.plain)
                    
                    Divider()
                    
                    // Content
                    if isLoading {
                        LoadingView("Loading commentary...")
                    } else if let content = commentaryContent {
                        commentaryContentView(content)
                    } else if selectedCommentary == nil {
                        EmptyStateView(
                            icon: "book.closed",
                            title: "No Commentary Selected",
                            message: "Choose a commentary to view notes and insights for this passage",
                            actionTitle: "Select Commentary",
                            action: { showCommentaryPicker = true }
                        )
                    } else {
                        EmptyStateView(
                            icon: "text.book.closed",
                            title: "No Commentary Available",
                            message: "This commentary doesn't have content for the current chapter"
                        )
                    }
                }
            }
            .navigationTitle("Commentary")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showCommentaryPicker) {
                CommentaryPickerSheet(
                    commentaries: commentaries,
                    selectedCommentary: $selectedCommentary,
                    onSelect: { loadCommentary() }
                )
            }
            .task {
                await loadCommentaries()
            }
            .onChange(of: bibleViewModel.currentChapter?.id) { _, _ in
                loadCommentary()
            }
        }
    }
    
    @ViewBuilder
    private func commentaryContentView(_ content: CommentaryChapter) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                ForEach(content.content) { item in
                    VStack(alignment: .leading, spacing: 8) {
                        if let heading = item.heading {
                            Text(heading)
                                .font(.headline)
                                .foregroundColor(.accentColor)
                        }
                        
                        if let verse = item.verse {
                            Text("Verse \(verse)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                        }
                        
                        if let text = item.text {
                            Text(text)
                                .font(themeManager.verseFont)
                                .foregroundColor(themeManager.textColor)
                                .lineSpacing(themeManager.lineSpacing)
                        }
                    }
                    .padding()
                    .background(themeManager.cardBackgroundColor)
                    .cornerRadius(12)
                }
            }
            .padding()
        }
    }
    
    private func loadCommentaries() async {
        do {
            commentaries = try await apiService.fetchCommentaries()
            
            // Auto-select first commentary if none selected
            if selectedCommentary == nil, let first = commentaries.first {
                selectedCommentary = first
                loadCommentary()
            }
        } catch {
            print("Failed to load commentaries: \(error)")
        }
    }
    
    private func loadCommentary() {
        guard let commentary = selectedCommentary,
              let book = bibleViewModel.selectedBook else { return }
        
        let chapter = bibleViewModel.currentChapterNumber
        
        isLoading = true
        
        Task {
            do {
                commentaryContent = try await apiService.fetchCommentary(
                    commentaryId: commentary.id,
                    bookId: book.id,
                    chapter: chapter
                )
            } catch {
                commentaryContent = nil
            }
            isLoading = false
        }
    }
}

/// Commentary picker sheet
struct CommentaryPickerSheet: View {
    let commentaries: [Commentary]
    @Binding var selectedCommentary: Commentary?
    let onSelect: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                if commentaries.isEmpty {
                    Text("No commentaries available")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(commentaries) { commentary in
                        Button {
                            selectedCommentary = commentary
                            onSelect()
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(commentary.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    if let language = commentary.language {
                                        Text(language.languageDisplayName)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                if commentary.id == selectedCommentary?.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Commentaries")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

/// Expandable commentary panel for reader view
struct CommentaryPanel: View {
    let commentary: Commentary?
    let content: CommentaryChapter?
    let isExpanded: Bool
    let onToggle: () -> Void
    let onSelectCommentary: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: onToggle) {
                HStack {
                    Image(systemName: "book.closed")
                        .foregroundColor(.accentColor)
                    
                    Text(commentary?.name ?? "Commentary")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(themeManager.cardBackgroundColor)
            }
            .buttonStyle(.plain)
            
            // Content
            if isExpanded {
                if let content = content {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(content.content.prefix(3)) { item in
                            if let text = item.text {
                                Text(text)
                                    .font(.subheadline)
                                    .foregroundColor(themeManager.textColor)
                                    .lineLimit(4)
                            }
                        }
                        
                        if content.content.count > 3 {
                            Text("Tap to read more...")
                                .font(.caption)
                                .foregroundColor(.accentColor)
                        }
                    }
                    .padding()
                    .background(themeManager.backgroundColor)
                } else {
                    Button(action: onSelectCommentary) {
                        Text("Select a commentary")
                            .font(.subheadline)
                            .foregroundColor(.accentColor)
                            .padding()
                    }
                }
            }
        }
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    }
}

#Preview {
    CommentaryView(bibleViewModel: BibleViewModel())
}




