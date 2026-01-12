//
//  JournalStorageService.swift
//  Bible v1
//
//  Spiritual Journal - Persistence Service
//

import Foundation
import SwiftUI
import Combine

/// Service for storing and managing journal entries
class JournalStorageService: ObservableObject {
    static let shared = JournalStorageService()
    
    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let fileManager = FileManager.default
    
    // Storage Keys
    private enum Keys {
        static let journalEntries = "journal_entries"
        static let customTags = "journal_custom_tags"
        static let customPrompts = "journal_custom_prompts"
        static let lastEntryDate = "journal_last_entry_date"
        static let streakCount = "journal_streak_count"
        static let totalEntries = "journal_total_entries"
    }
    
    // MARK: - Published Properties
    
    @Published private(set) var entries: [JournalEntry] = []
    @Published private(set) var customTags: [JournalTag] = []
    @Published private(set) var customPrompts: [JournalPrompt] = []
    @Published private(set) var currentStreak: Int = 0
    
    // MARK: - Computed Properties
    
    /// All available tags (default + custom)
    var allTags: [JournalTag] {
        JournalTag.defaultTags + customTags
    }
    
    /// All available prompts (default + custom)
    var allPrompts: [JournalPrompt] {
        JournalPrompt.defaultPrompts + customPrompts
    }
    
    /// Today's entry if exists
    var todayEntry: JournalEntry? {
        entries.first { $0.isToday }
    }
    
    /// Total entries count
    var totalEntriesCount: Int {
        entries.count
    }
    
    /// Entries grouped by date
    var entriesByDate: [Date: [JournalEntry]] {
        Dictionary(grouping: entries) { entry in
            Calendar.current.startOfDay(for: entry.dateCreated)
        }
    }
    
    /// Entries from this week
    var thisWeekEntries: [JournalEntry] {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return entries.filter { $0.dateCreated >= weekAgo }
    }
    
    /// Entries from this month
    var thisMonthEntries: [JournalEntry] {
        let calendar = Calendar.current
        let monthAgo = calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        return entries.filter { $0.dateCreated >= monthAgo }
    }
    
    /// Photos directory URL
    private var photosDirectory: URL? {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent("JournalPhotos", isDirectory: true)
    }
    
    // MARK: - Initialization
    
    private init() {
        loadAll()
        calculateStreak()
        createPhotosDirectoryIfNeeded()
    }
    
    private func loadAll() {
        entries = loadEntries()
        customTags = loadCustomTags()
        customPrompts = loadCustomPrompts()
    }
    
    private func createPhotosDirectoryIfNeeded() {
        guard let photosDir = photosDirectory else { return }
        if !fileManager.fileExists(atPath: photosDir.path) {
            try? fileManager.createDirectory(at: photosDir, withIntermediateDirectories: true)
        }
    }
    
    // MARK: - Entries CRUD
    
    private func loadEntries() -> [JournalEntry] {
        guard let data = defaults.data(forKey: Keys.journalEntries) else { return [] }
        return (try? decoder.decode([JournalEntry].self, from: data)) ?? []
    }
    
    private func saveEntries() {
        guard let data = try? encoder.encode(entries) else { return }
        defaults.set(data, forKey: Keys.journalEntries)
    }
    
    /// Add a new journal entry
    func addEntry(_ entry: JournalEntry) {
        entries.insert(entry, at: 0)
        saveEntries()
        updateStreak()
    }
    
