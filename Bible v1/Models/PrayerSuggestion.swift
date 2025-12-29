//
//  PrayerSuggestion.swift
//  Bible v1
//
//  Smart prayer suggestion engine based on mood, time, and context
//

import Foundation
import SwiftUI

// MARK: - Prayer Suggestion Category

/// Categories for smart prayer suggestions
enum PrayerSuggestionCategory: String, Codable, CaseIterable, Identifiable {
    case peace
    case strength
    case gratitude
    case healing
    case guidance
    case protection
    case forgiveness
    case anxiety
    case morning
    case evening
    case family
    case work
    case relationships
    case faith
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .peace: return "Peace"
        case .strength: return "Strength"
        case .gratitude: return "Gratitude"
        case .healing: return "Healing"
        case .guidance: return "Guidance"
        case .protection: return "Protection"
        case .forgiveness: return "Forgiveness"
        case .anxiety: return "Anxiety Relief"
        case .morning: return "Morning"
        case .evening: return "Evening"
        case .family: return "Family"
        case .work: return "Work & Career"
        case .relationships: return "Relationships"
        case .faith: return "Faith & Trust"
        }
    }
    
    var icon: String {
        switch self {
        case .peace: return "leaf.fill"
        case .strength: return "bolt.fill"
        case .gratitude: return "heart.fill"
        case .healing: return "cross.fill"
        case .guidance: return "star.fill"
        case .protection: return "shield.fill"
        case .forgiveness: return "heart.circle.fill"
        case .anxiety: return "wind"
        case .morning: return "sunrise.fill"
        case .evening: return "moon.stars.fill"
        case .family: return "house.fill"
        case .work: return "briefcase.fill"
        case .relationships: return "person.2.fill"
        case .faith: return "hands.sparkles"
        }
    }
    
    var color: Color {
        switch self {
        case .peace: return .mint
        case .strength: return .orange
        case .gratitude: return .pink
        case .healing: return .red
        case .guidance: return .yellow
        case .protection: return .blue
        case .forgiveness: return .teal
        case .anxiety: return .cyan
        case .morning: return .orange
        case .evening: return .indigo
        case .family: return .green
        case .work: return .brown
        case .relationships: return .pink
        case .faith: return .violet
        }
    }
    
    var gradient: [Color] {
        [color.opacity(0.8), color.opacity(0.4)]
    }
}

// MARK: - Prayer Feeling

/// User feelings for prayer suggestions
enum PrayerFeeling: String, Codable, CaseIterable, Identifiable {
    case anxious
    case grateful
    case sad
    case hopeful
    case overwhelmed
    case peaceful
    case confused
    case joyful
    case angry
    case lonely
    case tired
    case blessed
    
    var id: String { rawValue }
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var emoji: String {
        switch self {
        case .anxious: return "😰"
        case .grateful: return "🙏"
        case .sad: return "😢"
        case .hopeful: return "🌟"
        case .overwhelmed: return "😫"
        case .peaceful: return "😌"
        case .confused: return "🤔"
        case .joyful: return "😊"
        case .angry: return "😤"
        case .lonely: return "🥺"
        case .tired: return "😴"
        case .blessed: return "✨"
        }
    }
    
    var suggestedCategories: [PrayerSuggestionCategory] {
        switch self {
        case .anxious: return [.peace, .anxiety, .protection]
        case .grateful: return [.gratitude, .faith]
        case .sad: return [.healing, .strength, .peace]
        case .hopeful: return [.faith, .guidance, .gratitude]
        case .overwhelmed: return [.strength, .peace, .guidance]
        case .peaceful: return [.gratitude, .peace, .faith]
        case .confused: return [.guidance, .faith, .peace]
        case .joyful: return [.gratitude, .faith]
        case .angry: return [.forgiveness, .peace, .strength]
        case .lonely: return [.relationships, .peace, .healing]
        case .tired: return [.strength, .peace, .healing]
        case .blessed: return [.gratitude, .faith]
        }
    }
}

// MARK: - Prayer Suggestion

/// A suggested prayer with content and metadata
struct PrayerSuggestion: Identifiable, Codable, Equatable {
    let id: UUID
    let title: String
    let content: String
    let category: PrayerSuggestionCategory
    let scriptureReference: String?
    let scriptureText: String?
    let tags: [String]
    let suitableForMorning: Bool
    let suitableForEvening: Bool
    let duration: Int // Estimated minutes
    
