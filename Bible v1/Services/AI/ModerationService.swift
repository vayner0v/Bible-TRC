//
//  ModerationService.swift
//  Bible v1
//
//  TRC AI Bible Assistant - OpenAI Moderation API Integration
//

import Foundation
import Combine

/// Result from the OpenAI Moderation API
struct ModerationResult {
    let flagged: Bool
    let categories: ModerationCategories
    let categoryScores: ModerationCategoryScores
    
    /// Check if any critical category is flagged
    var hasCriticalContent: Bool {
        categories.selfHarm || categories.selfHarmIntent || 
        categories.violence || categories.violenceGraphic
    }
    
    /// Check if the content needs intervention
    var needsIntervention: Bool {
        flagged && (hasCriticalContent || categories.selfHarmInstructions)
    }
    
    /// Get the primary flagged category
    var primaryCategory: String? {
        if categories.selfHarm || categories.selfHarmIntent { return "self-harm" }
        if categories.violence || categories.violenceGraphic { return "violence" }
        if categories.harassment || categories.harassmentThreatening { return "harassment" }
        if categories.hate || categories.hateThreatening { return "hate" }
        if categories.sexual || categories.sexualMinors { return "sexual" }
        return flagged ? "other" : nil
    }
}

struct ModerationCategories: Codable {
    let hate: Bool
    let hateThreatening: Bool
    let harassment: Bool
    let harassmentThreatening: Bool
    let selfHarm: Bool
    let selfHarmIntent: Bool
    let selfHarmInstructions: Bool
    let sexual: Bool
    let sexualMinors: Bool
    let violence: Bool
    let violenceGraphic: Bool
    
    enum CodingKeys: String, CodingKey {
        case hate
        case hateThreatening = "hate/threatening"
        case harassment
        case harassmentThreatening = "harassment/threatening"
        case selfHarm = "self-harm"
        case selfHarmIntent = "self-harm/intent"
        case selfHarmInstructions = "self-harm/instructions"
        case sexual
        case sexualMinors = "sexual/minors"
        case violence
        case violenceGraphic = "violence/graphic"
    }
}

struct ModerationCategoryScores: Codable {
    let hate: Double
    let hateThreatening: Double
    let harassment: Double
    let harassmentThreatening: Double
    let selfHarm: Double
    let selfHarmIntent: Double
    let selfHarmInstructions: Double
    let sexual: Double
    let sexualMinors: Double
    let violence: Double
    let violenceGraphic: Double
    
    enum CodingKeys: String, CodingKey {
        case hate
        case hateThreatening = "hate/threatening"
        case harassment
        case harassmentThreatening = "harassment/threatening"
        case selfHarm = "self-harm"
        case selfHarmIntent = "self-harm/intent"
        case selfHarmInstructions = "self-harm/instructions"
        case sexual
        case sexualMinors = "sexual/minors"
        case violence
        case violenceGraphic = "violence/graphic"
    }
    
    /// Get the highest scoring critical category
    var highestCriticalScore: Double {
        max(selfHarm, selfHarmIntent, violence, violenceGraphic)
    }
}

/// Errors that can occur during moderation
enum ModerationError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid moderation API URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from moderation API"
        case .apiError(let message):
            return "API error: \(message)"
        }
    }
}

/// Service for checking content against OpenAI's Moderation API
@MainActor
class ModerationService: ObservableObject {
    static let shared = ModerationService()
    
    // MARK: - Configuration
    
    private let baseURL = "https://api.openai.com/v1/moderations"
    private let model = "omni-moderation-latest"
    
    // MARK: - API Key
    
