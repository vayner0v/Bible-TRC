//
//  JournalPrompt.swift
//  Bible v1
//
//  Spiritual Journal - Guided Prompts Model
//

import Foundation
import SwiftUI

/// Represents a guided journaling prompt
struct JournalPrompt: Identifiable, Codable, Hashable {
    let id: UUID
    let text: String
    let category: PromptCategory
    let relatedVerse: String?
    let relatedVerseReference: String?
    let isCustom: Bool
    let dateCreated: Date
    
    init(
        id: UUID = UUID(),
        text: String,
        category: PromptCategory,
        relatedVerse: String? = nil,
        relatedVerseReference: String? = nil,
        isCustom: Bool = false,
        dateCreated: Date = Date()
    ) {
        self.id = id
        self.text = text
        self.category = category
        self.relatedVerse = relatedVerse
        self.relatedVerseReference = relatedVerseReference
        self.isCustom = isCustom
        self.dateCreated = dateCreated
    }
}

// MARK: - Prompt Category

/// Categories for journal prompts
enum PromptCategory: String, Codable, CaseIterable, Identifiable {
    case reflection
    case gratitude
    case prayer
    case study
    case lifeApplication
    case testimony
    case confession
    case worship
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .reflection: return "Reflection"
        case .gratitude: return "Gratitude"
        case .prayer: return "Prayer"
        case .study: return "Bible Study"
        case .lifeApplication: return "Life Application"
        case .testimony: return "Testimony"
        case .confession: return "Confession"
        case .worship: return "Worship"
        }
    }
    
    var icon: String {
        switch self {
        case .reflection: return "brain.head.profile"
        case .gratitude: return "heart.fill"
        case .prayer: return "hands.sparkles.fill"
        case .study: return "book.fill"
        case .lifeApplication: return "lightbulb.fill"
        case .testimony: return "star.fill"
        case .confession: return "arrow.uturn.backward"
        case .worship: return "music.note"
        }
    }
    
    var color: Color {
        switch self {
        case .reflection: return .indigo
        case .gratitude: return .pink
        case .prayer: return .purple
        case .study: return .blue
        case .lifeApplication: return .mint
        case .testimony: return .orange
        case .confession: return .teal
        case .worship: return .yellow
        }
    }
    
    var description: String {
        switch self {
        case .reflection: return "Contemplate God's word and its meaning"
        case .gratitude: return "Express thankfulness for God's blessings"
        case .prayer: return "Write out prayers and petitions"
        case .study: return "Deep dive into scripture passages"
        case .lifeApplication: return "Apply biblical truths to daily life"
        case .testimony: return "Share what God has done in your life"
        case .confession: return "Acknowledge sins and seek forgiveness"
        case .worship: return "Express praise and adoration to God"
        }
    }
}

// MARK: - Default Prompts

