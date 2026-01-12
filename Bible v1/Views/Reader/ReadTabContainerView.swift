//
//  ReadTabContainerView.swift
//  Bible v1
//
//  Container view for Read tab with collapsible header
//

import SwiftUI

/// Container that holds ReaderView, SavedView, SearchView, and JournalView with a collapsible header
struct ReadTabContainerView: View {
    @ObservedObject var bibleViewModel: BibleViewModel
    @ObservedObject var favoritesViewModel: FavoritesViewModel
    @ObservedObject var searchViewModel: SearchViewModel
    @StateObject private var journalViewModel = JournalViewModel()
    @ObservedObject private var themeManager = ThemeManager.shared
    
    @State private var selectedSegment: ReadSegment = .reader
    @State private var headerExpanded: Bool = true
    @State private var showSettings = false
    @State private var showVoiceSelection = false
    @State private var showChapterPicker = false
    @State private var showJournalStats = false
    @State private var showJournalExport = false
    @State private var showJournalReminders = false
    @State private var showJournalNewEntry = false
    @State private var isReadingMode: Bool = false
    @State private var pendingNavigation: VerseNavigation? = nil
    @Namespace private var segmentAnimation
    
    /// Represents a pending navigation request from Saved or Search
    struct VerseNavigation {
        let reference: String
        let bookId: String?
        let chapter: Int?
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background
            themeManager.backgroundColor
                .ignoresSafeArea()
            
            // Content based on selection
            VStack(spacing: 0) {
                // Header spacer - reduced in reading mode
                Color.clear.frame(height: isReadingMode ? 0 : (headerExpanded ? 52 : 0))
                
                Group {
                    switch selectedSegment {
                    case .reader:
                        ReaderView(
                            viewModel: bibleViewModel,
                            favoritesViewModel: favoritesViewModel,
                            onScroll: handleScrollIfNeeded
                        )
                        .transition(.opacity)
                        
                    case .saved:
                        EmbeddedSavedView(
                            viewModel: favoritesViewModel,
                            bibleViewModel: bibleViewModel,
                            themeManager: themeManager,
                            onNavigateToVerse: { reference in
                                navigateToVerseFromReference(reference)
                            }
                        )
                        .transition(.opacity)
                        
                    case .search:
                        EmbeddedSearchView(
                            viewModel: searchViewModel,
                            bibleViewModel: bibleViewModel,
                            themeManager: themeManager,
                            onNavigateToVerse: { reference in
                                navigateToVerseFromSearchResult(reference)
                            }
                        )
                        .transition(.opacity)
                        
                    case .journal:
                        JournalView(
                            viewModel: journalViewModel,
                            favoritesViewModel: favoritesViewModel
                        )
                        .transition(.opacity)
                    }
                }
            }
            
