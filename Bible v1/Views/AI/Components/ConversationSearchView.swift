//
//  ConversationSearchView.swift
//  Bible v1
//
//  TRC AI Bible Assistant - Enhanced Conversation Search
//

import SwiftUI

struct ConversationSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var storageService = ChatStorageService.shared
    
    @State private var searchText = ""
    @State private var searchResults: [ConversationSearchResult] = []
    @State private var includeArchived = false
    @State private var isSearching = false
    
    let onSelectConversation: (ChatConversation) -> Void
    let onSelectMessage: (ChatConversation, ChatMessage) -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                searchBar
                
                // Options
                optionsRow
                
                // Results
                if searchText.isEmpty {
                    emptySearchState
                } else if isSearching {
                    ProgressView("Searching...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if searchResults.isEmpty {
                    noResultsState
                } else {
                    resultsList
                }
            }
            .navigationTitle("Search Conversations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Components
    
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search in conversations...", text: $searchText)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .onChange(of: searchText) {
                    performSearch()
                }
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    searchResults = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding()
    }
    
    private var optionsRow: some View {
        HStack {
            Toggle("Include archived", isOn: $includeArchived)
                .toggleStyle(.switch)
                .font(.subheadline)
                .onChange(of: includeArchived) {
                    performSearch()
                }
            
            Spacer()
            
            if !searchResults.isEmpty {
                Text("\(searchResults.count) conversations")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    private var emptySearchState: some View {
        VStack(spacing: 16) {
            Image(systemName: "text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("Search Your Conversations")
                .font(.headline)
            
            Text("Find specific messages, verses, or topics across all your conversations.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var noResultsState: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Results Found")
                .font(.headline)
            
            Text("Try different keywords or enable \"Include archived\" to search older conversations.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(searchResults) { result in
                    ConversationSearchResultCard(
                        result: result,
                        searchQuery: searchText
                    ) { message in
                        if let msg = message {
                            onSelectMessage(result.conversation, msg)
                        } else {
                            onSelectConversation(result.conversation)
                        }
                        dismiss()
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Search Logic
    
    private func performSearch() {
        guard !searchText.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        
        // Debounce search
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            guard !searchText.isEmpty else {
                isSearching = false
                return
            }
            
            searchResults = storageService.searchWithHighlights(
                query: searchText,
                includeArchived: includeArchived
            )
            isSearching = false
        }
    }
}

// MARK: - Conversation Search Result Card

struct ConversationSearchResultCard: View {
    let result: ConversationSearchResult
    let searchQuery: String
    let onSelect: (ChatMessage?) -> Void
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Button {
                onSelect(nil)
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: result.conversation.currentMode.icon)
                                .foregroundColor(result.conversation.currentMode.accentColor)
                            
                            Text(result.conversation.title)
                                .font(.headline)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                        }
                        
                        HStack {
                            Text(result.conversation.dateModified, style: .relative)
                            Text("•")
                            Text("\(result.totalMatchCount) match\(result.totalMatchCount == 1 ? "" : "es")")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }
            
            // Preview snippet
            if let firstMatch = result.matchingMessages.first {
                HighlightedText(
                    text: firstMatch.contextSnippet,
                    highlight: searchQuery
                )
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            }
            
            // Expandable message matches
            if result.matchingMessages.count > 1 {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack {
                        Text(isExpanded ? "Show less" : "Show \(result.matchingMessages.count - 1) more match\(result.matchingMessages.count == 2 ? "" : "es")")
                            .font(.caption)
                            .foregroundColor(.accentColor)
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(.accentColor)
                    }
                }
                
                if isExpanded {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(result.matchingMessages.dropFirst())) { match in
                            Button {
                                onSelect(match.message)
                            } label: {
                                HStack(alignment: .top) {
                                    Image(systemName: match.message.role == .user ? "person.fill" : "sparkles")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .frame(width: 16)
                                    
                                    HighlightedText(
                                        text: match.contextSnippet,
                                        highlight: searchQuery
                                    )
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                                }
                            }
                        }
                    }
                    .padding(.leading, 8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Highlighted Text View

struct HighlightedText: View {
    let text: String
    let highlight: String
    
    var body: some View {
        let ranges = findHighlightRanges()
        
        if ranges.isEmpty {
            Text(text)
        } else {
            Text(attributedString)
        }
    }
    
    private var attributedString: AttributedString {
        var attributedString = AttributedString(text)
        let lowercasedText = text.lowercased()
        let lowercasedHighlight = highlight.lowercased()
        
        var searchRange = lowercasedText.startIndex..<lowercasedText.endIndex
        
        while let range = lowercasedText.range(of: lowercasedHighlight, range: searchRange) {
            // Convert String.Index to AttributedString range
            let startOffset = lowercasedText.distance(from: lowercasedText.startIndex, to: range.lowerBound)
            let endOffset = lowercasedText.distance(from: lowercasedText.startIndex, to: range.upperBound)
            
            let attrStart = attributedString.index(attributedString.startIndex, offsetByCharacters: startOffset)
            let attrEnd = attributedString.index(attributedString.startIndex, offsetByCharacters: endOffset)
            
            attributedString[attrStart..<attrEnd].foregroundColor = .accentColor
            attributedString[attrStart..<attrEnd].font = .body.bold()
            
            searchRange = range.upperBound..<lowercasedText.endIndex
        }
        
        return attributedString
    }
    
    private func findHighlightRanges() -> [Range<String.Index>] {
        var ranges: [Range<String.Index>] = []
        var searchRange = text.startIndex..<text.endIndex
        
        while let range = text.range(of: highlight, options: .caseInsensitive, range: searchRange) {
            ranges.append(range)
            searchRange = range.upperBound..<text.endIndex
        }
        
        return ranges
    }
}

#Preview {
    ConversationSearchView(
        onSelectConversation: { _ in },
        onSelectMessage: { _, _ in }
    )
}

