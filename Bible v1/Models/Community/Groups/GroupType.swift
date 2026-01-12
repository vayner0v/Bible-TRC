//
//  GroupType.swift
//  Bible v1
//
//  Community Tab - Group Type Enum
//

import Foundation
import SwiftUI

/// Types of community groups
enum GroupType: String, Codable, CaseIterable, Identifiable {
    case topic = "topic"
    case readingPlan = "reading_plan"
    case church = "church"
    case study = "study"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .topic: return "Topic Group"
        case .readingPlan: return "Reading Plan"
        case .church: return "Church Group"
        case .study: return "Bible Study"
        }
    }
    
    var icon: String {
        switch self {
        case .topic: return "tag.fill"
        case .readingPlan: return "book.fill"
        case .church: return "building.columns.fill"
        case .study: return "text.book.closed.fill"
        }
    }
    
    var description: String {
        switch self {
        case .topic: return "Connect around shared interests"
        case .readingPlan: return "Read through a plan together"
        case .church: return "Official church community"
        case .study: return "Deep dive into scripture"
        }
    }
    
    var color: Color {
        switch self {
        case .topic: return .blue
        case .readingPlan: return .green
        case .church: return .purple
        case .study: return .orange
        }
    }
    
    /// Whether this group type can be verified
    var canBeVerified: Bool {
        self == .church
    }
    
    /// Whether this group type supports reading plan linking
    var supportsReadingPlan: Bool {
        self == .readingPlan || self == .study
    }
}

/// Privacy levels for groups
enum GroupPrivacy: String, Codable, CaseIterable {
    case `public` = "public"
    case `private` = "private"
    case hidden = "hidden"
    
    var displayName: String {
        switch self {
        case .public: return "Public"
        case .private: return "Private"
        case .hidden: return "Hidden"
        }
    }
    
    var icon: String {
        switch self {
        case .public: return "globe"
        case .private: return "lock"
        case .hidden: return "eye.slash"
        }
    }
    
    var description: String {
        switch self {
        case .public: return "Anyone can find and join"
        case .private: return "Anyone can find, but must request to join"
        case .hidden: return "Only members can find this group"
        }
    }
}