            // Floating header or reading mode button
            if isReadingMode {
                readingModeOverlay
            } else {
                floatingHeader
            }
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                ReaderSettingsSheet()
            }
        }
        .sheet(isPresented: $showVoiceSelection) {
            VoiceSelectionSheet { voiceType in
                startAudioPlayback(with: voiceType)
            }
        }
        .sheet(isPresented: $showChapterPicker) {
            BookPicker(viewModel: bibleViewModel, autoExpandCurrentBook: true)
        }
        .sheet(isPresented: $showJournalStats) {
            JournalStatsView(viewModel: journalViewModel)
        }
        .sheet(isPresented: $showJournalExport) {
            JournalExportSheet(viewModel: journalViewModel)
        }
        .sheet(isPresented: $showJournalReminders) {
            JournalReminderSheet()
        }
        .sheet(isPresented: $journalViewModel.showingPrompts) {
            PromptBrowserView(viewModel: journalViewModel, showingNewEntry: $showJournalNewEntry)
        }
        .sheet(isPresented: $showJournalNewEntry) {
            JournalEntryEditorView(
                viewModel: journalViewModel,
                favoritesViewModel: favoritesViewModel,
                isPresented: $showJournalNewEntry
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: .selectReadSegment)) { notification in
            if let segmentName = notification.userInfo?["segment"] as? String {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    switch segmentName {
                    case "reader": selectedSegment = .reader
                    case "saved": selectedSegment = .saved
                    case "search": selectedSegment = .search
                    case "journal": selectedSegment = .journal
                    default: break
                    }
                }
            }
        }
    }
    
    // MARK: - Floating Header
    
    private var floatingHeader: some View {
        HStack(spacing: 8) {
            // Left side - expandable content
            if headerExpanded {
                // Segment Toggle
                segmentToggle
                    .transition(.scale.combined(with: .opacity))
                
                // Context-specific info based on segment (minimal - chapter info moved to reader)
                switch selectedSegment {
                case .reader:
                    // Chapter info now displayed in reader header
                    EmptyView()
                    
                case .saved:
                    Spacer()
                    
                    // Saved count badge
                    savedCountBadge
                        .transition(.scale.combined(with: .opacity))
                    
                case .search:
                    Spacer()
                    
                    // Recent searches preview or results count
                    recentSearchesBadge
                        .transition(.scale.combined(with: .opacity))
                    
                case .journal:
                    Spacer()
                    
                    // Journal entries count
                    journalCountBadge
                        .transition(.scale.combined(with: .opacity))
                }
            }
            
            if !headerExpanded {
                Spacer()
                
                // Compact toggle when header collapsed
                segmentToggle
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Group {
                if headerExpanded {
                    themeManager.cardBackgroundColor
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: themeManager.hubShadowColor, radius: 6, y: 3)
                }
            }
        )
        .padding(.horizontal, headerExpanded ? 12 : 0)
        .padding(.top, 6)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: headerExpanded)
    }
    
    private var savedCountBadge: some View {
        let totalCount = favoritesViewModel.favorites.count + favoritesViewModel.highlights.count + favoritesViewModel.notes.count
        return Text("\(totalCount) saved")
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(themeManager.secondaryTextColor)
    }
    
    @ViewBuilder
    private var recentSearchesBadge: some View {
        if searchViewModel.hasSearched && !searchViewModel.searchResults.isEmpty {
            // Show results count when there are search results
            HStack(spacing: 4) {
                Text("\(searchViewModel.searchResults.count)")
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.accentColor)
                Text("found")
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            .font(.system(size: 12, weight: .medium))
        } else if !searchViewModel.recentSearches.isEmpty {
            // Show recent searches preview
            let preview = searchViewModel.recentSearches.prefix(2).joined(separator: ", ")
            Text(preview)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(themeManager.secondaryTextColor)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: 120)
        } else {
            // Default
            Text("Find verses")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(themeManager.secondaryTextColor)
        }
    }
    
    private var journalCountBadge: some View {
        let count = journalViewModel.entries.count
        return Text("\(count) \(count == 1 ? "entry" : "entries")")
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(themeManager.secondaryTextColor)
    }
    
    private var segmentToggle: some View {
        HStack(spacing: 0) {
            ForEach(ReadSegment.allCases) { segment in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        selectedSegment = segment
                    }
                    HapticManager.shared.lightImpact()
                } label: {
                    Image(systemName: segment.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(selectedSegment == segment ? .white : themeManager.secondaryTextColor)
                        .frame(width: 40, height: 36)
                        .background {
                            if selectedSegment == segment {
                                Capsule()
                                    .fill(segment.color(for: themeManager))
                                    .matchedGeometryEffect(id: "segmentPill", in: segmentAnimation)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
            
            // Integrated menu button in the toggle
            Menu {
                switch selectedSegment {
                case .reader:
                    Button {
                        showVoiceSelection = true
                    } label: {
                        Label("Listen", systemImage: "headphones")
                    }
                    .disabled(bibleViewModel.currentChapter == nil)
                    
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isReadingMode = true
                        }
                        HapticManager.shared.mediumImpact()
                    } label: {
                        Label("Reading Mode", systemImage: "eye")
                    }
                    
                    Divider()
                    
                    Button {
                        showSettings = true
                    } label: {
                        Label("Reading Settings", systemImage: "textformat.size")
                    }
                    
                case .saved:
                    // Saved menu options
                    Button(role: .destructive) {
                        clearAllSavedContent()
                    } label: {
                        Label("Clear All", systemImage: "trash")
                    }
                    .disabled(favoritesViewModel.favorites.isEmpty && favoritesViewModel.highlights.isEmpty && favoritesViewModel.notes.isEmpty)
                    
                case .search:
                    // Search menu options
                    if !searchViewModel.recentSearches.isEmpty {
                        Button {
                            searchViewModel.clearRecentSearches()
                        } label: {
                            Label("Clear Recent Searches", systemImage: "clock.arrow.circlepath")
                        }
                    }
                    
                    Button {
                        searchViewModel.clearSearch()
                    } label: {
                        Label("Clear Search", systemImage: "xmark.circle")
                    }
                    .disabled(searchViewModel.searchQuery.isEmpty && !searchViewModel.hasSearched)
                    
                case .journal:
                    // Journal menu options
                    Button {
                        journalViewModel.showingPrompts = true
                    } label: {
                        Label("Browse Prompts", systemImage: "lightbulb")
                    }
                    
                    Button {
                        showJournalStats = true
                    } label: {
                        Label("Statistics", systemImage: "chart.bar.xaxis")
                    }
                    
                    Divider()
                    
                    Button {
                        journalViewModel.goToToday()
                    } label: {
                        Label("Go to Today", systemImage: "calendar")
                    }
                    
                    if journalViewModel.hasActiveFilters {
                        Button {
                            journalViewModel.clearFilters()
                        } label: {
                            Label("Clear Filters", systemImage: "xmark.circle")
                        }
                    }
                    
                    Divider()
                    
                    Button {
                        showJournalReminders = true
                    } label: {
                        Label("Reminders", systemImage: "bell")
                    }
                    
                    Button {
                        showJournalExport = true
                    } label: {
                        Label("Export Journal", systemImage: "square.and.arrow.up")
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeManager.secondaryTextColor)
                    .frame(width: 40, height: 36)
            }
        }
        .padding(3)
        .background(themeManager.backgroundColor.opacity(0.8))
        .clipShape(Capsule())
    }
    
    // MARK: - Reading Mode Overlay
    
    private var readingModeOverlay: some View {
        VStack {
            HStack {
                Spacer()
                
                // Minimal floating menu
                Menu {
                    // Current chapter info
                    if let book = bibleViewModel.selectedBook {
                        Text("\(book.displayName) \(bibleViewModel.currentChapterNumber)")
                    }
                    
                    Divider()
                    
                    Button {
                        showChapterPicker = true
                    } label: {
                        Label("Go to Chapter", systemImage: "book")
                    }
                    
                    Button {
                        showVoiceSelection = true
                    } label: {
                        Label("Listen", systemImage: "headphones")
                    }
                    .disabled(bibleViewModel.currentChapter == nil)
                    
                    Button {
                        showSettings = true
                    } label: {
                        Label("Reading Settings", systemImage: "textformat.size")
                    }
                    
                    Divider()
                    
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isReadingMode = false
                        }
                        HapticManager.shared.lightImpact()
                    } label: {
                        Label("Exit Reading Mode", systemImage: "arrow.down.left.and.arrow.up.right")
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(themeManager.cardBackgroundColor.opacity(0.9))
                            .frame(width: 44, height: 44)
                            .shadow(color: themeManager.hubShadowColor, radius: 8, y: 2)
                        
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                }
                .padding(.trailing, 16)
                .padding(.top, 8)
            }
            
            Spacer()
        }
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }
    
    // MARK: - Scroll Handler
    
    private func handleScrollIfNeeded(_ direction: ScrollDirection) {
        guard !isReadingMode else { return }
        handleScroll(direction)
    }
    
    private func handleScroll(_ direction: ScrollDirection) {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            headerExpanded = (direction == .up)
        }
    }
    
    private func startAudioPlayback(with voiceType: VoiceType) {
        guard let chapter = bibleViewModel.currentChapter else { return }
        
        let preferredType: PreferredVoiceType = voiceType == .premium ? .premium : .builtin
        let audioService = AudioService.shared
        
        audioService.play(
            verses: chapter.verses,
            reference: chapter.reference,
            language: audioService.languageCode(for: bibleViewModel.selectedTranslation?.language ?? "eng"),
            translationId: bibleViewModel.selectedTranslation?.id ?? "",
            bookId: bibleViewModel.selectedBook?.id ?? "",
            chapter: bibleViewModel.currentChapterNumber,
            voiceType: preferredType
        ) { _ in }
    }
    
    // MARK: - Navigation Helpers
    
    /// Navigate to a verse from a reference string (from Saved)
    private func navigateToVerseFromReference(_ reference: String) {
        bibleViewModel.navigateToReference(reference)
        
        // Switch to reader segment with animation
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            selectedSegment = .reader
        }
        HapticManager.shared.lightImpact()
    }
    
    /// Navigate to a verse from search result
    private func navigateToVerseFromSearchResult(_ reference: VerseReference) {
        Task {
            // Find the book and navigate
            if let book = bibleViewModel.books.first(where: { $0.id == reference.bookId }) {
                await bibleViewModel.selectBook(book, chapter: reference.chapter)
            }
            
            // Switch to reader segment with animation
            await MainActor.run {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    selectedSegment = .reader
                }
                HapticManager.shared.lightImpact()
            }
        }
    }
    
    /// Clear all saved content
    private func clearAllSavedContent() {
        favoritesViewModel.favorites.forEach { favoritesViewModel.removeFavorite($0) }
        favoritesViewModel.highlights.forEach { favoritesViewModel.removeHighlight($0) }
        favoritesViewModel.notes.forEach { favoritesViewModel.removeNote($0) }
        HapticManager.shared.success()
    }
}

