//
//  PostTone.swift
//  Bible v1
//
//  Community Tab - Post Tone Enum
//

import Foundation
import SwiftUI

/// Emotional tone of a post
enum PostTone: String, Codable, CaseIterable, Identifiable {
    case encouragement = "encouragement"
    case lament = "lament"
    case gratitude = "gratitude"
    case confession = "confession"
    case hope = "hope"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .encouragement: return "Encouragement"
        case .lament: return "Lament"
        case .gratitude: return "Gratitude"
        case .confession: return "Confession"
        case .hope: return "Hope"
        }
    }
    
    var icon: String {
        switch self {
        case .encouragement: return "hand.thumbsup"
        case .lament: return "cloud.rain"
        case .gratitude: return "heart.fill"
        case .confession: return "arrow.uturn.backward.circle"
        case .hope: return "sun.horizon"
        }
    }
    
    var description: String {
        switch self {
        case .encouragement: return "Uplifting and supportive"
        case .lament: return "Processing grief or difficulty"
        case .gratitude: return "Thankful and appreciative"
        case .confession: return "Honest and vulnerable"
        case .hope: return "Looking forward with faith"
        }
    }
    
    var color: Color {
        switch self {
        case .encouragement: return .green
        case .lament: return .gray
        case .gratitude: return .pink
        case .confession: return .purple
        case .hope: return .orange
        }
    }
    
    /// Suggested background color for posts with this tone
    var backgroundGradient: [Color] {
        switch self {
        case .encouragement: return [.green.opacity(0.1), .green.opacity(0.05)]
        case .lament: return [.gray.opacity(0.1), .gray.opacity(0.05)]
        case .gratitude: return [.pink.opacity(0.1), .pink.opacity(0.05)]
        case .confession: return [.purple.opacity(0.1), .purple.opacity(0.05)]
        case .hope: return [.orange.opacity(0.1), .orange.opacity(0.05)]
        }
    }
}

