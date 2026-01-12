//
//  JournalTag.swift
//  Bible v1
//
//  Spiritual Journal - Tag/Category Model
//

import Foundation
import SwiftUI

/// Represents a tag for organizing journal entries
struct JournalTag: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var colorName: String
    var icon: String
    let isDefault: Bool
    let dateCreated: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        colorName: String = "blue",
        icon: String = "tag.fill",
        isDefault: Bool = false,
        dateCreated: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.colorName = colorName
        self.icon = icon
        self.isDefault = isDefault
        self.dateCreated = dateCreated
    }
    
    /// Get SwiftUI Color from color name
    var color: Color {
        TagColor(rawValue: colorName)?.color ?? .blue
    }
    
    /// Lighter shade for backgrounds
    var lightColor: Color {
        color.opacity(0.15)
    }
}

// MARK: - Tag Colors

/// Available tag colors
enum TagColor: String, Codable, CaseIterable, Identifiable {
    case red
    case orange
    case yellow
    case green
    case mint
    case teal
    case blue
    case indigo
    case purple
    case pink
    case brown
    case gray
    
    var id: String { rawValue }
    
    var color: Color {
        switch self {
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green: return .green
        case .mint: return .mint
        case .teal: return .teal
        case .blue: return .blue
        case .indigo: return .indigo
        case .purple: return .purple
        case .pink: return .pink
        case .brown: return .brown
        case .gray: return .gray
        }
    }
    
    var displayName: String {
        rawValue.capitalized
    }
}

// MARK: - Default Tags

extension JournalTag {
    /// Default tags available to all users
    static let defaultTags: [JournalTag] = [
        JournalTag(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            name: "Reflection",
            colorName: "indigo",
            icon: "brain.head.profile",
            isDefault: true
        ),
        JournalTag(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            name: "Prayer",
            colorName: "purple",
            icon: "hands.sparkles.fill",
            isDefault: true
        ),
        JournalTag(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            name: "Study",
            colorName: "blue",
            icon: "book.fill",
            isDefault: true
        ),
        JournalTag(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
            name: "Personal",
            colorName: "teal",
            icon: "person.fill",
            isDefault: true
        ),
        JournalTag(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!,
            name: "Gratitude",
            colorName: "pink",
            icon: "heart.fill",
            isDefault: true
        ),
        JournalTag(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000006")!,
            name: "Testimony",
            colorName: "orange",
            icon: "star.fill",
            isDefault: true
        ),
        JournalTag(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000007")!,
            name: "Sermon Notes",
            colorName: "green",
            icon: "text.alignleft",
            isDefault: true
        ),
        JournalTag(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000008")!,
            name: "Life Application",
            colorName: "mint",
            icon: "lightbulb.fill",
            isDefault: true
        )
    ]
    
    /// Get a default tag by name
    static func defaultTag(named name: String) -> JournalTag? {
        defaultTags.first { $0.name.lowercased() == name.lowercased() }
    }
}

// MARK: - Tag Icons

/// Available icons for custom tags
struct TagIcons {
    static let available: [String] = [
        "tag.fill",
        "bookmark.fill",
        "star.fill",
        "heart.fill",
        "flame.fill",
        "bolt.fill",
        "leaf.fill",
        "drop.fill",
        "sun.max.fill",
        "moon.fill",
        "cloud.fill",
        "sparkles",
        "hands.sparkles.fill",
        "book.fill",
        "text.alignleft",
        "lightbulb.fill",
        "brain.head.profile",
        "person.fill",
        "person.2.fill",
        "figure.walk",
        "house.fill",
        "building.2.fill",
        "cross.fill",
        "music.note",
        "camera.fill",
        "flag.fill",
        "mappin",
        "gift.fill",
        "bell.fill",
        "calendar"
    ]
}






