//
//  Mission.swift
//  Bible v1
//
//  Spiritual Hub - Missions System Model
//

import Foundation
import SwiftUI

/// Types of missions
enum MissionType: String, Codable, CaseIterable, Identifiable {
    case service = "Acts of Service"
    case character = "Character Growth"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .service: return "hand.raised.fill"
        case .character: return "person.fill.checkmark"
        }
    }
    
    var color: Color {
        switch self {
        case .service: return .orange
        case .character: return .teal
        }
    }
    
    var description: String {
        switch self {
        case .service: return "Practical ways to show God's love to others"
        case .character: return "Daily practices to develop Christ-like character"
        }
    }
}

/// Categories for service missions
enum ServiceCategory: String, Codable, CaseIterable, Identifiable {
    case forgiveness = "Forgiveness"
    case generosity = "Generosity"
    case connection = "Connection"
    case volunteering = "Volunteering"
    case encouragement = "Encouragement"
    case kindness = "Kindness"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .forgiveness: return "heart.circle"
        case .generosity: return "gift.fill"
        case .connection: return "phone.fill"
        case .volunteering: return "person.3.fill"
        case .encouragement: return "text.bubble.fill"
        case .kindness: return "hands.clap.fill"
        }
    }
}

/// Categories for character missions
enum CharacterCategory: String, Codable, CaseIterable, Identifiable {
    case patience = "Patience"
    case selfControl = "Self-Control"
    case kindness = "Kindness"
    case humility = "Humility"
    case gratitude = "Gratitude"
    case faithfulness = "Faithfulness"
    case gentleness = "Gentleness"
    case love = "Love"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .patience: return "clock.fill"
        case .selfControl: return "hand.raised.slash.fill"
        case .kindness: return "heart.fill"
        case .humility: return "figure.walk"
        case .gratitude: return "sparkles"
        case .faithfulness: return "shield.fill"
        case .gentleness: return "leaf.fill"
        case .love: return "heart.circle.fill"
        }
    }
    
    var relatedVerse: (reference: String, text: String) {
        switch self {
        case .patience:
            return ("James 1:4", "Let patience have its perfect work, that you may be perfect and complete, lacking nothing.")
        case .selfControl:
            return ("Galatians 5:22-23", "The fruit of the Spirit is... self-control.")
        case .kindness:
            return ("Ephesians 4:32", "Be kind to one another, tenderhearted, forgiving one another.")
        case .humility:
            return ("Philippians 2:3", "In humility count others more significant than yourselves.")
        case .gratitude:
            return ("1 Thessalonians 5:18", "Give thanks in all circumstances.")
        case .faithfulness:
            return ("Proverbs 3:3", "Let not steadfast love and faithfulness forsake you.")
        case .gentleness:
            return ("Proverbs 15:1", "A gentle answer turns away wrath.")
        case .love:
            return ("1 John 4:19", "We love because he first loved us.")
        }
    }
}

/// A mission definition
struct Mission: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let type: MissionType
    let serviceCategoryRaw: String?
    let characterCategoryRaw: String?
    let suggestedActions: [String]
    let reflectionPrompt: String
    let relatedVerseReference: String
    let relatedVerseText: String
    let difficulty: MissionDifficulty
    
    var serviceCategory: ServiceCategory? {
        guard let raw = serviceCategoryRaw else { return nil }
        return ServiceCategory(rawValue: raw)
    }
    
    var characterCategory: CharacterCategory? {
        guard let raw = characterCategoryRaw else { return nil }
        return CharacterCategory(rawValue: raw)
    }
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        type: MissionType,
        serviceCategory: ServiceCategory? = nil,
        characterCategory: CharacterCategory? = nil,
        suggestedActions: [String],
        reflectionPrompt: String,
        relatedVerseReference: String,
        relatedVerseText: String,
        difficulty: MissionDifficulty = .medium
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.type = type
        self.serviceCategoryRaw = serviceCategory?.rawValue
        self.characterCategoryRaw = characterCategory?.rawValue
        self.suggestedActions = suggestedActions
        self.reflectionPrompt = reflectionPrompt
        self.relatedVerseReference = relatedVerseReference
        self.relatedVerseText = relatedVerseText
        self.difficulty = difficulty
    }
}

