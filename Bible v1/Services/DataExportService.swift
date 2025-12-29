//
//  DataExportService.swift
//  Bible v1
//
//  Export user data for backup
//

import Foundation
import SwiftUI
import Combine

/// Data export format
struct ExportedUserData: Codable {
    let exportDate: Date
    let appVersion: String
    let favorites: [ExportedFavorite]
    let highlights: [ExportedHighlight]
    let notes: [ExportedNote]
    let prayerEntries: [ExportedPrayerEntry]
    let fastingEntries: [ExportedFastingEntry]
    let journalEntries: [ExportedJournalEntry]
    let readingProgress: ExportedReadingProgress?
}

// Simplified export models to avoid dependency on full models
struct ExportedFavorite: Codable {
    let translationId: String
    let bookId: String
    let chapter: Int
    let verse: Int
    let text: String
    let createdAt: Date
}

struct ExportedHighlight: Codable {
    let translationId: String
    let bookId: String
    let chapter: Int
    let verse: Int
    let text: String
    let colorName: String
    let createdAt: Date
}

struct ExportedNote: Codable {
    let translationId: String
    let bookId: String
    let chapter: Int
    let verse: Int
    let noteText: String
    let createdAt: Date
    let updatedAt: Date
}

struct ExportedPrayerEntry: Codable {
    let id: String
    let title: String
    let content: String
    let category: String
    let isAnswered: Bool
    let createdAt: Date
}

struct ExportedFastingEntry: Codable {
    let id: String
    let startDate: Date
    let plannedEndDate: Date
    let actualEndDate: Date?
    let type: String
    let intention: String
    let reflection: String?
}

struct ExportedJournalEntry: Codable {
    let id: String
    let title: String
    let content: String
    let mood: String?
    let createdAt: Date
    let updatedAt: Date
}

struct ExportedReadingProgress: Codable {
    let translationId: String
    let bookId: String
    let lastChapter: Int
    let lastVerse: Int
    let lastReadAt: Date
}

/// Service for exporting and importing user data
@MainActor
class DataExportService: ObservableObject {
    static let shared = DataExportService()
    
    @Published var isExporting = false
    @Published var exportError: String?
    @Published var lastExportDate: Date?
    
    private let storageService = StorageService.shared
    private let hubStorageService = HubStorageService.shared
    
    private init() {
        // Load last export date
        if let timestamp = UserDefaults.standard.object(forKey: "lastDataExportTimestamp") as? Double {
            lastExportDate = Date(timeIntervalSince1970: timestamp)
        }
    }
    
    /// Export all user data to a JSON file
    func exportUserData() async throws -> URL {
        isExporting = true
        exportError = nil
        
        defer {
            isExporting = false
        }
        
        // Collect all data
        let exportData = ExportedUserData(
            exportDate: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            favorites: exportFavorites(),
            highlights: exportHighlights(),
            notes: exportNotes(),
            prayerEntries: exportPrayerEntries(),
            fastingEntries: exportFastingEntries(),
            journalEntries: exportJournalEntries(),
            readingProgress: exportReadingProgress()
        )
        
        // Encode to JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        let jsonData = try encoder.encode(exportData)
        
        // Create file
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let dateString = dateFormatter.string(from: Date())
        let fileName = "BibleApp_Backup_\(dateString).json"
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try jsonData.write(to: tempURL)
        
        // Update last export date
        lastExportDate = Date()
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "lastDataExportTimestamp")
        SettingsStore.shared.lastDataExportDate = Date()
        
        return tempURL
    }
    
    // MARK: - Export Helpers
    
    private func exportFavorites() -> [ExportedFavorite] {
        storageService.favorites.map { favorite in
            ExportedFavorite(
                translationId: favorite.translationId,
                bookId: favorite.bookId,
                chapter: favorite.chapter,
                verse: favorite.verse,
                text: favorite.text,
                createdAt: favorite.createdAt
            )
        }
    }
    
    private func exportHighlights() -> [ExportedHighlight] {
        storageService.highlights.map { highlight in
            ExportedHighlight(
                translationId: highlight.translationId,
                bookId: highlight.bookId,
                chapter: highlight.chapter,
                verse: highlight.verse,
                text: highlight.text,
                colorName: highlight.colorName,
                createdAt: highlight.createdAt
            )
        }
    }
    
    private func exportNotes() -> [ExportedNote] {
        storageService.notes.map { note in
            ExportedNote(
                translationId: note.translationId,
                bookId: note.bookId,
                chapter: note.chapter,
                verse: note.verse,
                noteText: note.noteText,
                createdAt: note.createdAt,
                updatedAt: note.dateModified
            )
        }
    }
    
    private func exportPrayerEntries() -> [ExportedPrayerEntry] {
        hubStorageService.prayerEntries.map { entry in
            ExportedPrayerEntry(
                id: entry.id.uuidString,
                title: entry.title,
                content: entry.content,
                category: entry.category.rawValue,
                isAnswered: entry.isAnswered,
                createdAt: entry.dateCreated
            )
        }
    }
    
    private func exportFastingEntries() -> [ExportedFastingEntry] {
        hubStorageService.fastingEntries.map { entry in
            ExportedFastingEntry(
                id: entry.id.uuidString,
                startDate: entry.startDate,
                plannedEndDate: entry.plannedEndDate,
                actualEndDate: entry.actualEndDate,
                type: entry.type.rawValue,
                intention: entry.intention,
                reflection: entry.reflection
            )
        }
    }
    
    private func exportJournalEntries() -> [ExportedJournalEntry] {
        // Get journal entries from JournalStorageService if available
        let entries: [JournalEntry] = JournalStorageService.shared.entries
        return entries.map { entry in
            ExportedJournalEntry(
                id: entry.id.uuidString,
                title: entry.title,
                content: entry.content,
                mood: entry.mood?.rawValue,
                createdAt: entry.dateCreated,
                updatedAt: entry.dateModified
            )
        }
    }
    
    private func exportReadingProgress() -> ExportedReadingProgress? {
        // Export last reading position (StorageService only tracks single position)
        guard let position = storageService.getLastPosition() else {
            return nil
        }
        return ExportedReadingProgress(
            translationId: position.translationId,
            bookId: position.bookId,
            lastChapter: position.chapter,
            lastVerse: position.verse ?? 1,
            lastReadAt: position.dateAccessed
        )
    }
    
    // MARK: - Import (Future Enhancement)
    
    /// Import user data from a backup file
    func importUserData(from url: URL) async throws {
        // Future implementation for data restoration
        throw NSError(domain: "DataExportService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Import not yet implemented"])
    }
    
    // MARK: - Statistics
    
    /// Get counts of exportable data
    var exportableDataCounts: (favorites: Int, highlights: Int, notes: Int, prayers: Int, fasts: Int, journals: Int) {
        (
            favorites: storageService.favorites.count,
            highlights: storageService.highlights.count,
            notes: storageService.notes.count,
            prayers: hubStorageService.prayerEntries.count,
            fasts: hubStorageService.fastingEntries.count,
            journals: JournalStorageService.shared.entries.count
        )
    }
    
    /// Check if there's any data to export
    var hasExportableData: Bool {
        let counts = exportableDataCounts
        return counts.favorites > 0 || counts.highlights > 0 || counts.notes > 0 ||
               counts.prayers > 0 || counts.fasts > 0 || counts.journals > 0
    }
}

// Note: ShareSheet is defined in JournalEntryDetailView.swift
// Use that implementation for sharing exported data
