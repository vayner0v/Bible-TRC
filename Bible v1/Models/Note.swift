//
//  Note.swift
//  Bible v1
//
//  Advanced Bible Reader App
//

import Foundation

/// Represents a personal note attached to a verse
struct Note: Identifiable, Codable, Hashable {
    let id: UUID
    let translationId: String
    let bookId: String
    let bookName: String
    let chapter: Int
    let verse: Int
    let verseText: String
    var noteText: String
    let dateCreated: Date
    var dateModified: Date
    
    init(id: UUID = UUID(), translationId: String, bookId: String, bookName: String, chapter: Int, verse: Int, verseText: String, noteText: String, dateCreated: Date = Date(), dateModified: Date = Date()) {
        self.id = id
        self.translationId = translationId
        self.bookId = bookId
        self.bookName = bookName
        self.chapter = chapter
        self.verse = verse
        self.verseText = verseText
        self.noteText = noteText
        self.dateCreated = dateCreated
        self.dateModified = dateModified
    }
    
    /// Create from verse reference
    init(from reference: VerseReference, text: String) {
        self.id = UUID()
        self.translationId = reference.translationId
        self.bookId = reference.bookId
        self.bookName = reference.bookName
        self.chapter = reference.chapter
        self.verse = reference.verse
        self.verseText = reference.text
        self.noteText = text
        self.dateCreated = Date()
        self.dateModified = Date()
    }
    
    /// Short reference string (e.g., "John 3:16")
    var shortReference: String {
        "\(bookName) \(chapter):\(verse)"
    }
    
    /// Reference string for display
    var reference: String {
        shortReference
    }
    
    /// Created at date (alias for dateCreated)
    var createdAt: Date {
        dateCreated
    }
    
    /// Full reference with translation
    var fullReference: String {
        "\(shortReference) (\(translationId))"
    }
    
    /// Unique key for this verse location
    var verseKey: String {
        "\(translationId)_\(bookId)_\(chapter)_\(verse)"
    }
    
    /// Update the note text
    mutating func updateText(_ newText: String) {
        noteText = newText
        dateModified = Date()
    }
}
