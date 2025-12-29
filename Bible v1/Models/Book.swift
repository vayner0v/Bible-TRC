//
//  Book.swift
//  Bible v1
//
//  Advanced Bible Reader App
//

import Foundation

/// Represents a book of the Bible
struct Book: Codable, Identifiable, Hashable {
    let id: String
    let translationId: String?
    let name: String
    let commonName: String?
    let title: String?
    let order: Int?
    let numberOfChapters: Int
    let firstChapterNumber: Int?
    let lastChapterNumber: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case translationId
        case name
        case commonName
        case title
        case order
        case numberOfChapters
        case firstChapterNumber
        case lastChapterNumber
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        translationId = try container.decodeIfPresent(String.self, forKey: .translationId)
        name = try container.decode(String.self, forKey: .name)
        commonName = try container.decodeIfPresent(String.self, forKey: .commonName)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        order = try container.decodeIfPresent(Int.self, forKey: .order)
        numberOfChapters = try container.decodeIfPresent(Int.self, forKey: .numberOfChapters) ?? 1
        firstChapterNumber = try container.decodeIfPresent(Int.self, forKey: .firstChapterNumber)
        lastChapterNumber = try container.decodeIfPresent(Int.self, forKey: .lastChapterNumber)
    }
    
    init(id: String, translationId: String? = nil, name: String, commonName: String? = nil, title: String? = nil, order: Int? = nil, numberOfChapters: Int, firstChapterNumber: Int? = nil, lastChapterNumber: Int? = nil) {
        self.id = id
        self.translationId = translationId
        self.name = name
        self.commonName = commonName
        self.title = title
        self.order = order
        self.numberOfChapters = numberOfChapters
        self.firstChapterNumber = firstChapterNumber
        self.lastChapterNumber = lastChapterNumber
    }
    
    /// Display name - prefers common name if available
    var displayName: String {
        commonName ?? name
    }
    
    /// Abbreviated name for tight spaces (e.g., "1 Thess" instead of "1 Thessalonians")
    var abbreviatedName: String {
        // Common abbreviations for long book names
        let abbreviations: [String: String] = [
            // Old Testament
            "Genesis": "Gen",
            "Exodus": "Exod",
            "Leviticus": "Lev",
            "Numbers": "Num",
            "Deuteronomy": "Deut",
            "Joshua": "Josh",
            "Judges": "Judg",
            "1 Samuel": "1 Sam",
            "2 Samuel": "2 Sam",
            "1 Kings": "1 Kgs",
            "2 Kings": "2 Kgs",
            "1 Chronicles": "1 Chr",
            "2 Chronicles": "2 Chr",
            "Nehemiah": "Neh",
            "Esther": "Esth",
            "Psalms": "Ps",
            "Proverbs": "Prov",
            "Ecclesiastes": "Eccl",
            "Song of Solomon": "Song",
            "Song of Songs": "Song",
            "Isaiah": "Isa",
            "Jeremiah": "Jer",
            "Lamentations": "Lam",
            "Ezekiel": "Ezek",
            "Daniel": "Dan",
            "Hosea": "Hos",
            "Obadiah": "Obad",
            "Jonah": "Jon",
            "Micah": "Mic",
            "Nahum": "Nah",
            "Habakkuk": "Hab",
            "Zephaniah": "Zeph",
            "Haggai": "Hag",
            "Zechariah": "Zech",
            "Malachi": "Mal",
            // New Testament
            "Matthew": "Matt",
            "Philippians": "Phil",
            "Colossians": "Col",
            "1 Thessalonians": "1 Thess",
            "2 Thessalonians": "2 Thess",
            "1 Timothy": "1 Tim",
            "2 Timothy": "2 Tim",
            "Philemon": "Phlm",
            "Hebrews": "Heb",
            "Revelation": "Rev"
        ]
        
        let name = displayName
        return abbreviations[name] ?? name
    }
    
    /// Short name - uses abbreviation only if the display name is long (> 12 chars)
    var shortName: String {
        displayName.count > 12 ? abbreviatedName : displayName
    }
    
    /// Inferred testament based on book order (for 66-book Protestant canon)
    var inferredTestament: Testament {
        if let o = order {
            return o <= 39 ? .old : .new
        }
        // Fallback: check common OT book IDs
        let otBooks = ["GEN", "EXO", "LEV", "NUM", "DEU", "JOS", "JDG", "RUT", "1SA", "2SA",
                       "1KI", "2KI", "1CH", "2CH", "EZR", "NEH", "EST", "JOB", "PSA", "PRO",
                       "ECC", "SNG", "ISA", "JER", "LAM", "EZK", "DAN", "HOS", "JOL", "AMO",
                       "OBA", "JON", "MIC", "NAM", "HAB", "ZEP", "HAG", "ZEC", "MAL"]
        return otBooks.contains(id.uppercased()) ? .old : .new
    }
}

/// Testament of the Bible
enum Testament: String, Codable, CaseIterable {
    case old
    case new
    
    var displayName: String {
        switch self {
        case .old: return "Old Testament"
        case .new: return "New Testament"
        }
    }
    
    var shortName: String {
        switch self {
        case .old: return "OT"
        case .new: return "NT"
        }
    }
}

/// Response wrapper for books list
struct BooksResponse: Codable {
    let translation: Translation?
    let books: [Book]
}
