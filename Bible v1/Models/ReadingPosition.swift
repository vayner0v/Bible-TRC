//
//  ReadingPosition.swift
//  Bible v1
//
//  Advanced Bible Reader App
//

import Foundation

/// Represents the user's last reading position
struct ReadingPosition: Codable, Equatable {
    let translationId: String
    let bookId: String
    let bookName: String
    let chapter: Int
    let verse: Int?
    let dateAccessed: Date
    
    init(translationId: String, bookId: String, bookName: String, chapter: Int, verse: Int? = nil, dateAccessed: Date = Date()) {
        self.translationId = translationId
        self.bookId = bookId
        self.bookName = bookName
        self.chapter = chapter
        self.verse = verse
        self.dateAccessed = dateAccessed
    }
    
    /// Display string for continue reading (e.g., "Genesis 1")
    var displayString: String {
        if let v = verse {
            return "\(bookName) \(chapter):\(v)"
        }
        return "\(bookName) \(chapter)"
    }
    
    /// Full display with translation
    var fullDisplayString: String {
        "\(displayString) (\(translationId))"
    }
}




