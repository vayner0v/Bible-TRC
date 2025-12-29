//
//  AudioPrayer.swift
//  Bible v1
//
//  Spiritual Hub - Audio Prayer Model
//

import Foundation
import SwiftUI

/// Category for audio prayers
enum AudioPrayerCategory: String, Codable, CaseIterable, Identifiable {
    case morning = "Morning"
    case evening = "Evening"
    case anxiety = "Anxiety & Peace"
    case gratitude = "Gratitude"
    case sleep = "Sleep"
    case commute = "Commute"
    case healing = "Healing"
    case strength = "Strength"
    case guidance = "Guidance"
    case worship = "Worship"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .morning: return "sunrise.fill"
        case .evening: return "sunset.fill"
        case .anxiety: return "cloud.sun.fill"
        case .gratitude: return "heart.fill"
        case .sleep: return "moon.stars.fill"
        case .commute: return "car.fill"
        case .healing: return "cross.fill"
        case .strength: return "bolt.fill"
        case .guidance: return "signpost.right.fill"
        case .worship: return "music.note"
        }
    }
    
    var color: Color {
        switch self {
        case .morning: return .orange
        case .evening: return .indigo
        case .anxiety: return .teal
        case .gratitude: return .pink
        case .sleep: return .indigo
        case .commute: return .blue
        case .healing: return .green
        case .strength: return .red
        case .guidance: return .yellow
        case .worship: return .cyan
        }
    }
    
    var description: String {
        switch self {
        case .morning: return "Start your day with God"
        case .evening: return "End your day in peace"
        case .anxiety: return "Find calm in His presence"
        case .gratitude: return "Cultivate a thankful heart"
        case .sleep: return "Rest in God's protection"
        case .commute: return "Pray on the go"
        case .healing: return "Prayers for restoration"
        case .strength: return "Find courage in God"
        case .guidance: return "Seek His direction"
        case .worship: return "Praise and adoration"
        }
    }
}

/// Audio content type
enum AudioContentType: String, Codable, CaseIterable {
    case prayer = "Prayer"
    case meditation = "Meditation"
    case scripture = "Scripture Reading"
    case devotional = "Devotional"
    case worship = "Worship"
}

/// An audio prayer entry
struct AudioPrayer: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var description: String
    var duration: TimeInterval // seconds
    var category: AudioPrayerCategory
    var contentType: AudioContentType
    var audioFileName: String? // Local bundled file
    var audioURL: String? // Remote URL (future use)
    var transcript: String // Full text for accessibility & TTS
    var scriptureReferences: [String]
    var author: String
    var isFavorite: Bool
    var playCount: Int
    var lastPlayed: Date?
    var isDownloaded: Bool
    let dateAdded: Date
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        duration: TimeInterval,
        category: AudioPrayerCategory,
        contentType: AudioContentType = .prayer,
        audioFileName: String? = nil,
        audioURL: String? = nil,
        transcript: String,
        scriptureReferences: [String] = [],
        author: String = "Bible App",
        isFavorite: Bool = false,
        playCount: Int = 0,
        lastPlayed: Date? = nil,
        isDownloaded: Bool = true,
        dateAdded: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.duration = duration
        self.category = category
        self.contentType = contentType
        self.audioFileName = audioFileName
        self.audioURL = audioURL
        self.transcript = transcript
        self.scriptureReferences = scriptureReferences
        self.author = author
        self.isFavorite = isFavorite
        self.playCount = playCount
        self.lastPlayed = lastPlayed
        self.isDownloaded = isDownloaded
        self.dateAdded = dateAdded
    }
    
    /// Format duration for display
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes > 0 {
            return "\(minutes):\(String(format: "%02d", seconds))"
        } else {
            return "0:\(String(format: "%02d", seconds))"
        }
    }
    
    /// Short duration display
    var shortDuration: String {
        let minutes = Int(duration) / 60
        if minutes > 0 {
            return "\(minutes) min"
        } else {
            return "\(Int(duration)) sec"
        }
    }
    
    /// Check if has audio file
    var hasAudio: Bool {
        audioFileName != nil || audioURL != nil
    }
    
    /// Increment play count
    mutating func recordPlay() {
        playCount += 1
        lastPlayed = Date()
    }
    
    /// Toggle favorite
    mutating func toggleFavorite() {
        isFavorite.toggle()
    }
}

// MARK: - User Audio Prayer (Text-to-Speech)

