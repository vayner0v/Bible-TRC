//
//  ReaderView.swift
//  Bible v1
//
//  Advanced Bible Reader App
//

import SwiftUI

/// Main Bible reading view
struct ReaderView: View {
    @ObservedObject var viewModel: BibleViewModel
    @ObservedObject var favoritesViewModel: FavoritesViewModel
    @ObservedObject var audioService = AudioService.shared
    @ObservedObject var themeManager = ThemeManager.shared
    @ObservedObject private var settings = SettingsStore.shared
    
    var onScroll: ((ScrollDirection) -> Void)?
    
    @State private var showTranslationPicker = false
    @State private var showBookPicker = false
    @State private var showChapterPicker = false
    @State private var selectedVerse: Verse?
    @State private var selectedReference: VerseReference?
    @State private var showNoteEditor = false
    @State private var noteText = ""
    @State private var showAudioPlayer = false
    @State private var showVoiceSelection = false
    @State private var showListeningMode = false
    @State private var scrollProxy: ScrollViewProxy?
    @State private var lastScrollY: CGFloat = 0
    @State private var scrollAccumulator: CGFloat = 0
    
    // TRC Insight state
    @State private var insightState: InsightState = .idle
    @State private var insightVerseReference: VerseReference?
    @State private var insightStreamingContent: String = ""
    @State private var currentInsightRequestId: UUID? // Track current request to prevent stale updates
    @StateObject private var insightService = VerseInsightService.shared
    