extension JournalPrompt {
    /// Default prompts organized by category
    static let defaultPrompts: [JournalPrompt] = [
        // Reflection
        JournalPrompt(
            text: "What verse or passage spoke to you today, and why?",
            category: .reflection
        ),
        JournalPrompt(
            text: "How has God revealed Himself to you this week?",
            category: .reflection
        ),
        JournalPrompt(
            text: "What area of your life is God asking you to surrender?",
            category: .reflection
        ),
        JournalPrompt(
            text: "How have you grown spiritually in the past month?",
            category: .reflection
        ),
        JournalPrompt(
            text: "What does your relationship with God look like right now?",
            category: .reflection
        ),
        
        // Gratitude
        JournalPrompt(
            text: "List five blessings you've experienced today.",
            category: .gratitude,
            relatedVerse: "Give thanks in all circumstances; for this is God's will for you in Christ Jesus.",
            relatedVerseReference: "1 Thessalonians 5:18"
        ),
        JournalPrompt(
            text: "Who has God placed in your life to be thankful for?",
            category: .gratitude
        ),
        JournalPrompt(
            text: "What unexpected blessing surprised you recently?",
            category: .gratitude
        ),
        JournalPrompt(
            text: "How has God provided for you during a difficult time?",
            category: .gratitude
        ),
        JournalPrompt(
            text: "What simple pleasure reminds you of God's goodness?",
            category: .gratitude
        ),
        
        // Prayer
        JournalPrompt(
            text: "What are you bringing before God in prayer today?",
            category: .prayer,
            relatedVerse: "Do not be anxious about anything, but in every situation, by prayer and petition, with thanksgiving, present your requests to God.",
            relatedVerseReference: "Philippians 4:6"
        ),
        JournalPrompt(
            text: "Write a prayer of surrender for an area you're struggling with.",
            category: .prayer
        ),
        JournalPrompt(
            text: "Who needs your prayers today, and how can you pray for them?",
            category: .prayer
        ),
        JournalPrompt(
            text: "How has God answered a prayer recently?",
            category: .prayer
        ),
        JournalPrompt(
            text: "Write a prayer expressing your deepest desire to God.",
            category: .prayer
        ),
        
        // Bible Study
        JournalPrompt(
            text: "What is the context of the passage you're reading? Who wrote it and why?",
            category: .study
        ),
        JournalPrompt(
            text: "What does this passage reveal about God's character?",
            category: .study
        ),
        JournalPrompt(
            text: "How does this scripture connect to other parts of the Bible?",
            category: .study
        ),
        JournalPrompt(
            text: "What key words or themes stand out in today's reading?",
            category: .study
        ),
        JournalPrompt(
            text: "What questions do you have about this passage?",
            category: .study
        ),
        
        // Life Application
        JournalPrompt(
            text: "How can you apply what you read today to your life this week?",
            category: .lifeApplication,
            relatedVerse: "But be doers of the word, and not hearers only, deceiving yourselves.",
            relatedVerseReference: "James 1:22"
        ),
        JournalPrompt(
            text: "What is one practical step you can take based on today's scripture?",
            category: .lifeApplication
        ),
        JournalPrompt(
            text: "How does this passage challenge your current habits or attitudes?",
            category: .lifeApplication
        ),
        JournalPrompt(
            text: "What would change if you fully lived out this teaching?",
            category: .lifeApplication
        ),
        JournalPrompt(
            text: "How can you share what you've learned with someone else?",
            category: .lifeApplication
        ),
        
        // Testimony
        JournalPrompt(
            text: "Describe a time when you clearly saw God working in your life.",
            category: .testimony
        ),
        JournalPrompt(
            text: "How has your faith journey changed who you are?",
            category: .testimony
        ),
        JournalPrompt(
            text: "What would you tell someone about who God is based on your experience?",
            category: .testimony
        ),
        JournalPrompt(
            text: "When did you feel closest to God, and what was happening?",
            category: .testimony
        ),
        JournalPrompt(
            text: "How has God brought beauty from a difficult situation in your life?",
            category: .testimony
        ),
        
        // Confession
        JournalPrompt(
            text: "Is there anything you need to confess to God today?",
            category: .confession,
            relatedVerse: "If we confess our sins, he is faithful and just and will forgive us our sins and purify us from all unrighteousness.",
            relatedVerseReference: "1 John 1:9"
        ),
        JournalPrompt(
            text: "What patterns of sin do you need God's help to overcome?",
            category: .confession
        ),
        JournalPrompt(
            text: "Who do you need to forgive, and what's holding you back?",
            category: .confession
        ),
        JournalPrompt(
            text: "Where have you been trying to control instead of trusting God?",
            category: .confession
        ),
        
        // Worship
        JournalPrompt(
            text: "Write out a prayer of praise to God for who He is.",
            category: .worship,
            relatedVerse: "Let everything that has breath praise the Lord.",
            relatedVerseReference: "Psalm 150:6"
        ),
        JournalPrompt(
            text: "What attributes of God are you most in awe of today?",
            category: .worship
        ),
        JournalPrompt(
            text: "How can you worship God through your actions today?",
            category: .worship
        ),
        JournalPrompt(
            text: "Write about a moment when you felt overwhelmed by God's love.",
            category: .worship
        )
    ]
    
    /// Get prompts by category
    static func prompts(for category: PromptCategory) -> [JournalPrompt] {
        defaultPrompts.filter { $0.category == category }
    }
    
    /// Get a random prompt
    static var randomPrompt: JournalPrompt {
        defaultPrompts.randomElement() ?? defaultPrompts[0]
    }
    
    /// Get today's prompt (rotates daily)
    static var todaysPrompt: JournalPrompt {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        let index = dayOfYear % defaultPrompts.count
        return defaultPrompts[index]
    }
    
    /// Get a prompt suggestion based on mood
    static func prompt(for mood: JournalMood) -> JournalPrompt {
        switch mood {
        case .joyful, .grateful:
            return prompts(for: .gratitude).randomElement() ?? todaysPrompt
        case .peaceful:
            return prompts(for: .worship).randomElement() ?? todaysPrompt
        case .hopeful:
            return prompts(for: .testimony).randomElement() ?? todaysPrompt
        case .reflective:
            return prompts(for: .reflection).randomElement() ?? todaysPrompt
        case .anxious:
            return prompts(for: .prayer).randomElement() ?? todaysPrompt
        case .struggling:
            return prompts(for: .confession).randomElement() ?? todaysPrompt
        }
    }
}






