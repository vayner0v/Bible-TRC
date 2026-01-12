//
//  CommunitySearchView.swift
//  Bible v1
//
//  Community Tab - Search View
//

import SwiftUI

struct CommunitySearchView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CommunitySearchViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    @FocusState private var isSearchFocused: Bool
    
    let initialQuery: String?
    
    init(initialQuery: String? = nil) {
        self.initialQuery = initialQuery
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                searchBar
                
                // Content
                if viewModel.searchText.isEmpty {
                    recentAndSuggestions
                } else if viewModel.isSearching {
                    loadingView
                } else {
                    searchResults
                }
            }
            .background(themeManager.backgroundColor)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.accentColor)
                }
            }
            .onAppear {
                if let query = initialQuery, !query.isEmpty {
                    viewModel.searchText = query
                    Task { await viewModel.search() }
                }
                isSearchFocused = true
            }
        }
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundColor(themeManager.textColor.opacity(0.5))
                
                TextField("Search community...", text: $viewModel.searchText)
                    .font(.system(size: 16))
                    .foregroundColor(themeManager.textColor)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .focused($isSearchFocused)
                    .submitLabel(.search)
                    .onSubmit {
                        Task { await viewModel.search() }
                    }
                
                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.clearSearch()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(themeManager.textColor.opacity(0.4))
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(themeManager.backgroundColor.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding()
    }
    
    // MARK: - Recent & Suggestions
    
    private var recentAndSuggestions: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Recent Searches
                if !viewModel.recentSearches.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Recent")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(themeManager.textColor)
                            
                            Spacer()
                            
                            Button("Clear") {
                                viewModel.clearRecentSearches()
                            }
                            .font(.system(size: 14))
                            .foregroundColor(themeManager.accentColor)
                        }
                        
                        ForEach(viewModel.recentSearches, id: \.self) { query in
                            Button {
                                viewModel.searchText = query
                                Task { await viewModel.search() }
                            } label: {
                                HStack {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .font(.system(size: 14))
                                        .foregroundColor(themeManager.textColor.opacity(0.5))
                                    
                                    Text(query)
                                        .font(.system(size: 15))
                                        .foregroundColor(themeManager.textColor)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "arrow.up.left")
                                        .font(.system(size: 12))
                                        .foregroundColor(themeManager.textColor.opacity(0.3))
                                }
                                .padding(.vertical, 8)
                            }
                        }
                    }
                }
                
                // Trending Topics
                if !viewModel.trendingTopics.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Trending")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(themeManager.textColor)
                        
                        FlowLayout(spacing: 8) {
                            ForEach(viewModel.trendingTopics, id: \.self) { topic in
                                Button {
                                    viewModel.searchText = topic
                                    Task { await viewModel.search() }
                                } label: {
                                    Text("#\(topic)")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(themeManager.accentColor)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(themeManager.accentColor.opacity(0.1))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }
                
                // Suggested Users
                if !viewModel.suggestedUsers.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Suggested People")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(themeManager.textColor)
                        
                        ForEach(viewModel.suggestedUsers) { user in
                            NavigationLink(value: CommunityDestination.profile(user.id)) {
                                SuggestedUserRow(user: user)
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
                .tint(themeManager.accentColor)
            Spacer()
        }
    }
    
    // MARK: - Search Results
    
    private var searchResults: some View {
        VStack(spacing: 0) {
            // Filter Tabs
            filterTabs
            
            // Results
            ScrollView {
                LazyVStack(spacing: 12) {
                    switch viewModel.selectedFilter {
                    case .all:
                        allResults
                    case .posts:
                        postResults
                    case .people:
                        peopleResults
                    case .groups:
                        groupResults
                    case .verses:
                        verseResults
                    }
                }
                .padding()
            }
        }
    }
    
    private var filterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SearchFilter.allCases) { filter in
                    Button {
                        viewModel.selectedFilter = filter
                    } label: {
                        Text(filter.displayName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(
                                viewModel.selectedFilter == filter
                                    ? .white
                                    : themeManager.textColor.opacity(0.7)
                            )
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                viewModel.selectedFilter == filter
                                    ? themeManager.accentColor
                                    : themeManager.backgroundColor.opacity(0.3)
                            )
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
    
    private var allResults: some View {
        VStack(spacing: 20) {
            // People Section
            if !viewModel.peopleResults.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    sectionHeader("People", count: viewModel.peopleResults.count)
                    
                    ForEach(viewModel.peopleResults.prefix(3)) { user in
                        NavigationLink(value: CommunityDestination.profile(user.id)) {
                            SearchUserRow(user: user)
                        }
                    }
                    
                    if viewModel.peopleResults.count > 3 {
                        Button {
                            viewModel.selectedFilter = .people
                        } label: {
                            Text("See all \(viewModel.peopleResults.count) people")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(themeManager.accentColor)
                        }
                    }
                }
            }
            
            // Posts Section
            if !viewModel.postResults.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    sectionHeader("Posts", count: viewModel.postResults.count)
                    
                    ForEach(viewModel.postResults.prefix(3)) { post in
                        NavigationLink(value: CommunityDestination.postDetail(post.id)) {
                            SearchPostRow(post: post)
                        }
                    }
                    
                    if viewModel.postResults.count > 3 {
                        Button {
                            viewModel.selectedFilter = .posts
                        } label: {
                            Text("See all \(viewModel.postResults.count) posts")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(themeManager.accentColor)
                        }
                    }
                }
            }
            
            // Groups Section
            if !viewModel.groupResults.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    sectionHeader("Groups", count: viewModel.groupResults.count)
                    
                    ForEach(viewModel.groupResults.prefix(3)) { group in
                        NavigationLink(value: CommunityDestination.group(group.id)) {
                            SearchGroupRow(group: group)
                        }
                    }
                    
                    if viewModel.groupResults.count > 3 {
                        Button {
                            viewModel.selectedFilter = .groups
                        } label: {
                            Text("See all \(viewModel.groupResults.count) groups")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(themeManager.accentColor)
                        }
                    }
                }
            }
            
            // Verses Section
            if !viewModel.verseResults.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    sectionHeader("Related Verses", count: viewModel.verseResults.count)
                    
                    ForEach(viewModel.verseResults.prefix(3)) { verse in
                        SearchVerseRow(verse: verse)
                    }
                    
                    if viewModel.verseResults.count > 3 {
                        Button {
                            viewModel.selectedFilter = .verses
                        } label: {
                            Text("See all \(viewModel.verseResults.count) verses")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(themeManager.accentColor)
                        }
                    }
                }
            }
            
            // No Results
            if viewModel.postResults.isEmpty && viewModel.peopleResults.isEmpty && viewModel.groupResults.isEmpty && viewModel.verseResults.isEmpty {
                noResultsView
            }
        }
    }
    
    private var postResults: some View {
        ForEach(viewModel.postResults) { post in
            NavigationLink(value: CommunityDestination.postDetail(post.id)) {
                SearchPostRow(post: post)
            }
        }
    }
    
    private var peopleResults: some View {
        ForEach(viewModel.peopleResults) { user in
            NavigationLink(value: CommunityDestination.profile(user.id)) {
                SearchUserRow(user: user)
            }
        }
    }
    
    private var groupResults: some View {
        ForEach(viewModel.groupResults) { group in
            NavigationLink(value: CommunityDestination.group(group.id)) {
                SearchGroupRow(group: group)
            }
        }
    }
    
    private var verseResults: some View {
        ForEach(viewModel.verseResults) { verse in
            SearchVerseRow(verse: verse)
        }
    }
    
    private func sectionHeader(_ title: String, count: Int) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(themeManager.textColor)
            
            Text("(\(count))")
                .font(.system(size: 14))
                .foregroundColor(themeManager.textColor.opacity(0.5))
            
            Spacer()
        }
    }
    
    private var noResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(themeManager.textColor.opacity(0.3))
            
            Text("No results for \"\(viewModel.searchText)\"")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(themeManager.textColor)
            
            Text("Try a different search term or check your spelling")
                .font(.system(size: 14))
                .foregroundColor(themeManager.textColor.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 60)
    }
}

