//
//  VerseHubViewModel.swift
//  Bible v1
//
//  Community Tab - Verse Hub View Model
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class VerseHubViewModel: ObservableObject {
    
    // MARK: - Published State
    
    @Published private(set) var hubData: VerseHubData?
    @Published private(set) var isLoading = false
    @Published var selectedSection: VerseHubSection = .reflections
    @Published var error: CommunityError?
    @Published var showComposer = false
    
    // MARK: - Properties
    
    let book: String
    let chapter: Int
    let verse: Int
    let translationId: String
    
    private var verseHubService: VerseHubService { CommunityService.shared.verseHubService }
    
    var reference: String {
        "\(book) \(chapter):\(verse)"
    }
    
    var fullReference: String {
        "\(book) \(chapter):\(verse) (\(translationId.uppercased()))"
    }
    
    // MARK: - Initialization
    
    init(book: String, chapter: Int, verse: Int, translationId: String = "KJV") {
        self.book = book
        self.chapter = chapter
        self.verse = verse
        self.translationId = translationId
    }
    
    // MARK: - Public Methods
    
    /// Load verse hub data
    func load() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            hubData = try await verseHubService.getVerseHub(
                book: book,
                chapter: chapter,
                verse: verse,
                translationId: translationId
            )
        } catch {
            self.error = error as? CommunityError ?? .unknown(error.localizedDescription)
        }
    }
    
    /// Refresh hub data
    func refresh() async {
        await load()
    }
    
    /// Get posts for selected section
    var sectionPosts: [Post] {
        guard let hubData = hubData else { return [] }
        
        switch selectedSection {
        case .reflections:
            return hubData.reflections
        case .questions:
            return hubData.questions
        case .prayers:
            return hubData.prayers
        case .testimonies:
            return hubData.testimonies
        }
    }
    
    /// Count for selected section
    var sectionCount: Int {
        sectionPosts.count
    }
    
    /// Create post for this verse
    func createPost(type: PostType) {
        // Will be handled by navigation
    }
    
    /// Open composer with verse pre-selected
    func openComposer(type: PostType = .reflection) {
        showComposer = true
    }
}

// MARK: - Supporting Types

enum VerseHubSection: String, CaseIterable, Identifiable {
    case reflections = "reflections"
    case questions = "questions"
    case prayers = "prayers"
    case testimonies = "testimonies"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .reflections: return "Reflections"
        case .questions: return "Questions"
        case .prayers: return "Prayers"
        case .testimonies: return "Testimonies"
        }
    }
    
    var icon: String {
        switch self {
        case .reflections: return "text.quote"
        case .questions: return "questionmark.circle"
        case .prayers: return "hands.sparkles"
        case .testimonies: return "heart.text.square"
        }
    }
    
    var emptyMessage: String {
        switch self {
        case .reflections: return "No reflections yet. Be the first to share your thoughts!"
        case .questions: return "No questions yet. Ask something about this verse!"
        case .prayers: return "No prayers yet. Share a prayer related to this verse."
        case .testimonies: return "No testimonies yet. Share how this verse impacted you!"
        }
    }
}