// MARK: - Scroll Direction

enum ScrollDirection {
    case up, down, none
}

// MARK: - Notification Names

extension Notification.Name {
    static let showBookPicker = Notification.Name("showBookPicker")
    static let showTranslationPicker = Notification.Name("showTranslationPicker")
    static let selectReadSegment = Notification.Name("selectReadSegment")
}

// MARK: - Read Segment Enum

enum ReadSegment: String, CaseIterable, Identifiable {
    case reader
    case saved
    case search
    case journal
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .reader: return "Read"
        case .saved: return "Saved"
        case .search: return "Search"
        case .journal: return "Journal"
        }
    }
    
    var icon: String {
        switch self {
        case .reader: return "book.fill"
        case .saved: return "heart.fill"
        case .search: return "magnifyingglass"
        case .journal: return "pencil.line"
        }
    }
    
    func color(for themeManager: ThemeManager) -> Color {
        switch self {
        case .reader: return themeManager.accentColor
        case .saved: return Color.red
        case .search: return Color.blue
        case .journal: return themeManager.hubGlowColor
        }
    }
}

// MARK: - Embedded Saved View

/// Saved content view embedded within ReadTabContainerView (no NavigationStack)
struct EmbeddedSavedView: View {
    @ObservedObject var viewModel: FavoritesViewModel
    @ObservedObject var bibleViewModel: BibleViewModel
    @ObservedObject var themeManager: ThemeManager
    
