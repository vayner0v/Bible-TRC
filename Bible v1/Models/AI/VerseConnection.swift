//
//  VerseConnection.swift
//  Bible v1
//
//  TRC AI Bible Assistant - Verse Connection Model for Cross-Reference Explorer
//

import Foundation
import SwiftUI
import Combine

/// Types of connections between Bible verses
enum ConnectionType: String, Codable, CaseIterable, Identifiable {
    case prophecyFulfillment = "prophecy_fulfillment"
    case parallelPassage = "parallel_passage"
    case directQuote = "direct_quote"
    case thematicLink = "thematic_link"
    case historicalContext = "historical_context"
    case typology = "typology"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .prophecyFulfillment: return "Prophecy & Fulfillment"
        case .parallelPassage: return "Parallel Passage"
        case .directQuote: return "Direct Quote"
        case .thematicLink: return "Thematic Link"
        case .historicalContext: return "Historical Context"
        case .typology: return "Type & Antitype"
        }
    }
    
    var icon: String {
        switch self {
        case .prophecyFulfillment: return "arrow.forward.circle"
        case .parallelPassage: return "arrow.left.arrow.right"
        case .directQuote: return "quote.bubble"
        case .thematicLink: return "link"
        case .historicalContext: return "clock.arrow.circlepath"
        case .typology: return "arrow.triangle.2.circlepath"
        }
    }
    
    var color: Color {
        switch self {
        case .prophecyFulfillment: return .purple
        case .parallelPassage: return .blue
        case .directQuote: return .green
        case .thematicLink: return .orange
        case .historicalContext: return .brown
        case .typology: return .pink
        }
    }
    
    var description: String {
        switch self {
        case .prophecyFulfillment:
            return "Old Testament prophecies fulfilled in the New Testament"
        case .parallelPassage:
            return "Similar accounts in different books (e.g., Synoptic Gospels)"
        case .directQuote:
            return "One passage directly quoting another"
        case .thematicLink:
            return "Passages sharing common themes or topics"
        case .historicalContext:
            return "Historical events referenced across passages"
        case .typology:
            return "Old Testament figures/events prefiguring New Testament realities"
        }
    }
}

/// A connection between two Bible verses
struct VerseConnection: Identifiable, Codable, Hashable {
    let id: UUID
    let sourceReference: String
    let targetReference: String
    let connectionType: ConnectionType
    let strength: ConnectionStrength
    let explanation: String
    let aiGenerated: Bool
    let dateCreated: Date
    
    init(
        id: UUID = UUID(),
        sourceReference: String,
        targetReference: String,
        connectionType: ConnectionType,
        strength: ConnectionStrength = .moderate,
        explanation: String = "",
        aiGenerated: Bool = false,
        dateCreated: Date = Date()
    ) {
        self.id = id
        self.sourceReference = sourceReference
        self.targetReference = targetReference
        self.connectionType = connectionType
        self.strength = strength
        self.explanation = explanation
        self.aiGenerated = aiGenerated
        self.dateCreated = dateCreated
    }
}

/// Strength of a verse connection
enum ConnectionStrength: String, Codable, CaseIterable {
    case strong = "strong"
    case moderate = "moderate"
    case weak = "weak"
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var lineWidth: CGFloat {
        switch self {
        case .strong: return 3.0
        case .moderate: return 2.0
        case .weak: return 1.0
        }
    }
    
    var opacity: Double {
        switch self {
        case .strong: return 1.0
        case .moderate: return 0.7
        case .weak: return 0.4
        }
    }
}

/// A node in the cross-reference graph
struct VerseNode: Identifiable, Hashable {
    let id: String // The verse reference
    let reference: String
    let bookName: String
    let chapter: Int
    let verseStart: Int
    let verseEnd: Int?
    let testament: CrossRefTestament
    var position: CGPoint
    var connections: [VerseConnection]
    
    init(
        reference: String,
        bookName: String,
        chapter: Int,
        verseStart: Int,
        verseEnd: Int? = nil,
        testament: CrossRefTestament,
        position: CGPoint = .zero,
        connections: [VerseConnection] = []
    ) {
        self.id = reference
        self.reference = reference
        self.bookName = bookName
        self.chapter = chapter
        self.verseStart = verseStart
        self.verseEnd = verseEnd
        self.testament = testament
        self.position = position
        self.connections = connections
    }
    
    var displayReference: String {
        if let end = verseEnd, end != verseStart {
            return "\(bookName) \(chapter):\(verseStart)-\(end)"
        }
        return "\(bookName) \(chapter):\(verseStart)"
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: VerseNode, rhs: VerseNode) -> Bool {
        lhs.id == rhs.id
    }
}

/// Testament classification for cross-reference nodes
enum CrossRefTestament: String, Codable {
    case old = "old"
    case new = "new"
    
    var displayName: String {
        switch self {
        case .old: return "Old Testament"
        case .new: return "New Testament"
        }
    }
    
    var color: Color {
        switch self {
        case .old: return .blue
        case .new: return .green
        }
    }
}

/// Graph data structure for cross-references
struct CrossReferenceGraph {
    var nodes: [String: VerseNode] = [:]
    var connections: [VerseConnection] = []
    var centerVerse: String?
    
    /// Add a node to the graph
    mutating func addNode(_ node: VerseNode) {
        nodes[node.id] = node
    }
    
    /// Add a connection between nodes
    mutating func addConnection(_ connection: VerseConnection) {
        connections.append(connection)
        
        // Update node connections
        if var sourceNode = nodes[connection.sourceReference] {
            sourceNode.connections.append(connection)
            nodes[connection.sourceReference] = sourceNode
        }
    }
    
    /// Get all nodes connected to a given node
    func connectedNodes(to reference: String) -> [VerseNode] {
        let relatedConnections = connections.filter {
            $0.sourceReference == reference || $0.targetReference == reference
        }
        
        var relatedRefs = Set<String>()
        for conn in relatedConnections {
            if conn.sourceReference == reference {
                relatedRefs.insert(conn.targetReference)
            } else {
                relatedRefs.insert(conn.sourceReference)
            }
        }
        
        return relatedRefs.compactMap { nodes[$0] }
    }
    
    /// Filter connections by type
    func connections(ofType type: ConnectionType) -> [VerseConnection] {
        connections.filter { $0.connectionType == type }
    }
}

