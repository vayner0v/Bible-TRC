//
//  Chapter.swift
//  Bible v1
//
//  Advanced Bible Reader App
//

import Foundation

/// Represents a chapter of the Bible with its verses
struct Chapter: Codable, Identifiable {
    let translation: Translation?
    let book: Book
    let chapterInfo: ChapterInfo
    let verses: [Verse]
    let footnotes: [Footnote]?
    
    var id: String {
        "\(book.id)_\(chapterInfo.number)"
    }
    
    /// Chapter number
    var chapter: Int {
        chapterInfo.number
    }
    
    enum CodingKeys: String, CodingKey {
        case translation
        case book
        case chapterInfo = "chapter"
        case footnotes
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        translation = try container.decodeIfPresent(Translation.self, forKey: .translation)
        book = try container.decode(Book.self, forKey: .book)
        chapterInfo = try container.decode(ChapterInfo.self, forKey: .chapterInfo)
        footnotes = try container.decodeIfPresent([Footnote].self, forKey: .footnotes)
        
        // Parse verses from content
        verses = chapterInfo.content.compactMap { content -> Verse? in
            guard content.type == "verse", let number = content.number else { return nil }
            
            // Extract text from all content items (strings and objects with text)
            let textParts = content.content?.compactMap { item -> String? in
                item.textContent
            } ?? []
            
            // Join text parts and clean up whitespace
            let rawText = textParts.joined(separator: " ")
            let cleanedText = rawText
                .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Filter out verses with empty text
            guard !cleanedText.isEmpty else { return nil }
            
            return Verse(verse: number, text: cleanedText)
        }
    }
    
    init(translation: Translation?, book: Book, chapterInfo: ChapterInfo, verses: [Verse], footnotes: [Footnote]? = nil) {
        self.translation = translation
        self.book = book
        self.chapterInfo = chapterInfo
        self.verses = verses
        self.footnotes = footnotes
    }
    
    /// Full reference string (e.g., "Genesis 1")
    var reference: String {
        "\(book.displayName) \(chapterInfo.number)"
    }
}

/// Chapter information from API
struct ChapterInfo: Codable {
    let number: Int
    let content: [ChapterContent]
    let next: ChapterNavigation?
    let previous: ChapterNavigation?
}

/// Content item in a chapter (verse, heading, line break, etc.)
struct ChapterContent: Codable {
    let type: String
    let number: Int?
    let content: [ContentItem]?
    
    enum CodingKeys: String, CodingKey {
        case type
        case number
        case content
    }
}

/// A content item can be a string or an object (like footnote reference)
enum ContentItem: Codable {
    case string(String)
    case object([String: AnyCodable])
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else if let objectValue = try? container.decode([String: AnyCodable].self) {
            self = .object(objectValue)
        } else {
            self = .string("")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        }
    }
    
    /// Extract text content from this item
    /// - Strings return their value directly
    /// - Objects may contain a "text" field or other text-bearing properties
    var textContent: String? {
        switch self {
        case .string(let str):
            return str.isEmpty ? nil : str
        case .object(let dict):
            // Try to extract text from common text-bearing properties in the API
            // The API may embed text in objects like footnote refs, word studies, etc.
            if let textValue = dict["text"]?.value as? String, !textValue.isEmpty {
                return textValue
            }
            // Some objects have a "content" field with text
            if let contentValue = dict["content"]?.value as? String, !contentValue.isEmpty {
                return contentValue
            }
            // Some objects have inline text in a "value" field
            if let valueText = dict["value"]?.value as? String, !valueText.isEmpty {
                return valueText
            }
            return nil
        }
    }
}

/// Helper for decoding any JSON value
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else {
            value = ""
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        if let intValue = value as? Int {
            try container.encode(intValue)
        } else if let doubleValue = value as? Double {
            try container.encode(doubleValue)
        } else if let stringValue = value as? String {
            try container.encode(stringValue)
        } else if let boolValue = value as? Bool {
            try container.encode(boolValue)
        }
    }
}

/// Navigation to another chapter
struct ChapterNavigation: Codable {
    let book: BookNavigation?
    let chapter: Int?
    let apiLink: String?
}

/// Book reference in navigation
struct BookNavigation: Codable {
    let id: String
    let name: String
}

/// Footnote in a chapter
struct Footnote: Codable {
    let noteId: Int
    let text: String?
    let reference: FootnoteReference?
    let caller: String?
}

/// Footnote reference
struct FootnoteReference: Codable {
    let book: String?
    let chapter: Int?
    let verse: Int?
}
