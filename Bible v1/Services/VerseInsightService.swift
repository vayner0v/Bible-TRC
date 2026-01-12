//
//  VerseInsightService.swift
//  Bible v1
//
//  Service for saving and loading verse insights
//

import Foundation
import Combine

/// Service for managing saved verse insights
@MainActor
class VerseInsightService: ObservableObject {
    static let shared = VerseInsightService()
    
    @Published private(set) var insights: [VerseInsight] = []
    @Published private(set) var isLoading = false
    
    private let storageKey = "saved_verse_insights"
    private let maxInsights = 100 // Limit stored insights
    
    private init() {
        loadInsights()
    }
    
    // MARK: - Public Methods
    
    /// Save a new insight
    func saveInsight(_ insight: VerseInsight) {
        // Check if we already have an insight for this verse and type
        if let existingIndex = insights.firstIndex(where: {
            $0.reference == insight.reference && $0.analysisType == insight.analysisType
        }) {
            // Replace existing
            insights[existingIndex] = insight
        } else {
            // Add new
            insights.insert(insight, at: 0)
            
            // Trim if over limit
            if insights.count > maxInsights {
                insights = Array(insights.prefix(maxInsights))
            }
        }
        
        persistInsights()
    }
    
    /// Remove an insight
    func removeInsight(_ insight: VerseInsight) {
        insights.removeAll { $0.id == insight.id }
        persistInsights()
    }
    
    /// Remove all insights
    func clearAllInsights() {
        insights.removeAll()
        persistInsights()
    }
    
    /// Get insights for a specific verse reference
    func getInsights(for reference: String) -> [VerseInsight] {
        insights.filter { $0.reference == reference }
    }
    
    /// Get insight for a specific verse and analysis type
    func getInsight(for reference: String, type: InsightAnalysisType) -> VerseInsight? {
        insights.first { $0.reference == reference && $0.analysisType == type }
    }
    
    /// Check if insight exists for a verse
    func hasInsight(for reference: String) -> Bool {
        insights.contains { $0.reference == reference }
    }
    
    /// Get insights grouped by book
    func getInsightsGroupedByBook() -> [(bookName: String, insights: [VerseInsight])] {
        let grouped = Dictionary(grouping: insights) { $0.bookName ?? "Unknown" }
        return grouped
            .map { (bookName: $0.key, insights: $0.value.sorted { $0.createdAt > $1.createdAt }) }
            .sorted { $0.bookName < $1.bookName }
    }
    
    /// Get recent insights
    func getRecentInsights(limit: Int = 10) -> [VerseInsight] {
        Array(insights.prefix(limit))
    }
    
    // MARK: - Persistence
    
    private func loadInsights() {
        isLoading = true
        defer { isLoading = false }
        
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            return
        }
        
        do {
            let decoded = try JSONDecoder().decode([VerseInsight].self, from: data)
            insights = decoded
        } catch {
            print("VerseInsightService: Failed to decode insights: \(error)")
        }
    }
    
    private func persistInsights() {
        do {
            let data = try JSONEncoder().encode(insights)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("VerseInsightService: Failed to encode insights: \(error)")
        }
    }
}