    var body: some View {
        ZStack {
            // Background
            themeManager.backgroundColor
                .ignoresSafeArea()
            
            // Content
            VStack(spacing: 0) {
                // Verses
                if viewModel.isLoadingChapter {
                    LoadingView("Loading scripture...")
                } else if let chapter = viewModel.currentChapter {
                    versesScrollView(chapter: chapter)
                } else {
                    EmptyStateView(
                        icon: "book.closed",
                        title: "No Chapter Selected",
                        message: "Select a book and chapter to begin reading",
                        actionTitle: "Browse Books",
                        action: { showBookPicker = true }
                    )
                }
            }
            
            // Audio player overlay (mini player when not in listening mode)
            if (showAudioPlayer || audioService.isPlaying) && !audioService.isInListeningMode {
                VStack {
                    Spacer()
                    MiniAudioPlayerView(
                        audioService: audioService,
                        themeManager: themeManager,
                        onExpand: {
                            showListeningMode = true
                            audioService.enterListeningMode()
                        },
                        onClose: { 
                            showAudioPlayer = false
                            audioService.stop()
                        },
                        onVerseSelect: { index in
                            scrollToVerse(index + 1)
                        }
                    )
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showAudioPlayer || audioService.isPlaying)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showBookPicker)) { _ in
            showBookPicker = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .showTranslationPicker)) { _ in
            showTranslationPicker = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .audioChapterCompleted)) { _ in
            handleAudioChapterCompleted()
        }
        .onReceive(NotificationCenter.default.publisher(for: .resumeAudioFromPosition)) { notification in
            if let position = notification.userInfo?["position"] as? AudioPlaybackPosition {
                handleResumeFromPosition(position)
            }
        }
        .sheet(isPresented: $showTranslationPicker) {
            TranslationPicker(viewModel: viewModel)
        }
        .sheet(isPresented: $showBookPicker) {
            BookPicker(viewModel: viewModel)
        }
        .sheet(isPresented: $showChapterPicker) {
            ChapterPickerSheet(viewModel: viewModel)
        }
        .sheet(item: $selectedReference) { reference in
            VerseActionSheet(
                verse: selectedVerse ?? Verse(verse: reference.verse, text: reference.text),
                reference: reference,
                currentHighlight: favoritesViewModel.getHighlight(for: reference),
                isFavorite: favoritesViewModel.isFavorite(reference),
                onAction: { action in
                    handleVerseAction(action, for: reference)
                }
            )
        }
        .sheet(isPresented: $showNoteEditor) {
            NoteEditorSheet(
                reference: selectedReference,
                initialText: noteText,
                onSave: { text in
                    if let ref = selectedReference {
                        favoritesViewModel.addNote(for: ref, text: text)
                    }
                }
            )
        }
        .sheet(isPresented: $showVoiceSelection) {
            VoiceSelectionSheet { voiceType in
                startAudioPlayback(with: voiceType)
            }
        }
        .fullScreenCover(isPresented: $showListeningMode) {
            ListeningModeView(
                audioService: audioService,
                themeManager: themeManager,
                onClose: {
                    showListeningMode = false
                    audioService.exitListeningMode()
                },
                onVerseSelect: { index in
                    scrollToVerse(index + 1)
                }
            )
        }
        .onChange(of: audioService.isInListeningMode) { _, isInListeningMode in
            showListeningMode = isInListeningMode
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
            Button("Retry") {
                Task {
                    await viewModel.loadCurrentChapter()
                }
            }
        } message: {
            Text(viewModel.error?.localizedDescription ?? "An error occurred")
        }
    }
    
    private func startAudioPlayback(with voiceType: VoiceType) {
        guard let chapter = viewModel.currentChapter else { return }
        
        // Convert VoiceType to PreferredVoiceType
        let preferredType: PreferredVoiceType = voiceType == .premium ? .premium : .builtin
        
        showAudioPlayer = true
        audioService.play(
            verses: chapter.verses,
            reference: chapter.reference,
            language: audioService.languageCode(for: viewModel.selectedTranslation?.language ?? "eng"),
            translationId: viewModel.selectedTranslation?.id ?? "",
            bookId: viewModel.selectedBook?.id ?? "",
            chapter: viewModel.currentChapterNumber,
            voiceType: preferredType
        ) { index in
            scrollToVerse(index + 1)
        }
        
        // Show listening mode if enabled
        if audioService.immersiveModeEnabled {
            showListeningMode = true
        }
    }
    
    private func scrollToVerse(_ verseNumber: Int) {
        withAnimation(.easeInOut(duration: 0.3)) {
            scrollProxy?.scrollTo(verseNumber, anchor: .center)
        }
    }
    
    /// Handle audio chapter completion - continue to next chapter if available
    private func handleAudioChapterCompleted() {
        guard viewModel.hasNextChapter else {
            // No next chapter available, stop playback
            audioService.stop()
            return
        }
        
        // Navigate to next chapter and restart audio
        Task {
            await viewModel.nextChapter()
            
            // Wait briefly for the chapter to load, then restart audio
            if let chapter = viewModel.currentChapter {
                let preferredType = audioService.preferredVoiceType
                audioService.play(
                    verses: chapter.verses,
                    reference: chapter.reference,
                    language: audioService.languageCode(for: viewModel.selectedTranslation?.language ?? "eng"),
                    translationId: viewModel.selectedTranslation?.id ?? "",
                    bookId: viewModel.selectedBook?.id ?? "",
                    chapter: viewModel.currentChapterNumber,
                    voiceType: preferredType
                ) { index in
                    scrollToVerse(index + 1)
                }
            }
        }
    }
    
    /// Handle resuming audio from a saved position
    private func handleResumeFromPosition(_ position: AudioPlaybackPosition) {
        Task {
            // Navigate to the saved position first
            await viewModel.navigateTo(
                translationId: position.translationId,
                bookId: position.bookId,
                chapter: position.chapter
            )
            
            // Wait for chapter to load
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s
            
            // Start playback from the saved verse
            if let chapter = viewModel.currentChapter {
                showAudioPlayer = true
                audioService.play(
                    verses: chapter.verses,
                    reference: chapter.reference,
                    startingAt: position.verseIndex,
                    language: audioService.languageCode(for: viewModel.selectedTranslation?.language ?? "eng"),
                    translationId: position.translationId,
                    bookId: position.bookId,
                    bookName: position.bookName,
                    chapter: position.chapter,
                    voiceType: position.voiceType
                ) { index in
                    scrollToVerse(index + 1)
                }
                
                // Scroll to the verse
                scrollToVerse(position.verseIndex + 1)
                
                // Show listening mode if enabled
                if audioService.immersiveModeEnabled {
                    showListeningMode = true
                }
            }
        }
    }
    
    @ViewBuilder
    private func versesScrollView(chapter: Chapter) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                // Scroll offset detector
                GeometryReader { geo in
                    Color.clear.preference(
                        key: ScrollOffsetPreferenceKey.self,
                        value: geo.frame(in: .named("readerScroll")).minY
                    )
                }
                .frame(height: 0)
                
                LazyVStack(spacing: 0) {
                    // Top padding for content
                    Color.clear.frame(height: 16)
                    
                    // Chapter Header - Book name, chapter number, translation
                    ChapterHeaderView(
                        bookName: viewModel.selectedBook?.displayName ?? "Book",
                        chapterNumber: viewModel.currentChapterNumber,
                        translationId: viewModel.selectedTranslation?.id ?? "KJV",
                        themeManager: themeManager,
                        onBookTap: { showBookPicker = true },
                        onTranslationTap: {
                            NotificationCenter.default.post(name: .showTranslationPicker, object: nil)
                        }
                    )
                    .padding(.bottom, 24)
                    
                    // Render based on paragraph mode setting
                    if settings.paragraphMode {
                        // Paragraph mode: display all verses as flowing text
                        paragraphModeContent(chapter: chapter)
                    } else {
                        // Verse-by-verse mode (default)
                        verseModeContent(chapter: chapter)
                    }
                    
                    // Bottom padding for audio player
                    Color.clear
                        .frame(height: showAudioPlayer || audioService.isPlaying ? 180 : 100)
                }
            }
            .coordinateSpace(name: "readerScroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { newY in
                detectScrollDirection(newY)
            }
            .chapterSwipeNavigation(viewModel: viewModel)
            .onAppear {
                scrollProxy = proxy
            }
        }
    }
    
    /// Verse-by-verse rendering (default mode)
    @ViewBuilder
    private func verseModeContent(chapter: Chapter) -> some View {
        // Verses - filter out any with empty text (safeguard for cached data)
        ForEach(chapter.verses.filter { !$0.text.isEmpty }) { verse in
            let reference = viewModel.verseReference(for: verse)
            let highlight = reference.flatMap { favoritesViewModel.getHighlight(for: $0) }
            let isFavorite = reference.map { favoritesViewModel.isFavorite($0) } ?? false
            let hasNote = reference.flatMap { favoritesViewModel.getNote(for: $0) } != nil
            
            TappableVerseRow(
                verse: verse,
                isRTL: viewModel.selectedTranslation?.isRTL ?? false,
                highlightColor: highlight?.color.color,
                hasNote: hasNote,
                isFavorite: isFavorite,
                isPlaying: audioService.isPlaying && audioService.currentVerseIndex == verse.verse - 1,
                themeManager: themeManager,
                verseFont: settings.verseFont,
                verseNumberFont: settings.verseNumberFont,
                lineSpacing: settings.readerLineSpacing,
                showVerseNumbers: settings.showVerseNumbers,
                textAlignment: settings.readerTextAlignment
            ) {
                // Tap action - show verse options only if reference is valid
                if let validReference = reference {
                    selectedVerse = verse
                    selectedReference = validReference
                }
            }
            // Use a composite ID to force re-render when settings change
            .id("\(verse.verse)-\(settings.effectiveReaderFontSize)-\(settings.readerLineSpacing)-\(settings.paragraphMode)")
            
            // Show TRC Insight overlay below this verse if it's the active one
            if let insightRef = insightVerseReference,
               let verseRef = reference,
               insightRef.verse == verseRef.verse && insightRef.chapter == verseRef.chapter,
               insightState.isActive {
                TRCInsightOverlay(
                    reference: insightRef,
                    state: insightState,
                    onDismiss: dismissInsight,
                    onSave: saveInsight,
                    onShare: shareInsightContent
                )
                .id("insight-\(insightRef.chapter)-\(insightRef.verse)")
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.95)).combined(with: .move(edge: .top)),
                    removal: .opacity.combined(with: .scale(scale: 0.95))
                ))
            }
        }
    }
    
    /// Paragraph mode rendering - verses flow as continuous text
    @ViewBuilder
    private func paragraphModeContent(chapter: Chapter) -> some View {
        let verses = chapter.verses.filter { !$0.text.isEmpty }
        let isRTL = viewModel.selectedTranslation?.isRTL ?? false
        let alignment: HorizontalAlignment = {
            if isRTL { return .trailing }
            switch settings.readerTextAlignment {
            case .center: return .center
            case .trailing: return .trailing
            default: return .leading
            }
        }()
        let textAlignment: SwiftUI.TextAlignment = {
            if isRTL { return .trailing }
            switch settings.readerTextAlignment {
            case .center: return .center
            case .trailing: return .trailing
            default: return .leading
            }
        }()
        
        VStack(alignment: alignment, spacing: 0) {
            // Build attributed text with inline verse numbers
            ParagraphTextView(
                verses: verses,
                isRTL: isRTL,
                verseFont: settings.verseFont,
                verseNumberFont: settings.verseNumberFont,
                lineSpacing: settings.readerLineSpacing,
                showVerseNumbers: settings.showVerseNumbers,
                textAlignment: textAlignment,
                themeManager: themeManager,
                currentPlayingIndex: audioService.isPlaying ? audioService.currentVerseIndex : nil,
                onVerseTap: { verse in
                    if let reference = viewModel.verseReference(for: verse) {
                        selectedVerse = verse
                        selectedReference = reference
                    }
                }
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .id("paragraph-\(settings.effectiveReaderFontSize)-\(settings.readerLineSpacing)-\(settings.paragraphMode)")
    }
    
    private func detectScrollDirection(_ newY: CGFloat) {
        let delta = newY - lastScrollY
        scrollAccumulator += delta
        
        // Only trigger after accumulating enough scroll
        if scrollAccumulator > 30 {
            onScroll?(.up)
            scrollAccumulator = 0
        } else if scrollAccumulator < -30 {
            onScroll?(.down)
            scrollAccumulator = 0
        }
        
        lastScrollY = newY
    }
    
    private func handleVerseAction(_ action: VerseAction, for reference: VerseReference) {
        switch action {
        case .favorite:
            favoritesViewModel.toggleFavorite(reference)
            HapticManager.shared.success()
            
        case .highlight(let color):
            favoritesViewModel.setHighlight(for: reference, color: color)
            HapticManager.shared.lightImpact()
            
        case .removeHighlight:
            if let highlight = favoritesViewModel.getHighlight(for: reference) {
                favoritesViewModel.removeHighlight(highlight)
            }
            
        case .addNote:
            let existingNote = favoritesViewModel.getNote(for: reference)
            noteText = existingNote?.noteText ?? ""
            selectedReference = reference
            showNoteEditor = true
            
        case .copy:
            UIPasteboard.general.string = reference.shareableText
            HapticManager.shared.success()
            
        case .share:
            let activityVC = UIActivityViewController(
                activityItems: [reference.shareableText],
                applicationActivities: nil
            )
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootVC = window.rootViewController {
                rootVC.present(activityVC, animated: true)
            }
            
        case .trcInsight(let analysisType):
            // Trigger TRC Insight analysis
            startInsightAnalysis(for: reference, type: analysisType)
        }
    }
    
    // MARK: - TRC Insight Methods
    
    private func startInsightAnalysis(for reference: VerseReference, type: InsightAnalysisType) {
        // Cancel any existing AI request first
        TRCAIService.shared.cancel()
        
        // Generate a new request ID to track this specific request
        let requestId = UUID()
        currentInsightRequestId = requestId
        
        // Reset streaming content for new request
        insightStreamingContent = ""
        
        // Set the new verse reference and thinking state together
        // This ensures the overlay shows for the correct verse immediately
        insightVerseReference = reference
        insightState = .thinking(type)
        
        HapticManager.shared.lightImpact()
        
        // Scroll to show the insight overlay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation {
                scrollProxy?.scrollTo("insight-\(reference.chapter)-\(reference.verse)", anchor: .center)
            }
        }
        
        // Call AI service for verse analysis
        Task {
            await performVerseAnalysis(reference: reference, type: type, requestId: requestId)
        }
    }
    
    private func performVerseAnalysis(reference: VerseReference, type: InsightAnalysisType, requestId: UUID) async {
        let aiService = TRCAIService.shared
        
        // Create a temporary conversation for this analysis
        let conversation = ChatConversation(id: UUID(), currentMode: .study)
        
        // Capture the current request ID for validation
        let expectedRequestId = requestId
        
        aiService.analyzeVerse(
            verseReference: reference,
            analysisType: type,
            conversation: conversation,
            translationId: viewModel.selectedTranslation?.id ?? "BSB",
            onToken: { token in
                Task { @MainActor in
                    // Only update if this is still the current request
                    guard self.currentInsightRequestId == expectedRequestId else { return }
                    self.insightStreamingContent += token
                    self.insightState = .streaming(type, self.insightStreamingContent)
                }
            },
            onComplete: { result in
                Task { @MainActor in
                    // Only update if this is still the current request
                    guard self.currentInsightRequestId == expectedRequestId else {
                        print("TRC Insight: Ignoring stale completion for request \(expectedRequestId)")
                        return
                    }
                    
                    switch result {
                    case .success(let response):
                        // Create the insight with the reference we started with
                        let insight = VerseInsight.from(
                            reference: reference,
                            analysisType: type,
                            content: response.answerMarkdown,
                            citations: response.citations.map { $0.reference }
                        )
                        
                        self.insightState = .complete(insight)
                        HapticManager.shared.success()
                        
                    case .failure(let error):
                        self.insightState = .error(error.localizedDescription)
                        HapticManager.shared.error()
                    }
                }
            }
        )
    }
    
    private func dismissInsight() {
        // Cancel any pending AI request
        TRCAIService.shared.cancel()
        
        // Clear request ID FIRST to prevent any pending callbacks from updating state
        currentInsightRequestId = nil
        
        // Clear all insight state
        insightState = .idle
        insightVerseReference = nil
        insightStreamingContent = ""
    }
    
    private func saveInsight(_ insight: VerseInsight) {
        insightService.saveInsight(insight)
        
        // Capture the request ID at save time
        let savedRequestId = currentInsightRequestId
        
        // Show brief feedback then dismiss only if no new request started
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Only dismiss if this is still the same request (no new insight started)
            if self.currentInsightRequestId == savedRequestId {
                self.dismissInsight()
            }
        }
    }
    
    private func shareInsightContent(_ content: String) {
        let activityVC = UIActivityViewController(
            activityItems: [content],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

/// Paragraph mode view - displays verses as flowing continuous text
struct ParagraphTextView: View {
    let verses: [Verse]
    let isRTL: Bool
    let verseFont: Font
    let verseNumberFont: Font
    let lineSpacing: Double
    let showVerseNumbers: Bool
    let textAlignment: SwiftUI.TextAlignment
    let themeManager: ThemeManager
    let currentPlayingIndex: Int?
    let onVerseTap: (Verse) -> Void
    
    var body: some View {
        // Build the paragraph text with inline verse numbers
        let paragraphText = buildParagraphText()
        
        Text(paragraphText)
            .font(verseFont)
            .foregroundColor(themeManager.textColor)
            .lineSpacing(CGFloat(lineSpacing * 4))
            .multilineTextAlignment(textAlignment)
            .environment(\.layoutDirection, isRTL ? .rightToLeft : .leftToRight)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: frameAlignment)
    }
    
    private var frameAlignment: Alignment {
        switch textAlignment {
        case .center: return .center
        case .trailing: return .trailing
        default: return .leading
        }
    }
    
    private func buildParagraphText() -> AttributedString {
        var result = AttributedString()
        
        for (index, verse) in verses.enumerated() {
            // Add verse number as superscript if enabled
            if showVerseNumbers {
                var verseNumberAttr = AttributedString("\(verse.verse) ")
                verseNumberAttr.font = verseNumberFont
                verseNumberAttr.foregroundColor = themeManager.accentColor
                verseNumberAttr.baselineOffset = 4 // Superscript effect
                result += verseNumberAttr
            }
            
            // Add verse text
            var verseTextAttr = AttributedString(verse.text)
            verseTextAttr.font = verseFont
            
            // Highlight current playing verse
            if let playingIndex = currentPlayingIndex, playingIndex == verse.verse - 1 {
                verseTextAttr.backgroundColor = themeManager.accentColor.opacity(0.15)
            }
            
            result += verseTextAttr
            
            // Add space between verses (not after the last one)
            if index < verses.count - 1 {
                result += AttributedString(" ")
            }
        }
        
        return result
    }
}

/// Tappable verse row that shows options on tap
struct TappableVerseRow: View {
    let verse: Verse
    let isRTL: Bool
    let highlightColor: Color?
    let hasNote: Bool
    let isFavorite: Bool
    let isPlaying: Bool
    let themeManager: ThemeManager
    
    // Font settings passed from parent to ensure proper LazyVStack re-rendering
    let verseFont: Font
    let verseNumberFont: Font
    let lineSpacing: Double
    let showVerseNumbers: Bool
    let textAlignment: TextAlignment
    
    // Trailing closure parameter - must be last for trailing closure syntax
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    /// Computed text alignment that respects RTL override
    private var effectiveTextAlignment: SwiftUI.TextAlignment {
        if isRTL { return .trailing }
        switch textAlignment {
        case .center: return .center
        case .trailing: return .trailing
        default: return .leading
        }
    }
    
    /// Computed horizontal alignment for the VStack
    private var effectiveHorizontalAlignment: HorizontalAlignment {
        if isRTL { return .trailing }
        switch textAlignment {
        case .center: return .center
        case .trailing: return .trailing
        default: return .leading
        }
    }
    
    /// Computed frame alignment
    private var effectiveFrameAlignment: Alignment {
        if isRTL { return .trailing }
        switch textAlignment {
        case .center: return .center
        case .trailing: return .trailing
        default: return .leading
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 0) {
                if !isRTL && showVerseNumbers {
                    verseNumberView
                }
                
                // Verse text
                VStack(alignment: effectiveHorizontalAlignment, spacing: 6) {
                    Text(verse.text)
                        .font(verseFont)
                        .foregroundColor(themeManager.textColor)
                        .lineSpacing(CGFloat(lineSpacing * 4))
                        .multilineTextAlignment(effectiveTextAlignment)
                        .environment(\.layoutDirection, isRTL ? .rightToLeft : .leftToRight)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // Indicators
                    if hasNote || isFavorite {
                        HStack(spacing: 6) {
                            if isFavorite {
                                Image(systemName: "heart.fill")
                                    .font(.caption2)
                                    .foregroundColor(.red)
                            }
                            if hasNote {
                                Image(systemName: "note.text")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: effectiveFrameAlignment)
                
                if isRTL && showVerseNumbers {
                    verseNumberView
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(backgroundView)
        }
        .buttonStyle(VerseButtonStyle())
    }
    
    private var verseNumberView: some View {
        Text("\(verse.verse)")
            .font(verseNumberFont)
            .foregroundColor(themeManager.accentColor)
            .frame(width: 36, alignment: isRTL ? .trailing : .leading)
            .padding(.top, 3)
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        if isPlaying {
            themeManager.accentColor.opacity(0.15)
        } else if let highlightColor = highlightColor {
            highlightColor
        } else {
            Color.clear
        }
    }
}

/// Custom button style for verses
struct VerseButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.99 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// Full audio player view with OpenAI TTS integration
struct AudioPlayerView: View {
    @ObservedObject var audioService: AudioService
    @ObservedObject var openAITTSService = OpenAITTSService.shared
    let themeManager: ThemeManager
    let onClose: () -> Void
    let onVerseSelect: (Int) -> Void
    
    @State private var showVoiceSettings = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle bar
            Capsule()
                .fill(Color.gray.opacity(0.4))
                .frame(width: 36, height: 5)
                .padding(.top, 10)
            
            VStack(spacing: 16) {
                // Audio source indicator
                HStack(spacing: 6) {
                    Image(systemName: audioService.currentAudioSource.icon)
                        .font(.caption2)
                    Text(audioService.currentAudioSource.displayName)
                        .font(.caption2)
                        .fontWeight(.medium)
                    
                    if audioService.currentAudioSource == .openAI {
                        Text("• \(openAITTSService.selectedVoice.displayName)")
                            .font(.caption2)
                            .foregroundColor(themeManager.accentColor)
                    }
                }
                .foregroundColor(themeManager.secondaryTextColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(themeManager.cardBackgroundColor)
                .cornerRadius(12)
                
                // Now playing info
                VStack(spacing: 6) {
                    Text(audioService.currentReference)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    HStack(spacing: 8) {
                        Text("Verse \(audioService.currentVerseNumber) of \(audioService.totalVerses)")
                            .font(.headline)
                            .foregroundColor(themeManager.textColor)
                        
                        // Loading indicator
                        if audioService.isLoadingAudio {
                            ProgressView()
                                .scaleEffect(0.7)
                        }
                    }
                }
                
                // Current verse text or loading state
                ZStack {
                    if audioService.isLoadingAudio {
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Generating audio...")
                                .font(.subheadline)
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                    } else {
                        Text(audioService.currentVerseText)
                            .font(.subheadline)
                            .foregroundColor(themeManager.secondaryTextColor)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(height: 44)
                .padding(.horizontal)
                
                // Error message (if any)
                if let error = audioService.audioError {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                        Text(error)
                            .font(.caption2)
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(themeManager.dividerColor)
                            .frame(height: 4)
                        
                        Capsule()
                            .fill(themeManager.accentColor)
                            .frame(width: geometry.size.width * audioService.progress, height: 4)
                            .animation(.easeInOut(duration: 0.3), value: audioService.progress)
                    }
                }
                .frame(height: 4)
                .padding(.horizontal)
                
                // Controls
                HStack(spacing: 32) {
                    // Previous
                    Button {
                        audioService.previousVerse()
                    } label: {
                        Image(systemName: "backward.fill")
                            .font(.title2)
                            .foregroundColor(audioService.currentVerseIndex > 0 && !audioService.isLoadingAudio ? themeManager.textColor : themeManager.secondaryTextColor.opacity(0.4))
                    }
                    .disabled(audioService.currentVerseIndex == 0 || audioService.isLoadingAudio)
                    
                    // Play/Pause
                    Button {
                        audioService.togglePlayPause()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(audioService.isLoadingAudio ? themeManager.accentColor.opacity(0.5) : themeManager.accentColor)
                                .frame(width: 56, height: 56)
                            
                            if audioService.isLoadingAudio {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: audioService.isPaused ? "play.fill" : "pause.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .disabled(audioService.isLoadingAudio)
                    
                    // Next
                    Button {
                        audioService.nextVerse()
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.title2)
                            .foregroundColor(audioService.currentVerseIndex < audioService.totalVerses - 1 && !audioService.isLoadingAudio ? themeManager.textColor : themeManager.secondaryTextColor.opacity(0.4))
                    }
                    .disabled(audioService.currentVerseIndex >= audioService.totalVerses - 1 || audioService.isLoadingAudio)
                }
                
                // Voice settings and controls
                HStack {
                    // Voice selector (OpenAI TTS)
                    Button {
                        showVoiceSettings = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "person.wave.2")
                            Text(openAITTSService.selectedVoice.displayName)
                                .font(.caption)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(themeManager.cardBackgroundColor)
                        .cornerRadius(20)
                        .foregroundColor(themeManager.textColor)
                    }
                    
                    Spacer()
                    
                    // Speed control (for System TTS)
                    if audioService.currentAudioSource == .systemTTS {
                        Menu {
                            ForEach([0.3, 0.4, 0.5, 0.6, 0.7], id: \.self) { rate in
                                Button {
                                    audioService.setRate(Float(rate))
                                } label: {
                                    HStack {
                                        Text(audioService.rateDisplayName(Float(rate)))
                                        if abs(Double(audioService.speechRate) - rate) < 0.05 {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "speedometer")
                                Text(audioService.rateDisplayName(audioService.speechRate))
                                    .font(.caption)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(themeManager.cardBackgroundColor)
                            .cornerRadius(20)
                            .foregroundColor(themeManager.textColor)
                        }
                    }
                    
                    // Close
                    Button {
                        onClose()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                }
                .padding(.horizontal)
            }
            .padding()
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(themeManager.backgroundColor)
                .shadow(color: Color.black.opacity(0.15), radius: 20, y: -5)
        )
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
        .sheet(isPresented: $showVoiceSettings) {
            VoiceSettingsSheet(themeManager: themeManager)
        }
    }
}

/// Voice settings sheet for OpenAI voice selection
struct VoiceSettingsSheet: View {
    let themeManager: ThemeManager
    @ObservedObject var openAITTSService = OpenAITTSService.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // OpenAI TTS toggle
                        VStack(alignment: .leading, spacing: 12) {
                            Text("AI Voice")
                                .font(.headline)
                                .foregroundColor(themeManager.textColor)
                            
                            Toggle(isOn: Binding(
                                get: { openAITTSService.isEnabled },
                                set: { openAITTSService.setEnabled($0) }
                            )) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Use OpenAI TTS")
                                        .foregroundColor(themeManager.textColor)
                                    Text("High-quality AI narration")
                                        .font(.caption)
                                        .foregroundColor(themeManager.secondaryTextColor)
                                }
                            }
                            .tint(themeManager.accentColor)
                            .padding()
                            .background(themeManager.cardBackgroundColor)
                            .cornerRadius(12)
                        }
                        
                        // Voice selection
                        if openAITTSService.isEnabled {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Select Voice")
                                    .font(.headline)
                                    .foregroundColor(themeManager.textColor)
                                
                                ForEach(OpenAIVoice.allCases) { voice in
                                    Button {
                                        openAITTSService.setVoice(voice)
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(voice.displayName)
                                                    .font(.body)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(themeManager.textColor)
                                                Text(voice.description)
                                                    .font(.caption)
                                                    .foregroundColor(themeManager.secondaryTextColor)
                                            }
                                            
                                            Spacer()
                                            
                                            if openAITTSService.selectedVoice == voice {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(themeManager.accentColor)
                                            }
                                        }
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(openAITTSService.selectedVoice == voice ?
                                                      themeManager.accentColor.opacity(0.1) :
                                                      themeManager.cardBackgroundColor)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(openAITTSService.selectedVoice == voice ?
                                                        themeManager.accentColor : Color.clear, lineWidth: 2)
                                        )
                                    }
                                }
                            }
                        }
                        
                        // Info about fallback
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.blue)
                                Text("About Voice Options")
                                    .font(.headline)
                                    .foregroundColor(themeManager.textColor)
                            }
                            
                            Text("OpenAI TTS provides natural AI voices but requires an internet connection and a premium subscription. If unavailable, the app will use your device's built-in voice.")
                                .font(.caption)
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .padding()
                }
            }
            .navigationTitle("Voice Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

/// Mini audio player for bottom bar
struct MiniAudioPlayerView: View {
    @ObservedObject var audioService: AudioService
    let themeManager: ThemeManager
    let onExpand: () -> Void
    let onClose: () -> Void
    let onVerseSelect: (Int) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress bar at top
            GeometryReader { geometry in
                Rectangle()
                    .fill(themeManager.accentColor)
                    .frame(width: geometry.size.width * audioService.progress, height: 3)
                    .animation(.easeInOut(duration: 0.3), value: audioService.progress)
            }
            .frame(height: 3)
            .background(themeManager.dividerColor)
            
            HStack(spacing: 16) {
                // Expand button / Verse info
                Button(action: onExpand) {
                    HStack(spacing: 12) {
                        // Animated icon
                        ZStack {
                            Circle()
                                .fill(themeManager.accentColor.opacity(0.15))
                                .frame(width: 44, height: 44)
                            
                            if audioService.isLoadingAudio {
                                ProgressView()
                                    .scaleEffect(0.7)
                            } else {
                                Image(systemName: "waveform")
                                    .font(.title3)
                                    .foregroundColor(themeManager.accentColor)
                            }
                        }
                        
                        // Info
                        VStack(alignment: .leading, spacing: 2) {
                            Text(audioService.currentReference)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(themeManager.textColor)
                                .lineLimit(1)
                            
                            Text("Verse \(audioService.currentVerseNumber) of \(audioService.totalVerses)")
                                .font(.caption)
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                    }
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                // Play/Pause button
                Button {
                    audioService.togglePlayPause()
                } label: {
                    Image(systemName: audioService.isPaused ? "play.fill" : "pause.fill")
                        .font(.title2)
                        .foregroundColor(themeManager.textColor)
                        .frame(width: 44, height: 44)
                }
                .disabled(audioService.isLoadingAudio)
                
                // Next button
                Button {
                    audioService.nextVerse()
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.title3)
                        .foregroundColor(audioService.currentVerseIndex < audioService.totalVerses - 1 ? themeManager.textColor : themeManager.secondaryTextColor.opacity(0.4))
                }
                .disabled(audioService.currentVerseIndex >= audioService.totalVerses - 1)
                
                // Close button
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(
            Rectangle()
                .fill(themeManager.cardBackgroundColor)
                .shadow(color: Color.black.opacity(0.1), radius: 10, y: -5)
        )
    }
}

/// Font button for reading settings
struct FontButton: View {
    let font: ReadingFont
    let isSelected: Bool
    let themeManager: ThemeManager
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text("Aa")
                    .font(font.font(size: 18))
                    .foregroundColor(isSelected ? themeManager.accentColor : themeManager.textColor)
                
                Text(font.displayName)
                    .font(.caption2)
                    .foregroundColor(isSelected ? themeManager.accentColor : themeManager.secondaryTextColor)
            }
            .frame(width: 64, height: 56)
            .background(isSelected ? themeManager.accentColor.opacity(0.15) : themeManager.cardBackgroundColor)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? themeManager.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

/// Reading settings sheet (quick settings in reader)
/// Now uses SettingsStore directly for proper sync with Settings tab
struct ReaderSettingsSheet: View {
    @ObservedObject private var settings = SettingsStore.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            themeManager.backgroundColor
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Font size - uses SettingsStore.readerTextOffset for sync
                    SettingsSection(title: "Text Size", themeManager: themeManager) {
                        VStack(spacing: 16) {
                            SettingsSliderRow(
                                title: "Reader Text Size",
                                value: $settings.readerTextOffset,
                                range: 0.70...2.0,
                                step: 0.05,
                                tickMarks: [0.70, 1.0, 1.25, 1.5, 1.75, 2.0],
                                formatValue: { String(format: "%.0f%%", $0 * 100) }
                            )
                            
                            // Computed size display
                            HStack {
                                Text("Effective size:")
                                    .font(.caption)
                                    .foregroundColor(themeManager.secondaryTextColor)
                                Text(String(format: "%.0fpt", settings.effectiveReaderFontSize))
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(themeManager.accentColor)
                            }
                        }
                    }
                    
                    // Line spacing - uses SettingsStore.readerLineSpacing for sync
                    SettingsSection(title: "Line Spacing", themeManager: themeManager) {
                        SettingsSliderRow(
                            title: "Spacing",
                            value: $settings.readerLineSpacing,
                            range: 1.0...2.5,
                            step: 0.1,
                            tickMarks: [1.0, 1.4, 1.8, 2.2],
                            formatValue: { String(format: "%.1fx", $0) }
                        )
                    }
                    
                    // Font family - uses SettingsStore.readerFontFamily for sync
                    SettingsSection(title: "Font Style", themeManager: themeManager) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(ReadingFont.allCases) { font in
                                    FontButton(
                                        font: font,
                                        isSelected: settings.readerFontFamily == font,
                                        themeManager: themeManager
                                    ) {
                                        settings.readerFontFamily = font
                                        HapticManager.shared.selection()
                                    }
                                }
                            }
                        }
                    }
                    
                    // Preview - uses settings from SettingsStore
                    SettingsSection(title: "Preview", themeManager: themeManager) {
                        Text("For God so loved the world, that he gave his only begotten Son, that whosoever believeth in him should not perish, but have everlasting life.")
                            .font(settings.verseFont)
                            .lineSpacing(CGFloat(settings.readerLineSpacing * 4))
                            .foregroundColor(themeManager.textColor)
                    }
                    
                    // Reset button
                    Button {
                        settings.resetReaderSettings()
                        HapticManager.shared.success()
                    } label: {
                        Text("Reset to Defaults")
                            .font(.subheadline)
                            .foregroundColor(themeManager.accentColor)
                    }
                    .padding(.top, 8)
                }
                .padding()
            }
        }
        .navigationTitle("Reading Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
                .fontWeight(.semibold)
            }
        }
    }
}

