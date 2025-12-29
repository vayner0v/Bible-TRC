//
//  Highlight.swift
//  Bible v1
//
//  Advanced Bible Reader App
//

import Foundation
import SwiftUI

/// Represents a highlighted verse
struct Highlight: Identifiable, Codable, Hashable {
    let id: UUID
    let translationId: String
    let bookId: String
    let bookName: String
    let chapter: Int
    let verse: Int
    let text: String
    let colorName: String
    let dateAdded: Date
    
    init(id: UUID = UUID(), translationId: String, bookId: String, bookName: String = "", chapter: Int, verse: Int, text: String = "", colorName: String, dateAdded: Date = Date()) {
        self.id = id
        self.translationId = translationId
        self.bookId = bookId
        self.bookName = bookName
        self.chapter = chapter
        self.verse = verse
        self.text = text
        self.colorName = colorName
        self.dateAdded = dateAdded
    }
    
    /// Create from verse reference
    init(from reference: VerseReference, color: HighlightColor) {
        self.id = UUID()
        self.translationId = reference.translationId
        self.bookId = reference.bookId
        self.bookName = reference.bookName
        self.chapter = reference.chapter
        self.verse = reference.verse
        self.text = reference.text
        self.colorName = color.rawValue
        self.dateAdded = Date()
    }
    
    /// The highlight color
    var color: HighlightColor {
        HighlightColor(rawValue: colorName) ?? .yellow
    }
    
    /// Short reference string
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
    
    /// Unique key for this verse location
    var verseKey: String {
        "\(translationId)_\(bookId)_\(chapter)_\(verse)"
    }
}

/// Available highlight colors
enum HighlightColor: String, Codable, CaseIterable, Identifiable {
    case yellow
    case green
    case blue
    case pink
    case purple
    case orange
    
    var id: String { rawValue }
    
    /// SwiftUI Color for the highlight
    var color: Color {
        switch self {
        case .yellow: return Color.yellow.opacity(0.4)
        case .green: return Color.green.opacity(0.4)
        case .blue: return Color.blue.opacity(0.4)
        case .pink: return Color.pink.opacity(0.4)
        case .purple: return Color.teal.opacity(0.4)
        case .orange: return Color.orange.opacity(0.4)
        }
    }
    
    /// Solid color for picker display
    var solidColor: Color {
        switch self {
        case .yellow: return .yellow
        case .green: return .green
        case .blue: return .blue
        case .pink: return .pink
        case .purple: return .teal
        case .orange: return .orange
        }
    }
    
    /// Display name
    var displayName: String {
        rawValue.capitalized
    }
}