/// Mission difficulty levels
enum MissionDifficulty: String, Codable, CaseIterable {
    case easy = "Easy"
    case medium = "Medium"
    case challenging = "Challenging"
    
    var color: Color {
        switch self {
        case .easy: return .green
        case .medium: return .orange
        case .challenging: return .red
        }
    }
}

/// A completed mission entry
struct MissionCompletion: Identifiable, Codable {
    let id: UUID
    let missionId: UUID
    let missionTitle: String
    let completedAt: Date
    var reflection: String?
    var experienceNotes: String?
    
    init(
        id: UUID = UUID(),
        missionId: UUID,
        missionTitle: String,
        completedAt: Date = Date(),
        reflection: String? = nil,
        experienceNotes: String? = nil
    ) {
        self.id = id
        self.missionId = missionId
        self.missionTitle = missionTitle
        self.completedAt = completedAt
        self.reflection = reflection
        self.experienceNotes = experienceNotes
    }
}

/// Static mission content
extension Mission {
    
    // MARK: - Service Missions
    
    static let serviceMissions: [Mission] = [
        // Forgiveness
        Mission(
            title: "Release and Forgive",
            description: "Extend forgiveness to someone who has wronged you",
            type: .service,
            serviceCategory: .forgiveness,
            suggestedActions: [
                "Pray for someone who hurt you",
                "Write a letter of forgiveness (send or keep)",
                "Let go of a grudge you've been holding",
                "Choose not to bring up a past offense"
            ],
            reflectionPrompt: "How did it feel to release this burden? What did God teach you?",
            relatedVerseReference: "Colossians 3:13",
            relatedVerseText: "Bear with each other and forgive one another if any of you has a grievance against someone. Forgive as the Lord forgave you."
        ),
        
        // Generosity
        Mission(
            title: "Give Generously",
            description: "Practice unexpected generosity today",
            type: .service,
            serviceCategory: .generosity,
            suggestedActions: [
                "Pay for someone's coffee or meal",
                "Give a generous tip",
                "Donate to someone in need",
                "Share something valuable with others"
            ],
            reflectionPrompt: "How did giving change your perspective today?",
            relatedVerseReference: "2 Corinthians 9:7",
            relatedVerseText: "Each of you should give what you have decided in your heart to give, not reluctantly or under compulsion, for God loves a cheerful giver."
        ),
        
        // Connection
        Mission(
            title: "Reach Out",
            description: "Connect with someone who might be lonely or struggling",
            type: .service,
            serviceCategory: .connection,
            suggestedActions: [
                "Call a family member you haven't talked to",
                "Visit someone who is isolated",
                "Send an encouraging text to a friend",
                "Have lunch with someone who sits alone"
            ],
            reflectionPrompt: "What did you learn from this connection?",
            relatedVerseReference: "Hebrews 10:24-25",
            relatedVerseText: "And let us consider how we may spur one another on toward love and good deeds, not giving up meeting together."
        ),
        
        // Encouragement
        Mission(
            title: "Speak Life",
            description: "Intentionally encourage someone today",
            type: .service,
            serviceCategory: .encouragement,
            suggestedActions: [
                "Write a thank-you note",
                "Compliment someone sincerely",
                "Share how someone has impacted your life",
                "Encourage someone facing difficulty"
            ],
            reflectionPrompt: "How did your words affect others and yourself?",
            relatedVerseReference: "Proverbs 16:24",
            relatedVerseText: "Gracious words are a honeycomb, sweet to the soul and healing to the bones."
        ),
        
        // Kindness
        Mission(
            title: "Random Kindness",
            description: "Perform an unexpected act of kindness",
            type: .service,
            serviceCategory: .kindness,
            suggestedActions: [
                "Help someone with a task",
                "Hold the door for others",
                "Let someone go ahead of you",
                "Leave an encouraging note for a stranger"
            ],
            reflectionPrompt: "How did this small act create ripples of kindness?",
            relatedVerseReference: "Galatians 6:10",
            relatedVerseText: "Therefore, as we have opportunity, let us do good to all people."
        ),
        
        // Volunteering
        Mission(
            title: "Serve Your Community",
            description: "Give your time to serve others",
            type: .service,
            serviceCategory: .volunteering,
            suggestedActions: [
                "Volunteer at a local organization",
                "Help a neighbor with yardwork",
                "Serve at your church",
                "Organize donations for those in need"
            ],
            reflectionPrompt: "What did you discover through serving?",
            relatedVerseReference: "Mark 10:45",
            relatedVerseText: "For even the Son of Man did not come to be served, but to serve."
        )
    ]
    