// MARK: - Search Filter

enum SearchFilter: String, CaseIterable, Identifiable {
    case all, posts, people, groups, verses
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .posts: return "Posts"
        case .people: return "People"
        case .groups: return "Groups"
        case .verses: return "Verses"
        }
    }
}

// MARK: - Search Result Rows

struct SearchUserRow: View {
    let user: CommunityProfileSummary
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 12) {
            UserAvatarView(profile: user, size: 44)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(user.displayName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(themeManager.textColor)
                    
                    if user.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 12))
                            .foregroundColor(user.verificationType?.badgeColor ?? .blue)
                    }
                }
                
                if let username = user.username {
                    Text("@\(username)")
                        .font(.system(size: 13))
                        .foregroundColor(themeManager.textColor.opacity(0.5))
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(themeManager.textColor.opacity(0.3))
        }
        .padding()
        .background(themeManager.backgroundColor.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct SearchPostRow: View {
    let post: Post
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Author
            HStack(spacing: 8) {
                if let author = post.author {
                    UserAvatarView(profile: author, size: 28, showBadge: false)
                    Text(author.displayName)
                        .font(.system(size: 13, weight: .medium))
                }
                
                Text("•")
                    .foregroundColor(themeManager.textColor.opacity(0.4))
                
                Text(post.relativeTime)
                    .font(.system(size: 12))
            }
            .foregroundColor(themeManager.textColor.opacity(0.7))
            
            // Content Preview
            Text(post.previewText)
                .font(.system(size: 14))
                .foregroundColor(themeManager.textColor)
                .lineLimit(2)
            
            // Type Badge
            HStack(spacing: 4) {
                Image(systemName: post.type.icon)
                Text(post.type.displayName)
            }
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(post.type.color)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(themeManager.backgroundColor.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct SearchGroupRow: View {
    let group: GroupSummary
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            if let avatarUrl = group.avatarUrl, let url = URL(string: avatarUrl) {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    defaultGroupAvatar
                }
                .frame(width: 50, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                defaultGroupAvatar
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(group.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(themeManager.textColor)
                
                HStack(spacing: 6) {
                    Image(systemName: group.type.icon)
                        .font(.system(size: 11))
                        .foregroundColor(group.type.color)
                    
                    Text("\(group.memberCount) members")
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.textColor.opacity(0.5))
                }
            }
            
            Spacer()
            
            if group.isMember {
                Text("Joined")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.green)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.green.opacity(0.1))
                    .clipShape(Capsule())
            }
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(themeManager.textColor.opacity(0.3))
        }
        .padding()
        .background(themeManager.backgroundColor.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var defaultGroupAvatar: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(group.type.color.opacity(0.2))
            .frame(width: 50, height: 50)
            .overlay(
                Image(systemName: group.type.icon)
                    .font(.system(size: 20))
                    .foregroundColor(group.type.color)
            )
    }
}

