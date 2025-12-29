//
//  Devotional.swift
//  Bible v1
//
//  Spiritual Hub - Devotionals Model
//

import Foundation
import SwiftUI

/// Devotional topic categories
enum DevotionalTopic: String, Codable, CaseIterable, Identifiable {
    case anxiety = "Overcoming Anxiety"
    case grief = "Walking Through Grief"
    case joy = "Finding Joy"
    case purpose = "Discovering Purpose"
    case faith = "Growing in Faith"
    case relationships = "Healthy Relationships"
    case identity = "Identity in Christ"
    case prayer = "Deepening Prayer"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .anxiety: return "cloud.sun.fill"
        case .grief: return "heart.slash"
        case .joy: return "sun.max.fill"
        case .purpose: return "target"
        case .faith: return "mountain.2.fill"
        case .relationships: return "person.2.fill"
        case .identity: return "person.fill.checkmark"
        case .prayer: return "hands.sparkles"
        }
    }
    
    var color: Color {
        switch self {
        case .anxiety: return .teal
        case .grief: return .indigo
        case .joy: return .yellow
        case .purpose: return .blue
        case .faith: return .brown
        case .relationships: return .pink
        case .identity: return .green
        case .prayer: return .indigo
        }
    }
    
    var description: String {
        switch self {
        case .anxiety: return "Find peace in God's promises when worry overwhelms"
        case .grief: return "Experience God's comfort in seasons of loss"
        case .joy: return "Discover lasting joy that circumstances can't shake"
        case .purpose: return "Uncover God's unique plan for your life"
        case .faith: return "Strengthen your trust in God's faithfulness"
        case .relationships: return "Build God-honoring connections with others"
        case .identity: return "Understand who you are as God's beloved child"
        case .prayer: return "Transform your conversation with God"
        }
    }
}

/// A single day's devotional content
struct DevotionalDay: Identifiable, Codable {
    let id: UUID
    let dayNumber: Int
    let title: String
    let verseReference: String
    let verseText: String
    let reflection: String
    let prayerPrompt: String
    let applicationQuestion: String
    
    init(
        id: UUID = UUID(),
        dayNumber: Int,
        title: String,
        verseReference: String,
        verseText: String,
        reflection: String,
        prayerPrompt: String,
        applicationQuestion: String
    ) {
        self.id = id
        self.dayNumber = dayNumber
        self.title = title
        self.verseReference = verseReference
        self.verseText = verseText
        self.reflection = reflection
        self.prayerPrompt = prayerPrompt
        self.applicationQuestion = applicationQuestion
    }
}

/// A complete devotional series
struct DevotionalSeries: Identifiable, Codable {
    let id: UUID
    let topic: DevotionalTopic
    let title: String
    let description: String
    let days: [DevotionalDay]
    
    init(
        id: UUID = UUID(),
        topic: DevotionalTopic,
        title: String,
        description: String,
        days: [DevotionalDay]
    ) {
        self.id = id
        self.topic = topic
        self.title = title
        self.description = description
        self.days = days
    }
    
    var totalDays: Int { days.count }
}

/// User's progress through a devotional
struct DevotionalProgress: Identifiable, Codable {
    let id: UUID
    let seriesId: UUID
    let seriesTitle: String
    var currentDay: Int
    var completedDays: Set<Int>
    var startDate: Date
    var lastReadDate: Date?
    var notes: [Int: String]
    var isCompleted: Bool
    
    init(
        id: UUID = UUID(),
        seriesId: UUID,
        seriesTitle: String,
        currentDay: Int = 1,
        completedDays: Set<Int> = [],
        startDate: Date = Date(),
        lastReadDate: Date? = nil,
        notes: [Int: String] = [:],
        isCompleted: Bool = false
    ) {
        self.id = id
        self.seriesId = seriesId
        self.seriesTitle = seriesTitle
        self.currentDay = currentDay
        self.completedDays = completedDays
        self.startDate = startDate
        self.lastReadDate = lastReadDate
        self.notes = notes
        self.isCompleted = isCompleted
    }
    
    mutating func completeDay(_ day: Int, totalDays: Int) {
        completedDays.insert(day)
        lastReadDate = Date()
        if day >= currentDay {
            currentDay = min(day + 1, totalDays)
        }
        if completedDays.count >= totalDays {
            isCompleted = true
        }
    }
    
    func progressPercentage(totalDays: Int) -> Double {
        guard totalDays > 0 else { return 0 }
        return Double(completedDays.count) / Double(totalDays)
    }
}

// MARK: - Devotional Content

extension DevotionalSeries {
    
