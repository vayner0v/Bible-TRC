//
//  FavoritesView.swift
//  Bible v1
//
//  Advanced Bible Reader App
//

import SwiftUI

/// View for displaying saved favorites, highlights, and notes
struct FavoritesView: View {
    @ObservedObject var viewModel: FavoritesViewModel
    @ObservedObject var bibleViewModel: BibleViewModel
    @ObservedObject var themeManager = ThemeManager.shared
    
    @State private var selectedTab: SavedContentTab = .favorites
    @State private var searchText = ""
    @State private var showDeleteConfirmation = false
    @State private var itemToDelete: Any?
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom segmented control
                    CustomSegmentedControl(
                        selection: $selectedTab,
                        themeManager: themeManager
                    )
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Search bar
                    SearchBar(
                        text: $searchText,
                        placeholder: "Search \(selectedTab.rawValue.lowercased())...",
                        themeManager: themeManager
                    )
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    
                    // Content
                    TabView(selection: $selectedTab) {
                        FavoritesListView(
                            favorites: filteredFavorites,
                            themeManager: themeManager,
                            onDelete: { favorite in
                                viewModel.removeFavorite(favorite)
                            },
                            onSelect: { favorite in
                                navigateToVerse(from: favorite)
                            }
                        )
                        .tag(SavedContentTab.favorites)
                        
                        HighlightsListView(
                            highlights: filteredHighlights,
                            themeManager: themeManager,
                            onDelete: { highlight in
                                viewModel.removeHighlight(highlight)
                            },
                            onSelect: { highlight in
                                navigateToVerse(from: highlight)
                            }
                        )
                        .tag(SavedContentTab.highlights)
                        
                        NotesListView(
                            notes: filteredNotes,
                            themeManager: themeManager,
                            onDelete: { note in
                                viewModel.removeNote(note)
                            },
                            onSelect: { note in
                                navigateToVerse(from: note)
                            },
                            onEdit: { note in
                                // Could show edit sheet here
                            }
                        )
                        .tag(SavedContentTab.notes)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut(duration: 0.2), value: selectedTab)
                }
            }
            .navigationTitle("Saved")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(role: .destructive) {
                            clearAllForCurrentTab()
                        } label: {
                            Label("Clear All \(selectedTab.rawValue)", systemImage: "trash")
                        }
                        .disabled(isCurrentTabEmpty)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(themeManager.accentColor)
                    }
                }
            }
        }
    }
    
    // MARK: - Filtered Content
    
    private var filteredFavorites: [Favorite] {
        if searchText.isEmpty {
            return viewModel.favorites
        }
        return viewModel.favorites.filter { favorite in
            favorite.verseText.localizedCaseInsensitiveContains(searchText) ||
            favorite.reference.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var filteredHighlights: [Highlight] {
        if searchText.isEmpty {
            return viewModel.highlights
        }
        return viewModel.highlights.filter { highlight in
            highlight.verseText.localizedCaseInsensitiveContains(searchText) ||
            highlight.reference.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var filteredNotes: [Note] {
        if searchText.isEmpty {
            return viewModel.notes
        }
        return viewModel.notes.filter { note in
            note.noteText.localizedCaseInsensitiveContains(searchText) ||
            note.verseText.localizedCaseInsensitiveContains(searchText) ||
            note.reference.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var isCurrentTabEmpty: Bool {
        switch selectedTab {
        case .favorites: return viewModel.favorites.isEmpty
        case .highlights: return viewModel.highlights.isEmpty
        case .notes: return viewModel.notes.isEmpty
        }
    }
    
    // MARK: - Actions
    
    private func clearAllForCurrentTab() {
        switch selectedTab {
        case .favorites:
            viewModel.favorites.forEach { viewModel.removeFavorite($0) }
        case .highlights:
            viewModel.highlights.forEach { viewModel.removeHighlight($0) }
        case .notes:
            viewModel.notes.forEach { viewModel.removeNote($0) }
        }
    }
    
    private func navigateToVerse(from favorite: Favorite) {
        // Parse reference and navigate
        bibleViewModel.navigateToReference(favorite.reference)
    }
    
    private func navigateToVerse(from highlight: Highlight) {
        bibleViewModel.navigateToReference(highlight.reference)
    }
    
    private func navigateToVerse(from note: Note) {
        bibleViewModel.navigateToReference(note.reference)
    }
}

// MARK: - Supporting Types

enum SavedContentTab: String, CaseIterable {
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

// MARK: - Custom Segmented Control

struct CustomSegmentedControl: View {
    @Binding var selection: SavedContentTab
    @ObservedObject var themeManager: ThemeManager
    @Namespace private var animation
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(SavedContentTab.allCases, id: \.self) { tab in
                SegmentButton(
                    tab: tab,
                    isSelected: selection == tab,
                    animation: animation,
                    themeManager: themeManager
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selection = tab
                        HapticManager.shared.lightImpact()
                    }
                }
            }
        }
        .padding(4)
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(14)
    }
}

struct SegmentButton: View {
    let tab: SavedContentTab
    let isSelected: Bool
    var animation: Namespace.ID
    @ObservedObject var themeManager: ThemeManager
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: tab.icon)
                    .font(.caption)
                Text(tab.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : themeManager.textColor)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background {
                if isSelected {
                    Capsule()
                        .fill(themeManager.accentGradient)
                        .matchedGeometryEffect(id: "segment", in: animation)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Search Bar

struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    @ObservedObject var themeManager: ThemeManager
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(themeManager.secondaryTextColor)
            
            TextField(placeholder, text: $text)
                .foregroundColor(themeManager.textColor)
                .focused($isFocused)
                .tint(themeManager.accentColor)
            
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(12)
    }
}

// MARK: - Favorites List

struct FavoritesListView: View {
    let favorites: [Favorite]
    @ObservedObject var themeManager: ThemeManager
    let onDelete: (Favorite) -> Void
    let onSelect: (Favorite) -> Void
    
    var body: some View {
        if favorites.isEmpty {
            EmptyStateView(
                icon: "heart",
                title: "No Favorites Yet",
                message: "Tap on any verse to save it to your favorites",
                actionTitle: nil,
                action: nil,
                themeManager: themeManager
            )
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(Array(favorites.enumerated()), id: \.element.id) { index, favorite in
                        FavoriteCard(
                            favorite: favorite,
                            themeManager: themeManager,
                            onTap: { onSelect(favorite) },
                            onDelete: { onDelete(favorite) }
                        )
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .trailing)),
                            removal: .opacity.combined(with: .scale(scale: 0.8))
                        ))
                        .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(Double(index) * 0.03), value: favorites.count)
                    }
                }
                .padding()
            }
        }
    }
}

