//
//  CommunitySearchViewModel.swift
//  Bible v1
//
//  Community Tab - Search View Model
//

import Foundation
import SwiftUI
import Combine
import Supabase

@MainActor
final class CommunitySearchViewModel: ObservableObject {
    
    // MARK: - Published State
    
    @Published var searchText = ""
    @Published var selectedFilter: SearchFilter = .all
    @Published var isSearching = false
    
    // Results
    @Published var postResults: [Post] = []
    @Published var peopleResults: [CommunityProfileSummary] = []
    @Published var groupResults: [GroupSummary] = []
    @Published var verseResults: [VerseSearchResult] = []
    
    // Suggestions
    @Published var recentSearches: [String] = []
    @Published var trendingTopics: [String] = []
    @Published var suggestedUsers: [CommunityProfileSummary] = []
    
    // MARK: - Properties
    
    private var discoveryService: DiscoveryService { CommunityService.shared.discoveryService }
    private var feedService: FeedService { CommunityService.shared.feedService }
    private var searchTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    
    private let recentSearchesKey = "community_recent_searches"
    
    // MARK: - Initialization
    
    init() {
        loadRecentSearches()
        loadTrendingTopics()
        loadSuggestedUsers()
        setupSearchDebounce()
    }
    
    // MARK: - Public Methods
    
    /// Perform search
    func search() async {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        
        isSearching = true
        defer { isSearching = false }
        
        // Save to recent searches
        saveRecentSearch(query)
        
        do {
            // Parallel search across different content types
            async let posts = searchPosts(query: query)
            async let people = searchPeople(query: query)
            async let groups = searchGroups(query: query)
            async let verses = searchVerses(query: query)
            
            let (postRes, peopleRes, groupRes, verseRes) = await (
                try posts,
                try people,
                try groups,
                try verses
            )
            
            postResults = postRes
            peopleResults = peopleRes
            groupResults = groupRes
            verseResults = verseRes
        } catch {
            print("❌ Search error: \(error.localizedDescription)")
        }
    }
    
    /// Clear search
    func clearSearch() {
        searchText = ""
        postResults = []
        peopleResults = []
        groupResults = []
        verseResults = []
        selectedFilter = .all
    }
    
    /// Clear recent searches
    func clearRecentSearches() {
        recentSearches = []
        UserDefaults.standard.removeObject(forKey: recentSearchesKey)
    }
    
    // MARK: - Private Methods
    
    private func setupSearchDebounce() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] query in
                guard let self = self else { return }
                self.searchTask?.cancel()
                
                if !query.isEmpty {
                    self.searchTask = Task {
                        await self.search()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func loadRecentSearches() {
        if let searches = UserDefaults.standard.stringArray(forKey: recentSearchesKey) {
            recentSearches = searches
        }
    }
    
    private func saveRecentSearch(_ query: String) {
        var searches = recentSearches
        searches.removeAll { $0.lowercased() == query.lowercased() }
        searches.insert(query, at: 0)
        searches = Array(searches.prefix(10)) // Keep only last 10
        recentSearches = searches
        UserDefaults.standard.set(searches, forKey: recentSearchesKey)
    }
    
    private func loadTrendingTopics() {
        Task {
            // Load trending topics from discovery service
            trendingTopics = [
                "faith", "prayer", "love", "jesus", "hope",
                "healing", "gratitude", "wisdom", "peace", "strength"
            ]
        }
    }
    
    private func loadSuggestedUsers() {
        Task {
            // Load suggested users from discovery service
            // For now, empty - would be populated from API
            suggestedUsers = []
        }
    }
    
    private func searchPosts(query: String) async throws -> [Post] {
        // Search posts containing the query
        // This would use the Supabase full-text search
        let supabase = SupabaseService.shared.client
        
        let posts: [Post] = try await supabase
            .from("posts")
            .select("*, author:community_profiles!author_id(*)")
            .textSearch("content", query: query, type: .websearch)
            .eq("visibility", value: "public")
            .is("deleted_at", value: nil)
            .order("created_at", ascending: false)
            .limit(20)
            .execute()
            .value
        
        return posts
    }
    
    private func searchPeople(query: String) async throws -> [CommunityProfileSummary] {
        let supabase = SupabaseService.shared.client
        
        let profiles: [CommunityProfileSummary] = try await supabase
            .from("community_profiles")
            .select("id, display_name, username, avatar_url, is_verified, verification_type")
            .or("display_name.ilike.%\(query)%,username.ilike.%\(query)%")
            .limit(20)
            .execute()
            .value
        
        return profiles
    }
    
    private func searchGroups(query: String) async throws -> [GroupSummary] {
        let supabase = SupabaseService.shared.client
        
        let groups: [GroupSummary] = try await supabase
            .from("groups")
            .select("id, name, type, privacy, avatar_url, member_count")
            .or("name.ilike.%\(query)%,description.ilike.%\(query)%")
            .eq("privacy", value: "public")
            .limit(20)
            .execute()
            .value
        
        return groups
    }
    
    private func searchVerses(query: String) async throws -> [VerseSearchResult] {
        // Search for verses that match the query
        // This would integrate with the Bible search functionality
        // For now, return sample data
        
        // Common verses that might match searches
        let sampleVerses: [VerseSearchResult] = [
            VerseSearchResult(book: "John", chapter: 3, verse: 16, text: "For God so loved the world that he gave his one and only Son...", postCount: 45),
            VerseSearchResult(book: "Philippians", chapter: 4, verse: 13, text: "I can do all things through Christ who strengthens me.", postCount: 32),
            VerseSearchResult(book: "Jeremiah", chapter: 29, verse: 11, text: "For I know the plans I have for you, declares the LORD...", postCount: 28),
            VerseSearchResult(book: "Romans", chapter: 8, verse: 28, text: "And we know that in all things God works for the good...", postCount: 25),
            VerseSearchResult(book: "Psalm", chapter: 23, verse: 1, text: "The LORD is my shepherd; I shall not want.", postCount: 22)
        ]
        
        // Filter verses that might match the query
        return sampleVerses.filter { verse in
            verse.text.lowercased().contains(query.lowercased()) ||
            verse.reference.lowercased().contains(query.lowercased())
        }
    }
}

