//
//  CacheService.swift
//  Bible v1
//
//  Advanced Bible Reader App
//

import Foundation

/// Service for caching Bible data to disk for offline use
class CacheService {
    static let shared = CacheService()
    
    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private var cacheDirectory: URL? {
        fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent("BibleCache")
    }
    
    init() {
        createCacheDirectoryIfNeeded()
    }
    
    // MARK: - Directory Management
    
    private func createCacheDirectoryIfNeeded() {
        guard let cacheDir = cacheDirectory else { return }
        
        if !fileManager.fileExists(atPath: cacheDir.path) {
            try? fileManager.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        }
    }
    
    private func translationDirectory(for translationId: String) -> URL? {
        cacheDirectory?.appendingPathComponent(translationId)
    }
    
    // MARK: - Translations Cache
    
    /// Cache the translations list
    func cacheTranslations(_ translations: [Translation]) {
        guard let url = cacheDirectory?.appendingPathComponent("translations.json") else { return }
        
        do {
            let data = try encoder.encode(translations)
            try data.write(to: url)
        } catch {
            print("Failed to cache translations: \(error)")
        }
    }
    
    /// Get cached translations
    func getCachedTranslations() -> [Translation]? {
        guard let url = cacheDirectory?.appendingPathComponent("translations.json"),
              let data = try? Data(contentsOf: url) else { return nil }
        
        return try? decoder.decode([Translation].self, from: data)
    }
    
    // MARK: - Books Cache
    
    /// Cache books for a translation
    func cacheBooks(_ books: [Book], for translationId: String) {
        guard let transDir = translationDirectory(for: translationId) else { return }
        
        do {
            try fileManager.createDirectory(at: transDir, withIntermediateDirectories: true)
            let url = transDir.appendingPathComponent("books.json")
            let data = try encoder.encode(books)
            try data.write(to: url)
        } catch {
            print("Failed to cache books: \(error)")
        }
    }
    
    /// Get cached books for a translation
    func getCachedBooks(for translationId: String) -> [Book]? {
        guard let url = translationDirectory(for: translationId)?.appendingPathComponent("books.json"),
              let data = try? Data(contentsOf: url) else { return nil }
        
        return try? decoder.decode([Book].self, from: data)
    }
    
    // MARK: - Chapter Cache
    
    /// Cache a chapter
    func cacheChapter(_ chapter: Chapter, translationId: String, bookId: String, chapterNum: Int) {
        guard let transDir = translationDirectory(for: translationId) else { return }
        
        let bookDir = transDir.appendingPathComponent(bookId)
        
        do {
            try fileManager.createDirectory(at: bookDir, withIntermediateDirectories: true)
            let url = bookDir.appendingPathComponent("\(chapterNum).json")
            let data = try encoder.encode(chapter)
            try data.write(to: url)
        } catch {
            print("Failed to cache chapter: \(error)")
        }
    }
    
    /// Get cached chapter
    func getCachedChapter(translationId: String, bookId: String, chapter: Int) -> Chapter? {
        guard let url = translationDirectory(for: translationId)?
            .appendingPathComponent(bookId)
            .appendingPathComponent("\(chapter).json"),
              let data = try? Data(contentsOf: url) else { return nil }
        
        return try? decoder.decode(Chapter.self, from: data)
    }
    
    /// Check if a chapter is cached
    func isChapterCached(translationId: String, bookId: String, chapter: Int) -> Bool {
        guard let url = translationDirectory(for: translationId)?
            .appendingPathComponent(bookId)
            .appendingPathComponent("\(chapter).json") else { return false }
        
        return fileManager.fileExists(atPath: url.path)
    }
    
    // MARK: - Download Entire Translation
    
    /// Download and cache an entire translation
    func downloadTranslation(_ translationId: String, books: [Book], progressHandler: @escaping (Double) -> Void) async throws {
        let apiService = BibleAPIService.shared
        var totalChapters = 0
        var downloadedChapters = 0
        
        // Calculate total chapters
        for book in books {
            totalChapters += book.numberOfChapters
        }
        
        // Download each chapter
        for book in books {
            for chapterNum in 1...book.numberOfChapters {
                if !isChapterCached(translationId: translationId, bookId: book.id, chapter: chapterNum) {
                    let chapter = try await apiService.fetchChapter(translationId: translationId, bookId: book.id, chapter: chapterNum)
                    cacheChapter(chapter, translationId: translationId, bookId: book.id, chapterNum: chapterNum)
                }
                
                downloadedChapters += 1
                let progress = Double(downloadedChapters) / Double(totalChapters)
                progressHandler(progress)
                
                // Small delay to avoid overwhelming the API
                try await Task.sleep(nanoseconds: 50_000_000) // 50ms
            }
        }
        
        // Cache the books list
        cacheBooks(books, for: translationId)
    }
    
