//
//  StorageService.swift
//  Bible v1
//
//  Advanced Bible Reader App
//

import Foundation
import Combine
import SwiftUI

/// Service for storing user data (favorites, highlights, notes, settings)
class StorageService: ObservableObject {
    static let shared = StorageService()
    
    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    // Keys
    private enum Keys {
        static let favorites = "bible_favorites"
        static let highlights = "bible_highlights"
        static let notes = "bible_notes"
        static let lastPosition = "bible_last_position"
        static let selectedTranslation = "bible_selected_translation"
        static let recentTranslations = "bible_recent_translations"
        static let downloadedTranslations = "bible_downloaded_translations"
    }
    
    // MARK: - Published Properties
    
    @Published private(set) var favorites: [Favorite] = []
    @Published private(set) var highlights: [Highlight] = []
    @Published private(set) var notes: [Note] = []
    
    init() {
        loadAll()
    }
    
    private func loadAll() {
        favorites = loadFavorites()
        highlights = loadHighlights()
        notes = loadNotes()
    }
    
    // MARK: - Favorites
    
    private func loadFavorites() -> [Favorite] {
        guard let data = defaults.data(forKey: Keys.favorites) else { return [] }
        return (try? decoder.decode([Favorite].self, from: data)) ?? []
    }
    
    func saveFavorites() {
        guard let data = try? encoder.encode(favorites) else { return }
        defaults.set(data, forKey: Keys.favorites)
    }
    
    func addFavorite(_ favorite: Favorite) {
        // Check for duplicates
        if !favorites.contains(where: { $0.verseKey == favorite.verseKey }) {
            favorites.append(favorite)
            saveFavorites()
        }
    }
    
    func removeFavorite(_ favorite: Favorite) {
        favorites.removeAll { $0.id == favorite.id }
        saveFavorites()
    }
    
    func removeFavorite(at offsets: IndexSet) {
        favorites.remove(atOffsets: offsets)
        saveFavorites()
    }
    
    func isFavorite(translationId: String, bookId: String, chapter: Int, verse: Int) -> Bool {
        let key = "\(translationId)_\(bookId)_\(chapter)_\(verse)"
        return favorites.contains { $0.verseKey == key }
    }
    
    func toggleFavorite(_ reference: VerseReference) {
        if let index = favorites.firstIndex(where: { $0.verseKey == reference.verseKey }) {
            favorites.remove(at: index)
        } else {
            favorites.append(Favorite(from: reference))
        }
        saveFavorites()
    }
    
    // MARK: - Highlights
    
    private func loadHighlights() -> [Highlight] {
        guard let data = defaults.data(forKey: Keys.highlights) else { return [] }
        return (try? decoder.decode([Highlight].self, from: data)) ?? []
    }
    
    func saveHighlights() {
        guard let data = try? encoder.encode(highlights) else { return }
        defaults.set(data, forKey: Keys.highlights)
    }
    
    func addHighlight(_ highlight: Highlight) {
        // Remove existing highlight for the same verse
        highlights.removeAll { $0.verseKey == highlight.verseKey }
        highlights.append(highlight)
        saveHighlights()
    }
    
    func removeHighlight(for verseKey: String) {
        highlights.removeAll { $0.verseKey == verseKey }
        saveHighlights()
    }
    
    func removeHighlight(_ highlight: Highlight) {
        highlights.removeAll { $0.id == highlight.id }
        saveHighlights()
    }
    
    func getHighlight(translationId: String, bookId: String, chapter: Int, verse: Int) -> Highlight? {
        let key = "\(translationId)_\(bookId)_\(chapter)_\(verse)"
        return highlights.first { $0.verseKey == key }
    }
    
    func setHighlight(translationId: String, bookId: String, chapter: Int, verse: Int, color: HighlightColor, bookName: String = "", text: String = "") {
        let highlight = Highlight(
            translationId: translationId,
            bookId: bookId,
            bookName: bookName,
            chapter: chapter,
            verse: verse,
            text: text,
            colorName: color.rawValue
        )
        addHighlight(highlight)
    }
    