    // MARK: - Character Missions
    
    static let characterMissions: [Mission] = [
        // Patience
        Mission(
            title: "Practice Patience",
            description: "Respond with patience instead of frustration",
            type: .character,
            characterCategory: .patience,
            suggestedActions: [
                "When delayed, pray instead of complaining",
                "Listen fully before responding",
                "Wait without checking your phone",
                "Let someone take their time"
            ],
            reflectionPrompt: "Where did you see God working through your patience?",
            relatedVerseReference: "James 1:4",
            relatedVerseText: "Let patience have its perfect work, that you may be perfect and complete, lacking nothing."
        ),
        
        // Self-Control
        Mission(
            title: "Exercise Self-Control",
            description: "Practice restraint in a specific area today",
            type: .character,
            characterCategory: .selfControl,
            suggestedActions: [
                "Fast from social media for a day",
                "Choose silence instead of a sharp reply",
                "Skip an indulgence and pray instead",
                "Control your thoughts when tempted"
            ],
            reflectionPrompt: "How did self-control strengthen your spirit?",
            relatedVerseReference: "Proverbs 25:28",
            relatedVerseText: "Like a city whose walls are broken through is a person who lacks self-control."
        ),
        
        // Kindness
        Mission(
            title: "Cultivate Kindness",
            description: "Let kindness guide all your interactions",
            type: .character,
            characterCategory: .kindness,
            suggestedActions: [
                "Respond gently to a difficult person",
                "Find something good to say about everyone",
                "Go out of your way to help",
                "Choose kindness over being right"
            ],
            reflectionPrompt: "How did intentional kindness change your day?",
            relatedVerseReference: "Ephesians 4:32",
            relatedVerseText: "Be kind to one another, tenderhearted, forgiving one another, as God in Christ forgave you."
        ),
        
        // Humility
        Mission(
            title: "Walk Humbly",
            description: "Practice humility in your interactions",
            type: .character,
            characterCategory: .humility,
            suggestedActions: [
                "Admit when you're wrong",
                "Let someone else receive credit",
                "Ask for help when you need it",
                "Serve without seeking recognition"
            ],
            reflectionPrompt: "What did humility teach you about yourself?",
            relatedVerseReference: "Philippians 2:3",
            relatedVerseText: "Do nothing out of selfish ambition or vain conceit. Rather, in humility value others above yourselves."
        ),
        
        // Gratitude
        Mission(
            title: "Live Gratefully",
            description: "Approach everything with a grateful heart",
            type: .character,
            characterCategory: .gratitude,
            suggestedActions: [
                "Thank God for 10 specific things",
                "Express thanks to people around you",
                "Find gratitude in a difficult situation",
                "Keep a gratitude log all day"
            ],
            reflectionPrompt: "How did gratitude shift your perspective?",
            relatedVerseReference: "1 Thessalonians 5:18",
            relatedVerseText: "Give thanks in all circumstances; for this is God's will for you in Christ Jesus."
        ),
        
        // Love
        Mission(
            title: "Love Unconditionally",
            description: "Show love without expecting anything in return",
            type: .character,
            characterCategory: .love,
            suggestedActions: [
                "Do something loving for someone difficult",
                "Love through actions, not just words",
                "Pray for someone you struggle to love",
                "Show love to a stranger"
            ],
            reflectionPrompt: "How did loving others draw you closer to God?",
            relatedVerseReference: "1 John 4:19",
            relatedVerseText: "We love because he first loved us."
        )
    ]
    
    static let allMissions: [Mission] = serviceMissions + characterMissions
    
    /// Get mission of the day based on date
    static func missionOfTheDay(for date: Date = Date()) -> Mission {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
        let index = (dayOfYear - 1) % allMissions.count
        return allMissions[index]
    }
}