struct FavoriteCard: View {
    let favorite: Favorite
    @ObservedObject var themeManager: ThemeManager
    let onTap: () -> Void
    let onDelete: () -> Void
    
    @State private var showingDeleteConfirm = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(favorite.reference)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(themeManager.accentColor)
                        
                        Text(favorite.translationId)
                            .font(.caption2)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Text(favorite.verseText)
                    .font(themeManager.subheadingFont)
                    .foregroundColor(themeManager.textColor)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                
                HStack {
                    Text(formatDate(favorite.createdAt))
                        .font(.caption2)
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    Spacer()
                    
                    Button {
                        showingDeleteConfirm = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                }
            }
            .padding()
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(16)
            .shadow(color: themeManager.hubShadowColor, radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .confirmationDialog("Delete Favorite?", isPresented: $showingDeleteConfirm) {
            Button("Delete", role: .destructive) {
                withAnimation {
                    onDelete()
                }
            }
            Button("Cancel", role: .cancel) { }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Highlights List

struct HighlightsListView: View {
    let highlights: [Highlight]
    @ObservedObject var themeManager: ThemeManager
    let onDelete: (Highlight) -> Void
    let onSelect: (Highlight) -> Void
    
    var body: some View {
        if highlights.isEmpty {
            EmptyStateView(
                icon: "highlighter",
                title: "No Highlights Yet",
                message: "Highlight verses to mark important passages",
                actionTitle: nil,
                action: nil,
                themeManager: themeManager
            )
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(Array(highlights.enumerated()), id: \.element.id) { index, highlight in
                        HighlightCard(
                            highlight: highlight,
                            themeManager: themeManager,
                            onTap: { onSelect(highlight) },
                            onDelete: { onDelete(highlight) }
                        )
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .trailing)),
                            removal: .opacity.combined(with: .scale(scale: 0.8))
                        ))
                        .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(Double(index) * 0.03), value: highlights.count)
                    }
                }
                .padding()
            }
        }
    }
}

