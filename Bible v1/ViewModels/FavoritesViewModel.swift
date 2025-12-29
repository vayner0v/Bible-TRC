//
//  FavoritesViewModel.swift
//  Bible v1
//
//  Advanced Bible Reader App
//

import Foundation
import SwiftUI
import Combine

/// View model for managing favorites, highlights, and notes
@MainActor
class FavoritesViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var favorites: [Favorite] = []
    @Published var highlights: [Highlight] = []
    @Published var notes: [Note] = []
    
    @Published var selectedTab: Tab = .favorites
    @Published var sortOrder: SortOrder = .dateDescending
    @Published var filterColor: HighlightColor?
    
    // MARK: - Services
    
    private let storageService = StorageService.shared
    
    // MARK: - Enums
    
    enum Tab: String, CaseIterable {
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
    
    enum SortOrder: String, CaseIterable {
        case dateDescending = "Newest First"
        case dateAscending = "Oldest First"
        case bookOrder = "Book Order"
    }
    
    // MARK: - Computed Properties
    
    var sortedFavorites: [Favorite] {
        switch sortOrder {
        case .dateDescending:
            return favorites.sorted { $0.dateAdded > $1.dateAdded }
        case .dateAscending:
            return favorites.sorted { $0.dateAdded < $1.dateAdded }
        case .bookOrder:
            return favorites.sorted { ($0.bookId, $0.chapter, $0.verse) < ($1.bookId, $1.chapter, $1.verse) }
        }
    }
    
    var sortedHighlights: [Highlight] {
        var filtered = highlights
        if let color = filterColor {
            filtered = filtered.filter { $0.colorName == color.rawValue }
        }
        
        switch sortOrder {
        case .dateDescending:
            return filtered.sorted { $0.dateAdded > $1.dateAdded }
        case .dateAscending:
            return filtered.sorted { $0.dateAdded < $1.dateAdded }
        case .bookOrder:
            return filtered.sorted { ($0.bookId, $0.chapter, $0.verse) < ($1.bookId, $1.chapter, $1.verse) }
        }
    }
    
    var sortedNotes: [Note] {
        switch sortOrder {
        case .dateDescending:
            return notes.sorted { $0.dateModified > $1.dateModified }
        case .dateAscending:
            return notes.sorted { $0.dateCreated < $1.dateCreated }
        case .bookOrder:
            return notes.sorted { ($0.bookId, $0.chapter, $0.verse) < ($1.bookId, $1.chapter, $1.verse) }
        }
    }
    
    var highlightColorCounts: [HighlightColor: Int] {
        var counts: [HighlightColor: Int] = [:]
        for highlight in highlights {
            let color = highlight.color
            counts[color, default: 0] += 1
        }
        return counts
    }
    
    // MARK: - Initialization
    
    init() {
        loadData()
    }
    
    func loadData() {
        favorites = storageService.favorites
        highlights = storageService.highlights
        notes = storageService.notes
    }
    
    // MARK: - Favorites
    
    func addFavorite(_ reference: VerseReference) {
        let favorite = Favorite(from: reference)
        storageService.addFavorite(favorite)
        favorites = storageService.favorites
    }
    
    func removeFavorite(_ favorite: Favorite) {
        storageService.removeFavorite(favorite)
        favorites = storageService.favorites
    }
    
    func removeFavorites(at offsets: IndexSet) {
        let sortedItems = sortedFavorites
        for index in offsets {
            storageService.removeFavorite(sortedItems[index])
        }
        favorites = storageService.favorites
    }
    
    func isFavorite(_ reference: VerseReference) -> Bool {
        storageService.isFavorite(
            translationId: reference.translationId,
            bookId: reference.bookId,
            chapter: reference.chapter,
            verse: reference.verse
        )
    }
    
    func toggleFavorite(_ reference: VerseReference) {
        storageService.toggleFavorite(reference)
        favorites = storageService.favorites
    }
    
    // MARK: - Highlights
    
    func setHighlight(for reference: VerseReference, color: HighlightColor) {
        storageService.setHighlight(for: reference, color: color)
        highlights = storageService.highlights
    }
    
    func removeHighlight(_ highlight: Highlight) {
        storageService.removeHighlight(highlight)
        highlights = storageService.highlights
    }
    
    func removeHighlights(at offsets: IndexSet) {
        let sortedItems = sortedHighlights
        for index in offsets {
            storageService.removeHighlight(sortedItems[index])
        }
        highlights = storageService.highlights
    }
    
    func getHighlight(for reference: VerseReference) -> Highlight? {
        storageService.getHighlight(
            translationId: reference.translationId,
            bookId: reference.bookId,
            chapter: reference.chapter,
            verse: reference.verse
        )
    }
    
    func clearColorFilter() {
        filterColor = nil
    }
    
    // MARK: - Notes
    
    func addNote(for reference: VerseReference, text: String) {
        let note = Note(
            translationId: reference.translationId,
            bookId: reference.bookId,
            bookName: reference.bookName,
            chapter: reference.chapter,
            verse: reference.verse,
            verseText: reference.text,
            noteText: text
        )
        storageService.addNote(note)
        notes = storageService.notes
    }
    
    func updateNote(_ note: Note, text: String) {
        var updatedNote = note
        updatedNote.updateText(text)
        storageService.updateNote(updatedNote)
        notes = storageService.notes
    }
    
    func removeNote(_ note: Note) {
        storageService.removeNote(note)
        notes = storageService.notes
    }
    
    func removeNotes(at offsets: IndexSet) {
        let sortedItems = sortedNotes
        for index in offsets {
            storageService.removeNote(sortedItems[index])
        }
        notes = storageService.notes
    }
    
    func getNote(for reference: VerseReference) -> Note? {
        storageService.getNote(
            translationId: reference.translationId,
            bookId: reference.bookId,
            chapter: reference.chapter,
            verse: reference.verse
        )
    }
    
    // MARK: - Export
    
    func exportNotes() -> String {
        var export = "Bible Notes Export\n"
        export += "Generated: \(Date().formatted())\n\n"
        export += String(repeating: "=", count: 50) + "\n\n"
        
        for note in sortedNotes {
            export += "\(note.fullReference)\n"
            export += "\"\(note.verseText)\"\n\n"
            export += "Note: \(note.noteText)\n"
            export += "Created: \(note.dateCreated.formatted())\n"
            export += String(repeating: "-", count: 50) + "\n\n"
        }
        
        return export
    }
    
    func exportFavorites() -> String {
        var export = "Favorite Verses\n"
        export += "Generated: \(Date().formatted())\n\n"
        export += String(repeating: "=", count: 50) + "\n\n"
        
        for favorite in sortedFavorites {
            export += "\(favorite.fullReference)\n"
            export += "\"\(favorite.text)\"\n\n"
        }
        
        return export
    }
}

