//
//  JournalSearchView.swift
//  Bible v1
//
//  Spiritual Journal - Search View
//

import SwiftUI

/// Full-text search view for journal entries
struct JournalSearchView: View {
    @ObservedObject var viewModel: JournalViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var localSearchQuery = ""
    @State private var searchResults: [JournalEntry] = []
    @State private var recentSearches: [String] = []
    @State private var isSearching = false
    
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search bar
                    searchBar
                        .padding()
                    
                    if localSearchQuery.isEmpty {
                        // Show recent searches and suggestions
                        emptySearchContent
                    } else if isSearching {
                        // Loading state
                        loadingView
                    } else if searchResults.isEmpty {
                        // No results
                        noResultsView
                    } else {
                        // Results list
                        resultsListView
                    }
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadRecentSearches()
                isSearchFocused = true
            }
        }
    }
    
    // MARK: - Components
    
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(themeManager.secondaryTextColor)
            
            TextField("Search entries...", text: $localSearchQuery)
                .foregroundColor(themeManager.textColor)
                .focused($isSearchFocused)
                .submitLabel(.search)
                .onSubmit {
                    performSearch()
                }
                .onChange(of: localSearchQuery) { _, newValue in
                    if !newValue.isEmpty {
                        debounceSearch()
                    } else {
                        searchResults = []
                    }
                }
            
            if !localSearchQuery.isEmpty {
                Button {
                    localSearchQuery = ""
                    searchResults = []
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
    
    private var emptySearchContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Recent searches
                if !recentSearches.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Recent Searches")
                                .font(.headline)
                                .foregroundColor(themeManager.textColor)
                            
                            Spacer()
                            
                            Button {
                                clearRecentSearches()
                            } label: {
                                Text("Clear")
                                    .font(.caption)
                                    .foregroundColor(themeManager.accentColor)
                            }
                        }
                        
                        ForEach(recentSearches, id: \.self) { query in
                            Button {
                                localSearchQuery = query
                                performSearch()
                            } label: {
                                HStack {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .foregroundColor(themeManager.secondaryTextColor)
                                    
                                    Text(query)
                                        .foregroundColor(themeManager.textColor)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "arrow.up.left")
                                        .font(.caption)
                                        .foregroundColor(themeManager.secondaryTextColor)
                                }
                                .padding()
                                .background(themeManager.cardBackgroundColor)
                                .cornerRadius(10)
                            }
                        }
                    }
                }
                
                // Search suggestions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Try Searching For")
                        .font(.headline)
                        .foregroundColor(themeManager.textColor)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 10) {
                        SearchSuggestionChip(text: "Gratitude", icon: "heart.fill", color: themeManager.accentColor, themeManager: themeManager) {
                            localSearchQuery = "Gratitude"
                            performSearch()
                        }
                        
                        SearchSuggestionChip(text: "Prayer", icon: "hands.sparkles.fill", color: themeManager.hubGlowColor, themeManager: themeManager) {
                            localSearchQuery = "Prayer"
                            performSearch()
                        }
                        
                        SearchSuggestionChip(text: "Peace", icon: "leaf.fill", color: themeManager.hubTileSecondaryColor, themeManager: themeManager) {
                            localSearchQuery = "Peace"
                            performSearch()
                        }
                        
                        SearchSuggestionChip(text: "Joy", icon: "sun.max.fill", color: themeManager.accentColor.opacity(0.8), themeManager: themeManager) {
                            localSearchQuery = "Joy"
                            performSearch()
                        }
                        
                        SearchSuggestionChip(text: "Reflection", icon: "brain.head.profile", color: themeManager.hubGlowColor.opacity(0.8), themeManager: themeManager) {
                            localSearchQuery = "Reflection"
                            performSearch()
                        }
                        
                        SearchSuggestionChip(text: "Scripture", icon: "book.fill", color: themeManager.accentColor, themeManager: themeManager) {
                            localSearchQuery = "Scripture"
                            performSearch()
                        }
                    }
                }
                
                // Stats
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your Journal")
                        .font(.headline)
                        .foregroundColor(themeManager.textColor)
                    
                    HStack(spacing: 16) {
                        StatCard(
                            value: "\(viewModel.entries.count)",
                            label: "Entries",
                            icon: "doc.text.fill",
                            color: themeManager.accentColor,
                            themeManager: themeManager
                        )
                        
                        StatCard(
                            value: "\(viewModel.currentStreak)",
                            label: "Day Streak",
                            icon: "flame.fill",
                            color: .orange,
                            themeManager: themeManager
                        )
                    }
                }
            }
            .padding()
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
            Text("Searching...")
                .font(.subheadline)
                .foregroundColor(themeManager.secondaryTextColor)
            Spacer()
        }
    }
    
    private var noResultsView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(themeManager.secondaryTextColor.opacity(0.5))
            
            Text("No Results")
                .font(.headline)
                .foregroundColor(themeManager.textColor)
            
            Text("No entries found matching \"\(localSearchQuery)\"")
                .font(.subheadline)
                .foregroundColor(themeManager.secondaryTextColor)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding()
    }
    
    private var resultsListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Results count
                HStack {
                    Text("\(searchResults.count) result\(searchResults.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                    Spacer()
                }
                .padding(.horizontal)
                
                ForEach(searchResults) { entry in
                    SearchResultCard(
                        entry: entry,
                        searchQuery: localSearchQuery,
                        themeManager: themeManager
                    ) {
                        // Could navigate to entry detail
                        viewModel.selectedEntry = entry
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Search Logic
    
    private func debounceSearch() {
        // Simple debounce implementation
        isSearching = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            performSearch()
        }
    }
    
    private func performSearch() {
        guard !localSearchQuery.isEmpty else {
            searchResults = []
            isSearching = false
            return
        }
        
        isSearching = true
        
        // Perform search
        let query = localSearchQuery.lowercased()
        searchResults = viewModel.entries.filter { entry in
            entry.title.lowercased().contains(query) ||
            entry.content.lowercased().contains(query) ||
            entry.tags.contains { $0.name.lowercased().contains(query) } ||
            entry.linkedVerses.contains { $0.shortReference.lowercased().contains(query) } ||
            (entry.mood?.displayName.lowercased().contains(query) ?? false)
        }.sorted { $0.dateCreated > $1.dateCreated }
        
        // Save to recent searches
        saveRecentSearch(localSearchQuery)
        
        isSearching = false
    }
    
    // MARK: - Recent Searches
    
    private func loadRecentSearches() {
        recentSearches = UserDefaults.standard.stringArray(forKey: "journal_recent_searches") ?? []
    }
    
    private func saveRecentSearch(_ query: String) {
        var searches = recentSearches
        searches.removeAll { $0.lowercased() == query.lowercased() }
        searches.insert(query, at: 0)
        if searches.count > 5 {
            searches = Array(searches.prefix(5))
        }
        recentSearches = searches
        UserDefaults.standard.set(searches, forKey: "journal_recent_searches")
    }
    
    private func clearRecentSearches() {
        recentSearches = []
        UserDefaults.standard.removeObject(forKey: "journal_recent_searches")
    }
}

// MARK: - Supporting Components

struct SearchSuggestionChip: View {
    let text: String
    let icon: String
    let color: Color
    let themeManager: ThemeManager
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                
                Text(text)
                    .font(.subheadline)
                    .foregroundColor(themeManager.textColor)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    let themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(themeManager.textColor)
            
            Text(label)
                .font(.caption)
                .foregroundColor(themeManager.secondaryTextColor)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(12)
    }
}

