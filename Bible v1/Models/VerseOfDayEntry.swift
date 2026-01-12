//
//  VerseOfDayEntry.swift
//  Bible v1
//
//  Spiritual Hub - Verse of the Day Model
//

import Foundation

/// A verse of the day entry with user interactions
struct VerseOfDayEntry: Identifiable, Codable, Hashable {
    let id: UUID
    let date: Date
    let verseReference: String
    let verseText: String
    var isSaved: Bool
    var reflection: String?
    var isMemorized: Bool
    var memorizationProgress: Int // 0-100
    var shareCount: Int
    let createdAt: Date
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        verseReference: String,
        verseText: String,
        isSaved: Bool = false,
        reflection: String? = nil,
        isMemorized: Bool = false,
        memorizationProgress: Int = 0,
        shareCount: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.verseReference = verseReference
        self.verseText = verseText
        self.isSaved = isSaved
        self.reflection = reflection
        self.isMemorized = isMemorized
        self.memorizationProgress = memorizationProgress
        self.shareCount = shareCount
        self.createdAt = createdAt
    }
    
    /// Toggle saved status
    mutating func toggleSaved() {
        isSaved.toggle()
    }
    
    /// Add reflection
    mutating func addReflection(_ text: String) {
        reflection = text
    }
    
    /// Update memorization progress
    mutating func updateMemorizationProgress(_ progress: Int) {
        memorizationProgress = min(100, max(0, progress))
        if memorizationProgress >= 100 {
            isMemorized = true
        }
    }
    
    /// Record share
    mutating func recordShare() {
        shareCount += 1
    }
    
    /// Check if entry is for today
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    /// Formatted date
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

/// Curated verses of the day collection
struct VerseOfDayCollection {
    
