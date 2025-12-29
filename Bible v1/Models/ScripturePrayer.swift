//
//  ScripturePrayer.swift
//  Bible v1
//
//  Spiritual Hub - Scripture-backed Prayer Model
//

import Foundation
import SwiftUI

/// Types of prayer templates based on verse themes
enum PrayerTemplateType: String, Codable, CaseIterable, Identifiable {
    case praise = "Praise"
    case thanksgiving = "Thanksgiving"
    case petition = "Petition"
    case confession = "Confession"
    case intercession = "Intercession"
    case surrender = "Surrender"
    case declaration = "Declaration"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .praise: return "hands.sparkles"
        case .thanksgiving: return "heart.fill"
        case .petition: return "hand.raised.fill"
        case .confession: return "arrow.uturn.backward.circle"
        case .intercession: return "person.2.fill"
        case .surrender: return "leaf.fill"
        case .declaration: return "megaphone.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .praise: return .yellow
        case .thanksgiving: return .pink
        case .petition: return .blue
        case .confession: return .teal
        case .intercession: return .orange
        case .surrender: return .teal
        case .declaration: return .indigo
        }
    }
    
    var description: String {
        switch self {
        case .praise:
            return "Exalt God for who He is"
        case .thanksgiving:
            return "Thank God for what He's done"
        case .petition:
            return "Bring your requests to God"
        case .confession:
            return "Acknowledge sin and receive forgiveness"
        case .intercession:
            return "Pray on behalf of others"
        case .surrender:
            return "Release control to God"
        case .declaration:
            return "Speak God's truth over your life"
        }
    }
    
    /// Prayer structure prompts for this type
    var prompts: [String] {
        switch self {
        case .praise:
            return [
                "Lord, I praise You because...",
                "Your character reveals...",
                "I worship You for Your...",
                "May my life reflect Your glory."
            ]
        case .thanksgiving:
            return [
                "Thank You, Lord, for...",
                "I'm grateful that You have...",
                "Your blessings in my life include...",
                "Help me live with a thankful heart."
            ]
        case .petition:
            return [
                "Lord, I bring before You...",
                "I ask that You would...",
                "Please provide/guide/heal...",
                "I trust Your answer and timing."
            ]
        case .confession:
            return [
                "Lord, I confess that I have...",
                "Forgive me for...",
                "Create in me a clean heart...",
                "Help me walk in Your ways."
            ]
        case .intercession:
            return [
                "Lord, I lift up [person/situation]...",
                "Please bring Your peace/healing/provision to...",
                "Surround them with Your love...",
                "May Your will be done in their life."
            ]
        case .surrender:
            return [
                "Lord, I release to You...",
                "I surrender my desire for...",
                "Take control of...",
                "Your will, not mine, be done."
            ]
        case .declaration:
            return [
                "I declare that God is...",
                "According to Your Word, I am...",
                "I stand on the truth that...",
                "By faith, I proclaim..."
            ]
        }
    }
}

/// A prayer generated from or inspired by Scripture
struct ScripturePrayer: Identifiable, Codable, Hashable {
    let id: UUID
    let verseReference: String
    let verseText: String
    var prayerText: String
    let templateType: PrayerTemplateType
    let createdAt: Date
    var isFavorite: Bool
    var tags: [String]
    var lastUsedAt: Date?
    var usageCount: Int
    
    init(
        id: UUID = UUID(),
        verseReference: String,
        verseText: String,
        prayerText: String,
        templateType: PrayerTemplateType,
        createdAt: Date = Date(),
        isFavorite: Bool = false,
        tags: [String] = [],
        lastUsedAt: Date? = nil,
        usageCount: Int = 0
    ) {
        self.id = id
        self.verseReference = verseReference
        self.verseText = verseText
        self.prayerText = prayerText
        self.templateType = templateType
        self.createdAt = createdAt
        self.isFavorite = isFavorite
        self.tags = tags
        self.lastUsedAt = lastUsedAt
        self.usageCount = usageCount
    }
    
    /// Record usage of this prayer
    mutating func recordUsage() {
        usageCount += 1
        lastUsedAt = Date()
    }
    
    /// Toggle favorite status
    mutating func toggleFavorite() {
        isFavorite.toggle()
    }
    