/// A user-created prayer that can be played via TTS
struct UserAudioPrayer: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var content: String
    var voiceIdentifier: String? // System voice preference
    var speechRate: Float // 0.0 to 1.0
    var isFavorite: Bool
    var playCount: Int
    var lastPlayed: Date?
    let dateCreated: Date
    
    init(
        id: UUID = UUID(),
        title: String,
        content: String,
        voiceIdentifier: String? = nil,
        speechRate: Float = 0.5,
        isFavorite: Bool = false,
        playCount: Int = 0,
        lastPlayed: Date? = nil,
        dateCreated: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.voiceIdentifier = voiceIdentifier
        self.speechRate = speechRate
        self.isFavorite = isFavorite
        self.playCount = playCount
        self.lastPlayed = lastPlayed
        self.dateCreated = dateCreated
    }
    
    /// Estimated duration based on word count
    var estimatedDuration: TimeInterval {
        let wordCount = content.split(separator: " ").count
        // Average speaking rate ~150 words per minute at normal speed
        let adjustedRate = Double(speechRate) * 100 + 100 // 100-200 wpm
        return Double(wordCount) / adjustedRate * 60
    }
    
    var formattedDuration: String {
        let minutes = Int(estimatedDuration) / 60
        let seconds = Int(estimatedDuration) % 60
        if minutes > 0 {
            return "\(minutes):\(String(format: "%02d", seconds))"
        } else {
            return "0:\(String(format: "%02d", seconds))"
        }
    }
}

// MARK: - Audio Playback State

/// Current playback state
enum PlaybackState: Equatable, Sendable {
    case idle
    case loading
    case playing
    case paused
    case finished
    case error(String)
}

/// Sleep timer options
enum SleepTimerOption: Int, CaseIterable, Identifiable {
    case off = 0
    case fiveMinutes = 5
    case tenMinutes = 10
    case fifteenMinutes = 15
    case thirtyMinutes = 30
    case oneHour = 60
    
    var id: Int { rawValue }
    
    var displayName: String {
        switch self {
        case .off: return "Off"
        case .fiveMinutes: return "5 minutes"
        case .tenMinutes: return "10 minutes"
        case .fifteenMinutes: return "15 minutes"
        case .thirtyMinutes: return "30 minutes"
        case .oneHour: return "1 hour"
        }
    }
}

// MARK: - Curated Audio Prayers

extension AudioPrayer {
    
    /// Morning prayer content
    static let morningPrayer = AudioPrayer(
        title: "Morning Surrender",
        description: "Start your day by surrendering to God's will",
        duration: 180, // 3 minutes
        category: .morning,
        transcript: """
        Heavenly Father,
        
        As I begin this new day, I surrender it completely to You. Before my feet touch the floor, before my mind races to the tasks ahead, I pause to acknowledge that You are God and I am Yours.
        
        Thank You for the gift of another day. Thank You for breath in my lungs and purpose in my heart. Whatever this day holds, I trust that You hold me.
        
        Lord, guide my thoughts today. Let them be pleasing to You. Guard my words—may they bring life and encouragement to those I encounter. Direct my steps according to Your perfect will.
        
        I release my plans, my worries, and my expectations into Your capable hands. I choose to trust You with what I cannot control. I choose peace over anxiety, faith over fear.
        
        Fill me with Your Holy Spirit. Give me wisdom for decisions, patience in difficulties, and joy that isn't dependent on circumstances.
        
        Use me today for Your glory. Help me see the people around me the way You see them. Give me opportunities to show Your love.
        
        In Jesus' name, Amen.
        """,
        scriptureReferences: ["Proverbs 3:5-6", "Psalm 118:24", "Matthew 6:34"],
        author: "Bible App"
    )
    
    /// Evening reflection
    static let eveningReflection = AudioPrayer(
        title: "Evening Reflection",
        description: "End your day in gratitude and peace",
        duration: 240, // 4 minutes
        category: .evening,
        transcript: """
        Lord God,
        
        As this day draws to a close, I come before You with a grateful heart. Thank You for walking with me through every moment—the highs and the lows, the expected and the surprising.
        
        I reflect on this day with honesty before You. For the moments I fell short—the sharp words, the selfish choices, the missed opportunities to love—I ask Your forgiveness. Thank You that Your mercies are new every morning.
        
        For the good in this day—the kindness I received, the beauty I noticed, the progress I made—I give You praise. Every good gift comes from You.
        
        Now, Lord, I release the weight of this day. I lay down the things I couldn't finish. I surrender the conversations that replay in my mind. I trust You with tomorrow's concerns.
        
        As I prepare for rest, quiet my mind. Calm my anxious thoughts. Let Your peace, which surpasses understanding, guard my heart and mind through the night.
        
        Watch over those I love. Protect us as we sleep. And when morning comes, renew my strength to serve You again.
        
        Thank You for being faithful. Thank You for being near. I rest in Your presence tonight.
        
        In Jesus' name, Amen.
        """,
        scriptureReferences: ["Psalm 4:8", "Lamentations 3:22-23", "Philippians 4:6-7"],
        author: "Bible App"
    )
    