    /// Check if a translation is fully downloaded
    func isTranslationDownloaded(_ translationId: String, books: [Book]) -> Bool {
        for book in books {
            for chapter in 1...book.numberOfChapters {
                if !isChapterCached(translationId: translationId, bookId: book.id, chapter: chapter) {
                    return false
                }
            }
        }
        return true
    }
    
    /// Get list of downloaded translations
    func getDownloadedTranslations() -> [String] {
        guard let cacheDir = cacheDirectory else { return [] }
        
        do {
            let contents = try fileManager.contentsOfDirectory(at: cacheDir, includingPropertiesForKeys: nil)
            return contents
                .filter { $0.hasDirectoryPath }
                .map { $0.lastPathComponent }
        } catch {
            return []
        }
    }
    
    // MARK: - Clear Cache
    
    /// Clear cache for a specific translation
    func clearTranslationCache(_ translationId: String) {
        guard let transDir = translationDirectory(for: translationId) else { return }
        try? fileManager.removeItem(at: transDir)
    }
    
    /// Clear all caches
    func clearAllCaches() {
        guard let cacheDir = cacheDirectory else { return }
        try? fileManager.removeItem(at: cacheDir)
        createCacheDirectoryIfNeeded()
    }
    
    /// Get cache size in bytes
    func getCacheSize() -> Int64 {
        guard let cacheDir = cacheDirectory else { return 0 }
        return directorySize(at: cacheDir)
    }
    
    private func directorySize(at url: URL) -> Int64 {
        var size: Int64 = 0
        
        guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        
        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
                  let fileSize = resourceValues.fileSize else { continue }
            size += Int64(fileSize)
        }
        
        return size
    }
    
    /// Format cache size for display
    func formattedCacheSize() -> String {
        let bytes = getCacheSize()
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    // MARK: - Audio Cache (TTS)
    
    private var audioDirectory: URL? {
        cacheDirectory?.appendingPathComponent("Audio")
    }
    
    /// Generate a unique key for audio cache lookup
    private func audioKey(translationId: String, bookId: String, chapter: Int, verse: Int, voiceId: String) -> String {
        "\(translationId)_\(bookId)_\(chapter)_\(verse)_\(voiceId)"
    }
    
    /// Cache audio data for a verse
    func cacheAudio(_ audioData: Data, translationId: String, bookId: String, chapter: Int, verse: Int, voiceId: String) {
        guard let audioDir = audioDirectory else { return }
        
        do {
            try fileManager.createDirectory(at: audioDir, withIntermediateDirectories: true)
            let key = audioKey(translationId: translationId, bookId: bookId, chapter: chapter, verse: verse, voiceId: voiceId)
            let url = audioDir.appendingPathComponent("\(key).mp3")
            try audioData.write(to: url)
        } catch {
            print("Failed to cache audio: \(error)")
        }
    }
    
    /// Get cached audio for a verse
    func getCachedAudio(translationId: String, bookId: String, chapter: Int, verse: Int, voiceId: String) -> Data? {
        guard let audioDir = audioDirectory else { return nil }
        
        let key = audioKey(translationId: translationId, bookId: bookId, chapter: chapter, verse: verse, voiceId: voiceId)
        let url = audioDir.appendingPathComponent("\(key).mp3")
        
        return try? Data(contentsOf: url)
    }
    
    /// Get cached audio file URL for a verse
    func getCachedAudioURL(translationId: String, bookId: String, chapter: Int, verse: Int, voiceId: String) -> URL? {
        guard let audioDir = audioDirectory else { return nil }
        
        let key = audioKey(translationId: translationId, bookId: bookId, chapter: chapter, verse: verse, voiceId: voiceId)
        let url = audioDir.appendingPathComponent("\(key).mp3")
        
        if fileManager.fileExists(atPath: url.path) {
            return url
        }
        return nil
    }
    
    /// Check if audio is cached for a verse
    func isAudioCached(translationId: String, bookId: String, chapter: Int, verse: Int, voiceId: String) -> Bool {
        guard let audioDir = audioDirectory else { return false }
        
        let key = audioKey(translationId: translationId, bookId: bookId, chapter: chapter, verse: verse, voiceId: voiceId)
        let url = audioDir.appendingPathComponent("\(key).mp3")
        
        return fileManager.fileExists(atPath: url.path)
    }
    
    /// Clear all cached audio
    func clearAudioCache() {
        guard let audioDir = audioDirectory else { return }
        try? fileManager.removeItem(at: audioDir)
    }
    
    /// Get audio cache size in bytes
    func getAudioCacheSize() -> Int64 {
        guard let audioDir = audioDirectory else { return 0 }
        return directorySize(at: audioDir)
    }
    
    /// Format audio cache size for display
    func formattedAudioCacheSize() -> String {
        let bytes = getAudioCacheSize()
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

