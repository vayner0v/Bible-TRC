//
//  VerseLinkingSheet.swift
//  Bible v1
//
//  Spiritual Journal - Verse Linking Components
//

import SwiftUI

/// Sheet for linking verses, highlights, and notes to journal entries
struct VerseLinkingSheet: View {
    @ObservedObject var viewModel: JournalViewModel
    @ObservedObject var favoritesViewModel: FavoritesViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTab: LinkingTab = .favorites
    @State private var searchQuery = ""
    
    enum LinkingTab: String, CaseIterable {
        case favorites = "Favorites"
        case highlights = "Highlights"
        case notes = "Notes"
        
        var icon: String {
            switch self {
            case .favorites: return "heart.fill"
            case .highlights: return "highlighter"
            case .notes: return "note.text"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Tab selector
                    HStack(spacing: 0) {
                        ForEach(LinkingTab.allCases, id: \.self) { tab in
                            tabButton(for: tab)
                        }
                    }
                    .padding(4)
                    .background(themeManager.cardBackgroundColor)
                    .cornerRadius(12)
                    .padding()
                    
                    // Search bar
                    searchBar
                        .padding(.horizontal)
                    
                    // Content based on tab
                    switch selectedTab {
                    case .favorites:
                        favoritesList
                    case .highlights:
                        highlightsList
                    case .notes:
                        notesList
                    }
                }
            }
            .navigationTitle("Link Scripture")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    // MARK: - Components
    
