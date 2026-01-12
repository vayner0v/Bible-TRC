//
//  CrossReferenceService.swift
//  Bible v1
//
//  TRC AI Bible Assistant - Cross-Reference Service
//  Manages verse connections and generates AI-powered cross-references
//

import Foundation
import SwiftUI
import Combine

/// Service for managing and discovering Bible cross-references
@MainActor
class CrossReferenceService: ObservableObject {
    static let shared = CrossReferenceService()
    
    // MARK: - Storage
    
    private let storageKey = "trc_cross_references"
    
    // MARK: - State
    
    @Published private(set) var isLoading = false
    @Published private(set) var currentGraph = CrossReferenceGraph()
    @Published var selectedConnectionTypes: Set<ConnectionType> = Set(ConnectionType.allCases)
    
    // MARK: - Dependencies
    
    private let referenceParser = ReferenceParser.shared
    
    // MARK: - Static Cross-References (Common well-known connections)
    
    private let staticCrossReferences: [VerseConnection] = [
        // Messianic prophecies
        VerseConnection(
            sourceReference: "Isaiah 7:14",
            targetReference: "Matthew 1:23",
            connectionType: .prophecyFulfillment,
            strength: .strong,
            explanation: "Virgin birth prophecy fulfilled in Jesus"
        ),
        VerseConnection(
            sourceReference: "Micah 5:2",
            targetReference: "Matthew 2:6",
            connectionType: .prophecyFulfillment,
            strength: .strong,
            explanation: "Bethlehem as birthplace of the Messiah"
        ),
        VerseConnection(
            sourceReference: "Isaiah 53:5",
            targetReference: "1 Peter 2:24",
            connectionType: .prophecyFulfillment,
            strength: .strong,
            explanation: "Suffering servant prophecy fulfilled in Christ's crucifixion"
        ),
        VerseConnection(
            sourceReference: "Psalm 22:1",
            targetReference: "Matthew 27:46",
            connectionType: .directQuote,
            strength: .strong,
            explanation: "Jesus quotes Psalm 22 from the cross"
        ),
        VerseConnection(
            sourceReference: "Psalm 110:1",
            targetReference: "Matthew 22:44",
            connectionType: .directQuote,
            strength: .strong,
            explanation: "Jesus references David's psalm about the Messiah"
        ),
        
        // Synoptic parallels
        VerseConnection(
            sourceReference: "Matthew 3:13-17",
            targetReference: "Mark 1:9-11",
            connectionType: .parallelPassage,
            strength: .strong,
            explanation: "Jesus's baptism recorded in both Gospels"
        ),
        VerseConnection(
            sourceReference: "Matthew 3:13-17",
            targetReference: "Luke 3:21-22",
            connectionType: .parallelPassage,
            strength: .strong,
            explanation: "Jesus's baptism in Luke's Gospel"
        ),
        
        // Thematic connections
        VerseConnection(
            sourceReference: "Genesis 3:15",
            targetReference: "Romans 16:20",
            connectionType: .typology,
            strength: .moderate,
            explanation: "Proto-evangelium connection to ultimate victory"
        ),
        VerseConnection(
            sourceReference: "Exodus 12:1-13",
            targetReference: "1 Corinthians 5:7",
            connectionType: .typology,
            strength: .strong,
            explanation: "Passover lamb as type of Christ"
        ),
        VerseConnection(
            sourceReference: "John 3:16",
            targetReference: "Romans 5:8",
            connectionType: .thematicLink,
            strength: .moderate,
            explanation: "God's love demonstrated through Christ"
        ),
        VerseConnection(
            sourceReference: "Deuteronomy 6:4-5",
            targetReference: "Mark 12:29-30",
            connectionType: .directQuote,
            strength: .strong,
            explanation: "Jesus quotes the Shema as greatest commandment"
        ),
        
        // Historical context
        VerseConnection(
            sourceReference: "2 Kings 25:1-21",
            targetReference: "Jeremiah 52:1-27",
            connectionType: .historicalContext,
            strength: .strong,
            explanation: "Fall of Jerusalem recorded in both books"
        )
    ]
    
    // MARK: - Public API
    
    /// Get cross-references for a verse
    func getCrossReferences(for reference: String) async -> [VerseConnection] {
        isLoading = true
        defer { isLoading = false }
        
        var connections: [VerseConnection] = []
        
        // First, check static references
        connections.append(contentsOf: staticCrossReferences.filter {
            $0.sourceReference == reference || $0.targetReference == reference
        })
        
        // TODO: Add AI-generated cross-references for premium users
        // This would use TRCAIService to find thematic connections
        
        return connections
    }
    
