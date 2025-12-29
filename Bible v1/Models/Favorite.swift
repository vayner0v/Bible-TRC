//
//  Favorite.swift
//  Bible v1
//
//  Advanced Bible Reader App
//

import Foundation
import Combine

/// Represents a favorited/bookmarked verse (for non-CoreData use)
struct Favorite: Identifiable, Codable, Hashable {
    let id: UUID
    let translationId: String
    let bookId: String
    let bookName: String
    let chapter: Int
    let verse: Int
    let text: String
    let dateAdded: Date
    
    init(id: UUID = UUID(), translationId: String, bookId: String, bookName: String, chapter: Int, verse: Int, text: String, dateAdded: Date = Date()) {
        self.id = id
        self.translationId = translationId
        self.bookId = bookId
        self.bookName = bookName
        self.chapter = chapter
        self.verse = verse
        self.text = text
        self.dateAdded = dateAdded
    }
    
    /// Create from a verse reference
    init(from reference: VerseReference) {
        self.id = UUID()
        self.translationId = reference.translationId
        self.bookId = reference.bookId
        self.bookName = reference.bookName
        self.chapter = reference.chapter
        self.verse = reference.verse
        self.text = reference.text
        self.dateAdded = Date()
    }
    
    /// Short reference string (e.g., "John 3:16")
    var shortReference: String {
        "\(bookName) \(chapter):\(verse)"
    }
    
    /// Reference string for display
    var reference: String {
        shortReference
    }
    
    /// Verse text for display
    var verseText: String {
        text
    }
    
    /// Created at date (alias for dateAdded)
    var createdAt: Date {
        dateAdded
    }
    
    /// Full reference with translation
    var fullReference: String {
        "\(shortReference) (\(translationId))"
    }
    
    /// Convert to VerseReference
    var verseReference: VerseReference {
        VerseReference(
            translationId: translationId,
            bookId: bookId,
            bookName: bookName,
            chapter: chapter,
            verse: verse,
            text: text
        )
    }
    
    /// Unique key for this verse location
    var verseKey: String {
        "\(translationId)_\(bookId)_\(chapter)_\(verse)"
    }
}