    init(
        id: UUID = UUID(),
        title: String,
        content: String,
        category: PrayerSuggestionCategory,
        scriptureReference: String? = nil,
        scriptureText: String? = nil,
        tags: [String] = [],
        suitableForMorning: Bool = true,
        suitableForEvening: Bool = true,
        duration: Int = 2
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.category = category
        self.scriptureReference = scriptureReference
        self.scriptureText = scriptureText
        self.tags = tags
        self.suitableForMorning = suitableForMorning
        self.suitableForEvening = suitableForEvening
        self.duration = duration
    }
}

// MARK: - Prayer Suggestion Engine

/// Smart engine for generating prayer suggestions based on context
struct PrayerSuggestionEngine {
    
    // MARK: - Context-Based Suggestions
    
    /// Get suggestions based on current time of day
    static func suggestionsForTimeOfDay() -> [PrayerSuggestion] {
        let hour = Calendar.current.component(.hour, from: Date())
        
        if hour >= 5 && hour < 12 {
            return morningPrayers
        } else if hour >= 18 || hour < 4 {
            return eveningPrayers
        } else {
            return afternoonPrayers
        }
    }
    
    /// Get suggestions based on user feeling
    static func suggestionsFor(feeling: PrayerFeeling) -> [PrayerSuggestion] {
        let categories = feeling.suggestedCategories
        return allPrayers.filter { prayer in
            categories.contains(prayer.category)
        }
    }
    
    /// Get suggestions based on category
    static func suggestionsFor(category: PrayerSuggestionCategory) -> [PrayerSuggestion] {
        allPrayers.filter { $0.category == category }
    }
    
    /// Get daily suggested prayer (rotates based on day)
    static var dailySuggestion: PrayerSuggestion {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let index = (dayOfYear - 1) % allPrayers.count
        return allPrayers[index]
    }
    
    /// Get personalized suggestions based on mood history
    static func personalizedSuggestions(recentMoods: [MoodLevel]) -> [PrayerSuggestion] {
        // Analyze recent moods to suggest appropriate prayers
        guard !recentMoods.isEmpty else {
            return Array(allPrayers.prefix(5))
        }
        
        let averageMood = recentMoods.map { $0.value }.reduce(0, +) / recentMoods.count
        
        if averageMood <= 2 {
            // Low mood - suggest healing, strength, peace
            return allPrayers.filter { [.healing, .strength, .peace].contains($0.category) }
        } else if averageMood >= 4 {
            // High mood - suggest gratitude, faith
            return allPrayers.filter { [.gratitude, .faith].contains($0.category) }
        } else {
            // Neutral - suggest a variety
            return Array(allPrayers.shuffled().prefix(5))
        }
    }
    
    // MARK: - Prayer Library
    
    static var morningPrayers: [PrayerSuggestion] {
        allPrayers.filter { $0.suitableForMorning }
    }
    
    static var eveningPrayers: [PrayerSuggestion] {
        allPrayers.filter { $0.suitableForEvening }
    }
    
    static var afternoonPrayers: [PrayerSuggestion] {
        allPrayers.filter { [.strength, .guidance, .peace, .work].contains($0.category) }
    }
    
    // MARK: - Pre-Built Prayers
    