    /// Generate prayer text from verse
    static func generatePrayer(from verse: String, reference: String, type: PrayerTemplateType) -> String {
        // This generates a structured prayer based on the verse and type
        let opener: String
        let body: String
        let closer: String
        
        switch type {
        case .praise:
            opener = "Heavenly Father, I praise You today."
            body = "Your Word in \(reference) reminds me: \"\(verse)\" Lord, I lift my voice in worship for who You are — faithful, loving, and mighty."
            closer = "May my life be a living praise to Your name. Amen."
            
        case .thanksgiving:
            opener = "Lord, I come before You with a grateful heart."
            body = "Thank You for the truth in \(reference): \"\(verse)\" I'm thankful for Your faithfulness and the many ways You've blessed my life."
            closer = "Help me live each day with thanksgiving. Amen."
            
        case .petition:
            opener = "Father, I bring my requests before Your throne."
            body = "Your Word says in \(reference): \"\(verse)\" Based on this promise, I ask that You would move in my situation according to Your perfect will."
            closer = "I trust in Your timing and Your ways. Amen."
            
        case .confession:
            opener = "Merciful God, I come humbly before You."
            body = "Your Word in \(reference) teaches: \"\(verse)\" Lord, I confess where I have fallen short. Forgive me and cleanse me from all unrighteousness."
            closer = "Create in me a clean heart and renew a right spirit within me. Amen."
            
        case .intercession:
            opener = "Lord, I lift others before Your throne of grace."
            body = "According to \(reference): \"\(verse)\" I pray for those in need — for Your peace, healing, and provision to flow into their lives."
            closer = "Let Your will be done in their circumstances. Amen."
            
        case .surrender:
            opener = "Father, I surrender all to You."
            body = "Your Word in \(reference) says: \"\(verse)\" I release my grip on my plans, fears, and desires. Take control of every area of my life."
            closer = "Not my will, but Yours be done. Amen."
            
        case .declaration:
            opener = "In Jesus' name, I declare over my life:"
            body = "According to \(reference): \"\(verse)\" I stand on this truth. I am who God says I am. I can do what God says I can do."
            closer = "I speak life and faith over my circumstances. Amen."
        }
        
        return "\(opener)\n\n\(body)\n\n\(closer)"
    }
}

/// Quick prayer templates for common situations
struct QuickPrayerTemplate: Identifiable {
    let id: UUID
    let title: String
    let suggestedVerse: String
    let verseReference: String
    let templateType: PrayerTemplateType
    
    init(
        id: UUID = UUID(),
        title: String,
        suggestedVerse: String,
        verseReference: String,
        templateType: PrayerTemplateType
    ) {
        self.id = id
        self.title = title
        self.suggestedVerse = suggestedVerse
        self.verseReference = verseReference
        self.templateType = templateType
    }
    
    static let templates: [QuickPrayerTemplate] = [
        QuickPrayerTemplate(
            title: "When Anxious",
            suggestedVerse: "Cast all your anxiety on him because he cares for you.",
            verseReference: "1 Peter 5:7",
            templateType: .surrender
        ),
        QuickPrayerTemplate(
            title: "For Guidance",
            suggestedVerse: "Trust in the Lord with all your heart and lean not on your own understanding.",
            verseReference: "Proverbs 3:5",
            templateType: .petition
        ),
        QuickPrayerTemplate(
            title: "For Strength",
            suggestedVerse: "I can do all things through Christ who strengthens me.",
            verseReference: "Philippians 4:13",
            templateType: .declaration
        ),
        QuickPrayerTemplate(
            title: "For Others",
            suggestedVerse: "Therefore I tell you, whatever you ask for in prayer, believe that you have received it.",
            verseReference: "Mark 11:24",
            templateType: .intercession
        ),
        QuickPrayerTemplate(
            title: "Morning Praise",
            suggestedVerse: "This is the day the Lord has made; let us rejoice and be glad in it.",
            verseReference: "Psalm 118:24",
            templateType: .praise
        ),
        QuickPrayerTemplate(
            title: "Evening Thanks",
            suggestedVerse: "Give thanks to the Lord, for he is good; his love endures forever.",
            verseReference: "Psalm 107:1",
            templateType: .thanksgiving
        )
    ]
}



