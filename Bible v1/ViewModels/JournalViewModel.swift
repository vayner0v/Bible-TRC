//
//  JournalViewModel.swift
//  Bible v1
//
//  Spiritual Journal - Main ViewModel
//

import Foundation
import SwiftUI
import Combine
import PhotosUI

/// Main ViewModel for the Journal feature
@MainActor
class JournalViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var entries: [JournalEntry] = []
    @Published var selectedEntry: JournalEntry?
    @Published var selectedDate: Date = Date()
    @Published var selectedMonth: Date = Date()
    
    // Filters
    @Published var searchQuery: String = ""
    @Published var selectedTags: [JournalTag] = []
    @Published var selectedMood: JournalMood?
    @Published var dateRangeStart: Date?
    @Published var dateRangeEnd: Date?
    @Published var showOnlyWithPhotos: Bool = false
    @Published var showOnlyFavorites: Bool = false
    
    // Editor state
    @Published var isEditing: Bool = false
    @Published var editingEntry: JournalEntry?
    @Published var draftTitle: String = ""
    @Published var draftContent: String = ""
    @Published var draftMood: JournalMood?
    @Published var draftTags: [JournalTag] = []
    @Published var draftLinkedVerses: [LinkedVerse] = []
    @Published var draftLinkedHighlightIds: [UUID] = []
    @Published var draftLinkedNoteIds: [UUID] = []
    @Published var draftPhotoFileNames: [String] = []
    @Published var draftPrompt: JournalPrompt?
    
    // UI State
    @Published var showingSearch: Bool = false
    @Published var showingCalendar: Bool = false
    @Published var showingPrompts: Bool = false
    @Published var showingTagPicker: Bool = false
    @Published var showingMoodPicker: Bool = false
    @Published var showingVerseLinking: Bool = false
    @Published var showingPhotoPicker: Bool = false
    @Published var showingFilterSheet: Bool = false
    @Published var showingEntryDetail: Bool = false
    
    // MARK: - Services
    
    private let storageService = JournalStorageService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    /// Filtered entries based on current filters
    var filteredEntries: [JournalEntry] {
        var results = entries
        
        // Apply search
        if !searchQuery.isEmpty {
            let query = searchQuery.lowercased()
            results = results.filter { entry in
                entry.title.lowercased().contains(query) ||
                entry.content.lowercased().contains(query) ||
                entry.tags.contains { $0.name.lowercased().contains(query) }
            }
        }
        
        // Apply tag filter
        if !selectedTags.isEmpty {
            results = results.filter { entry in
                selectedTags.allSatisfy { tag in
                    entry.tags.contains { $0.id == tag.id }
                }
            }
        }
        
        // Apply mood filter
        if let mood = selectedMood {
            results = results.filter { $0.mood == mood }
        }
        
        // Apply date range
        if let start = dateRangeStart {
            results = results.filter { $0.dateCreated >= start }
        }
        if let end = dateRangeEnd {
            results = results.filter { $0.dateCreated <= end }
        }
        
        // Apply photos filter
        if showOnlyWithPhotos {
            results = results.filter { $0.hasPhotos }
        }
        
        // Apply favorites filter
        if showOnlyFavorites {
            results = results.filter { $0.isFavorite }
        }
        
        return results.sorted { $0.dateCreated > $1.dateCreated }
    }
    
    /// Entries for the selected date
    var entriesForSelectedDate: [JournalEntry] {
        let calendar = Calendar.current
        return entries.filter { calendar.isDate($0.dateCreated, inSameDayAs: selectedDate) }
            .sorted { $0.dateCreated > $1.dateCreated }
    }
    
    /// Entries for the selected month
    var entriesForSelectedMonth: [JournalEntry] {
        let calendar = Calendar.current
        return entries.filter { entry in
            calendar.isDate(entry.dateCreated, equalTo: selectedMonth, toGranularity: .month)
        }.sorted { $0.dateCreated > $1.dateCreated }
    }
    
    /// Dates with entries in selected month (for calendar)
    var datesWithEntriesInMonth: Set<Date> {
        let calendar = Calendar.current
        return Set(entriesForSelectedMonth.map { calendar.startOfDay(for: $0.dateCreated) })
    }
    
    /// Today's entry
    var todayEntry: JournalEntry? {
        entries.first { $0.isToday }
    }
    
    /// Has active filters
    var hasActiveFilters: Bool {
        !searchQuery.isEmpty ||
        !selectedTags.isEmpty ||
        selectedMood != nil ||
        dateRangeStart != nil ||
        dateRangeEnd != nil ||
        showOnlyWithPhotos ||
        showOnlyFavorites
    }
    
    /// Current streak
    var currentStreak: Int {
        storageService.currentStreak
    }
    
    /// All available tags
    var allTags: [JournalTag] {
        storageService.allTags
    }
    
    /// All available prompts
    var allPrompts: [JournalPrompt] {
        storageService.allPrompts
    }
    
    /// Today's prompt
    var todaysPrompt: JournalPrompt {
        JournalPrompt.todaysPrompt
    }
    
    /// Mood statistics
    var moodStats: MoodStatistics {
        storageService.moodStatistics()
    }
    
    /// Is draft valid for saving
    var canSaveDraft: Bool {
        !draftTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !draftContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Initialization
    
    init() {
        loadEntries()
        setupBindings()
    }
    
    private func setupBindings() {
        storageService.$entries
            .receive(on: DispatchQueue.main)
            .assign(to: &$entries)
    }
    
    // MARK: - Data Loading
    
    func loadEntries() {
        entries = storageService.entries
    }
    
    func refreshData() {
        loadEntries()
    }
    
    // MARK: - Entry CRUD
    
    /// Create a new entry from current draft
    func createEntry() {
        let entry = JournalEntry(
            title: draftTitle.trimmingCharacters(in: .whitespacesAndNewlines),
            content: draftContent.trimmingCharacters(in: .whitespacesAndNewlines),
            mood: draftMood,
            linkedVerses: draftLinkedVerses,
            linkedHighlightIds: draftLinkedHighlightIds,
            linkedNoteIds: draftLinkedNoteIds,
            tags: draftTags,
            photoFileNames: draftPhotoFileNames,
            promptUsed: draftPrompt
        )
        
        storageService.addEntry(entry)
        clearDraft()
        isEditing = false
    }
    
    /// Update an existing entry from current draft
    func updateEntry() {
        guard var entry = editingEntry else { return }
        
        entry.title = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        entry.content = draftContent.trimmingCharacters(in: .whitespacesAndNewlines)
        entry.mood = draftMood
        entry.linkedVerses = draftLinkedVerses
        entry.linkedHighlightIds = draftLinkedHighlightIds
        entry.linkedNoteIds = draftLinkedNoteIds
        entry.tags = draftTags
        entry.photoFileNames = draftPhotoFileNames
        entry.promptUsed = draftPrompt
        
        storageService.updateEntry(entry)
        clearDraft()
        isEditing = false
        editingEntry = nil
    }
    
    /// Delete an entry
    func deleteEntry(_ entry: JournalEntry) {
        storageService.deleteEntry(entry)
    }
    
    /// Toggle favorite status
    func toggleFavorite(_ entry: JournalEntry) {
        storageService.toggleFavorite(entry)
    }
    
    // MARK: - Draft Management
    
    /// Start creating a new entry
    func startNewEntry(withPrompt prompt: JournalPrompt? = nil) {
        clearDraft()
        draftPrompt = prompt
        if let prompt = prompt {
            draftContent = prompt.text + "\n\n"
        }
        isEditing = true
        editingEntry = nil
    }
    
    /// Start editing an existing entry
    func startEditing(_ entry: JournalEntry) {
        draftTitle = entry.title
        draftContent = entry.content
        draftMood = entry.mood
        draftTags = entry.tags
        draftLinkedVerses = entry.linkedVerses
        draftLinkedHighlightIds = entry.linkedHighlightIds
        draftLinkedNoteIds = entry.linkedNoteIds
        draftPhotoFileNames = entry.photoFileNames
        draftPrompt = entry.promptUsed
        
        editingEntry = entry
        isEditing = true
    }
    
    /// Clear current draft
    func clearDraft() {
        draftTitle = ""
        draftContent = ""
        draftMood = nil
        draftTags = []
        draftLinkedVerses = []
        draftLinkedHighlightIds = []
        draftLinkedNoteIds = []
        draftPhotoFileNames = []
        draftPrompt = nil
    }
    
    /// Cancel editing
    func cancelEditing() {
        // Delete any newly added photos that weren't saved
        if editingEntry == nil {
            for fileName in draftPhotoFileNames {
                storageService.deletePhoto(fileName: fileName)
            }
        }
        
        clearDraft()
        isEditing = false
        editingEntry = nil
    }
    
    /// Save draft (create or update)
    func saveDraft() {
        if editingEntry != nil {
            updateEntry()
        } else {
            createEntry()
        }
    }
    
    // MARK: - Verse Linking
    
    /// Add a linked verse
    func addLinkedVerse(_ verse: LinkedVerse) {
        guard !draftLinkedVerses.contains(where: { 
            $0.bookId == verse.bookId && 
            $0.chapter == verse.chapter && 
            $0.verse == verse.verse 
        }) else { return }
        
        draftLinkedVerses.append(verse)
    }
    
    /// Add linked verse from VerseReference
    func addLinkedVerse(from reference: VerseReference) {
        let linkedVerse = LinkedVerse(from: reference)
        addLinkedVerse(linkedVerse)
    }
    
    /// Remove a linked verse
    func removeLinkedVerse(_ verse: LinkedVerse) {
        draftLinkedVerses.removeAll { $0.id == verse.id }
    }
    
    /// Link a highlight by ID
    func linkHighlight(_ highlightId: UUID) {
        guard !draftLinkedHighlightIds.contains(highlightId) else { return }
        draftLinkedHighlightIds.append(highlightId)
    }
    
    /// Unlink a highlight
    func unlinkHighlight(_ highlightId: UUID) {
        draftLinkedHighlightIds.removeAll { $0 == highlightId }
    }
    
    /// Link a note by ID
    func linkNote(_ noteId: UUID) {
        guard !draftLinkedNoteIds.contains(noteId) else { return }
        draftLinkedNoteIds.append(noteId)
    }
    
    /// Unlink a note
    func unlinkNote(_ noteId: UUID) {
        draftLinkedNoteIds.removeAll { $0 == noteId }
    }
    
    // MARK: - Tags
    
    /// Toggle a tag in draft
    func toggleTag(_ tag: JournalTag) {
        if let index = draftTags.firstIndex(where: { $0.id == tag.id }) {
            draftTags.remove(at: index)
        } else {
            draftTags.append(tag)
        }
    }
    
    /// Add a custom tag
    func addCustomTag(name: String, colorName: String, icon: String) {
        let tag = JournalTag(name: name, colorName: colorName, icon: icon)
        storageService.addTag(tag)
    }
    
    /// Delete a custom tag
    func deleteTag(_ tag: JournalTag) {
        storageService.deleteTag(tag)
    }
    
    // MARK: - Photos
    
    /// Add a photo to draft
    func addPhoto(data: Data) {
        if let fileName = storageService.savePhoto(data) {
            draftPhotoFileNames.append(fileName)
        }
    }
    
    /// Remove a photo from draft
    func removePhoto(fileName: String) {
        draftPhotoFileNames.removeAll { $0 == fileName }
        // Don't delete the file until the entry is saved/discarded
    }
    
    /// Get photo URL
    func photoURL(for fileName: String) -> URL? {
        storageService.photoURL(for: fileName)
    }
    
    // MARK: - Calendar Navigation
    
    /// Go to previous month
    func previousMonth() {
        if let newMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) {
            selectedMonth = newMonth
        }
    }
    
    /// Go to next month
    func nextMonth() {
        if let newMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) {
            selectedMonth = newMonth
        }
    }
    
    /// Go to today
    func goToToday() {
        selectedDate = Date()
        selectedMonth = Date()
    }
    
    /// Select a date
    func selectDate(_ date: Date) {
        selectedDate = date
    }
    
    // MARK: - Filters
    
    /// Clear all filters
    func clearFilters() {
        searchQuery = ""
        selectedTags = []
        selectedMood = nil
        dateRangeStart = nil
        dateRangeEnd = nil
        showOnlyWithPhotos = false
        showOnlyFavorites = false
    }
    
    /// Toggle tag filter
    func toggleTagFilter(_ tag: JournalTag) {
        if let index = selectedTags.firstIndex(where: { $0.id == tag.id }) {
            selectedTags.remove(at: index)
        } else {
            selectedTags.append(tag)
        }
    }
    
    // MARK: - Prompts
    
    /// Get prompts for a category
    func prompts(for category: PromptCategory) -> [JournalPrompt] {
        allPrompts.filter { $0.category == category }
    }
    
    /// Add a custom prompt
    func addCustomPrompt(text: String, category: PromptCategory) {
        let prompt = JournalPrompt(text: text, category: category, isCustom: true)
        storageService.addPrompt(prompt)
    }
    
    // MARK: - Export
    
    /// Export journal as text
    func exportAsText() -> String {
        storageService.exportAsText()
    }
}