/// Note editor sheet
struct NoteEditorSheet: View {
    let reference: VerseReference?
    let initialText: String
    let onSave: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var noteText: String = ""
    @FocusState private var isTextEditorFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor
                    .ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 16) {
                    if let ref = reference {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(ref.shortReference)
                                .font(.headline)
                                .foregroundColor(themeManager.accentColor)
                            
                            Text(ref.text)
                                .font(.subheadline)
                                .foregroundColor(themeManager.secondaryTextColor)
                                .lineLimit(3)
                        }
                        .padding()
                        .background(themeManager.cardBackgroundColor)
                        .cornerRadius(12)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Note")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                        
                        TextEditor(text: $noteText)
                            .focused($isTextEditorFocused)
                            .font(.body)
                            .foregroundColor(themeManager.textColor)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 200)
                            .padding()
                            .background(themeManager.cardBackgroundColor)
                            .cornerRadius(12)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(noteText)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                noteText = initialText
                isTextEditorFocused = true
            }
        }
    }
}

// Keep old AudioControlBar for backward compatibility
struct AudioControlBar: View {
    @ObservedObject var audioService: AudioService
    let onClose: () -> Void
    
    var body: some View {
        Text("Audio Control")
    }
}

// MARK: - Scroll Offset Preference Key

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Chapter Header View

