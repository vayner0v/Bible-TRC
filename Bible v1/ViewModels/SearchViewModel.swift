//
//  SearchViewModel.swift
//  Bible v1
//
//  Advanced Bible Reader App
//

import Foundation
import SwiftUI
import Combine

/// Search result model
struct SearchResult: Identifiable {
    let id = UUID()
    let reference: VerseReference
    let matchRange: Range<String.Index>?
    
    var highlightedText: AttributedString {
        var attributed = AttributedString(reference.text)
        if let range = matchRange,
           let attrRange = Range(range, in: attributed) {
            attributed[attrRange].backgroundColor = .yellow.opacity(0.3)
            attributed[attrRange].font = .body.bold()
        }
        return attributed
    }
}

/// View model for search functionality
@MainActor
class SearchViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var searchQuery = ""
    @Published var searchResults: [SearchResult] = []
    @Published var isSearching = false
    @Published var hasSearched = false
    @Published var searchScope: SearchScope = .currentTranslation
    
    @Published var recentSearches: [String] = []
    @Published var popularVerses: [VerseReference] = []
    
    // MARK: - Services
    
    private let apiService = BibleAPIService.shared
    private let cacheService = CacheService.shared
    private let storageService = StorageService.shared
    
    // MARK: - Dependencies
    
    weak var bibleViewModel: BibleViewModel?
    
    // MARK: - Search Scope
    
    enum SearchScope: String, CaseIterable {
        case currentTranslation = "Current"
        case oldTestament = "Old Testament"
        case newTestament = "New Testament"
        
        var displayName: String { rawValue }
    }
    
    // MARK: - Initialization
    
    init() {
        loadRecentSearches()
        loadPopularVerses()
    }
    
    // MARK: - Search Methods
    
    /// Perform search
    func search() async {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            searchResults = []
            hasSearched = false
            return
        }
        
        isSearching = true
        hasSearched = true
        defer { isSearching = false }
        
        // Try parsing as a reference first
        if let parsed = ParsedReference.parse(query) {
            await searchByReference(parsed)
        } else {
            await searchByKeyword(query)
        }
        
        // Save to recent searches
        saveRecentSearch(query)
    }
    
    /// Search by verse reference (e.g., "John 3:16")
    private func searchByReference(_ reference: ParsedReference) async {
        guard let bibleVM = bibleViewModel,
              let translation = bibleVM.selectedTranslation else { return }
        
        // Find matching book
        let bookName = reference.bookName.lowercased()
        guard let book = bibleVM.books.first(where: {
            $0.name.lowercased().contains(bookName) ||
            $0.displayName.lowercased().contains(bookName) ||
            $0.id.lowercased() == bookName
        }) else {
            searchResults = []
            return
        }
        
        // Fetch the chapter
        do {
            let chapter = try await apiService.fetchChapter(
                translationId: translation.id,
                bookId: book.id,
                chapter: reference.chapter
            )
            
            var results: [SearchResult] = []
            
            if let verseStart = reference.verseStart {
                // Specific verse(s) requested
                let verseEnd = reference.verseEnd ?? verseStart
                for verse in chapter.verses where verse.verse >= verseStart && verse.verse <= verseEnd {
                    let verseRef = VerseReference(
                        translationId: translation.id,
                        bookId: book.id,
                        bookName: book.displayName,
                        chapter: reference.chapter,
                        verse: verse.verse,
                        text: verse.text
                    )
                    results.append(SearchResult(reference: verseRef, matchRange: nil))
                }
            } else {
                // Return first few verses of the chapter
                for verse in chapter.verses.prefix(5) {
                    let verseRef = VerseReference(
                        translationId: translation.id,
                        bookId: book.id,
                        bookName: book.displayName,
                        chapter: reference.chapter,
                        verse: verse.verse,
                        text: verse.text
                    )
                    results.append(SearchResult(reference: verseRef, matchRange: nil))
                }
            }
            
            searchResults = results
        } catch {
            searchResults = []
        }
    }
    
    /// Search by keyword
    private func searchByKeyword(_ keyword: String) async {
        guard let bibleVM = bibleViewModel,
              let translation = bibleVM.selectedTranslation else { return }
        
        let lowercasedKeyword = keyword.lowercased()
        var results: [SearchResult] = []
        let maxResults = 50
        
        // Determine which books to search
        let booksToSearch: [Book]
        switch searchScope {
        case .currentTranslation:
            booksToSearch = bibleVM.books
        case .oldTestament:
            booksToSearch = bibleVM.oldTestamentBooks
        case .newTestament:
            booksToSearch = bibleVM.newTestamentBooks
        }
        
        // Search through cached chapters first
        for book in booksToSearch {
            guard results.count < maxResults else { break }
            
            for chapterNum in 1...book.numberOfChapters {
                guard results.count < maxResults else { break }
                
                // Check cache
                if let chapter = cacheService.getCachedChapter(
                    translationId: translation.id,
                    bookId: book.id,
                    chapter: chapterNum
                ) {
                    for verse in chapter.verses {
                        let lowercasedText = verse.text.lowercased()
                        if let range = lowercasedText.range(of: lowercasedKeyword) {
                            // Convert to original text range
                            let startOffset = lowercasedText.distance(from: lowercasedText.startIndex, to: range.lowerBound)
                            let endOffset = lowercasedText.distance(from: lowercasedText.startIndex, to: range.upperBound)
                            let originalStart = verse.text.index(verse.text.startIndex, offsetBy: startOffset)
                            let originalEnd = verse.text.index(verse.text.startIndex, offsetBy: endOffset)
                            
                            let verseRef = VerseReference(
                                translationId: translation.id,
                                bookId: book.id,
                                bookName: book.displayName,
                                chapter: chapterNum,
                                verse: verse.verse,
                                text: verse.text
                            )
                            results.append(SearchResult(reference: verseRef, matchRange: originalStart..<originalEnd))
                            
                            guard results.count < maxResults else { break }
                        }
                    }
                }
            }
        }
        
        searchResults = results
    }
    
    /// Clear search
    func clearSearch() {
        searchQuery = ""
        searchResults = []
        hasSearched = false
    }
    
    // MARK: - Recent Searches
    
    private func loadRecentSearches() {
        recentSearches = UserDefaults.standard.stringArray(forKey: "bible_recent_searches") ?? []
    }
    
    private func saveRecentSearch(_ query: String) {
        var searches = recentSearches
        searches.removeAll { $0.lowercased() == query.lowercased() }
        searches.insert(query, at: 0)
        if searches.count > 10 {
            searches = Array(searches.prefix(10))
        }
        recentSearches = searches
        UserDefaults.standard.set(searches, forKey: "bible_recent_searches")
    }
    
    func clearRecentSearches() {
        recentSearches = []
        UserDefaults.standard.removeObject(forKey: "bible_recent_searches")
    }
    
    // MARK: - Popular Verses
    
    private func loadPopularVerses() {
        // Pre-defined popular verses
        popularVerses = [
            VerseReference(translationId: "engKJV", bookId: "JHN", bookName: "John", chapter: 3, verse: 16, text: "For God so loved the world, that he gave his only begotten Son..."),
            VerseReference(translationId: "engKJV", bookId: "PSA", bookName: "Psalms", chapter: 23, verse: 1, text: "The LORD is my shepherd; I shall not want."),
            VerseReference(translationId: "engKJV", bookId: "PRO", bookName: "Proverbs", chapter: 3, verse: 5, text: "Trust in the LORD with all thine heart..."),
            VerseReference(translationId: "engKJV", bookId: "ROM", bookName: "Romans", chapter: 8, verse: 28, text: "And we know that all things work together for good..."),
            VerseReference(translationId: "engKJV", bookId: "PHP", bookName: "Philippians", chapter: 4, verse: 13, text: "I can do all things through Christ which strengtheneth me."),
        ]
    }
}

