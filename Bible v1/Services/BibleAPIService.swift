//
//  BibleAPIService.swift
//  Bible v1
//
//  Advanced Bible Reader App
//

import Foundation
import Combine

/// Errors that can occur when fetching Bible data
enum BibleError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case noData
    case serverError(Int)
    case offline
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to parse data: \(error.localizedDescription)"
        case .noData:
            return "No data received"
        case .serverError(let code):
            return "Server error (code: \(code))"
        case .offline:
            return "You appear to be offline. Please check your connection."
        }
    }
}

/// Service for fetching Bible data from the Free Use Bible API
@MainActor
class BibleAPIService: ObservableObject {
    static let shared = BibleAPIService()
    
    private let baseURL = "https://bible.helloao.org/api"
    private let session: URLSession
    
    // In-memory cache
    private var translationsCache: [Translation]?
    private var booksCache: [String: [Book]] = [:]
    private var chaptersCache: [String: Chapter] = [:]
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Translations
    
    /// Fetch all available Bible translations
    func fetchTranslations() async throws -> [Translation] {
        // Return cached if available
        if let cached = translationsCache {
            return cached
        }
        
        let url = "\(baseURL)/available_translations.json"
        let data = try await fetchData(from: url)
        
        // The API returns an object with "translations" array
        let response = try JSONDecoder().decode(TranslationsResponse.self, from: data)
        translationsCache = response.translations
        return response.translations
    }
    
    /// Get a specific translation by ID
    func getTranslation(id: String) async throws -> Translation? {
        let translations = try await fetchTranslations()
        return translations.first { $0.id == id }
    }
    
    // MARK: - Books
    
    /// Fetch books for a specific translation
    func fetchBooks(translationId: String) async throws -> [Book] {
        // Return cached if available
        if let cached = booksCache[translationId] {
            return cached
        }
        
        let url = "\(baseURL)/\(translationId)/books.json"
        let data = try await fetchData(from: url)
        
        // The API returns an object with "books" array
        let response = try JSONDecoder().decode(BooksResponse.self, from: data)
        booksCache[translationId] = response.books
        return response.books
    }
    
    /// Get a specific book by ID
    func getBook(translationId: String, bookId: String) async throws -> Book? {
        let books = try await fetchBooks(translationId: translationId)
        return books.first { $0.id == bookId }
    }
    
    // MARK: - Chapters
    
    /// Fetch a specific chapter
    func fetchChapter(translationId: String, bookId: String, chapter: Int) async throws -> Chapter {
        let cacheKey = "\(translationId)_\(bookId)_\(chapter)"
        
        // Return cached if available
        if let cached = chaptersCache[cacheKey] {
            return cached
        }
        
        let url = "\(baseURL)/\(translationId)/\(bookId)/\(chapter).json"
        let data = try await fetchData(from: url)
        
        let chapterData = try JSONDecoder().decode(Chapter.self, from: data)
        chaptersCache[cacheKey] = chapterData
        return chapterData
    }
    
    // MARK: - Commentaries (Phase 3)
    
    /// Fetch available commentaries
    func fetchCommentaries() async throws -> [Commentary] {
        let url = "\(baseURL)/available_commentaries.json"
        let data = try await fetchData(from: url)
        
        let response = try JSONDecoder().decode(CommentariesResponse.self, from: data)
        return response.commentaries
    }
    
    /// Fetch commentary for a specific chapter
    func fetchCommentary(commentaryId: String, bookId: String, chapter: Int) async throws -> CommentaryChapter {
        let url = "\(baseURL)/\(commentaryId)/\(bookId)/\(chapter).json"
        let data = try await fetchData(from: url)
        
        return try JSONDecoder().decode(CommentaryChapter.self, from: data)
    }
    
    // MARK: - Cache Management
    
    /// Clear all caches
    func clearCache() {
        translationsCache = nil
        booksCache.removeAll()
        chaptersCache.removeAll()
    }
    
    /// Check if a chapter is cached
    func isChapterCached(translationId: String, bookId: String, chapter: Int) -> Bool {
        let cacheKey = "\(translationId)_\(bookId)_\(chapter)"
        return chaptersCache[cacheKey] != nil
    }
    
    // MARK: - Private Helpers
    
    private func fetchData(from urlString: String) async throws -> Data {
        guard let url = URL(string: urlString) else {
            throw BibleError.invalidURL
        }
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw BibleError.noData
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw BibleError.serverError(httpResponse.statusCode)
            }
            
            return data
        } catch let error as BibleError {
            throw error
        } catch {
            if (error as NSError).code == NSURLErrorNotConnectedToInternet {
                throw BibleError.offline
            }
            throw BibleError.networkError(error)
        }
    }
}

// MARK: - Commentary Models (Phase 3)

struct Commentary: Codable, Identifiable {
    let id: String
    let name: String
    let language: String?
}

struct CommentariesResponse: Codable {
    let commentaries: [Commentary]
}

struct CommentaryChapter: Codable {
    let book: BookNavigation?
    let chapter: Int?
    let content: [CommentaryContent]
}

struct CommentaryContent: Codable, Identifiable {
    let verse: Int?
    let text: String?
    let heading: String?
    
    var id: String {
        "\(verse ?? 0)_\(text?.prefix(20) ?? "")"
    }
}