    func setHighlight(for reference: VerseReference, color: HighlightColor) {
        let highlight = Highlight(from: reference, color: color)
        addHighlight(highlight)
    }
    
    // MARK: - Notes
    
    private func loadNotes() -> [Note] {
        guard let data = defaults.data(forKey: Keys.notes) else { return [] }
        return (try? decoder.decode([Note].self, from: data)) ?? []
    }
    
    func saveNotes() {
        guard let data = try? encoder.encode(notes) else { return }
        defaults.set(data, forKey: Keys.notes)
    }
    
    func addNote(_ note: Note) {
        // Replace existing note for same verse
        notes.removeAll { $0.verseKey == note.verseKey }
        notes.append(note)
        saveNotes()
    }
    
    func updateNote(_ note: Note) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index] = note
            saveNotes()
        }
    }
    
    func removeNote(_ note: Note) {
        notes.removeAll { $0.id == note.id }
        saveNotes()
    }
    
    func getNote(translationId: String, bookId: String, chapter: Int, verse: Int) -> Note? {
        let key = "\(translationId)_\(bookId)_\(chapter)_\(verse)"
        return notes.first { $0.verseKey == key }
    }
    
    // MARK: - Reading Position
    
    func saveLastPosition(_ position: ReadingPosition) {
        guard let data = try? encoder.encode(position) else { return }
        defaults.set(data, forKey: Keys.lastPosition)
    }
    
    func getLastPosition() -> ReadingPosition? {
        guard let data = defaults.data(forKey: Keys.lastPosition) else { return nil }
        return try? decoder.decode(ReadingPosition.self, from: data)
    }
    
    // MARK: - Selected Translation
    
    func saveSelectedTranslation(_ translationId: String) {
        defaults.set(translationId, forKey: Keys.selectedTranslation)
        addRecentTranslation(translationId)
    }
    
    func getSelectedTranslation() -> String? {
        defaults.string(forKey: Keys.selectedTranslation)
    }
    
    // MARK: - Recent Translations
    
    private func addRecentTranslation(_ translationId: String) {
        var recent = getRecentTranslations()
        recent.removeAll { $0 == translationId }
        recent.insert(translationId, at: 0)
        if recent.count > 10 {
            recent = Array(recent.prefix(10))
        }
        defaults.set(recent, forKey: Keys.recentTranslations)
    }
    
    func getRecentTranslations() -> [String] {
        defaults.stringArray(forKey: Keys.recentTranslations) ?? []
    }
    
    // MARK: - Downloaded Translations
    
    func saveDownloadedTranslations(_ translations: [String]) {
        defaults.set(translations, forKey: Keys.downloadedTranslations)
    }
    
    func getDownloadedTranslations() -> [String] {
        defaults.stringArray(forKey: Keys.downloadedTranslations) ?? []
    }
    
    func addDownloadedTranslation(_ translationId: String) {
        var downloaded = getDownloadedTranslations()
        if !downloaded.contains(translationId) {
            downloaded.append(translationId)
            saveDownloadedTranslations(downloaded)
        }
    }
    
    func removeDownloadedTranslation(_ translationId: String) {
        var downloaded = getDownloadedTranslations()
        downloaded.removeAll { $0 == translationId }
        saveDownloadedTranslations(downloaded)
    }
    
    // MARK: - Clear Data
    
    func clearAllUserData() {
        favorites = []
        highlights = []
        notes = []
        
        defaults.removeObject(forKey: Keys.favorites)
        defaults.removeObject(forKey: Keys.highlights)
        defaults.removeObject(forKey: Keys.notes)
        defaults.removeObject(forKey: Keys.lastPosition)
        defaults.removeObject(forKey: Keys.recentTranslations)
    }
}