    let onNavigateToVerse: (String) -> Void
    
    @State private var selectedTab: SavedContentTab = .favorites
    @State private var searchText = ""
    
    private var totalCount: Int {
        viewModel.favorites.count + viewModel.highlights.count + viewModel.notes.count
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Top padding to match reader
                Color.clear.frame(height: 16)
                
                // Section Header
                SectionHeaderView(
                    title: "Saved",
                    subtitle: totalCount > 0 ? "\(totalCount) items" : "Your collection",
                    icon: "heart.fill",
                    iconColor: .red,
                    themeManager: themeManager
                )
                .padding(.bottom, 20)
                
                // Custom segmented control
                CustomSegmentedControl(
                    selection: $selectedTab,
                    themeManager: themeManager
                )
                .padding(.horizontal)
                
                // Search bar
                SearchBar(
                    text: $searchText,
                    placeholder: "Search \(selectedTab.rawValue.lowercased())...",
                    themeManager: themeManager
                )
                .padding(.horizontal)
                .padding(.vertical, 12)
                
                // Content based on selected tab
                switch selectedTab {
                case .favorites:
                    if filteredFavorites.isEmpty {
                        EmptyStateView(
                            icon: "heart",
                            title: "No Favorites Yet",
                            message: "Tap on any verse to save it to your favorites",
                            actionTitle: nil,
                            action: nil,
                            themeManager: themeManager
                        )
                        .frame(minHeight: 300)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredFavorites) { favorite in
                                FavoriteCard(
                                    favorite: favorite,
                                    themeManager: themeManager,
                                    onTap: { onNavigateToVerse(favorite.reference) },
                                    onDelete: { viewModel.removeFavorite(favorite) }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                case .highlights:
                    if filteredHighlights.isEmpty {
                        EmptyStateView(
                            icon: "highlighter",
                            title: "No Highlights Yet",
                            message: "Highlight verses to mark important passages",
                            actionTitle: nil,
                            action: nil,
                            themeManager: themeManager
                        )
                        .frame(minHeight: 300)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredHighlights) { highlight in
                                HighlightCard(
                                    highlight: highlight,
                                    themeManager: themeManager,
                                    onTap: { onNavigateToVerse(highlight.reference) },
                                    onDelete: { viewModel.removeHighlight(highlight) }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                case .notes:
                    if filteredNotes.isEmpty {
                        EmptyStateView(
                            icon: "note.text",
                            title: "No Notes Yet",
                            message: "Add personal notes to verses for deeper study",
                            actionTitle: nil,
                            action: nil,
                            themeManager: themeManager
                        )
                        .frame(minHeight: 300)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredNotes) { note in
                                NoteCard(
                                    note: note,
                                    themeManager: themeManager,
                                    onTap: { onNavigateToVerse(note.reference) },
                                    onEdit: { },
                                    onDelete: { viewModel.removeNote(note) }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Bottom padding
                Color.clear.frame(height: 100)
            }
        }
    }
    
    // MARK: - Filtered Content
    
    private var filteredFavorites: [Favorite] {
        if searchText.isEmpty {
            return viewModel.favorites
        }
        return viewModel.favorites.filter { favorite in
            favorite.verseText.localizedCaseInsensitiveContains(searchText) ||
            favorite.reference.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var filteredHighlights: [Highlight] {
        if searchText.isEmpty {
            return viewModel.highlights
        }
        return viewModel.highlights.filter { highlight in
            highlight.verseText.localizedCaseInsensitiveContains(searchText) ||
            highlight.reference.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var filteredNotes: [Note] {
        if searchText.isEmpty {
            return viewModel.notes
        }
        return viewModel.notes.filter { note in
            note.noteText.localizedCaseInsensitiveContains(searchText) ||
            note.verseText.localizedCaseInsensitiveContains(searchText) ||
            note.reference.localizedCaseInsensitiveContains(searchText)
        }
    }
}

// MARK: - Embedded Search View

/// Search view embedded within ReadTabContainerView (no NavigationStack)
struct EmbeddedSearchView: View {
    @ObservedObject var viewModel: SearchViewModel
    @ObservedObject var bibleViewModel: BibleViewModel
    @ObservedObject var themeManager: ThemeManager
    
    let onNavigateToVerse: (VerseReference) -> Void
    
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Top padding to match reader
                Color.clear.frame(height: 16)
                
                // Section Header
                SectionHeaderView(
                    title: "Search",
                    subtitle: viewModel.hasSearched ? "\(viewModel.searchResults.count) results in downloaded chapters" : "Find in downloaded chapters",
                    icon: "magnifyingglass",
                    iconColor: themeManager.accentColor,
                    themeManager: themeManager
                )
                .padding(.bottom, 20)
                
                // Search input
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    TextField("Search verses or enter reference", text: $viewModel.searchQuery)
                        .foregroundColor(themeManager.textColor)
                        .focused($isSearchFocused)
                        .tint(themeManager.accentColor)
                        .submitLabel(.search)
                        .onSubmit {
                            Task {
                                await viewModel.search()
                            }
                        }
                    
                    if !viewModel.searchQuery.isEmpty {
                        Button {
                            viewModel.searchQuery = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(themeManager.cardBackgroundColor)
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Search scope picker - themed
                if !viewModel.searchQuery.isEmpty || viewModel.hasSearched {
                    SearchScopePicker(
                        selection: $viewModel.searchScope,
                        themeManager: themeManager
                    )
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .onChange(of: viewModel.searchScope) { _, _ in
                        // Re-run search when scope changes
                        if viewModel.hasSearched && !viewModel.searchQuery.isEmpty {
                            Task {
                                await viewModel.search()
                            }
                        }
                    }
                }
                
                // Content
                if viewModel.isSearching {
                    LoadingView("Searching...")
                        .frame(minHeight: 300)
                } else if viewModel.hasSearched {
                    embeddedSearchResultsContent
                } else {
                    embeddedSearchSuggestionsContent
                }
                
                // Bottom padding
                Color.clear.frame(height: 100)
            }
        }
    }
    
    @ViewBuilder
    private var embeddedSearchResultsContent: some View {
        if viewModel.searchResults.isEmpty {
            EmptyStateView(
                icon: "magnifyingglass",
                title: "No Results",
                message: "Try a different search term or check spelling",
                actionTitle: "Clear Search",
                action: { viewModel.clearSearch() }
            )
            .frame(minHeight: 300)
        } else {
            LazyVStack(spacing: 0) {
                // Results
                ForEach(viewModel.searchResults) { result in
                    Button {
                        onNavigateToVerse(result.reference)
                    } label: {
                        SearchResultRow(result: result, themeManager: themeManager)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private var embeddedSearchSuggestionsContent: some View {
        LazyVStack(spacing: 0) {
            // Recent searches
            if !viewModel.recentSearches.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("Recent")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(themeManager.secondaryTextColor)
                        
                        Spacer()
                        
                        Button("Clear") {
                            viewModel.clearRecentSearches()
                        }
                        .font(.caption)
                        .foregroundColor(themeManager.accentColor)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                    
                    ForEach(viewModel.recentSearches, id: \.self) { query in
                        Button {
                            viewModel.searchQuery = query
                            Task {
                                await viewModel.search()
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "clock")
                                    .foregroundColor(themeManager.secondaryTextColor)
                                
                                Text(query)
                                    .foregroundColor(themeManager.textColor)
                                
                                Spacer()
                                
                                Image(systemName: "arrow.up.left")
                                    .font(.caption)
                                    .foregroundColor(themeManager.secondaryTextColor)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            // Popular verses
            VStack(alignment: .leading, spacing: 0) {
                Text("Popular Verses")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 12)
                
                ForEach(viewModel.popularVerses) { verse in
                    Button {
                        viewModel.searchQuery = verse.shortReference
                        Task {
                            await viewModel.search()
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(verse.shortReference)
                                .font(.headline)
                                .foregroundColor(themeManager.accentColor)
                            
                            Text(verse.text)
                                .font(.subheadline)
                                .foregroundColor(themeManager.secondaryTextColor)
                                .lineLimit(2)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Search tips
            VStack(alignment: .leading, spacing: 12) {
                Text("Search Tips")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .padding(.top, 24)
                
                SearchTipRow(
                    example: "John 3:16",
                    description: "Jump to a specific verse",
                    themeManager: themeManager
                )
                
                SearchTipRow(
                    example: "Romans 8:28-30",
                    description: "Find a range of verses",
                    themeManager: themeManager
                )
                
                SearchTipRow(
                    example: "love",
                    description: "Search for keywords",
                    themeManager: themeManager
                )
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Section Header View

/// Beautiful section header for Saved, Search, Journal tabs
struct SectionHeaderView: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    @ObservedObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 56, height: 56)
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            
            // Title
            Text(title)
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundColor(themeManager.textColor)
            
            // Subtitle
            Text(subtitle)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(themeManager.secondaryTextColor)
            
            // Decorative divider
            HStack(spacing: 12) {
                Rectangle()
                    .fill(themeManager.dividerColor)
                    .frame(height: 1)
                
                Circle()
                    .fill(iconColor.opacity(0.5))
                    .frame(width: 6, height: 6)
                
                Rectangle()
                    .fill(themeManager.dividerColor)
                    .frame(height: 1)
            }
            .padding(.horizontal, 60)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

// MARK: - Search Scope Picker

/// Themed search scope picker that follows the app's design
struct SearchScopePicker: View {
    @Binding var selection: SearchViewModel.SearchScope
    @ObservedObject var themeManager: ThemeManager
    @Namespace private var animation
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(SearchViewModel.SearchScope.allCases, id: \.self) { scope in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selection = scope
                        HapticManager.shared.lightImpact()
                    }
                } label: {
                    VStack(spacing: 4) {
                        // Icon for scope
                        Image(systemName: scope.icon)
                            .font(.system(size: 14, weight: .medium))
                        
                        Text(scope.shortName)
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(selection == scope ? .white : themeManager.secondaryTextColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background {
                        if selection == scope {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(themeManager.accentColor)
                                .matchedGeometryEffect(id: "scopePill", in: animation)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(14)
    }
}

// MARK: - SearchScope Extension

extension SearchViewModel.SearchScope {
    var icon: String {
        switch self {
        case .currentTranslation: return "book.closed"
        case .oldTestament: return "scroll"
        case .newTestament: return "book"
        }
    }
    
    var shortName: String {
        switch self {
        case .currentTranslation: return "Current"
        case .oldTestament: return "Old"
        case .newTestament: return "New"
        }
    }
}

#Preview {
    ReadTabContainerView(
        bibleViewModel: BibleViewModel(),
        favoritesViewModel: FavoritesViewModel(),
        searchViewModel: SearchViewModel()
    )
}