    /// Update an existing entry
    func updateEntry(_ entry: JournalEntry) {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            var updatedEntry = entry
            updatedEntry.dateModified = Date()
            entries[index] = updatedEntry
            saveEntries()
        }
    }
    
    /// Delete an entry
    func deleteEntry(_ entry: JournalEntry) {
        // Delete associated photos
        for fileName in entry.photoFileNames {
            deletePhoto(fileName: fileName)
        }
        
        entries.removeAll { $0.id == entry.id }
        saveEntries()
    }
    
    /// Delete entries at offsets
    func deleteEntries(at offsets: IndexSet) {
        let entriesToDelete = offsets.map { entries[$0] }
        for entry in entriesToDelete {
            for fileName in entry.photoFileNames {
                deletePhoto(fileName: fileName)
            }
        }
        entries.remove(atOffsets: offsets)
        saveEntries()
    }
    
    /// Get entry by ID
    func entry(withId id: UUID) -> JournalEntry? {
        entries.first { $0.id == id }
    }
    
    /// Toggle favorite status
    func toggleFavorite(_ entry: JournalEntry) {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[index].isFavorite.toggle()
            saveEntries()
        }
    }
    
    // MARK: - Filtering & Search
    
    /// Filter entries by tag
    func entries(withTag tag: JournalTag) -> [JournalEntry] {
        entries.filter { entry in
            entry.tags.contains { $0.id == tag.id }
        }
    }
    
    /// Filter entries by mood
    func entries(withMood mood: JournalMood) -> [JournalEntry] {
        entries.filter { $0.mood == mood }
    }
    
    /// Filter entries by date range
    func entries(from startDate: Date, to endDate: Date) -> [JournalEntry] {
        entries.filter { entry in
            entry.dateCreated >= startDate && entry.dateCreated <= endDate
        }
    }
    
    /// Search entries by text
    func search(query: String) -> [JournalEntry] {
        guard !query.isEmpty else { return entries }
        let lowercasedQuery = query.lowercased()
        
        return entries.filter { entry in
            entry.title.lowercased().contains(lowercasedQuery) ||
            entry.content.lowercased().contains(lowercasedQuery) ||
            entry.tags.contains { $0.name.lowercased().contains(lowercasedQuery) } ||
            entry.linkedVerses.contains { $0.shortReference.lowercased().contains(lowercasedQuery) }
        }
    }
    
    /// Advanced search with filters
    func search(
        query: String?,
        tags: [JournalTag]?,
        mood: JournalMood?,
        startDate: Date?,
        endDate: Date?,
        hasPhotos: Bool?
    ) -> [JournalEntry] {
        var results = entries
        
        // Filter by query
        if let query = query, !query.isEmpty {
            let lowercasedQuery = query.lowercased()
            results = results.filter { entry in
                entry.title.lowercased().contains(lowercasedQuery) ||
                entry.content.lowercased().contains(lowercasedQuery)
            }
        }
        
        // Filter by tags
        if let tags = tags, !tags.isEmpty {
            results = results.filter { entry in
                tags.allSatisfy { tag in
                    entry.tags.contains { $0.id == tag.id }
                }
            }
        }
        
        // Filter by mood
        if let mood = mood {
            results = results.filter { $0.mood == mood }
        }
        
        // Filter by date range
        if let startDate = startDate {
            results = results.filter { $0.dateCreated >= startDate }
        }
        if let endDate = endDate {
            results = results.filter { $0.dateCreated <= endDate }
        }
        
        // Filter by photos
        if let hasPhotos = hasPhotos {
            results = results.filter { $0.hasPhotos == hasPhotos }
        }
        
        return results
    }
    
    // MARK: - Tags
    
    private func loadCustomTags() -> [JournalTag] {
        guard let data = defaults.data(forKey: Keys.customTags) else { return [] }
        return (try? decoder.decode([JournalTag].self, from: data)) ?? []
    }
    
    private func saveCustomTags() {
        guard let data = try? encoder.encode(customTags) else { return }
        defaults.set(data, forKey: Keys.customTags)
    }
    
    /// Add a custom tag
    func addTag(_ tag: JournalTag) {
        guard !customTags.contains(where: { $0.name.lowercased() == tag.name.lowercased() }) else { return }
        customTags.append(tag)
        saveCustomTags()
    }
    
    /// Update a custom tag
    func updateTag(_ tag: JournalTag) {
        if let index = customTags.firstIndex(where: { $0.id == tag.id }) {
            customTags[index] = tag
            saveCustomTags()
        }
    }
    
    /// Delete a custom tag
    func deleteTag(_ tag: JournalTag) {
        guard !tag.isDefault else { return }
        customTags.removeAll { $0.id == tag.id }
        saveCustomTags()
    }
    
    // MARK: - Prompts
    
    private func loadCustomPrompts() -> [JournalPrompt] {
        guard let data = defaults.data(forKey: Keys.customPrompts) else { return [] }
        return (try? decoder.decode([JournalPrompt].self, from: data)) ?? []
    }
    
    private func saveCustomPrompts() {
        guard let data = try? encoder.encode(customPrompts) else { return }
        defaults.set(data, forKey: Keys.customPrompts)
    }
    
    /// Add a custom prompt
    func addPrompt(_ prompt: JournalPrompt) {
        customPrompts.append(prompt)
        saveCustomPrompts()
    }
    
    /// Delete a custom prompt
    func deletePrompt(_ prompt: JournalPrompt) {
        guard prompt.isCustom else { return }
        customPrompts.removeAll { $0.id == prompt.id }
        saveCustomPrompts()
    }
    
    // MARK: - Photos
    
    /// Save photo data and return file name
    func savePhoto(_ data: Data) -> String? {
        guard let photosDir = photosDirectory else { return nil }
        
        let fileName = UUID().uuidString + ".jpg"
        let fileURL = photosDir.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            return fileName
        } catch {
            print("Failed to save photo: \(error)")
            return nil
        }
    }
    
    /// Get photo URL for file name
    func photoURL(for fileName: String) -> URL? {
        photosDirectory?.appendingPathComponent(fileName)
    }
    
    /// Load photo data
    func loadPhoto(fileName: String) -> Data? {
        guard let url = photoURL(for: fileName) else { return nil }
        return try? Data(contentsOf: url)
    }
    
    /// Delete a photo
    func deletePhoto(fileName: String) {
        guard let url = photoURL(for: fileName) else { return }
        try? fileManager.removeItem(at: url)
    }
    
    // MARK: - Streak Tracking
    
    private func calculateStreak() {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())
        
        // Check if there's an entry for today or yesterday to continue the streak
        let hasEntryToday = entries.contains { calendar.isDate($0.dateCreated, inSameDayAs: checkDate) }
        
        if !hasEntryToday {
            // Check yesterday
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }
        
        // Count consecutive days with entries
        while true {
            let hasEntry = entries.contains { calendar.isDate($0.dateCreated, inSameDayAs: checkDate) }
            
            if hasEntry {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else {
                break
            }
        }
        
        currentStreak = streak
        defaults.set(streak, forKey: Keys.streakCount)
    }
    
    private func updateStreak() {
        calculateStreak()
    }
    
    // MARK: - Statistics
    
    /// Get mood statistics
    func moodStatistics() -> MoodStatistics {
        MoodStatistics(entries: entries)
    }
    
    /// Get entries count by tag
    func entriesCount(for tag: JournalTag) -> Int {
        entries(withTag: tag).count
    }
    
    /// Get entries per day for the last N days
    func entriesPerDay(days: Int) -> [(date: Date, count: Int)] {
        let calendar = Calendar.current
        var result: [(date: Date, count: Int)] = []
        
        for dayOffset in 0..<days {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) ?? Date()
            let startOfDay = calendar.startOfDay(for: date)
            let count = entries.filter { calendar.isDate($0.dateCreated, inSameDayAs: startOfDay) }.count
            result.append((date: startOfDay, count: count))
        }
        
        return result.reversed()
    }
    
    /// Average words per entry
    var averageWordCount: Int {
        guard !entries.isEmpty else { return 0 }
        let totalWords = entries.reduce(0) { $0 + $1.wordCount }
        return totalWords / entries.count
    }
    
    // MARK: - Export
    
    /// Export all entries as text
    func exportAsText() -> String {
        var export = "My Spiritual Journal\n"
        export += "Exported: \(Date().formatted())\n"
        export += String(repeating: "=", count: 50) + "\n\n"
        
        for entry in entries.sorted(by: { $0.dateCreated > $1.dateCreated }) {
            export += "Date: \(entry.formattedDate)\n"
            if !entry.title.isEmpty {
                export += "Title: \(entry.title)\n"
            }
            if let mood = entry.mood {
                export += "Mood: \(mood.displayName)\n"
            }
            if !entry.tags.isEmpty {
                export += "Tags: \(entry.tags.map { $0.name }.joined(separator: ", "))\n"
            }
            export += "\n\(entry.content)\n"
            
            if !entry.linkedVerses.isEmpty {
                export += "\nLinked Verses:\n"
                for verse in entry.linkedVerses {
                    export += "- \(verse.fullReference)\n"
                }
            }
            
            export += String(repeating: "-", count: 50) + "\n\n"
        }
        
        return export
    }
    
    // MARK: - Clear Data
    
    /// Clear all journal data
    func clearAllData() {
        // Delete all photos
        if let photosDir = photosDirectory {
            try? fileManager.removeItem(at: photosDir)
            createPhotosDirectoryIfNeeded()
        }
        
        entries = []
        customTags = []
        customPrompts = []
        currentStreak = 0
        
        defaults.removeObject(forKey: Keys.journalEntries)
        defaults.removeObject(forKey: Keys.customTags)
        defaults.removeObject(forKey: Keys.customPrompts)
        defaults.removeObject(forKey: Keys.streakCount)
    }
}






