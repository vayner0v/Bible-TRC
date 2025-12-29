//
//  Translation.swift
//  Bible v1
//
//  Advanced Bible Reader App
//

import Foundation

/// Represents a Bible translation/version available from the API
struct Translation: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let englishName: String?
    let language: String
    let textDirection: TextDirection
    let availableFormats: [String]?
    let listOfBooksApiLink: String?
    let numberOfBooks: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case englishName
        case language
        case textDirection
        case availableFormats
        case listOfBooksApiLink
        case numberOfBooks
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        englishName = try container.decodeIfPresent(String.self, forKey: .englishName)
        language = try container.decode(String.self, forKey: .language)
        
        // Handle text direction - default to LTR if not specified
        if let directionString = try container.decodeIfPresent(String.self, forKey: .textDirection) {
            textDirection = TextDirection(rawValue: directionString) ?? .ltr
        } else {
            textDirection = .ltr
        }
        
        availableFormats = try container.decodeIfPresent([String].self, forKey: .availableFormats)
        listOfBooksApiLink = try container.decodeIfPresent(String.self, forKey: .listOfBooksApiLink)
        numberOfBooks = try container.decodeIfPresent(Int.self, forKey: .numberOfBooks)
    }
    
    init(id: String, name: String, englishName: String? = nil, language: String, textDirection: TextDirection = .ltr, availableFormats: [String]? = nil, listOfBooksApiLink: String? = nil, numberOfBooks: Int? = nil) {
        self.id = id
        self.name = name
        self.englishName = englishName
        self.language = language
        self.textDirection = textDirection
        self.availableFormats = availableFormats
        self.listOfBooksApiLink = listOfBooksApiLink
        self.numberOfBooks = numberOfBooks
    }
    
    /// Display name - prefers English name for non-English translations
    var displayName: String {
        if let english = englishName, !english.isEmpty {
            return "\(name) (\(english))"
        }
        return name
    }
    
    /// Whether text flows right-to-left
    var isRTL: Bool {
        textDirection == .rtl
    }
}

/// Text direction for the translation
enum TextDirection: String, Codable {
    case ltr
    case rtl
}

/// Response wrapper for translations list
struct TranslationsResponse: Codable {
    let translations: [Translation]
}