    static let anxietySeries = DevotionalSeries(
        topic: .anxiety,
        title: "Peace Over Anxiety",
        description: "A 5-day journey to finding God's peace when worry overwhelms",
        days: [
            DevotionalDay(
                dayNumber: 1,
                title: "Cast Your Cares",
                verseReference: "1 Peter 5:7",
                verseText: "Cast all your anxiety on him because he cares for you.",
                reflection: "God doesn't want you to carry the weight of worry alone. He invites you to literally throw your anxieties onto Him—not gently place them, but cast them. Why? Because He genuinely cares for you. Your concerns matter to Him.",
                prayerPrompt: "Lord, I cast these specific worries onto You today: [name them]. I trust that You care about each one.",
                applicationQuestion: "What anxiety have you been holding onto that God is asking you to release today?"
            ),
            DevotionalDay(
                dayNumber: 2,
                title: "Do Not Be Anxious",
                verseReference: "Philippians 4:6-7",
                verseText: "Do not be anxious about anything, but in every situation, by prayer and petition, with thanksgiving, present your requests to God. And the peace of God, which transcends all understanding, will guard your hearts and minds.",
                reflection: "Paul doesn't say 'don't have concerns.' He says bring them to God through prayer—with thanksgiving. When we approach God gratefully even in anxiety, something supernatural happens: His peace guards us. It doesn't make sense, but it works.",
                prayerPrompt: "Father, I present [specific concern] to You. Thank You for being sovereign over this situation.",
                applicationQuestion: "How can you add thanksgiving to your prayers about anxious situations?"
            ),
            DevotionalDay(
                dayNumber: 3,
                title: "God's Presence",
                verseReference: "Isaiah 41:10",
                verseText: "So do not fear, for I am with you; do not be dismayed, for I am your God. I will strengthen you and help you; I will uphold you with my righteous right hand.",
                reflection: "Fear and anxiety often stem from feeling alone in our struggles. God's response: 'I am with you.' He promises not just His presence, but His strength, help, and support. You are held by the righteous right hand of the Almighty.",
                prayerPrompt: "Lord, help me sense Your presence today. Remind me that I am never alone.",
                applicationQuestion: "When do you most need to remember God's promise to be with you?"
            ),
            DevotionalDay(
                dayNumber: 4,
                title: "Perfect Peace",
                verseReference: "Isaiah 26:3",
                verseText: "You will keep in perfect peace those whose minds are steadfast, because they trust in you.",
                reflection: "Perfect peace isn't the absence of problems—it's the presence of trust. Where our minds dwell matters. When we fix our thoughts on God's faithfulness rather than our fears, peace becomes possible even in chaos.",
                prayerPrompt: "Father, help me keep my mind fixed on You. Replace anxious thoughts with trust.",
                applicationQuestion: "What truths about God can you meditate on when anxiety rises?"
            ),
            DevotionalDay(
                dayNumber: 5,
                title: "Tomorrow's Worries",
                verseReference: "Matthew 6:34",
                verseText: "Therefore do not worry about tomorrow, for tomorrow will worry about itself. Each day has enough trouble of its own.",
                reflection: "Jesus acknowledges that life has troubles—He doesn't promise a problem-free existence. But He does command us not to add tomorrow's worries to today's load. Live in the present. Trust God for tomorrow when tomorrow comes.",
                prayerPrompt: "Lord, help me live fully in today, trusting You with tomorrow.",
                applicationQuestion: "What future worry do you need to release into God's hands right now?"
            )
        ]
    )
    
    static let joySeries = DevotionalSeries(
        topic: .joy,
        title: "Choosing Joy",
        description: "A 5-day journey to discovering joy that circumstances can't steal",
        days: [
            DevotionalDay(
                dayNumber: 1,
                title: "The Joy of the Lord",
                verseReference: "Nehemiah 8:10",
                verseText: "The joy of the Lord is your strength.",
                reflection: "Joy isn't just a nice feeling—it's a source of strength. This joy doesn't come from circumstances but from the Lord Himself. When we tap into His joy, we find power to face whatever comes our way.",
                prayerPrompt: "Lord, let Your joy be my strength today, regardless of what I face.",
                applicationQuestion: "How might your day change if you drew strength from God's joy?"
            ),
            DevotionalDay(
                dayNumber: 2,
                title: "Joy in Trials",
                verseReference: "James 1:2-3",
                verseText: "Consider it pure joy, my brothers and sisters, whenever you face trials of many kinds, because you know that the testing of your faith produces perseverance.",
                reflection: "James doesn't say feel joy in trials—he says consider it joy. This is a choice to see trials through the lens of purpose. God uses challenges to grow us. Knowing this changes how we respond.",
                prayerPrompt: "Father, help me see my current challenges as opportunities for growth.",
                applicationQuestion: "What difficult situation might God be using to develop perseverance in you?"
            ),
            DevotionalDay(
                dayNumber: 3,
                title: "Fullness of Joy",
                verseReference: "Psalm 16:11",
                verseText: "You make known to me the path of life; you will fill me with joy in your presence, with eternal pleasures at your right hand.",
                reflection: "The deepest joy is found in God's presence. Not in achievements, relationships, or possessions—but in Him. As we draw near to God, we access a joy that fills us completely.",
                prayerPrompt: "Lord, draw me into Your presence today. Fill me with joy that only You can give.",
                applicationQuestion: "What practices help you experience God's presence and the joy it brings?"
            ),
            DevotionalDay(
                dayNumber: 4,
                title: "Rejoice Always",
                verseReference: "Philippians 4:4",
                verseText: "Rejoice in the Lord always. I will say it again: Rejoice!",
                reflection: "Paul wrote this from prison, yet he commands rejoicing—always. The secret? 'In the Lord.' Our rejoicing isn't in circumstances but in who God is. His character never changes, so our joy has a constant foundation.",
                prayerPrompt: "Father, help me rejoice in who You are, not just what You do.",
                applicationQuestion: "What attribute of God can you rejoice in right now?"
            ),
            DevotionalDay(
                dayNumber: 5,
                title: "Joy Restored",
                verseReference: "Psalm 51:12",
                verseText: "Restore to me the joy of your salvation and grant me a willing spirit, to sustain me.",
                reflection: "Joy can be lost and restored. David prayed this after sin had stolen his joy. God doesn't just forgive—He restores. If you've lost your joy, it can be recovered through honest confession and God's gracious restoration.",
                prayerPrompt: "Lord, restore the joy of my salvation. Renew my delight in You.",
                applicationQuestion: "Is there anything blocking your joy that you need to confess and release?"
            )
        ]
    )
    
