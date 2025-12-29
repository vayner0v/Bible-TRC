//
//  ReadTabContainerView.swift
//  Bible v1
//
//  Container view for Read tab with collapsible header
//

import SwiftUI

/// Container that holds both ReaderView and JournalView with a collapsible header
struct ReadTabContainerView: View {
    @ObservedObject var bibleViewModel: BibleViewModel
    @ObservedObject var favoritesViewModel: FavoritesViewModel
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
    @Namespace private var segmentAnimation
    
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
    }
    
    // MARK: - Floating Header
    
    private var floatingHeader: some View {
        HStack(spacing: 8) {
            // Left side - expandable content
            if headerExpanded {
                // Segment Toggle
                segmentToggle
                    .transition(.scale.combined(with: .opacity))
                
                if selectedSegment == .reader {
                    Spacer()
                    
                    // Book & Chapter
                    bookChapterButton
                        .transition(.scale.combined(with: .opacity))
                    
                    Spacer()
                    
                    // Translation
                    translationBadge
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
                if selectedSegment == .reader {
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
                } else {
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
    
    private var bookChapterButton: some View {
        Button {
            showChapterPicker = true
            HapticManager.shared.lightImpact()
        } label: {
            HStack(spacing: 6) {
                Text(bibleViewModel.selectedBook?.shortName ?? "Book")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(themeManager.textColor)
                    .lineLimit(1)
                
                Text("\(bibleViewModel.currentChapterNumber)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(themeManager.accentColor)
                    .clipShape(Circle())
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(themeManager.secondaryTextColor)
            }
        }
        .buttonStyle(.plain)
    }
    
    private var translationBadge: some View {
        Button {
            NotificationCenter.default.post(name: .showTranslationPicker, object: nil)
        } label: {
            Text(bibleViewModel.selectedTranslation?.id.uppercased() ?? "KJV")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(themeManager.accentColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(themeManager.accentColor.opacity(0.12))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
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
}

// MARK: - Scroll Direction

enum ScrollDirection {
    case up, down, none
}

// MARK: - Notification Names

extension Notification.Name {
    static let showBookPicker = Notification.Name("showBookPicker")
    static let showTranslationPicker = Notification.Name("showTranslationPicker")
}

// MARK: - Read Segment Enum

enum ReadSegment: String, CaseIterable, Identifiable {
    case reader
    case journal
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .reader: return "Read"
        case .journal: return "Journal"
        }
    }
    
    var icon: String {
        switch self {
        case .reader: return "book.fill"
        case .journal: return "pencil.line"
        }
    }
    
    func color(for themeManager: ThemeManager) -> Color {
        switch self {
        case .reader: return themeManager.accentColor
        case .journal: return themeManager.hubGlowColor
        }
    }
}

#Preview {
    ReadTabContainerView(
        bibleViewModel: BibleViewModel(),
        favoritesViewModel: FavoritesViewModel()
    )
}
