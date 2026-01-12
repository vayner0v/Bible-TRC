//
//  SearchView.swift
//  Bible v1
//
//  Advanced Bible Reader App
//

import SwiftUI

/// Search view for finding verses
struct SearchView: View {
    @ObservedObject var viewModel: SearchViewModel
    @ObservedObject var bibleViewModel: BibleViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    
    @State private var isSearchFocused = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search scope picker
                    if !viewModel.searchQuery.isEmpty || viewModel.hasSearched {
                        Picker("Scope", selection: $viewModel.searchScope) {
                            ForEach(SearchViewModel.SearchScope.allCases, id: \.self) { scope in
                                Text(scope.displayName).tag(scope)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                    }
                    
                    // Content
                    if viewModel.isSearching {
                        LoadingView("Searching...")
                    } else if viewModel.hasSearched {
                        searchResultsView
                    } else {
                        searchSuggestionsView
                    }
                }
            }
            .navigationTitle("Search")
            .searchable(
                text: $viewModel.searchQuery,
                isPresented: $isSearchFocused,
                prompt: "Search verses or enter reference"
            )
            .onSubmit(of: .search) {
                Task {
                    await viewModel.search()
                }
            }
        }
    }
    
    private var searchResultsView: some View {
        Group {
            if viewModel.searchResults.isEmpty {
                EmptyStateView(
                    icon: "magnifyingglass",
                    title: "No Results",
                    message: "Try a different search term or check spelling",
                    actionTitle: "Clear Search",
                    action: { viewModel.clearSearch() }
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // Results count
                        HStack {
                            Text("\(viewModel.searchResults.count) results found")
                                .font(.subheadline)
                                .foregroundColor(themeManager.secondaryTextColor)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        
                        // Results
                        ForEach(viewModel.searchResults) { result in
                            Button {
                                navigateToVerse(result.reference)
                            } label: {
                                SearchResultRow(result: result, themeManager: themeManager)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
    
    private var searchSuggestionsView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Recent searches
                if !viewModel.recentSearches.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            Text("Recent")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(themeManager.secondaryTextColor)
                            
                            Spacer()
                            
                            Button("Clear") {
                                viewModel.clearRecentSearches()
                            }
                            .font(.caption)
                            .foregroundColor(themeManager.accentColor)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 12)
                        
                        ForEach(viewModel.recentSearches, id: \.self) { query in
                            Button {
                                viewModel.searchQuery = query
                                Task {
                                    await viewModel.search()
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "clock")
                                        .foregroundColor(themeManager.secondaryTextColor)
                                    
                                    Text(query)
                                        .foregroundColor(themeManager.textColor)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "arrow.up.left")
                                        .font(.caption)
                                        .foregroundColor(themeManager.secondaryTextColor)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                // Popular verses
                VStack(alignment: .leading, spacing: 0) {
                    Text("Popular Verses")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.secondaryTextColor)
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .padding(.bottom, 12)
                    
                    ForEach(viewModel.popularVerses) { verse in
                        Button {
                            viewModel.searchQuery = verse.shortReference
                            Task {
                                await viewModel.search()
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(verse.shortReference)
                                    .font(.headline)
                                    .foregroundColor(themeManager.accentColor)
                                
                                Text(verse.text)
                                    .font(.subheadline)
                                    .foregroundColor(themeManager.secondaryTextColor)
                                    .lineLimit(2)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                // Search tips
                VStack(alignment: .leading, spacing: 12) {
                    Text("Search Tips")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.secondaryTextColor)
                        .padding(.top, 24)
                    
                    SearchTipRow(
                        example: "John 3:16",
                        description: "Jump to a specific verse",
                        themeManager: themeManager
                    )
                    
                    SearchTipRow(
                        example: "Romans 8:28-30",
                        description: "Find a range of verses",
                        themeManager: themeManager
                    )
                    
                    SearchTipRow(
                        example: "love",
                        description: "Search for keywords",
                        themeManager: themeManager
                    )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
    }
    
    private func navigateToVerse(_ reference: VerseReference) {
        Task {
            // Find the book and navigate
            if let book = bibleViewModel.books.first(where: { $0.id == reference.bookId }) {
                await bibleViewModel.selectBook(book, chapter: reference.chapter)
            }
        }
    }
}

/// Search result row
struct SearchResultRow: View {
    let result: SearchResult
    @ObservedObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(result.reference.shortReference)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.accentColor)
            
            Text(result.highlightedText)
                .font(.body)
                .foregroundColor(themeManager.textColor)
                .lineLimit(3)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(themeManager.cardBackgroundColor)
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
}

/// Search tip row
struct SearchTipRow: View {
    let example: String
    let description: String
    @ObservedObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 12) {
            Text(example)
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.medium)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(themeManager.cardBackgroundColor)
                .foregroundColor(themeManager.accentColor)
                .cornerRadius(6)
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(themeManager.secondaryTextColor)
        }
    }
}

// Keep old SearchTip for backward compatibility
struct SearchTip: View {
    let example: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(example)
                .font(.system(.caption, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(4)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    SearchView(
        viewModel: SearchViewModel(),
        bibleViewModel: BibleViewModel()
    )
}