struct SearchResultCard: View {
    let entry: JournalEntry
    let searchQuery: String
    let themeManager: ThemeManager
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                // Header
                HStack {
                    Text(entry.formattedDate)
                        .font(.caption)
                        .foregroundColor(themeManager.accentColor)
                    
                    Spacer()
                    
                    if let mood = entry.mood {
                        HStack(spacing: 4) {
                            Image(systemName: mood.icon)
                                .font(.caption2)
                            Text(mood.displayName)
                                .font(.caption2)
                        }
                        .foregroundColor(mood.color)
                    }
                }
                
                // Title (if exists)
                if !entry.title.isEmpty {
                    Text(highlightedText(entry.title))
                        .font(.headline)
                        .foregroundColor(themeManager.textColor)
                        .lineLimit(1)
                }
                
                // Content preview with highlighted match
                Text(highlightedText(entry.previewText))
                    .font(.subheadline)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .lineLimit(3)
                
                // Tags
                if !entry.tags.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(entry.tags.prefix(3)) { tag in
                            HStack(spacing: 4) {
                                Image(systemName: tag.icon)
                                    .font(.caption2)
                                Text(tag.name)
                                    .font(.caption2)
                            }
                            .foregroundColor(tag.color)
                        }
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
    
    private func highlightedText(_ text: String) -> AttributedString {
        var attributedString = AttributedString(text)
        
        if let range = text.lowercased().range(of: searchQuery.lowercased()) {
            let nsRange = NSRange(range, in: text)
            if let attrRange = Range(nsRange, in: attributedString) {
                attributedString[attrRange].backgroundColor = themeManager.accentColor.opacity(0.3)
            }
        }
        
        return attributedString
    }
}

#Preview {
    JournalSearchView(viewModel: JournalViewModel())
}