    static let purposeSeries = DevotionalSeries(
        topic: .purpose,
        title: "Created for Purpose",
        description: "A 5-day journey to discovering God's unique plan for your life",
        days: [
            DevotionalDay(
                dayNumber: 1,
                title: "Fearfully Made",
                verseReference: "Psalm 139:14",
                verseText: "I praise you because I am fearfully and wonderfully made; your works are wonderful, I know that full well.",
                reflection: "You are not an accident or an afterthought. God created you with intention, care, and wonder. Your unique combination of gifts, personality, and experiences is by design. Purpose starts with accepting how wonderfully you're made.",
                prayerPrompt: "Lord, help me see myself as You see me—wonderfully made for a purpose.",
                applicationQuestion: "What unique qualities has God given you that might point to your purpose?"
            ),
            DevotionalDay(
                dayNumber: 2,
                title: "Good Works Prepared",
                verseReference: "Ephesians 2:10",
                verseText: "For we are God's handiwork, created in Christ Jesus to do good works, which God prepared in advance for us to do.",
                reflection: "God has already prepared specific good works for you. Not random tasks, but assignments designed with you in mind. Your job isn't to invent your purpose—it's to discover and walk in what God has already prepared.",
                prayerPrompt: "Father, open my eyes to the good works You've prepared for me.",
                applicationQuestion: "What opportunities for good works are already in front of you?"
            ),
            DevotionalDay(
                dayNumber: 3,
                title: "God's Plans",
                verseReference: "Jeremiah 29:11",
                verseText: "For I know the plans I have for you, declares the Lord, plans to prosper you and not to harm you, plans to give you hope and a future.",
                reflection: "God's plans for you are good—full of hope and future. Even when life feels uncertain, His plans remain steady. Trust isn't about knowing every detail; it's about trusting the One who holds the plan.",
                prayerPrompt: "Lord, I trust Your plans even when I can't see them clearly.",
                applicationQuestion: "How does knowing God has good plans affect how you view your current situation?"
            ),
            DevotionalDay(
                dayNumber: 4,
                title: "Glorify God",
                verseReference: "1 Corinthians 10:31",
                verseText: "So whether you eat or drink or whatever you do, do it all for the glory of God.",
                reflection: "Ultimate purpose is simple: glorify God. This doesn't mean only 'spiritual' activities count. Every aspect of life—work, rest, relationships, hobbies—can bring glory to God when done with Him in mind.",
                prayerPrompt: "Father, help me see every part of my life as an opportunity to glorify You.",
                applicationQuestion: "How can you bring glory to God in your everyday activities?"
            ),
            DevotionalDay(
                dayNumber: 5,
                title: "Kingdom Work",
                verseReference: "Matthew 6:33",
                verseText: "But seek first his kingdom and his righteousness, and all these things will be given to you as well.",
                reflection: "When we prioritize God's kingdom, everything else falls into place. Purpose isn't about what we can achieve for ourselves—it's about participating in what God is doing in the world. Seek His kingdom first.",
                prayerPrompt: "Lord, align my priorities with Your kingdom. Show me how to participate.",
                applicationQuestion: "What would it look like to seek God's kingdom first in your decisions this week?"
            )
        ]
    )
    
    static let allSeries: [DevotionalSeries] = [
        anxietySeries,
        joySeries,
        purposeSeries
    ]
}



