//
//  AINavigationManager.swift
//  Bible v1
//
//  TRC AI Bible Assistant - Navigation Integration
//

import Foundation
import SwiftUI
import Combine

/// Manages navigation from AI chat to Bible reader and other destinations
@MainActor
class AINavigationManager: ObservableObject {
    static let shared = AINavigationManager()
    
    // MARK: - Published State
    
    @Published var pendingVerseNavigation: VerseReference?
    @Published var pendingJournalContent: JournalFromAI?
    @Published var shouldNavigateToReader: Bool = false
    @Published var shouldNavigateToJournal: Bool = false
    
    // MARK: - Navigation Methods
    
    /// Navigate to a specific verse in the Bible reader
    func navigateToVerse(_ reference: VerseReference) {
        pendingVerseNavigation = reference
        shouldNavigateToReader = true
    }
    
    /// Navigate to a verse from a citation
    func navigateToVerse(from citation: AICitation) {
        guard let reference = citation.toVerseReference() else {
            // Try to create a basic reference for navigation
            if let chapter = citation.chapter {
                let basicRef = VerseReference(
                    translationId: citation.translationId,
                    bookId: citation.bookId ?? "",
                    bookName: citation.bookName ?? citation.reference,
                    chapter: chapter,
                    verse: citation.verseStart ?? 1,
                    text: citation.text ?? ""
                )
                navigateToVerse(basicRef)
            }
            return
        }
        navigateToVerse(reference)
    }
    
    /// Navigate to journal with pre-filled content
    func navigateToJournal(content: String, citations: [AICitation]) {
        pendingJournalContent = JournalFromAI(
            content: content,
            citations: citations
        )
        shouldNavigateToJournal = true
    }
    
    /// Clear pending navigation
    func clearNavigation() {
        pendingVerseNavigation = nil
        pendingJournalContent = nil
        shouldNavigateToReader = false
        shouldNavigateToJournal = false
    }
    
    /// Handle the navigation in the Bible reader
    func applyPendingNavigation(to bibleViewModel: BibleViewModel) {
        guard let reference = pendingVerseNavigation else { return }
        
        // Use the existing navigateToReference method
        bibleViewModel.navigateToReference(reference.shortReference)
        
        // Clear after handling
        clearNavigation()
    }
}

/// Content to be saved to journal from AI
struct JournalFromAI {
    let content: String
    let citations: [AICitation]
    
    var linkedVerses: [LinkedVerse] {
        citations.compactMap { citation -> LinkedVerse? in
            guard let bookId = citation.bookId,
                  let bookName = citation.bookName,
                  let chapter = citation.chapter,
                  let verse = citation.verseStart else {
                return nil
            }
            
            return LinkedVerse(
                translationId: citation.translationId,
                bookId: bookId,
                bookName: bookName,
                chapter: chapter,
                verse: verse,
                text: citation.text ?? ""
            )
        }
    }
    
    var formattedContent: String {
        var text = content
        
        if !citations.isEmpty {
            text += "\n\n---\n**Verses Referenced:**\n"
            for citation in citations {
                text += "• \(citation.reference)"
                if let verseText = citation.text {
                    text += ": \"\(verseText)\""
                }
                text += "\n"
            }
        }
        
        return text
    }
}

// MARK: - Navigation View Modifier

/// View modifier to handle AI navigation
struct AINavigationModifier: ViewModifier {
    @ObservedObject var navigationManager = AINavigationManager.shared
    @ObservedObject var bibleViewModel: BibleViewModel
    
    func body(content: Content) -> some View {
        content
            .onChange(of: navigationManager.shouldNavigateToReader) { _, shouldNavigate in
                if shouldNavigate {
                    navigationManager.applyPendingNavigation(to: bibleViewModel)
                }
            }
    }
}

extension View {
    func handleAINavigation(bibleViewModel: BibleViewModel) -> some View {
        modifier(AINavigationModifier(bibleViewModel: bibleViewModel))
    }
}

// MARK: - Deep Link Handler

extension AINavigationManager {
    
    /// Handle a deep link for verse navigation
    func handleDeepLink(_ url: URL) -> Bool {
        // Format: biblev1://verse/John/3/16?translation=engKJV
        guard url.scheme == "biblev1",
              url.host == "verse" else {
            return false
        }
        
        let components = url.pathComponents.filter { $0 != "/" }
        guard components.count >= 3,
              let chapter = Int(components[1]),
              let verse = Int(components[2]) else {
            return false
        }
        
        let bookName = components[0]
        let translation = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == "translation" })?
            .value ?? "engKJV"
        
        let reference = VerseReference(
            translationId: translation,
            bookId: "", // Will be resolved by reader
            bookName: bookName,
            chapter: chapter,
            verse: verse,
            text: ""
        )
        
        navigateToVerse(reference)
        return true
    }
}