    static let verses: [(reference: String, text: String)] = [
        // Hope & Encouragement
        ("Jeremiah 29:11", "For I know the plans I have for you, declares the Lord, plans to prosper you and not to harm you, plans to give you hope and a future."),
        ("Romans 8:28", "And we know that in all things God works for the good of those who love him, who have been called according to his purpose."),
        ("Isaiah 40:31", "But those who hope in the Lord will renew their strength. They will soar on wings like eagles; they will run and not grow weary, they will walk and not be faint."),
        
        // Peace & Trust
        ("Philippians 4:6-7", "Do not be anxious about anything, but in every situation, by prayer and petition, with thanksgiving, present your requests to God. And the peace of God, which transcends all understanding, will guard your hearts and your minds in Christ Jesus."),
        ("Proverbs 3:5-6", "Trust in the Lord with all your heart and lean not on your own understanding; in all your ways submit to him, and he will make your paths straight."),
        ("Isaiah 26:3", "You will keep in perfect peace those whose minds are steadfast, because they trust in you."),
        
        // Strength & Courage
        ("Joshua 1:9", "Have I not commanded you? Be strong and courageous. Do not be afraid; do not be discouraged, for the Lord your God will be with you wherever you go."),
        ("Philippians 4:13", "I can do all this through him who gives me strength."),
        ("Isaiah 41:10", "So do not fear, for I am with you; do not be dismayed, for I am your God. I will strengthen you and help you; I will uphold you with my righteous right hand."),
        
        // Love & Grace
        ("John 3:16", "For God so loved the world that he gave his one and only Son, that whoever believes in him shall not perish but have eternal life."),
        ("Romans 8:38-39", "For I am convinced that neither death nor life, neither angels nor demons, neither the present nor the future, nor any powers, neither height nor depth, nor anything else in all creation, will be able to separate us from the love of God that is in Christ Jesus our Lord."),
        ("Ephesians 2:8-9", "For it is by grace you have been saved, through faith—and this is not from yourselves, it is the gift of God—not by works, so that no one can boast."),
        
        // Faith & Wisdom
        ("Hebrews 11:1", "Now faith is confidence in what we hope for and assurance about what we do not see."),
        ("James 1:5", "If any of you lacks wisdom, you should ask God, who gives generously to all without finding fault, and it will be given to you."),
        ("2 Corinthians 5:7", "For we live by faith, not by sight."),
        
        // Joy & Gratitude
        ("Nehemiah 8:10", "Do not grieve, for the joy of the Lord is your strength."),
        ("1 Thessalonians 5:16-18", "Rejoice always, pray continually, give thanks in all circumstances; for this is God's will for you in Christ Jesus."),
        ("Psalm 118:24", "This is the day the Lord has made; let us rejoice and be glad in it."),
        
        // Rest & Comfort
        ("Matthew 11:28-30", "Come to me, all you who are weary and burdened, and I will give you rest. Take my yoke upon you and learn from me, for I am gentle and humble in heart, and you will find rest for your souls. For my yoke is easy and my burden is light."),
        ("Psalm 23:1-3", "The Lord is my shepherd, I lack nothing. He makes me lie down in green pastures, he leads me beside quiet waters, he refreshes my soul."),
        ("2 Corinthians 1:3-4", "Praise be to the God and Father of our Lord Jesus Christ, the Father of compassion and the God of all comfort, who comforts us in all our troubles."),
        
        // Purpose & Identity
        ("Psalm 139:14", "I praise you because I am fearfully and wonderfully made; your works are wonderful, I know that full well."),
        ("Ephesians 2:10", "For we are God's handiwork, created in Christ Jesus to do good works, which God prepared in advance for us to do."),
        ("1 Peter 2:9", "But you are a chosen people, a royal priesthood, a holy nation, God's special possession, that you may declare the praises of him who called you out of darkness into his wonderful light."),
        
        // Guidance & Direction
        ("Psalm 32:8", "I will instruct you and teach you in the way you should go; I will counsel you with my loving eye on you."),
        ("Psalm 37:4", "Take delight in the Lord, and he will give you the desires of your heart."),
        ("Proverbs 16:3", "Commit to the Lord whatever you do, and he will establish your plans."),
        
        // Protection & Security
        ("Psalm 91:1-2", "Whoever dwells in the shelter of the Most High will rest in the shadow of the Almighty. I will say of the Lord, 'He is my refuge and my fortress, my God, in whom I trust.'"),
        ("Psalm 46:1", "God is our refuge and strength, an ever-present help in trouble."),
        ("2 Thessalonians 3:3", "But the Lord is faithful, and he will strengthen you and protect you from the evil one.")
    ]
    
    /// Get verse for a specific date
    static func verseForDate(_ date: Date) -> (reference: String, text: String) {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
        let index = (dayOfYear - 1) % verses.count
        return verses[index]
    }
    
    /// Get today's verse
    static var todaysVerse: (reference: String, text: String) {
        verseForDate(Date())
    }
}

/// Memorization session for a verse
struct MemorizationSession: Identifiable, Codable {
    let id: UUID
    let verseReference: String
    let verseText: String
    var attempts: Int
    var correctAttempts: Int
    var lastPracticed: Date
    var mastered: Bool
    
    init(
        id: UUID = UUID(),
        verseReference: String,
        verseText: String,
        attempts: Int = 0,
        correctAttempts: Int = 0,
        lastPracticed: Date = Date(),
        mastered: Bool = false
    ) {
        self.id = id
        self.verseReference = verseReference
        self.verseText = verseText
        self.attempts = attempts
        self.correctAttempts = correctAttempts
        self.lastPracticed = lastPracticed
        self.mastered = mastered
    }
    
    var accuracy: Double {
        guard attempts > 0 else { return 0 }
        return Double(correctAttempts) / Double(attempts)
    }
    
    mutating func recordAttempt(correct: Bool) {
        attempts += 1
        if correct {
            correctAttempts += 1
        }
        lastPracticed = Date()
        
        // Mark as mastered after 5 correct attempts with 80%+ accuracy
        if correctAttempts >= 5 && accuracy >= 0.8 {
            mastered = true
        }
    }
    
    /// Words in the verse for fill-in-blank
    var words: [String] {
        verseText.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
    }
}