/// Beautiful chapter header displayed above verses
struct ChapterHeaderView: View {
    let bookName: String
    let chapterNumber: Int
    let translationId: String
    @ObservedObject var themeManager: ThemeManager
    let onBookTap: () -> Void
    let onTranslationTap: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Main chapter title - tappable to open book picker
            Button(action: onBookTap) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(bookName)
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundColor(themeManager.textColor)
                    
                    Text("\(chapterNumber)")
                        .font(.system(size: 42, weight: .light, design: .serif))
                        .foregroundColor(themeManager.accentColor)
                }
            }
            .buttonStyle(.plain)
            
            // Decorative divider with translation badge
            HStack(spacing: 12) {
                // Left line
                Rectangle()
                    .fill(themeManager.dividerColor)
                    .frame(height: 1)
                
                // Translation badge - tappable
                Button(action: onTranslationTap) {
                    Text(translationId.uppercased())
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .tracking(1.5)
                        .foregroundColor(themeManager.accentColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .strokeBorder(themeManager.accentColor.opacity(0.3), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                
                // Right line
                Rectangle()
                    .fill(themeManager.dividerColor)
                    .frame(height: 1)
            }
            .padding(.horizontal, 40)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

#Preview {
    ReaderView(
        viewModel: BibleViewModel(),
        favoritesViewModel: FavoritesViewModel()
    )
}
