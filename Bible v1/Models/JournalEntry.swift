//
//  JournalEntry.swift
//  Bible v1
//
//  Spiritual Journal - Core Entry Model
//

import Foundation
import SwiftUI

/// Represents a journal entry with rich content and verse linking
struct JournalEntry: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var content: String
    var formattedContent: FormattedContent
    var mood: JournalMood?
    var linkedVerses: [LinkedVerse]
    var linkedHighlightIds: [UUID]
    var linkedNoteIds: [UUID]
    var tags: [JournalTag]
    var photoFileNames: [String]
    var promptUsed: JournalPrompt?
    var isFavorite: Bool
    let dateCreated: Date
    var dateModified: Date
    
    init(
        id: UUID = UUID(),
        title: String = "",
        content: String = "",
        formattedContent: FormattedContent = FormattedContent(),
        mood: JournalMood? = nil,
        linkedVerses: [LinkedVerse] = [],
        linkedHighlightIds: [UUID] = [],
        linkedNoteIds: [UUID] = [],
        tags: [JournalTag] = [],
        photoFileNames: [String] = [],
        promptUsed: JournalPrompt? = nil,
        isFavorite: Bool = false,
        dateCreated: Date = Date(),
        dateModified: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.formattedContent = formattedContent
        self.mood = mood
        self.linkedVerses = linkedVerses
        self.linkedHighlightIds = linkedHighlightIds
        self.linkedNoteIds = linkedNoteIds
        self.tags = tags
        self.photoFileNames = photoFileNames
        self.promptUsed = promptUsed
        self.isFavorite = isFavorite
        self.dateCreated = dateCreated
        self.dateModified = dateModified
    }
    
    // MARK: - Computed Properties
    
    /// Check if entry is from today
    var isToday: Bool {
        Calendar.current.isDateInToday(dateCreated)
    }
    
    /// Formatted date for display
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: dateCreated)
    }
    
    /// Short date for calendar
    var shortDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: dateCreated)
    }
    
    /// Day of week
    var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: dateCreated)
    }
    
    /// Time of day
    var timeOfDay: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: dateCreated)
    }
    
    /// Preview text for list display
    var previewText: String {
        let text = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.count > 100 {
            return String(text.prefix(100)) + "..."
        }
        return text
    }
    
    /// Has any linked content
    var hasLinkedContent: Bool {
        !linkedVerses.isEmpty || !linkedHighlightIds.isEmpty || !linkedNoteIds.isEmpty
    }
    
    /// Total linked items count
    var linkedItemsCount: Int {
        linkedVerses.count + linkedHighlightIds.count + linkedNoteIds.count
    }
    
    /// Has photos
    var hasPhotos: Bool {
        !photoFileNames.isEmpty
    }
    
    /// Word count
    var wordCount: Int {
        content.split(separator: " ").count
    }
    
    // MARK: - Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: JournalEntry, rhs: JournalEntry) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Linked Verse

/// Represents a verse linked to a journal entry
struct LinkedVerse: Identifiable, Codable, Hashable {
    let id: UUID
    let translationId: String
    let bookId: String
    let bookName: String
    let chapter: Int
    let verse: Int
    let text: String
    let dateLinked: Date
    
    init(
        id: UUID = UUID(),
        translationId: String,
        bookId: String,
        bookName: String,
        chapter: Int,
        verse: Int,
        text: String,
        dateLinked: Date = Date()
    ) {
        self.id = id
        self.translationId = translationId
        self.bookId = bookId
        self.bookName = bookName
        self.chapter = chapter
        self.verse = verse
        self.text = text
        self.dateLinked = dateLinked
    }
    
    /// Create from VerseReference
    init(from reference: VerseReference) {
        self.id = UUID()
        self.translationId = reference.translationId
        self.bookId = reference.bookId
        self.bookName = reference.bookName
        self.chapter = reference.chapter
        self.verse = reference.verse
        self.text = reference.text
        self.dateLinked = Date()
    }
    
    /// Short reference string
    var shortReference: String {
        "\(bookName) \(chapter):\(verse)"
    }
    
    /// Full reference with translation
    var fullReference: String {
        "\(shortReference) (\(translationId.uppercased()))"
    }
}

// MARK: - Formatted Content

/// Stores rich text formatting information
struct FormattedContent: Codable, Hashable {
    var segments: [FormattedSegment]
    
    init(segments: [FormattedSegment] = []) {
        self.segments = segments
    }
    
    /// Check if has any formatting
    var hasFormatting: Bool {
        !segments.isEmpty
    }
}

/// A segment of formatted text
struct FormattedSegment: Identifiable, Codable, Hashable {
    let id: UUID
    let range: Range<Int>
    let style: TextStyle
    
    init(id: UUID = UUID(), range: Range<Int>, style: TextStyle) {
        self.id = id
        self.range = range
        self.style = style
    }
    
    // Custom Codable for Range
    enum CodingKeys: String, CodingKey {
        case id, rangeStart, rangeEnd, style
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        let start = try container.decode(Int.self, forKey: .rangeStart)
        let end = try container.decode(Int.self, forKey: .rangeEnd)
        range = start..<end
        style = try container.decode(TextStyle.self, forKey: .style)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(range.lowerBound, forKey: .rangeStart)
        try container.encode(range.upperBound, forKey: .rangeEnd)
        try container.encode(style, forKey: .style)
    }
}

/// Text formatting styles
enum TextStyle: String, Codable, CaseIterable {
    case bold
    case italic
    case underline
    case quote
    case bulletList
    case numberedList
    case heading
    
    var icon: String {
        switch self {
        case .bold: return "bold"
        case .italic: return "italic"
        case .underline: return "underline"
        case .quote: return "text.quote"
        case .bulletList: return "list.bullet"
        case .numberedList: return "list.number"
        case .heading: return "textformat.size"
        }
    }
}

// MARK: - Photo Attachment

/// Represents a photo attached to a journal entry
struct PhotoAttachment: Identifiable, Codable, Hashable {
    let id: UUID
    let fileName: String
    let dateAdded: Date
    var caption: String?
    
    init(
        id: UUID = UUID(),
        fileName: String,
        dateAdded: Date = Date(),
        caption: String? = nil
    ) {
        self.id = id
        self.fileName = fileName
        self.dateAdded = dateAdded
        self.caption = caption
    }
}