    static let allPrayers: [PrayerSuggestion] = [
        // Peace Prayers
        PrayerSuggestion(
            title: "Prayer for Inner Peace",
            content: """
Lord, calm the storms within my heart. Replace my anxiety with Your perfect peace that surpasses all understanding.

Help me to cast all my cares upon You, knowing that You care for me deeply. Let Your peace guard my heart and mind in Christ Jesus.

I release my worries into Your capable hands. Fill me with Your presence and let tranquility flow through every part of my being.

Amen.
""",
            category: .peace,
            scriptureReference: "Philippians 4:6-7",
            scriptureText: "Do not be anxious about anything, but in every situation, by prayer and petition, with thanksgiving, present your requests to God.",
            tags: ["peace", "calm", "anxiety"],
            duration: 3
        ),
        
        PrayerSuggestion(
            title: "Stillness Prayer",
            content: """
Heavenly Father, in the chaos of this world, I seek the stillness of Your presence.

Quiet my racing thoughts. Slow my anxious heart. Help me to simply be still and know that You are God.

In this moment of silence, speak to my soul. Let Your voice be louder than my fears.

Amen.
""",
            category: .peace,
            scriptureReference: "Psalm 46:10",
            scriptureText: "Be still, and know that I am God.",
            tags: ["stillness", "quiet", "presence"],
            duration: 2
        ),
        
        // Strength Prayers
        PrayerSuggestion(
            title: "Prayer for Daily Strength",
            content: """
Almighty God, as I face this day, I ask for Your strength.

When my energy fails, renew me. When my courage falters, embolden me. When my hope dims, reignite it.

I can do all things through Christ who strengthens me. Today, I choose to rely not on my own power but on Yours.

Fill me with supernatural strength for every challenge ahead.

Amen.
""",
            category: .strength,
            scriptureReference: "Isaiah 40:31",
            scriptureText: "Those who hope in the Lord will renew their strength. They will soar on wings like eagles.",
            tags: ["strength", "perseverance", "courage"],
            duration: 2
        ),
        
        PrayerSuggestion(
            title: "When I Am Weak",
            content: """
Lord, I come to You in my weakness, knowing that Your power is made perfect in my limitations.

I don't have to be strong on my own. Your grace is sufficient for me.

Transform my weakness into a testimony of Your strength. Use my struggles to display Your glory.

Amen.
""",
            category: .strength,
            scriptureReference: "2 Corinthians 12:9",
            scriptureText: "My grace is sufficient for you, for my power is made perfect in weakness.",
            tags: ["weakness", "grace", "power"],
            duration: 2
        ),
        
        // Gratitude Prayers
        PrayerSuggestion(
            title: "Morning Gratitude",
            content: """
Good morning, Lord!

Thank You for the gift of this new day. Thank You for the breath in my lungs and the beating of my heart.

I am grateful for Your mercies that are new every morning. Your faithfulness is great.

Help me to see Your blessings throughout this day and to live with a grateful heart.

Amen.
""",
            category: .gratitude,
            scriptureReference: "Lamentations 3:22-23",
            scriptureText: "Because of the Lord's great love we are not consumed, for his compassions never fail. They are new every morning.",
            tags: ["morning", "thankfulness", "blessings"],
            suitableForEvening: false,
            duration: 2
        ),
        
        PrayerSuggestion(
            title: "Counting My Blessings",
            content: """
Father, open my eyes to see the countless blessings You have poured into my life.

For family and friends who love me, I thank You. For provision and protection, I thank You. For salvation and eternal hope, I thank You.

Even in difficult seasons, help me find reasons to praise Your name.

Amen.
""",
            category: .gratitude,
            scriptureReference: "1 Thessalonians 5:18",
            scriptureText: "Give thanks in all circumstances; for this is God's will for you in Christ Jesus.",
            tags: ["thankfulness", "blessings", "praise"],
            duration: 2
        ),
        
        // Healing Prayers
        PrayerSuggestion(
            title: "Prayer for Healing",
            content: """
Great Physician, I come before You seeking healing—for my body, my mind, and my spirit.

You are the God who heals. You are Jehovah Rapha. Nothing is impossible for You.

Whether healing comes swiftly or gradually, I trust in Your perfect plan. Give me patience and faith in the waiting.

Touch me now with Your healing hand.

Amen.
""",
            category: .healing,
            scriptureReference: "Jeremiah 17:14",
            scriptureText: "Heal me, Lord, and I will be healed; save me and I will be saved, for you are the one I praise.",
            tags: ["healing", "health", "restoration"],
            duration: 3
        ),
        
        PrayerSuggestion(
            title: "Healing from Heartbreak",
            content: """
Lord, You are close to the brokenhearted. Draw near to me now.

My heart aches, but I know You can heal what is broken. Bind up my wounds with Your tender love.

Help me to release the pain and embrace Your comfort. Restore joy to my soul.

Amen.
""",
            category: .healing,
            scriptureReference: "Psalm 34:18",
            scriptureText: "The Lord is close to the brokenhearted and saves those who are crushed in spirit.",
            tags: ["heartbreak", "comfort", "restoration"],
            duration: 2
        ),
        
        // Guidance Prayers
        PrayerSuggestion(
            title: "Prayer for Direction",
            content: """
Heavenly Father, I stand at a crossroads and need Your guidance.

Light my path. Make Your will clear to me. When I'm uncertain which way to turn, lead me with Your wisdom.

I surrender my plans to You. Direct my steps according to Your perfect purpose.

Amen.
""",
            category: .guidance,
            scriptureReference: "Proverbs 3:5-6",
            scriptureText: "Trust in the Lord with all your heart and lean not on your own understanding; in all your ways submit to him, and he will make your paths straight.",
            tags: ["guidance", "direction", "wisdom"],
            duration: 2
        ),
        
        // Forgiveness Prayers
        PrayerSuggestion(
            title: "Prayer to Forgive",
            content: """
Lord, I need Your help to forgive.

The hurt runs deep, and forgiveness feels impossible. But I know that unforgiveness only imprisons me.

By Your grace, help me release this burden. I choose to forgive as You have forgiven me.

Free my heart from bitterness and fill it with Your love.

Amen.
""",
            category: .forgiveness,
            scriptureReference: "Ephesians 4:32",
            scriptureText: "Be kind and compassionate to one another, forgiving each other, just as in Christ God forgave you.",
            tags: ["forgiveness", "release", "freedom"],
            duration: 3
        ),
        
        // Evening Prayers
        PrayerSuggestion(
            title: "Evening Rest Prayer",
            content: """
As this day comes to an end, I lay my burdens at Your feet, Lord.

Thank You for walking with me through today. Forgive my shortcomings and receive my gratitude for Your blessings.

Grant me peaceful sleep and watch over me through the night. Let me wake refreshed and ready to serve You.

Amen.
""",
            category: .evening,
            scriptureReference: "Psalm 4:8",
            scriptureText: "In peace I will lie down and sleep, for you alone, Lord, make me dwell in safety.",
            tags: ["evening", "rest", "sleep"],
            suitableForMorning: false,
            duration: 2
        ),
        
        // Anxiety Prayers
        PrayerSuggestion(
            title: "When Anxiety Overwhelms",
            content: """
Lord, my heart is racing and my mind won't stop. Anxiety threatens to consume me.

But You are greater than my fears. You hold my future in Your hands.

I cast every anxious thought upon You. Wrap me in Your peace. Remind me that You are in control.

I breathe in Your presence and exhale my worry.

Amen.
""",
            category: .anxiety,
            scriptureReference: "1 Peter 5:7",
            scriptureText: "Cast all your anxiety on him because he cares for you.",
            tags: ["anxiety", "fear", "trust"],
            duration: 2
        ),
        
        // Faith Prayers
        PrayerSuggestion(
            title: "Strengthen My Faith",
            content: """
Lord, I believe—help my unbelief!

When doubts creep in and my faith wavers, anchor me in Your truth. Remind me of Your faithfulness throughout my life.

Increase my faith. Help me to trust You more deeply with each passing day.

Amen.
""",
            category: .faith,
            scriptureReference: "Mark 9:24",
            scriptureText: "Immediately the boy's father exclaimed, 'I do believe; help me overcome my unbelief!'",
            tags: ["faith", "trust", "belief"],
            duration: 2
        ),
        
        // Protection
        PrayerSuggestion(
            title: "Prayer for Protection",
            content: """
Almighty Protector, I place myself and my loved ones under Your mighty hand.

Shield us from harm, both seen and unseen. Guard our going out and our coming in.

You are our refuge and fortress. In You, we trust.

Cover us with Your wings and keep us safe.

Amen.
""",
            category: .protection,
            scriptureReference: "Psalm 91:1-2",
            scriptureText: "Whoever dwells in the shelter of the Most High will rest in the shadow of the Almighty.",
            tags: ["protection", "safety", "shelter"],
            duration: 2
        )
    ]
    
    // MARK: - Category Prayers Quick Access
    
    static func quickPrayers(for category: PrayerSuggestionCategory) -> [PrayerSuggestion] {
        allPrayers.filter { $0.category == category }
    }
    
    static var categories: [PrayerSuggestionCategory] {
        PrayerSuggestionCategory.allCases
    }
    
    static var featuredCategories: [PrayerSuggestionCategory] {
        [.peace, .strength, .gratitude, .healing, .guidance, .anxiety]
    }
}

// MARK: - MoodLevel Extension

extension MoodLevel {
    /// Numeric value for mood calculations (uses rawValue)
    var value: Int {
        rawValue
    }
}

