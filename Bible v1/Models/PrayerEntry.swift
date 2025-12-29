//
//  PrayerEntry.swift
//  Bible v1
//
//  Spiritual Hub - Prayer Journal Model
//

import Foundation

/// Categories for organizing prayers
enum PrayerCategory: String, Codable, CaseIterable, Identifiable {
    case gratitude = "Gratitude"
    case repentance = "Repentance"
    case guidance = "Guidance"
    case anxiety = "Anxiety"
    case family = "Family"
    case work = "Work"
    case health = "Health"
    case relationships = "Relationships"
    case other = "Other"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .gratitude: return "heart.fill"
        case .repentance: return "arrow.uturn.backward.circle"
        case .guidance: return "compass.drawing"
        case .anxiety: return "cloud.sun"
        case .family: return "house.fill"
        case .work: return "briefcase.fill"
        case .health: return "cross.case.fill"
        case .relationships: return "person.2.fill"
        case .other: return "ellipsis.circle"
        }
    }
    
    var color: String {
        switch self {
        case .gratitude: return "pink"
        case .repentance: return "purple"
        case .guidance: return "blue"
        case .anxiety: return "teal"
        case .family: return "orange"
        case .work: return "brown"
        case .health: return "green"
        case .relationships: return "red"
        case .other: return "gray"
        }
    }
}

/// Represents a prayer journal entry
struct PrayerEntry: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var content: String
    var category: PrayerCategory
    var isAnswered: Bool
    var answeredDate: Date?
    var answeredNote: String?
    let dateCreated: Date
    var dateModified: Date
    
    // Optional linked verse
    var linkedVerseReference: String?
    var linkedVerseText: String?
    
    init(
        id: UUID = UUID(),
        title: String,
        content: String,
        category: PrayerCategory = .other,
        isAnswered: Bool = false,
        answeredDate: Date? = nil,
        answeredNote: String? = nil,
        dateCreated: Date = Date(),
        dateModified: Date = Date(),
        linkedVerseReference: String? = nil,
        linkedVerseText: String? = nil
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.category = category
        self.isAnswered = isAnswered
        self.answeredDate = answeredDate
        self.answeredNote = answeredNote
        self.dateCreated = dateCreated
        self.dateModified = dateModified
        self.linkedVerseReference = linkedVerseReference
        self.linkedVerseText = linkedVerseText
    }
    
    /// Mark the prayer as answered
    mutating func markAnswered(note: String? = nil) {
        isAnswered = true
        answeredDate = Date()
        answeredNote = note
        dateModified = Date()
    }
    
    /// Update the prayer content
    mutating func update(title: String, content: String, category: PrayerCategory) {
        self.title = title
        self.content = content
        self.category = category
        self.dateModified = Date()
    }
    
    /// Days since the prayer was created
    var daysSinceCreated: Int {
        Calendar.current.dateComponents([.day], from: dateCreated, to: Date()).day ?? 0
    }
}

/// Guided prayer duration options
enum GuidedPrayerDuration: Int, CaseIterable, Identifiable {
    case twoMinutes = 2
    case fiveMinutes = 5
    case tenMinutes = 10
    
    var id: Int { rawValue }
    
    var displayName: String {
        "\(rawValue) min"
    }
    
    var seconds: Int {
        rawValue * 60
    }
}

/// Guided prayer session themes
enum GuidedPrayerTheme: String, Codable, CaseIterable, Identifiable {
    case gratitude = "Gratitude"
    case repentance = "Repentance"
    case guidance = "Guidance"
    case peace = "Peace & Anxiety"
    case family = "Family"
    case work = "Work & Purpose"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .gratitude: return "heart.fill"
        case .repentance: return "arrow.uturn.backward.circle"
        case .guidance: return "compass.drawing"
        case .peace: return "leaf.fill"
        case .family: return "house.fill"
        case .work: return "briefcase.fill"
        }
    }
    
    var prompts: [String] {
        switch self {
        case .gratitude:
            return [
                "Begin by taking a deep breath and centering yourself in God's presence.",
                "Think of three specific blessings from today. Thank God for each one.",
                "Consider the people who have shown you kindness. Offer thanks for them.",
                "Reflect on a challenge that became a blessing in disguise.",
                "Thank God for His constant love and faithfulness in your life.",
                "Close by expressing gratitude for this moment of prayer."
            ]
        case .repentance:
            return [
                "Come before God with a humble heart, knowing He is gracious.",
                "Ask the Holy Spirit to reveal areas where you've fallen short.",
                "Confess specific actions or attitudes that have grieved God's heart.",
                "Release any guilt or shame, accepting God's complete forgiveness.",
                "Ask for strength to turn away from these patterns.",
                "Thank God for His mercy and commit to walking in His ways."
            ]
        case .guidance:
            return [
                "Still your mind and invite God into your decision-making.",
                "Present your situation clearly to God, holding nothing back.",
                "Ask for wisdom to see the path He has prepared for you.",
                "Listen quietly for His gentle direction.",
                "Surrender your own preferences and trust His perfect plan.",
                "Thank God for being your guide and faithful counselor."
            ]
        case .peace:
            return [
                "Take a slow, deep breath. Invite God's peace into this moment.",
                "Cast your anxieties on Him, for He cares for you deeply.",
                "Name your worries one by one, releasing each to God's care.",
                "Meditate on God's promises of protection and provision.",
                "Picture yourself resting in the palm of God's hand.",
                "Receive His peace that surpasses all understanding."
            ]
        case .family:
            return [
                "Bring your family members before God's throne of grace.",
                "Pray for each person by name, lifting their specific needs.",
                "Ask for unity, love, and understanding in your home.",
                "Pray for protection over your family's hearts and minds.",
                "Ask God to heal any broken relationships or hurts.",
                "Thank God for the gift of family and His design for it."
            ]
        case .work:
            return [
                "Acknowledge God as the source of your talents and opportunities.",
                "Offer your work today as an act of worship to Him.",
                "Pray for wisdom in challenges and decisions you face.",
                "Ask God to use you as a light in your workplace.",
                "Pray for your colleagues and those you serve.",
                "Commit your plans to the Lord and trust Him with the outcomes."
            ]
        }
    }
}

/// Record of a completed guided prayer session
struct GuidedPrayerSession: Identifiable, Codable {
    let id: UUID
    let theme: GuidedPrayerTheme
    let duration: Int // in seconds
    let completedAt: Date
    var notes: String?
    
    init(
        id: UUID = UUID(),
        theme: GuidedPrayerTheme,
        duration: Int,
        completedAt: Date = Date(),
        notes: String? = nil
    ) {
        self.id = id
        self.theme = theme
        self.duration = duration
        self.completedAt = completedAt
        self.notes = notes
    }
}