struct HighlightCard: View {
    let highlight: Highlight
    @ObservedObject var themeManager: ThemeManager
    let onTap: () -> Void
    let onDelete: () -> Void
    
    @State private var showingDeleteConfirm = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(highlight.reference)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(themeManager.accentColor)
                        
                        Text(highlight.translationId)
                            .font(.caption2)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    
                    Spacer()
                    
                    // Highlight color indicator
                    Circle()
                        .fill(highlight.color.color)
                        .frame(width: 16, height: 16)
                        .overlay(
                            Circle()
                                .strokeBorder(themeManager.dividerColor, lineWidth: 1)
                        )
                }
                
                Text(highlight.verseText)
                    .font(themeManager.subheadingFont)
                    .foregroundColor(themeManager.textColor)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .background(highlight.color.color)
                    .cornerRadius(8)
                
                HStack {
                    Text(formatDate(highlight.createdAt))
                        .font(.caption2)
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    Spacer()
                    
                    Button {
                        showingDeleteConfirm = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                }
            }
            .padding()
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(16)
            .shadow(color: themeManager.hubShadowColor, radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .confirmationDialog("Delete Highlight?", isPresented: $showingDeleteConfirm) {
            Button("Delete", role: .destructive) {
                withAnimation {
                    onDelete()
                }
            }
            Button("Cancel", role: .cancel) { }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Notes List

struct NotesListView: View {
    let notes: [Note]
    @ObservedObject var themeManager: ThemeManager
    let onDelete: (Note) -> Void
    let onSelect: (Note) -> Void
    let onEdit: (Note) -> Void
    
    var body: some View {
        if notes.isEmpty {
            EmptyStateView(
                icon: "note.text",
                title: "No Notes Yet",
                message: "Add personal notes to verses for deeper study",
                actionTitle: nil,
                action: nil,
                themeManager: themeManager
            )
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(Array(notes.enumerated()), id: \.element.id) { index, note in
                        NoteCard(
                            note: note,
                            themeManager: themeManager,
                            onTap: { onSelect(note) },
                            onEdit: { onEdit(note) },
                            onDelete: { onDelete(note) }
                        )
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .trailing)),
                            removal: .opacity.combined(with: .scale(scale: 0.8))
                        ))
                        .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(Double(index) * 0.03), value: notes.count)
                    }
                }
                .padding()
            }
        }
    }
}

struct NoteCard: View {
    let note: Note
    @ObservedObject var themeManager: ThemeManager
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var showingDeleteConfirm = false
    @State private var isExpanded = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(note.reference)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(themeManager.accentColor)
                        
                        Text(note.translationId)
                            .font(.caption2)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "note.text")
                        .foregroundColor(themeManager.accentColor)
                        .font(.caption)
                }
                
                // Verse text (collapsed)
                if !note.verseText.isEmpty {
                    Text(note.verseText)
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                        .lineLimit(isExpanded ? nil : 2)
                        .italic()
                }
                
                // Note text
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                        .background(themeManager.dividerColor)
                    
                    Text(note.noteText)
                        .font(themeManager.subheadingFont)
                        .foregroundColor(themeManager.textColor)
                        .lineLimit(isExpanded ? nil : 4)
                        .multilineTextAlignment(.leading)
                    
                    if note.noteText.count > 150 {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isExpanded.toggle()
                            }
                        } label: {
                            Text(isExpanded ? "Show less" : "Show more")
                                .font(.caption)
                                .foregroundColor(themeManager.accentColor)
                        }
                    }
                }
                
                // Footer
                HStack {
                    Text(formatDate(note.createdAt))
                        .font(.caption2)
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    Spacer()
                    
                    Button {
                        onEdit()
                    } label: {
                        Image(systemName: "pencil")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    .padding(.trailing, 8)
                    
                    Button {
                        showingDeleteConfirm = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.cardBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(themeManager.accentColor.opacity(0.2), lineWidth: 1)
                    )
            )
            .shadow(color: themeManager.hubShadowColor, radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .confirmationDialog("Delete Note?", isPresented: $showingDeleteConfirm) {
            Button("Delete", role: .destructive) {
                withAnimation {
                    onDelete()
                }
            }
            Button("Cancel", role: .cancel) { }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    FavoritesView(
        viewModel: FavoritesViewModel(),
        bibleViewModel: BibleViewModel()
    )
}
