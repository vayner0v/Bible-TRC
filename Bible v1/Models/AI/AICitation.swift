//
//  AICitation.swift
//  Bible v1
//
//  TRC AI Bible Assistant - Citation Model
//

import Foundation
import SwiftUI

/// Verification status for AI-quoted verses
enum VerificationStatus: String, Codable {
    case pending       // Still loading/verifying
    case verified      // Fetched from Bible API and confirmed
    case paraphrased   // Could not verify exact text, marked as paraphrase
    case failed        // API error during verification
    
    var icon: String {
        switch self {
        case .pending: return "clock"
        case .verified: return "checkmark.seal.fill"
        case .paraphrased: return "quote.opening"
        case .failed: return "exclamationmark.triangle"
        }
    }
    
    var color: Color {
        switch self {
        case .pending: return .gray
        case .verified: return .green
        case .paraphrased: return .orange
        case .failed: return .red
        }
    }
    
    var label: String {
        switch self {
        case .pending: return "Verifying..."
        case .verified: return "Verified"
        case .paraphrased: return "Paraphrased"
        case .failed: return "Unverified"
        }
    }
}

/// Represents a Bible verse citation in an AI response
struct AICitation: Identifiable, Codable, Hashable {
    let id: UUID
    let reference: String          // e.g., "John 3:16"
    let translationId: String      // e.g., "engKJV"
    let bookId: String?            // e.g., "JHN" - resolved after parsing
    let bookName: String?          // e.g., "John"
    let chapter: Int?
    let verseStart: Int?
    let verseEnd: Int?
    let text: String?              // The actual verse text (fetched from Bible API)
    var verificationStatus: VerificationStatus  // Verification state
    
    init(
        id: UUID = UUID(),
        reference: String,
        translationId: String,
        bookId: String? = nil,
        bookName: String? = nil,
        chapter: Int? = nil,
        verseStart: Int? = nil,
        verseEnd: Int? = nil,
        text: String? = nil,
        verificationStatus: VerificationStatus = .pending
    ) {
        self.id = id
        self.reference = reference
        self.translationId = translationId
        self.bookId = bookId
        self.bookName = bookName
        self.chapter = chapter
        self.verseStart = verseStart
        self.verseEnd = verseEnd
        self.text = text
        self.verificationStatus = verificationStatus
    }
    
    /// Short display reference
    var shortReference: String {
        reference
    }
    
    /// Full reference with translation
    var fullReference: String {
        "\(reference) (\(translationId.uppercased()))"
    }
    
    /// Whether this citation has been fully resolved with verse text
    var isResolved: Bool {
        text != nil && !text!.isEmpty
    }
    
    /// Whether this is a verse range
    var isRange: Bool {
        if let start = verseStart, let end = verseEnd {
            return end > start
        }
        return false
    }
    
    /// Create a copy with resolved verse text and verification status
    func withResolvedText(_ resolvedText: String, status: VerificationStatus = .verified) -> AICitation {
        AICitation(
            id: id,
            reference: reference,
            translationId: translationId,
            bookId: bookId,
            bookName: bookName,
            chapter: chapter,
            verseStart: verseStart,
            verseEnd: verseEnd,
            text: resolvedText,
            verificationStatus: status
        )
    }
    
    /// Create a copy with updated verification status
    func withVerificationStatus(_ status: VerificationStatus) -> AICitation {
        AICitation(
            id: id,
            reference: reference,
            translationId: translationId,
            bookId: bookId,
            bookName: bookName,
            chapter: chapter,
            verseStart: verseStart,
            verseEnd: verseEnd,
            text: text,
            verificationStatus: status
        )
    }
    
    /// Create a VerseReference for navigation (if fully resolved)
    func toVerseReference() -> VerseReference? {
        guard let bookId = bookId,
              let bookName = bookName,
              let chapter = chapter,
              let verse = verseStart,
              let text = text else {
            return nil
        }
        
        return VerseReference(
            translationId: translationId,
            bookId: bookId,
            bookName: bookName,
            chapter: chapter,
            verse: verse,
            text: text
        )
    }
}

/// Raw citation from LLM response (before resolution)
struct RawCitation: Codable {
    let reference: String
    let translation: String?
    
    var translationId: String {
        translation ?? "engKJV"
    }
}