    private func tabButton(for tab: LinkingTab) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = tab
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: tab.icon)
                    .font(.caption)
                Text(tab.rawValue)
                    .font(.subheadline)
            }
            .foregroundColor(selectedTab == tab ? .white : themeManager.textColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(selectedTab == tab ? themeManager.accentColor : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(themeManager.secondaryTextColor)
            
            TextField("Search verses", text: $searchQuery)
                .foregroundColor(themeManager.textColor)
            
            if !searchQuery.isEmpty {
                Button {
                    searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
        }
        .padding()
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(12)
    }
    
    private var favoritesList: some View {
        let filtered = filteredFavorites
        
        return Group {
            if filtered.isEmpty {
                emptyState(
                    icon: "heart",
                    title: "No Favorites",
                    message: "Save verses as favorites while reading to link them here."
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filtered) { favorite in
                            let isLinked = viewModel.draftLinkedVerses.contains {
                                $0.bookId == favorite.bookId &&
                                $0.chapter == favorite.chapter &&
                                $0.verse == favorite.verse
                            }
                            
                            LinkableVerseRow(
                                reference: favorite.shortReference,
                                text: favorite.text,
                                isLinked: isLinked,
                                themeManager: themeManager
                            ) {
                                if isLinked {
                                    if let linked = viewModel.draftLinkedVerses.first(where: {
                                        $0.bookId == favorite.bookId &&
                                        $0.chapter == favorite.chapter &&
                                        $0.verse == favorite.verse
                                    }) {
                                        viewModel.removeLinkedVerse(linked)
                                    }
                                } else {
                                    let linkedVerse = LinkedVerse(
                                        translationId: favorite.translationId,
                                        bookId: favorite.bookId,
                                        bookName: favorite.bookName,
                                        chapter: favorite.chapter,
                                        verse: favorite.verse,
                                        text: favorite.text
                                    )
                                    viewModel.addLinkedVerse(linkedVerse)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    private var highlightsList: some View {
        let filtered = filteredHighlights
        
        return Group {
            if filtered.isEmpty {
                emptyState(
                    icon: "highlighter",
                    title: "No Highlights",
                    message: "Highlight verses while reading to link them here."
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filtered) { highlight in
                            let isLinked = viewModel.draftLinkedHighlightIds.contains(highlight.id)
                            
                            LinkableHighlightRow(
                                highlight: highlight,
                                isLinked: isLinked,
                                themeManager: themeManager
                            ) {
                                if isLinked {
                                    viewModel.unlinkHighlight(highlight.id)
                                } else {
                                    viewModel.linkHighlight(highlight.id)
                                    // Also add as linked verse
                                    let linkedVerse = LinkedVerse(
                                        translationId: highlight.translationId,
                                        bookId: highlight.bookId,
                                        bookName: highlight.bookName,
                                        chapter: highlight.chapter,
                                        verse: highlight.verse,
                                        text: highlight.text
                                    )
                                    viewModel.addLinkedVerse(linkedVerse)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    private var notesList: some View {
        let filtered = filteredNotes
        
        return Group {
            if filtered.isEmpty {
                emptyState(
                    icon: "note.text",
                    title: "No Notes",
                    message: "Add notes to verses while reading to link them here."
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filtered) { note in
                            let isLinked = viewModel.draftLinkedNoteIds.contains(note.id)
                            
                            LinkableNoteRow(
                                note: note,
                                isLinked: isLinked,
                                themeManager: themeManager
                            ) {
                                if isLinked {
                                    viewModel.unlinkNote(note.id)
                                } else {
                                    viewModel.linkNote(note.id)
                                    // Also add as linked verse
                                    let linkedVerse = LinkedVerse(
                                        translationId: note.translationId,
                                        bookId: note.bookId,
                                        bookName: note.bookName,
                                        chapter: note.chapter,
                                        verse: note.verse,
                                        text: note.verseText
                                    )
                                    viewModel.addLinkedVerse(linkedVerse)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    private func emptyState(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(themeManager.secondaryTextColor.opacity(0.5))
            
            Text(title)
                .font(.headline)
                .foregroundColor(themeManager.textColor)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(themeManager.secondaryTextColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    // MARK: - Filtering
    
    private var filteredFavorites: [Favorite] {
        let favorites = favoritesViewModel.sortedFavorites
        if searchQuery.isEmpty { return favorites }
        
        let query = searchQuery.lowercased()
        return favorites.filter {
            $0.shortReference.lowercased().contains(query) ||
            $0.text.lowercased().contains(query)
        }
    }
    
    private var filteredHighlights: [Highlight] {
        let highlights = favoritesViewModel.sortedHighlights
        if searchQuery.isEmpty { return highlights }
        
        let query = searchQuery.lowercased()
        return highlights.filter {
            $0.shortReference.lowercased().contains(query) ||
            $0.text.lowercased().contains(query)
        }
    }
    
    private var filteredNotes: [Note] {
        let notes = favoritesViewModel.sortedNotes
        if searchQuery.isEmpty { return notes }
        
        let query = searchQuery.lowercased()
        return notes.filter {
            $0.shortReference.lowercased().contains(query) ||
            $0.verseText.lowercased().contains(query) ||
            $0.noteText.lowercased().contains(query)
        }
    }
}

// MARK: - Linkable Row Components

struct LinkableVerseRow: View {
    let reference: String
    let text: String
    let isLinked: Bool
    let themeManager: ThemeManager
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                // Link indicator
                Image(systemName: isLinked ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isLinked ? .green : themeManager.secondaryTextColor)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(reference)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.accentColor)
                    
                    Text(text)
                        .font(.caption)
                        .foregroundColor(themeManager.textColor)
                        .lineLimit(3)
                }
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.cardBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isLinked ? Color.green.opacity(0.5) : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct LinkableHighlightRow: View {
    let highlight: Highlight
    let isLinked: Bool
    let themeManager: ThemeManager
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                // Link indicator
                Image(systemName: isLinked ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isLinked ? .green : themeManager.secondaryTextColor)
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(highlight.shortReference)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(themeManager.accentColor)
                        
                        Spacer()
                        
                        // Highlight color indicator
                        Circle()
                            .fill(highlight.color.solidColor)
                            .frame(width: 12, height: 12)
                    }
                    
                    Text(highlight.text)
                        .font(.caption)
                        .foregroundColor(themeManager.textColor)
                        .lineLimit(3)
                        .padding(6)
                        .background(highlight.color.color)
                        .cornerRadius(6)
                }
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.cardBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isLinked ? Color.green.opacity(0.5) : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct LinkableNoteRow: View {
    let note: Note
    let isLinked: Bool
    let themeManager: ThemeManager
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                // Link indicator
                Image(systemName: isLinked ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isLinked ? .green : themeManager.secondaryTextColor)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(note.shortReference)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.accentColor)
                    
                    Text(note.verseText)
                        .font(.caption)
                        .italic()
                        .foregroundColor(themeManager.secondaryTextColor)
                        .lineLimit(2)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "note.text")
                            .font(.caption2)
                            .foregroundColor(.orange)
                        
                        Text(note.noteText)
                            .font(.caption)
                            .foregroundColor(themeManager.textColor)
                            .lineLimit(2)
                    }
                    .padding(8)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.cardBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isLinked ? Color.green.opacity(0.5) : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VerseLinkingSheet(
        viewModel: JournalViewModel(),
        favoritesViewModel: FavoritesViewModel()
    )
}

