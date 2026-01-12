//
//  BibleViewModel.swift
//  Bible v1
//
//  Advanced Bible Reader App
//

import Foundation
import SwiftUI
import Combine

/// Main view model for Bible reading functionality
@MainActor
class BibleViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var translations: [Translation] = []
    @Published var selectedTranslation: Translation?
    @Published var books: [Book] = []
    @Published var selectedBook: Book?
    @Published var currentChapter: Chapter?
    @Published var currentChapterNumber: Int = 1
    
    @Published var isLoadingTranslations = false
    @Published var isLoadingBooks = false
    @Published var isLoadingChapter = false
    
    @Published var error: BibleError?
    @Published var showError = false
    
    // Secondary translation for parallel view
    @Published var secondaryTranslation: Translation?
    @Published var secondaryChapter: Chapter?
    
    // MARK: - Services
    
    private let apiService = BibleAPIService.shared
    private let cacheService = CacheService.shared
    private let storageService = StorageService.shared
    
    // MARK: - Computed Properties
    
    var oldTestamentBooks: [Book] {
        books.filter { $0.inferredTestament == .old }
    }
    
    var newTestamentBooks: [Book] {
        books.filter { $0.inferredTestament == .new }
    }
    
    var hasNextChapter: Bool {
        guard let book = selectedBook else { return false }
        if currentChapterNumber < book.numberOfChapters {
            return true
        }
        // Check if there's a next book
        if let currentIndex = books.firstIndex(where: { $0.id == book.id }),
           currentIndex < books.count - 1 {
            return true
        }
        return false
    }
    
    var hasPreviousChapter: Bool {
        if currentChapterNumber > 1 {
            return true
        }
        // Check if there's a previous book
        guard let book = selectedBook,
              let currentIndex = books.firstIndex(where: { $0.id == book.id }) else {
            return false
        }
        return currentIndex > 0
    }
    
    var currentReference: String {
        guard let book = selectedBook else { return "" }
        return "\(book.displayName) \(currentChapterNumber)"
    }
    
    /// Short reference for compact displays (uses abbreviated book names)
    var shortReference: String {
        guard let book = selectedBook else { return "" }
        return "\(book.shortName) \(currentChapterNumber)"
    }
    
    // MARK: - Initialization
    
    private var hasLoadedInitialData = false
    
    init() {
        // Don't load data in init to avoid "Publishing changes from within view updates" warning
        // Data loading is triggered by the view's .task modifier
    }
    
    /// Called by views to ensure data is loaded
    func loadInitialDataIfNeeded() async {
        guard !hasLoadedInitialData else { return }
        hasLoadedInitialData = true
        await loadInitialData()
    }
    
    // MARK: - Data Loading
    
    /// Load initial data (translations and restore last position)
    func loadInitialData() async {
        await loadTranslations()
        
        // Restore last selected translation or default to KJV
        if let savedTranslationId = storageService.getSelectedTranslation(),
           let translation = translations.first(where: { $0.id == savedTranslationId }) {
            await selectTranslation(translation)
        } else if let kjv = translations.first(where: { $0.id == "engKJV" || $0.id == "KJV" }) {
            await selectTranslation(kjv)
        } else if let firstTranslation = translations.first {
            await selectTranslation(firstTranslation)
        }
        
        // Restore last reading position
        if let lastPosition = storageService.getLastPosition(),
           lastPosition.translationId == selectedTranslation?.id {
            if let book = books.first(where: { $0.id == lastPosition.bookId }) {
                await selectBook(book, chapter: lastPosition.chapter)
            }
        }
    }
    
    /// Load all available translations
    func loadTranslations() async {
        isLoadingTranslations = true
        defer { isLoadingTranslations = false }
        
        do {
            translations = try await apiService.fetchTranslations()
            // Sort by language then name
            translations.sort { ($0.language, $0.name) < ($1.language, $1.name) }
        } catch let error as BibleError {
            self.error = error
            showError = true
        } catch {
            self.error = .networkError(error)
            showError = true
        }
    }
    
    /// Select a translation and load its books
    func selectTranslation(_ translation: Translation) async {
        selectedTranslation = translation
        storageService.saveSelectedTranslation(translation.id)
        
        isLoadingBooks = true
        defer { isLoadingBooks = false }
        
        do {
            books = try await apiService.fetchBooks(translationId: translation.id)
            
            // Auto-select first book if none selected
            if selectedBook == nil, let firstBook = books.first {
                await selectBook(firstBook)
            }
        } catch let error as BibleError {
            self.error = error
            showError = true
        } catch {
            self.error = .networkError(error)
            showError = true
        }
    }
    
    /// Select a book and optionally a chapter
    func selectBook(_ book: Book, chapter: Int = 1) async {
        selectedBook = book
        currentChapterNumber = chapter
        await loadCurrentChapter()
    }
    
    /// Load the current chapter
    func loadCurrentChapter() async {
        guard let translation = selectedTranslation,
              let book = selectedBook else { return }
        
        isLoadingChapter = true
        defer { isLoadingChapter = false }
        
        // Try cache first
        if let cached = cacheService.getCachedChapter(
            translationId: translation.id,
            bookId: book.id,
            chapter: currentChapterNumber
        ) {
            currentChapter = cached
            saveReadingPosition()
            return
        }
        
        do {
            let chapter = try await apiService.fetchChapter(
                translationId: translation.id,
                bookId: book.id,
                chapter: currentChapterNumber
            )
            currentChapter = chapter
            
            // Cache for offline use
            cacheService.cacheChapter(
                chapter,
                translationId: translation.id,
                bookId: book.id,
                chapterNum: currentChapterNumber
            )
            
            saveReadingPosition()
            
            // Pre-fetch next chapter in background
            prefetchNextChapter()
        } catch let error as BibleError {
            self.error = error
            showError = true
        } catch {
            self.error = .networkError(error)
            showError = true
        }
    }
    
    /// Navigate to the next chapter
    func nextChapter() async {
        guard let book = selectedBook else { return }
        
        if currentChapterNumber < book.numberOfChapters {
            currentChapterNumber += 1
            await loadCurrentChapter()
        } else {
            // Move to next book
            if let currentIndex = books.firstIndex(where: { $0.id == book.id }),
               currentIndex < books.count - 1 {
                let nextBook = books[currentIndex + 1]
                await selectBook(nextBook, chapter: 1)
            }
        }
    }
    
    /// Navigate to the previous chapter
    func previousChapter() async {
        guard let book = selectedBook else { return }
        
        if currentChapterNumber > 1 {
            currentChapterNumber -= 1
            await loadCurrentChapter()
        } else {
            // Move to previous book
            if let currentIndex = books.firstIndex(where: { $0.id == book.id }),
               currentIndex > 0 {
                let prevBook = books[currentIndex - 1]
                await selectBook(prevBook, chapter: prevBook.numberOfChapters)
            }
        }
    }
    
    /// Jump to a specific chapter
    func goToChapter(_ chapter: Int) async {
        guard chapter >= 1, chapter <= (selectedBook?.numberOfChapters ?? 1) else { return }
        currentChapterNumber = chapter
        await loadCurrentChapter()
    }
    
    /// Navigate to a specific translation, book, and chapter
    func navigateTo(translationId: String, bookId: String, chapter: Int) async {
        // Find and select the translation if different
        if selectedTranslation?.id != translationId {
            if let translation = translations.first(where: { $0.id == translationId }) {
                await selectTranslation(translation)
            }
        }
        
        // Find and select the book if different
        if selectedBook?.id != bookId {
            if let book = books.first(where: { $0.id == bookId }) {
                await selectBook(book, chapter: chapter)
                return
            }
        }
        
        // Just navigate to the chapter if book is already selected
        if currentChapterNumber != chapter {
            await goToChapter(chapter)
        }
    }
    
    // MARK: - Secondary Translation (Parallel View)
    
    /// Set secondary translation for parallel view
    func setSecondaryTranslation(_ translation: Translation?) async {
        secondaryTranslation = translation
        if translation != nil {
            await loadSecondaryChapter()
        } else {
            secondaryChapter = nil
        }
    }
    
    /// Load the secondary translation's chapter
    func loadSecondaryChapter() async {
        guard let translation = secondaryTranslation,
              let book = selectedBook else { return }
        
        do {
            secondaryChapter = try await apiService.fetchChapter(
                translationId: translation.id,
                bookId: book.id,
                chapter: currentChapterNumber
            )
        } catch {
            // Silent failure for secondary translation
            secondaryChapter = nil
        }
    }
    
    // MARK: - Helpers
    
    private func saveReadingPosition() {
        guard let translation = selectedTranslation,
              let book = selectedBook else { return }
        
        let position = ReadingPosition(
            translationId: translation.id,
            bookId: book.id,
            bookName: book.displayName,
            chapter: currentChapterNumber
        )
        storageService.saveLastPosition(position)
    }
    
    private func prefetchNextChapter() {
        guard let translation = selectedTranslation,
              let book = selectedBook else { return }
        
        let nextChapter = currentChapterNumber + 1
        guard nextChapter <= book.numberOfChapters else { return }
        
        Task {
            _ = try? await apiService.fetchChapter(
                translationId: translation.id,
                bookId: book.id,
                chapter: nextChapter
            )
        }
    }
    
    /// Create a verse reference for a verse in the current chapter
    func verseReference(for verse: Verse) -> VerseReference? {
        guard let translation = selectedTranslation,
              let book = selectedBook else { return nil }
        
        return VerseReference(
            translationId: translation.id,
            bookId: book.id,
            bookName: book.displayName,
            chapter: currentChapterNumber,
            verse: verse.verse,
            text: verse.text
        )
    }
    
    /// Filter translations by language
    func translations(for language: String) -> [Translation] {
        translations.filter { $0.language.lowercased().contains(language.lowercased()) }
    }
    
    /// Get unique languages from translations
    var availableLanguages: [String] {
        Array(Set(translations.map { $0.language })).sorted()
    }
    
    /// Search translations by name or language
    func searchTranslations(_ query: String) -> [Translation] {
        guard !query.isEmpty else { return translations }
        let lowercased = query.lowercased()
        return translations.filter {
            $0.name.lowercased().contains(lowercased) ||
            $0.language.lowercased().contains(lowercased) ||
            ($0.englishName?.lowercased().contains(lowercased) ?? false)
        }
    }
    
    /// Navigate to a specific verse from a reference string (e.g., "Genesis 1:1")
    func navigateToReference(_ reference: String) {
        // Parse reference format: "BookName Chapter:Verse" or "BookName Chapter"
        let components = reference.components(separatedBy: " ")
        guard components.count >= 2 else { return }
        
        // Find the book name (can be multi-word like "1 Samuel")
        var bookNameComponents: [String] = []
        var chapterVerseComponent: String?
        
        for component in components {
            if component.contains(":") || Int(component) != nil {
                chapterVerseComponent = component
                break
            } else {
                bookNameComponents.append(component)
            }
        }
        
        let bookName = bookNameComponents.joined(separator: " ")
        
        // Find matching book
        guard let book = books.first(where: { 
            $0.displayName.lowercased() == bookName.lowercased() ||
            $0.name.lowercased() == bookName.lowercased()
        }) else { return }
        
        // Parse chapter
        var chapter = 1
        if let chapterVerse = chapterVerseComponent {
            if chapterVerse.contains(":") {
                let parts = chapterVerse.components(separatedBy: ":")
                chapter = Int(parts[0]) ?? 1
            } else {
                chapter = Int(chapterVerse) ?? 1
            }
        }
        
        // Navigate
        Task {
            await selectBook(book, chapter: chapter)
        }
    }
}

