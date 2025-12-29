//
//  Verse.swift
//  Bible v1
//
//  Advanced Bible Reader App
//

import Foundation

/// Represents a single verse of scripture
struct Verse: Codable, Identifiable, Hashable {
    let verse: Int
    let text: String
    
    var id: Int { verse }
    
    /// Formatted verse number for display
    var verseNumber: String {
        "\(verse)"
    }
}

/// A complete verse reference including translation and location
struct VerseReference: Codable, Hashable, Identifiable {
    let translationId: String
    let bookId: String
    let bookName: String
    let chapter: Int
    let verse: Int
    let text: String
    
    var id: String {
        "\(translationId)_\(bookId)_\(chapter)_\(verse)"
    }
    
    /// Unique key for storage lookups
    var verseKey: String {
        "\(translationId)_\(bookId)_\(chapter)_\(verse)"
    }
    
    /// Short reference string (e.g., "John 3:16")
    var shortReference: String {
        "\(bookName) \(chapter):\(verse)"
    }
    
    /// Full reference with translation (e.g., "John 3:16 (KJV)")
    var fullReference: String {
        "\(shortReference) (\(translationId))"
    }
    
    /// Shareable text format
    var shareableText: String {
        "\"\(text)\"\n— \(fullReference)"
    }
}

/// Parsed reference from user input (e.g., "John 3:16")
struct ParsedReference {
    let bookName: String
    let chapter: Int
    let verseStart: Int?
    let verseEnd: Int?
    
    /// Whether this is a range of verses
    var isRange: Bool {
        if let start = verseStart, let end = verseEnd {
            return end > start
        }
        return false
    }
    
    /// Creates a parsed reference from a string like "John 3:16" or "Genesis 1:1-5"
    static func parse(_ input: String) -> ParsedReference? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Regex pattern for book chapter:verse(-verse)
        // Examples: "John 3:16", "1 John 3:16", "Genesis 1:1-5", "Psalm 23"
        let pattern = #"^(\d?\s?[A-Za-z]+)\s+(\d+)(?::(\d+)(?:-(\d+))?)?$"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)) else {
            return nil
        }
        
        // Extract book name
        guard let bookRange = Range(match.range(at: 1), in: trimmed) else { return nil }
        let bookName = String(trimmed[bookRange]).trimmingCharacters(in: .whitespaces)
        
        // Extract chapter
        guard let chapterRange = Range(match.range(at: 2), in: trimmed),
              let chapter = Int(trimmed[chapterRange]) else { return nil }
        
        // Extract verse start (optional)
        var verseStart: Int? = nil
        if match.range(at: 3).location != NSNotFound,
           let verseRange = Range(match.range(at: 3), in: trimmed) {
            verseStart = Int(trimmed[verseRange])
        }
        
        // Extract verse end (optional)
        var verseEnd: Int? = nil
        if match.range(at: 4).location != NSNotFound,
           let endRange = Range(match.range(at: 4), in: trimmed) {
            verseEnd = Int(trimmed[endRange])
        }
        
        return ParsedReference(
            bookName: bookName,
            chapter: chapter,
            verseStart: verseStart,
            verseEnd: verseEnd
        )
    }
}

