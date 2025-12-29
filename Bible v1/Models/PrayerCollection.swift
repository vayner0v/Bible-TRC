//
//  PrayerCollection.swift
//  Bible v1
//
//  Spiritual Hub - Prayer Library Collection Model
//

import Foundation
import SwiftUI

/// Predefined collection types
enum PrayerCollectionType: String, Codable, CaseIterable, Identifiable {
    case morning = "Morning Prayers"
    case evening = "Evening Prayers"
    case family = "Family Prayers"
    case healing = "Prayers for Healing"
    case guidance = "Prayers for Guidance"
    case thanksgiving = "Thanksgiving Prayers"
    case protection = "Prayers for Protection"
    case custom = "Custom Collection"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .morning: return "sunrise.fill"
        case .evening: return "moon.stars.fill"
        case .family: return "house.fill"
        case .healing: return "cross.case.fill"
        case .guidance: return "compass.drawing"
        case .thanksgiving: return "heart.fill"
        case .protection: return "shield.fill"
        case .custom: return "folder.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .morning: return .orange
        case .evening: return .indigo
        case .family: return .brown
        case .healing: return .green
        case .guidance: return .blue
        case .thanksgiving: return .pink
        case .protection: return .teal
        case .custom: return .gray
        }
    }
}

/// A saved prayer in the library
struct SavedPrayer: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var content: String
    var sourceVerseReference: String?
    var sourceVerseText: String?
    var tags: [String]
    var isFavorite: Bool
    let createdAt: Date
    var lastUsedAt: Date?
    var usageCount: Int
    var isPrivate: Bool
    
    init(
        id: UUID = UUID(),
        title: String,
        content: String,
        sourceVerseReference: String? = nil,
        sourceVerseText: String? = nil,
        tags: [String] = [],
        isFavorite: Bool = false,
        createdAt: Date = Date(),
        lastUsedAt: Date? = nil,
        usageCount: Int = 0,
        isPrivate: Bool = false
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.sourceVerseReference = sourceVerseReference
        self.sourceVerseText = sourceVerseText
        self.tags = tags
        self.isFavorite = isFavorite
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
        self.usageCount = usageCount
        self.isPrivate = isPrivate
    }
    
    /// Create from scripture prayer
    init(from scripturePrayer: ScripturePrayer, title: String? = nil) {
        self.id = UUID()
        self.title = title ?? "Prayer from \(scripturePrayer.verseReference)"
        self.content = scripturePrayer.prayerText
        self.sourceVerseReference = scripturePrayer.verseReference
        self.sourceVerseText = scripturePrayer.verseText
        self.tags = scripturePrayer.tags
        self.isFavorite = scripturePrayer.isFavorite
        self.createdAt = Date()
        self.lastUsedAt = nil
        self.usageCount = 0
        self.isPrivate = false
    }
    
    /// Record usage
    mutating func recordUsage() {
        usageCount += 1
        lastUsedAt = Date()
    }
    
    /// Toggle favorite
    mutating func toggleFavorite() {
        isFavorite.toggle()
    }
}

/// A collection of saved prayers
struct PrayerCollection: Identifiable, Codable {
    let id: UUID
    var name: String
    var collectionType: PrayerCollectionType
    var prayerIds: [UUID]
    var icon: String
    var colorName: String
    let createdAt: Date
    var modifiedAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        collectionType: PrayerCollectionType = .custom,
        prayerIds: [UUID] = [],
        icon: String? = nil,
        colorName: String? = nil,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.collectionType = collectionType
        self.prayerIds = prayerIds
        self.icon = icon ?? collectionType.icon
        self.colorName = colorName ?? "blue"
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
    
    /// Create from predefined type
    init(type: PrayerCollectionType) {
        self.id = UUID()
        self.name = type.rawValue
        self.collectionType = type
        self.prayerIds = []
        self.icon = type.icon
        self.colorName = type.color.description
        self.createdAt = Date()
        self.modifiedAt = Date()
    }
    
    /// Add prayer to collection
    mutating func addPrayer(_ prayerId: UUID) {
        if !prayerIds.contains(prayerId) {
            prayerIds.append(prayerId)
            modifiedAt = Date()
        }
    }
    
    /// Remove prayer from collection
    mutating func removePrayer(_ prayerId: UUID) {
        prayerIds.removeAll { $0 == prayerId }
        modifiedAt = Date()
    }
    
    /// Number of prayers
    var prayerCount: Int {
        prayerIds.count
    }
}

/// Default prayers that come with the app
struct DefaultPrayer {
    static let serenityPrayer = SavedPrayer(
        title: "Serenity Prayer",
        content: """
        God, grant me the serenity
        to accept the things I cannot change,
        the courage to change the things I can,
        and the wisdom to know the difference.
        
        Living one day at a time,
        enjoying one moment at a time;
        accepting hardship as a pathway to peace;
        taking, as Jesus did,
        this sinful world as it is,
        not as I would have it;
        trusting that You will make all things right
        if I surrender to Your will;
        so that I may be reasonably happy in this life
        and supremely happy with You forever in the next.
        
        Amen.
        """,
        tags: ["classic", "peace", "surrender"]
    )
    
    static let lordsPrayer = SavedPrayer(
        title: "The Lord's Prayer",
        content: """
        Our Father, who art in heaven,
        hallowed be thy name;
        thy kingdom come;
        thy will be done;
        on earth as it is in heaven.
        Give us this day our daily bread.
        And forgive us our trespasses,
        as we forgive those who trespass against us.
        And lead us not into temptation;
        but deliver us from evil.
        For thine is the kingdom,
        the power and the glory,
        for ever and ever.
        
        Amen.
        """,
        sourceVerseReference: "Matthew 6:9-13",
        tags: ["classic", "Jesus", "model prayer"]
    )
    
    static let stFrancis = SavedPrayer(
        title: "Prayer of St. Francis",
        content: """
        Lord, make me an instrument of your peace:
        where there is hatred, let me sow love;
        where there is injury, pardon;
        where there is doubt, faith;
        where there is despair, hope;
        where there is darkness, light;
        where there is sadness, joy.
        
        O divine Master, grant that I may not so much seek
        to be consoled as to console,
        to be understood as to understand,
        to be loved as to love.
        For it is in giving that we receive,
        it is in pardoning that we are pardoned,
        and it is in dying that we are born to eternal life.
        
        Amen.
        """,
        tags: ["classic", "service", "peace"]
    )
    
    static let morningPrayer = SavedPrayer(
        title: "Morning Offering",
        content: """
        Lord, I offer You this day:
        all my thoughts, words, and actions.
        
        Guide my steps, guard my heart,
        and use me for Your glory.
        
        Help me to see others through Your eyes,
        to speak with Your grace,
        and to love with Your heart.
        
        May this day bring honor to Your name.
        
        Amen.
        """,
        tags: ["morning", "dedication"]
    )
    
    static let eveningPrayer = SavedPrayer(
        title: "Evening Rest",
        content: """
        Lord, as this day comes to an end,
        I release its worries into Your hands.
        
        Thank You for Your presence today,
        for the blessings both seen and unseen.
        
        Forgive where I fell short,
        and help me rest in Your peace.
        
        Watch over me through the night,
        and grant me renewed strength for tomorrow.
        
        Amen.
        """,
        tags: ["evening", "rest", "peace"]
    )
    
    static let allDefaults: [SavedPrayer] = [
        lordsPrayer,
        serenityPrayer,
        stFrancis,
        morningPrayer,
        eveningPrayer
    ]
}