struct SearchVerseRow: View {
    let verse: VerseSearchResult
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationLink(value: CommunityDestination.verseHub(verse.book, verse.chapter, verse.verse)) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(verse.reference)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(themeManager.accentColor)
                    
                    Spacer()
                    
                    Text("\(verse.postCount) posts")
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.textColor.opacity(0.5))
                }
                
                Text(verse.text)
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.textColor)
                    .lineLimit(2)
            }
            .padding()
            .background(themeManager.backgroundColor.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct SuggestedUserRow: View {
    let user: CommunityProfileSummary
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 12) {
            UserAvatarView(profile: user, size: 44)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(user.displayName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(themeManager.textColor)
                    
                    if user.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                    }
                }
                
                if let username = user.username {
                    Text("@\(username)")
                        .font(.system(size: 13))
                        .foregroundColor(themeManager.textColor.opacity(0.5))
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Verse Search Result Model

struct VerseSearchResult: Identifiable {
    let id = UUID()
    let book: String
    let chapter: Int
    let verse: Int
    let text: String
    let postCount: Int
    
    var reference: String {
        "\(book) \(chapter):\(verse)"
    }
}

// MARK: - Flow Layout
// Note: FlowLayout is defined in PrayerLibraryView.swift

#Preview {
    CommunitySearchView()
        .environmentObject(ThemeManager.shared)
}