    /// Anxiety relief prayer
    static let anxietyRelief = AudioPrayer(
        title: "Peace in Anxiety",
        description: "Find calm when worry overwhelms",
        duration: 300, // 5 minutes
        category: .anxiety,
        transcript: """
        Heavenly Father,
        
        My heart is racing. My thoughts are spinning. Anxiety has its grip on me, and I need Your peace right now.
        
        I breathe in... and I breathe out. With each breath, I remember that You are here. You have not left me. You will never leave me.
        
        Lord, I cast every anxious thought onto You—because You care for me. You care about what's troubling me. Nothing is too small or too big for Your attention.
        
        [Pause for 10 seconds]
        
        I choose to believe Your Word over my worried thoughts. You say You will keep in perfect peace those whose minds are fixed on You. So I fix my mind on You right now.
        
        You are sovereign. Nothing surprises You. The situation causing me anxiety is already in Your hands. You are working all things together for good.
        
        [Pause for 10 seconds]
        
        I release control. I don't have to figure everything out. I don't have to have all the answers. You are God, and I am not. And that is good news.
        
        Replace my fear with faith. Replace my worry with worship. Replace my anxiety with awareness of Your presence.
        
        I receive Your peace now—not as the world gives, but the deep, supernatural peace that only You provide.
        
        Thank You for hearing me. Thank You for calming the storm within me. I trust You.
        
        In Jesus' name, Amen.
        """,
        scriptureReferences: ["1 Peter 5:7", "Isaiah 26:3", "John 14:27", "Romans 8:28"],
        author: "Bible App"
    )
    
    /// Sleep prayer
    static let sleepPrayer = AudioPrayer(
        title: "Rest in His Arms",
        description: "A gentle prayer for peaceful sleep",
        duration: 360, // 6 minutes
        category: .sleep,
        transcript: """
        Lord,
        
        The day is done. The work is finished—or at least, I'm finished with what I could do today. Now I come to You seeking rest.
        
        Quiet my mind, Father. Slow my racing thoughts. Release the tension I'm holding in my body. Let every muscle relax in Your presence.
        
        [Pause for 15 seconds]
        
        I lay down my burdens at Your feet. The worries about tomorrow—they're Yours now. The regrets from today—covered by Your grace. The things left undone—I trust Your provision.
        
        [Pause for 10 seconds]
        
        As I close my eyes, I picture myself resting in Your arms—safe, secure, loved. Like a child held by a good father. Nothing can harm me here.
        
        You who watch over Israel neither slumber nor sleep. So I can sleep peacefully, knowing You are awake, watching over me and those I love.
        
        [Pause for 15 seconds]
        
        I choose to dwell on what is good, lovely, and praiseworthy. I fill my mind with thoughts of Your faithfulness, Your kindness, Your unfailing love.
        
        [Pause for 10 seconds]
        
        Guard my dreams tonight. Let my subconscious mind rest in Your truth. Restore my body, mind, and spirit as I sleep.
        
        And when I wake, let my first thought be of You. Let gratitude be my greeting to the new day.
        
        I love You, Lord. I trust You with my night.
        
        In Jesus' name, Amen.
        """,
        scriptureReferences: ["Psalm 4:8", "Psalm 121:4", "Matthew 11:28", "Philippians 4:8"],
        author: "Bible App"
    )
    
    /// Gratitude prayer
    static let gratitudePrayer = AudioPrayer(
        title: "A Grateful Heart",
        description: "Cultivate thankfulness in all circumstances",
        duration: 210, // 3.5 minutes
        category: .gratitude,
        transcript: """
        Father God,
        
        I come before You today choosing gratitude. Not because everything is perfect, but because You are good—always good.
        
        Thank You for life itself. For the breath filling my lungs right now. For another day to experience Your love and share it with others.
        
        Thank You for the people in my life—those who encourage me, challenge me, and walk alongside me. What a gift to not be alone.
        
        Thank You for provision. For food, shelter, and the basic needs so many go without. Help me never take these blessings for granted.
        
        Thank You for purpose. For work to do, people to love, and a calling to pursue. My life has meaning because of You.
        
        Thank You for grace. For second chances and tenth chances. For a love that doesn't give up on me even when I give up on myself.
        
        Thank You for hope. For the promise that this world isn't all there is. For eternity with You to look forward to.
        
        Lord, help me see today through grateful eyes. Let me notice the small blessings I usually overlook. Let me appreciate what I have instead of longing for what I don't.
        
        I will give thanks in all circumstances—not for all circumstances, but in them—because this is Your will for me in Christ Jesus.
        
        With a grateful heart, I pray. Amen.
        """,
        scriptureReferences: ["1 Thessalonians 5:18", "Psalm 100:4", "Colossians 3:17"],
        author: "Bible App"
    )
    
    /// All curated prayers
    static let curatedPrayers: [AudioPrayer] = [
        morningPrayer,
        eveningReflection,
        anxietyRelief,
        sleepPrayer,
        gratitudePrayer
    ]
}