    /// Build a graph for visualization starting from a verse
    func buildGraph(for reference: String, depth: Int = 1) async -> CrossReferenceGraph {
        isLoading = true
        defer { isLoading = false }
        
        var graph = CrossReferenceGraph()
        graph.centerVerse = reference
        
        // Parse the center verse
        if let parsed = referenceParser.parse(reference) {
            let centerNode = VerseNode(
                reference: reference,
                bookName: parsed.bookDisplayName,
                chapter: parsed.chapter,
                verseStart: parsed.verseStart ?? 1,
                verseEnd: parsed.verseEnd,
                testament: getTestament(for: parsed.osisBookId),
                position: CGPoint.zero
            )
            graph.addNode(centerNode)
        }
        
        // Get direct connections
        let directConnections = await getCrossReferences(for: reference)
        
        for connection in directConnections {
            graph.addConnection(connection)
            
            // Add connected nodes
            let connectedRef = connection.sourceReference == reference 
                ? connection.targetReference 
                : connection.sourceReference
            
            if let parsed = referenceParser.parse(connectedRef) {
                let node = VerseNode(
                    reference: connectedRef,
                    bookName: parsed.bookDisplayName,
                    chapter: parsed.chapter,
                    verseStart: parsed.verseStart ?? 1,
                    verseEnd: parsed.verseEnd,
                    testament: getTestament(for: parsed.osisBookId)
                )
                graph.addNode(node)
            }
        }
        
        // Expand to depth if requested
        if depth > 1 {
            for nodeRef in graph.nodes.keys where nodeRef != reference {
                let secondaryConnections = await getCrossReferences(for: nodeRef)
                for connection in secondaryConnections {
                    if graph.nodes[connection.sourceReference] != nil || 
                       graph.nodes[connection.targetReference] != nil {
                        graph.addConnection(connection)
                    }
                }
            }
        }
        
        // Calculate node positions
        layoutGraph(&graph)
        
        currentGraph = graph
        return graph
    }
    
    /// Generate AI-powered cross-references (Premium feature)
    func generateAICrossReferences(for reference: String, content: String) async throws -> [VerseConnection] {
        guard AIUsageManager.shared.isPremium else {
            return []
        }
        
        // This would use the AI service to find thematic connections
        // For now, return empty array - full implementation would call TRCAIService
        return []
    }
    
    /// Get all connections of a specific type
    func getConnections(ofType type: ConnectionType) -> [VerseConnection] {
        staticCrossReferences.filter { $0.connectionType == type }
    }
    
    /// Get connection statistics
    var connectionStats: (total: Int, byType: [ConnectionType: Int]) {
        var byType: [ConnectionType: Int] = [:]
        for type in ConnectionType.allCases {
            byType[type] = staticCrossReferences.filter { $0.connectionType == type }.count
        }
        return (staticCrossReferences.count, byType)
    }
    
    // MARK: - Private Helpers
    
    private func getTestament(for osisId: String) -> CrossRefTestament {
        let oldTestamentBooks = Set([
            "GEN", "EXO", "LEV", "NUM", "DEU", "JOS", "JDG", "RUT",
            "1SA", "2SA", "1KI", "2KI", "1CH", "2CH", "EZR", "NEH",
            "EST", "JOB", "PSA", "PRO", "ECC", "SNG", "ISA", "JER",
            "LAM", "EZK", "DAN", "HOS", "JOL", "AMO", "OBA", "JON",
            "MIC", "NAM", "HAB", "ZEP", "HAG", "ZEC", "MAL"
        ])
        
        return oldTestamentBooks.contains(osisId.uppercased()) ? .old : .new
    }
    
    /// Layout nodes in a radial pattern
    private func layoutGraph(_ graph: inout CrossReferenceGraph) {
        guard let centerRef = graph.centerVerse,
              var centerNode = graph.nodes[centerRef] else { return }
        
        let center = CGPoint(x: 200, y: 200)
        centerNode.position = center
        graph.nodes[centerRef] = centerNode
        
        let otherNodes = graph.nodes.keys.filter { $0 != centerRef }
        let angleStep = (2 * .pi) / CGFloat(max(1, otherNodes.count))
        let radius: CGFloat = 150
        
        for (index, ref) in otherNodes.enumerated() {
            guard var node = graph.nodes[ref] else { continue }
            
            let angle = CGFloat(index) * angleStep - .pi / 2
            node.position = CGPoint(
                x: center.x + radius * cos(angle),
                y: center.y + radius * sin(angle)
            )
            graph.nodes[ref] = node
        }
    }
}