    private var apiKey: String {
        if let key = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] {
            return key
        }
        if let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
           let secrets = NSDictionary(contentsOfFile: path),
           let key = secrets["OPENAI_API_KEY"] as? String {
            return key
        }
        return ""
    }
    
    // MARK: - State
    
    @Published var isChecking = false
    @Published var lastError: ModerationError?
    
    private let session: URLSession
    
    // MARK: - Cache for recent checks (avoid duplicate API calls)
    
    private var recentChecks: [String: ModerationResult] = [:]
    private let cacheExpiry: TimeInterval = 300 // 5 minutes
    private var cacheTimestamps: [String: Date] = [:]
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Public API
    
    /// Check content for moderation issues
    func checkContent(_ text: String) async throws -> ModerationResult {
        // Check cache first
        let cacheKey = text.prefix(500).lowercased()
        if let cached = getCachedResult(for: String(cacheKey)) {
            return cached
        }
        
        isChecking = true
        defer { isChecking = false }
        
        guard let url = URL(string: baseURL) else {
            throw ModerationError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "model": model,
            "input": text
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ModerationError.invalidResponse
        }
        
        if httpResponse.statusCode < 200 || httpResponse.statusCode >= 300 {
            // Parse error message
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = json["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw ModerationError.apiError(message)
            }
            throw ModerationError.apiError("HTTP \(httpResponse.statusCode)")
        }
        
        // Parse the response
        let result = try parseResponse(data)
        
        // Cache the result
        cacheResult(result, for: String(cacheKey))
        
        return result
    }
    
    /// Quick check that returns true if content is flagged for critical issues
    func isFlagged(_ text: String) async -> Bool {
        do {
            let result = try await checkContent(text)
            return result.needsIntervention
        } catch {
            // On error, don't block - let the safety classifier handle it
            print("ModerationService: Check failed, falling back to local classifier: \(error)")
            return false
        }
    }
    
    /// Check content with fallback to local safety classifier
    func checkWithFallback(_ text: String, localClassifier: SafetyClassifier) async -> (isFlagged: Bool, category: String?) {
        // First try the API
        do {
            let result = try await checkContent(text)
            if result.needsIntervention {
                return (true, result.primaryCategory)
            }
            // If API says it's fine, still check local classifier for Bible-specific patterns
            let localResult = localClassifier.classify(text)
            if localResult.requiresIntervention {
                return (true, localResult.rawValue)
            }
            return (false, nil)
        } catch {
            // Fallback to local classifier on API error
            let localResult = localClassifier.classify(text)
            return (localResult.requiresIntervention, localResult.rawValue)
        }
    }
    
    // MARK: - Private Helpers
    
    private func parseResponse(_ data: Data) throws -> ModerationResult {
        struct ModerationAPIResponse: Codable {
            let results: [ModerationResultItem]
        }
        
        struct ModerationResultItem: Codable {
            let flagged: Bool
            let categories: ModerationCategories
            let categoryScores: ModerationCategoryScores
            
            enum CodingKeys: String, CodingKey {
                case flagged
                case categories
                case categoryScores = "category_scores"
            }
        }
        
        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(ModerationAPIResponse.self, from: data)
        
        guard let firstResult = apiResponse.results.first else {
            throw ModerationError.invalidResponse
        }
        
        return ModerationResult(
            flagged: firstResult.flagged,
            categories: firstResult.categories,
            categoryScores: firstResult.categoryScores
        )
    }
    
    private func getCachedResult(for key: String) -> ModerationResult? {
        guard let timestamp = cacheTimestamps[key],
              Date().timeIntervalSince(timestamp) < cacheExpiry,
              let result = recentChecks[key] else {
            return nil
        }
        return result
    }
    
    private func cacheResult(_ result: ModerationResult, for key: String) {
        recentChecks[key] = result
        cacheTimestamps[key] = Date()
        
        // Clean up old cache entries
        let now = Date()
        cacheTimestamps = cacheTimestamps.filter { now.timeIntervalSince($0.value) < cacheExpiry }
        recentChecks = recentChecks.filter { cacheTimestamps[$0.key] != nil }
    }
    
    /// Clear the cache
    func clearCache() {
        recentChecks.removeAll()
        cacheTimestamps.removeAll()
    }
}

