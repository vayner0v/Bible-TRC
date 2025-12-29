//
//  ReadingPlan.swift
//  Bible v1
//
//  Spiritual Hub - Bible Reading Plans Model
//

import Foundation
import SwiftUI

/// Duration categories for reading plans
enum PlanDuration: String, Codable, CaseIterable, Identifiable {
    case week = "7 Days"
    case month = "30 Days"
    case quarter = "90 Days"
    case year = "365 Days"
    
    var id: String { rawValue }
    
    var days: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .quarter: return 90
        case .year: return 365
        }
    }
}

/// Thematic categories for reading plans
enum PlanTheme: String, Codable, CaseIterable, Identifiable {
    case beginner = "Beginner"
    case peace = "Peace"
    case wisdom = "Wisdom"
    case relationships = "Relationships"
    case faith = "Faith"
    case hope = "Hope"
    case love = "Love"
    case wholeBible = "Whole Bible"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .beginner: return "sparkle"
        case .peace: return "leaf.fill"
        case .wisdom: return "lightbulb.fill"
        case .relationships: return "person.2.fill"
        case .faith: return "mountain.2.fill"
        case .hope: return "sun.max.fill"
        case .love: return "heart.fill"
        case .wholeBible: return "book.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .beginner: return .green
        case .peace: return .teal
        case .wisdom: return .yellow
        case .relationships: return .pink
        case .faith: return .brown
        case .hope: return .orange
        case .love: return .red
        case .wholeBible: return .blue
        }
    }
    
    /// Primary gradient colors for immersive backgrounds
    var gradientColors: [Color] {
        switch self {
        case .beginner:
            return [
                Color(red: 0.2, green: 0.7, blue: 0.5),
                Color(red: 0.1, green: 0.5, blue: 0.4)
            ]
        case .peace:
            return [
                Color(red: 0.15, green: 0.45, blue: 0.55),
                Color(red: 0.08, green: 0.25, blue: 0.4)
            ]
        case .wisdom:
            return [
                Color(red: 0.85, green: 0.65, blue: 0.2),
                Color(red: 0.7, green: 0.45, blue: 0.1)
            ]
        case .relationships:
            return [
                Color(red: 0.9, green: 0.45, blue: 0.55),
                Color(red: 0.7, green: 0.3, blue: 0.4)
            ]
        case .faith:
            return [
                Color(red: 0.6, green: 0.4, blue: 0.25),
                Color(red: 0.4, green: 0.25, blue: 0.15)
            ]
        case .hope:
            return [
                Color(red: 0.95, green: 0.55, blue: 0.3),
                Color(red: 0.85, green: 0.35, blue: 0.2)
            ]
        case .love:
            return [
                Color(red: 0.85, green: 0.25, blue: 0.35),
                Color(red: 0.6, green: 0.15, blue: 0.25)
            ]
        case .wholeBible:
            return [
                Color(red: 0.25, green: 0.35, blue: 0.7),
                Color(red: 0.15, green: 0.2, blue: 0.5)
            ]
        }
    }
    
    /// Accent color for buttons and highlights
    var accentColor: Color {
        switch self {
        case .beginner: return Color(red: 0.4, green: 0.9, blue: 0.6)
        case .peace: return Color(red: 0.4, green: 0.8, blue: 0.9)
        case .wisdom: return Color(red: 1.0, green: 0.85, blue: 0.4)
        case .relationships: return Color(red: 1.0, green: 0.6, blue: 0.7)
        case .faith: return Color(red: 0.9, green: 0.7, blue: 0.5)
        case .hope: return Color(red: 1.0, green: 0.75, blue: 0.4)
        case .love: return Color(red: 1.0, green: 0.5, blue: 0.6)
        case .wholeBible: return Color(red: 0.6, green: 0.7, blue: 1.0)
        }
    }
    
    var description: String {
        switch self {
        case .beginner: return "Perfect for those new to Bible reading"
        case .peace: return "Find calm and rest in God's promises"
        case .wisdom: return "Grow in understanding and discernment"
        case .relationships: return "Strengthen your connections with others"
        case .faith: return "Deepen your trust in God"
        case .hope: return "Discover encouragement for difficult times"
        case .love: return "Experience God's love and share it"
        case .wholeBible: return "Journey through the entire Bible"
        }
    }
}

/// Question type for daily quizzes
enum QuestionType: String, Codable, Hashable {
    case comprehension  // Has right/wrong answer
    case reflection     // Open-ended personal response
}

/// A quiz question for a reading plan day
struct QuizQuestion: Identifiable, Codable, Hashable {
    let id: UUID
    let question: String
    let type: QuestionType
    var options: [String]?      // For multiple choice (comprehension)
    var correctAnswer: Int?     // Index of correct option for comprehension
    var hint: String?           // Optional hint for reflection questions
    
    init(
        id: UUID = UUID(),
        question: String,
        type: QuestionType,
        options: [String]? = nil,
        correctAnswer: Int? = nil,
        hint: String? = nil
    ) {
        self.id = id
        self.question = question
        self.type = type
        self.options = options
        self.correctAnswer = correctAnswer
        self.hint = hint
    }
}

/// A single day's reading in a plan
struct ReadingPlanDay: Identifiable, Codable, Hashable {
    let id: UUID
    let dayNumber: Int
    let title: String
    let readings: [ScriptureReading]
    var reflection: String?
    var devotionalThought: String?
    
    // Enhanced content fields
    var historicalContext: String?     // Background about the passage
    var guidedPrayer: String?          // Prayer based on the reading
    var todayChallenge: String?        // Practical action step
    var crossReferences: [String]?     // Related verses (e.g., "Romans 8:28")
    var quizQuestions: [QuizQuestion]? // Daily quiz questions
    
    init(
        id: UUID = UUID(),
        dayNumber: Int,
        title: String,
        readings: [ScriptureReading],
        reflection: String? = nil,
        devotionalThought: String? = nil,
        historicalContext: String? = nil,
        guidedPrayer: String? = nil,
        todayChallenge: String? = nil,
        crossReferences: [String]? = nil,
        quizQuestions: [QuizQuestion]? = nil
    ) {
        self.id = id
        self.dayNumber = dayNumber
        self.title = title
        self.readings = readings
        self.reflection = reflection
        self.devotionalThought = devotionalThought
        self.historicalContext = historicalContext
        self.guidedPrayer = guidedPrayer
        self.todayChallenge = todayChallenge
        self.crossReferences = crossReferences
        self.quizQuestions = quizQuestions
    }
}

/// A scripture reference within a reading plan
struct ScriptureReading: Identifiable, Codable, Hashable {
    let id: UUID
    let bookId: String
    let bookName: String
    let startChapter: Int
    let endChapter: Int?
    let startVerse: Int?
    let endVerse: Int?
    
    init(
        id: UUID = UUID(),
        bookId: String,
        bookName: String,
        startChapter: Int,
        endChapter: Int? = nil,
        startVerse: Int? = nil,
        endVerse: Int? = nil
    ) {
        self.id = id
        self.bookId = bookId
        self.bookName = bookName
        self.startChapter = startChapter
        self.endChapter = endChapter
        self.startVerse = startVerse
        self.endVerse = endVerse
    }
    
    /// Display reference like "John 3:16-21" or "Psalm 23"
    var displayReference: String {
        var ref = "\(bookName) \(startChapter)"
        
        if let startV = startVerse {
            ref += ":\(startV)"
            if let endV = endVerse, endV != startV {
                ref += "-\(endV)"
            }
        } else if let endCh = endChapter, endCh != startChapter {
            ref += "-\(endCh)"
        }
        
        return ref
    }
}

/// A complete reading plan definition
struct ReadingPlan: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String
    let tagline: String
    let heroDescription: String
    let theme: PlanTheme
    let duration: PlanDuration
    let days: [ReadingPlanDay]
    let imageSystemName: String
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        tagline: String = "",
        heroDescription: String = "",
        theme: PlanTheme,
        duration: PlanDuration,
        days: [ReadingPlanDay],
        imageSystemName: String? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.tagline = tagline.isEmpty ? description : tagline
        self.heroDescription = heroDescription.isEmpty ? description : heroDescription
        self.theme = theme
        self.duration = duration
        self.days = days
        self.imageSystemName = imageSystemName ?? theme.icon
    }
    
    /// Estimated reading time per day (rough estimate)
    var estimatedDailyMinutes: Int {
        switch duration {
        case .week: return 5
        case .month: return 10
        case .quarter: return 15
        case .year: return 15
        }
    }
    
    /// A sample devotional thought from the first few days
    var sampleQuote: String? {
        days.prefix(3).compactMap { $0.devotionalThought }.first
    }
}

/// User's progress through a reading plan
struct ReadingPlanProgress: Identifiable, Codable {
    let id: UUID
    let planId: UUID
    let planName: String
    var startDate: Date
    var completedDays: Set<Int>
    var currentDay: Int
    var lastReadDate: Date?
    var isCompleted: Bool
    var completedDate: Date?
    var notes: [Int: String] // Day number to note
    
    init(
        id: UUID = UUID(),
        planId: UUID,
        planName: String,
        startDate: Date = Date(),
        completedDays: Set<Int> = [],
        currentDay: Int = 1,
        lastReadDate: Date? = nil,
        isCompleted: Bool = false,
        completedDate: Date? = nil,
        notes: [Int: String] = [:]
    ) {
        self.id = id
        self.planId = planId
        self.planName = planName
        self.startDate = startDate
        self.completedDays = completedDays
        self.currentDay = currentDay
        self.lastReadDate = lastReadDate
        self.isCompleted = isCompleted
        self.completedDate = completedDate
        self.notes = notes
    }
    
    /// Mark a day as completed
    mutating func completeDay(_ day: Int, totalDays: Int) {
        completedDays.insert(day)
        lastReadDate = Date()
        
        if day >= currentDay {
            currentDay = min(day + 1, totalDays)
        }
        
        if completedDays.count >= totalDays {
            isCompleted = true
            completedDate = Date()
        }
    }
    
    /// Progress percentage (0.0 to 1.0)
    func progressPercentage(totalDays: Int) -> Double {
        guard totalDays > 0 else { return 0 }
        return Double(completedDays.count) / Double(totalDays)
    }
    
    /// Days remaining
    func daysRemaining(totalDays: Int) -> Int {
        totalDays - completedDays.count
    }
    
    /// Current streak
    var currentStreak: Int {
        guard let lastRead = lastReadDate else { return 0 }
        let calendar = Calendar.current
        if calendar.isDateInToday(lastRead) || calendar.isDateInYesterday(lastRead) {
            // Count consecutive days backwards from last read
            var streak = 1
            var checkDate = calendar.date(byAdding: .day, value: -1, to: lastRead)!
            
            while completedDays.contains(streak) {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            }
            
            return streak
        }
        return 0
    }
    
    /// Check if reading for today is due
    var isDueToday: Bool {
        guard let lastRead = lastReadDate else { return true }
        return !Calendar.current.isDateInToday(lastRead)
    }
}

// MARK: - Static Reading Plans

extension ReadingPlan {
    
    /// All available reading plans
    static let allPlans: [ReadingPlan] = [
        // 7-day plans
        beginnerPlan,
        peacePlan,
        wisdomPlan,
        relationshipsPlan,
        // 30-day plans
        faithPlan30Day,
        gospelOfJohnPlan,
        psalmsPlan30Day,
        // 90-day plans
        newTestamentPlan,
        wisdomBooks90Day,
        // 365-day plans
        wholeBiblePlan
    ]
    
    /// Plans grouped by duration
    static var plansByDuration: [PlanDuration: [ReadingPlan]] {
        Dictionary(grouping: allPlans, by: { $0.duration })
    }
    
    /// Plans grouped by theme
    static var plansByTheme: [PlanTheme: [ReadingPlan]] {
        Dictionary(grouping: allPlans, by: { $0.theme })
    }
    
    /// 7-day beginner plan with enriched content
    static let beginnerPlan = ReadingPlan(
        name: "Getting Started",
        description: "A gentle introduction to Bible reading with key passages that reveal God's love and plan.",
        tagline: "Your first steps into Scripture",
        heroDescription: "Begin your journey through the most transformative book ever written. Over seven carefully curated days, you'll encounter the God who created you, the shepherd who guides you, and the love that changes everything. Perfect for newcomers or anyone seeking a fresh start with Scripture.",
        theme: .beginner,
        duration: .week,
        days: [
            // Day 1: In the Beginning
            ReadingPlanDay(
                dayNumber: 1,
                title: "In the Beginning",
                readings: [ScriptureReading(bookId: "GEN", bookName: "Genesis", startChapter: 1)],
                devotionalThought: "God created everything with purpose and called it good. You are part of that good creation. Before there was anything else, there was God—and He chose to create you.",
                historicalContext: "Genesis is the book of beginnings, written by Moses around 1400 BC. The Hebrew word 'bara' (create) is used exclusively for God's creative acts. This opening chapter establishes God as the sovereign Creator who brings order from chaos and speaks life into existence.",
                guidedPrayer: "Creator God, thank You for making me with intention and purpose. Help me see myself as You see me—wonderfully made and deeply loved. Open my heart to discover more of who You are as I begin this journey through Your Word. Amen.",
                todayChallenge: "Take a walk outside today and notice three things in creation that remind you of God's creativity and care. Thank Him for each one.",
                crossReferences: ["Psalm 19:1", "John 1:1-3", "Colossians 1:16"],
                quizQuestions: [
                    QuizQuestion(
                        question: "According to Genesis 1, what did God say about His creation?",
                        type: .comprehension,
                        options: ["It was complete", "It was good", "It was finished", "It was perfect"],
                        correctAnswer: 1
                    ),
                    QuizQuestion(
                        question: "How does knowing you were created with purpose change how you see yourself today?",
                        type: .reflection,
                        hint: "Consider your unique gifts, personality, and circumstances."
                    )
                ]
            ),
            
            // Day 2: The Shepherd's Care
            ReadingPlanDay(
                dayNumber: 2,
                title: "The Shepherd's Care",
                readings: [ScriptureReading(bookId: "PSA", bookName: "Psalms", startChapter: 23)],
                devotionalThought: "God is your shepherd who guides, protects, and provides for you. In ancient Israel, a shepherd would lay down his life for his sheep. This is the kind of care God has for you.",
                historicalContext: "Psalm 23 was written by David, who spent his youth as a shepherd in Bethlehem. He understood firsthand the intimate care a shepherd provides—leading sheep to food and water, protecting them from predators, and knowing each one by name. Jesus later called Himself 'the Good Shepherd.'",
                guidedPrayer: "Lord, You are my Shepherd. I trust You to lead me where I need to go, even through difficult valleys. Help me rest in Your care today and follow Your voice. Thank You for never leaving me. Amen.",
                todayChallenge: "Identify one area of your life where you're feeling anxious or uncertain. Consciously hand it over to your Shepherd in prayer.",
                crossReferences: ["John 10:11", "Isaiah 40:11", "1 Peter 2:25"],
                quizQuestions: [
                    QuizQuestion(
                        question: "What does the shepherd do for the sheep in 'the valley of the shadow of death'?",
                        type: .comprehension,
                        options: ["Carries them", "Comforts them", "Hides them", "Leaves them"],
                        correctAnswer: 1
                    ),
                    QuizQuestion(
                        question: "What does it mean to you personally that God wants to be your Shepherd?",
                        type: .reflection,
                        hint: "Think about areas where you need guidance or protection."
                    )
                ]
            ),
            
            // Day 3: God's Love
            ReadingPlanDay(
                dayNumber: 3,
                title: "God's Love",
                readings: [ScriptureReading(bookId: "JHN", bookName: "John", startChapter: 3, startVerse: 1, endVerse: 21)],
                devotionalThought: "God's love is so great that He gave His Son so that everyone who believes can have eternal life. This is not a distant, abstract love—it's personal, sacrificial, and offered freely to you.",
                historicalContext: "Nicodemus was a Pharisee and member of the Jewish ruling council. He came to Jesus at night, perhaps afraid of what others would think. Jesus's words about being 'born again' introduced a revolutionary concept: relationship with God isn't about religious performance but spiritual transformation.",
                guidedPrayer: "Father, Your love amazes me. You didn't wait for me to be good enough—You loved me while I was still far from You. Help me receive this love fully and share it with others. Thank You for the gift of Your Son. Amen.",
                todayChallenge: "Write John 3:16 on a card and put it somewhere you'll see it often this week. Each time you see it, thank God for His love.",
                crossReferences: ["Romans 5:8", "1 John 4:9-10", "Ephesians 2:4-5"],
                quizQuestions: [
                    QuizQuestion(
                        question: "What motivated God to send His Son into the world?",
                        type: .comprehension,
                        options: ["Our goodness", "His love", "Our prayers", "Religious leaders"],
                        correctAnswer: 1
                    ),
                    QuizQuestion(
                        question: "Jesus told Nicodemus he must be 'born again.' What might need to be made new in your life?",
                        type: .reflection,
                        hint: "Consider habits, attitudes, or perspectives."
                    )
                ]
            ),
            
            // Day 4: The Beatitudes
            ReadingPlanDay(
                dayNumber: 4,
                title: "The Beatitudes",
                readings: [ScriptureReading(bookId: "MAT", bookName: "Matthew", startChapter: 5, startVerse: 1, endVerse: 16)],
                devotionalThought: "Jesus describes the heart attitudes that lead to true blessing. These 'Beatitudes' turn worldly values upside down—showing that God's kingdom operates by different rules than the world around us.",
                historicalContext: "The Sermon on the Mount was delivered on a hillside near the Sea of Galilee. Large crowds followed Jesus, and He sat down to teach—the traditional posture of a rabbi. These opening statements would have shocked His audience, blessing those society often overlooked: the poor, the mourning, the meek.",
                guidedPrayer: "Jesus, Your words challenge my assumptions about success and happiness. Give me hunger for righteousness, a merciful heart, and the courage to be a peacemaker. Let my life be salt and light to those around me. Amen.",
                todayChallenge: "Choose one Beatitude that challenges you most. Ask God to develop that quality in you today through a specific situation.",
                crossReferences: ["Luke 6:20-23", "James 4:10", "1 Peter 3:14"],
                quizQuestions: [
                    QuizQuestion(
                        question: "According to Jesus, who will be 'called sons of God'?",
                        type: .comprehension,
                        options: ["The strong", "The wealthy", "The peacemakers", "The religious"],
                        correctAnswer: 2
                    ),
                    QuizQuestion(
                        question: "Which Beatitude speaks most to your current life situation? Why?",
                        type: .reflection,
                        hint: "Consider your struggles and what kind of blessing you need."
                    )
                ]
            ),
            
            // Day 5: Faith Heroes
            ReadingPlanDay(
                dayNumber: 5,
                title: "Faith Heroes",
                readings: [ScriptureReading(bookId: "HEB", bookName: "Hebrews", startChapter: 11, startVerse: 1, endVerse: 16)],
                devotionalThought: "Faith is trusting God even when we can't see the full picture. These heroes of faith weren't perfect people—they were ordinary people who took extraordinary steps of trust in an extraordinary God.",
                historicalContext: "Hebrews was written to Jewish Christians facing persecution and tempted to return to Judaism. Chapter 11, often called 'The Hall of Faith,' reminded them of ancestors who trusted God despite incredible obstacles. Abraham left his homeland not knowing where he was going. Noah built a boat when there was no sign of rain.",
                guidedPrayer: "Lord, strengthen my faith. Like Abraham, help me step out in trust even when I can't see the destination. Like the heroes in this chapter, may I live with confidence in Your promises. Amen.",
                todayChallenge: "Identify one step of faith you've been hesitant to take. Write it down and commit it to prayer this week.",
                crossReferences: ["Romans 4:20-21", "2 Corinthians 5:7", "James 2:23"],
                quizQuestions: [
                    QuizQuestion(
                        question: "How does Hebrews 11:1 define faith?",
                        type: .comprehension,
                        options: ["Seeing is believing", "Confidence in what we hope for", "Following our feelings", "Religious ritual"],
                        correctAnswer: 1
                    ),
                    QuizQuestion(
                        question: "Which person of faith in this passage inspires you most? What can you learn from their example?",
                        type: .reflection,
                        hint: "Think about the challenges they faced and how they responded."
                    )
                ]
            ),
            
            // Day 6: The Fruit of the Spirit
            ReadingPlanDay(
                dayNumber: 6,
                title: "The Fruit of the Spirit",
                readings: [ScriptureReading(bookId: "GAL", bookName: "Galatians", startChapter: 5, startVerse: 16, endVerse: 26)],
                devotionalThought: "The Holy Spirit produces beautiful character in those who walk with Him. These qualities aren't achieved through willpower but received through surrender—letting God's Spirit work in us.",
                historicalContext: "Paul wrote to the Galatians to correct false teaching that Christians must follow Jewish law to be saved. He contrasts life controlled by sinful nature with life led by the Spirit. The 'fruit' is singular—these nine qualities are aspects of one unified character that the Spirit develops.",
                guidedPrayer: "Holy Spirit, I invite You to work in my heart. Produce Your fruit in me—love where there's indifference, joy where there's despair, peace where there's anxiety. I surrender my self-efforts and trust Your transforming work. Amen.",
                todayChallenge: "Pick one fruit of the Spirit you want to see grow in your life. Look for one opportunity today to practice it intentionally.",
                crossReferences: ["John 15:4-5", "Romans 8:5-6", "Colossians 3:12-14"],
                quizQuestions: [
                    QuizQuestion(
                        question: "How many 'fruits' of the Spirit are listed in Galatians 5:22-23?",
                        type: .comprehension,
                        options: ["Seven", "Eight", "Nine", "Twelve"],
                        correctAnswer: 2
                    ),
                    QuizQuestion(
                        question: "Which fruit of the Spirit do you most want to see developed in your life right now? What's blocking it?",
                        type: .reflection,
                        hint: "Consider which one feels most lacking or needed."
                    )
                ]
            ),
            
            // Day 7: A New Creation
            ReadingPlanDay(
                dayNumber: 7,
                title: "A New Creation",
                readings: [ScriptureReading(bookId: "REV", bookName: "Revelation", startChapter: 21, startVerse: 1, endVerse: 8)],
                devotionalThought: "God promises to make all things new. Hope awaits! The story that began with 'In the beginning' ends with a new beginning—a restored creation where God dwells with His people forever.",
                historicalContext: "Revelation was written by the Apostle John while exiled on the island of Patmos around 95 AD. This vision of the new heaven and earth was given to encourage persecuted Christians. The imagery draws on Old Testament prophecies, showing that God's plan of redemption will be completely fulfilled.",
                guidedPrayer: "God of hope, thank You that this world's brokenness is not the end of the story. You are making all things new—including me. Help me live today in light of eternity, with hope that anchors my soul. Come, Lord Jesus. Amen.",
                todayChallenge: "Reflect on your week of reading. Write down three things you've learned about God and one way you want to respond going forward.",
                crossReferences: ["Isaiah 65:17", "2 Corinthians 5:17", "2 Peter 3:13"],
                quizQuestions: [
                    QuizQuestion(
                        question: "In the new creation, where will God dwell?",
                        type: .comprehension,
                        options: ["In heaven alone", "With His people", "In the temple", "On a mountain"],
                        correctAnswer: 1
                    ),
                    QuizQuestion(
                        question: "Looking back on this 7-day journey, what is the most significant thing God has shown you?",
                        type: .reflection,
                        hint: "Consider your highlights and how your understanding of God has grown."
                    ),
                    QuizQuestion(
                        question: "What will you do next to continue growing in your faith?",
                        type: .reflection,
                        hint: "Think about next steps—another reading plan, joining a group, or a specific commitment."
                    )
                ]
            )
        ]
    )
    
    /// 7-day peace plan
    static let peacePlan = ReadingPlan(
        name: "Finding Peace",
        description: "Discover God's peace that surpasses understanding through these calming passages.",
        tagline: "Rest for your weary soul",
        heroDescription: "In a world of noise and anxiety, discover the deep stillness that only God can provide. This seven-day journey will lead you through Scripture's most calming passages—from quiet waters to perfect peace. Let these words wash over you and anchor your heart in divine tranquility.",
        theme: .peace,
        duration: .week,
        days: [
            ReadingPlanDay(
                dayNumber: 1,
                title: "Do Not Be Anxious",
                readings: [ScriptureReading(bookId: "PHP", bookName: "Philippians", startChapter: 4, startVerse: 4, endVerse: 9)],
                devotionalThought: "God invites you to bring every worry to Him in prayer."
            ),
            ReadingPlanDay(
                dayNumber: 2,
                title: "Rest for the Weary",
                readings: [ScriptureReading(bookId: "MAT", bookName: "Matthew", startChapter: 11, startVerse: 25, endVerse: 30)],
                devotionalThought: "Jesus offers rest to all who are weary and burdened."
            ),
            ReadingPlanDay(
                dayNumber: 3,
                title: "The Lord is My Shepherd",
                readings: [ScriptureReading(bookId: "PSA", bookName: "Psalms", startChapter: 23)],
                devotionalThought: "In God's care, you lack nothing and fear nothing."
            ),
            ReadingPlanDay(
                dayNumber: 4,
                title: "Peace I Leave With You",
                readings: [ScriptureReading(bookId: "JHN", bookName: "John", startChapter: 14, startVerse: 25, endVerse: 31)],
                devotionalThought: "The peace Jesus gives is different from what the world offers."
            ),
            ReadingPlanDay(
                dayNumber: 5,
                title: "Cast Your Cares",
                readings: [ScriptureReading(bookId: "1PE", bookName: "1 Peter", startChapter: 5, startVerse: 6, endVerse: 11)],
                devotionalThought: "God cares deeply for you. Cast all your anxiety on Him."
            ),
            ReadingPlanDay(
                dayNumber: 6,
                title: "Be Still and Know",
                readings: [ScriptureReading(bookId: "PSA", bookName: "Psalms", startChapter: 46)],
                devotionalThought: "God is our refuge and strength, always present in trouble."
            ),
            ReadingPlanDay(
                dayNumber: 7,
                title: "Perfect Peace",
                readings: [ScriptureReading(bookId: "ISA", bookName: "Isaiah", startChapter: 26, startVerse: 1, endVerse: 12)],
                devotionalThought: "Those who trust in God are kept in perfect peace."
            )
        ]
    )
    
    /// 7-day wisdom plan
    static let wisdomPlan = ReadingPlan(
        name: "Growing in Wisdom",
        description: "Gain godly wisdom for daily decisions and life's big questions.",
        tagline: "Ancient wisdom for modern life",
        heroDescription: "Every day presents choices that shape our lives. This week, sit at the feet of the wisest teachings ever recorded. From Solomon's proverbs to Jesus' parables, discover timeless truths that will transform how you think, speak, and live. Wisdom is calling—will you answer?",
        theme: .wisdom,
        duration: .week,
        days: [
            ReadingPlanDay(
                dayNumber: 1,
                title: "The Beginning of Wisdom",
                readings: [ScriptureReading(bookId: "PRO", bookName: "Proverbs", startChapter: 1, startVerse: 1, endVerse: 19)],
                devotionalThought: "The fear of the Lord is the foundation of all true wisdom."
            ),
            ReadingPlanDay(
                dayNumber: 2,
                title: "Seek Understanding",
                readings: [ScriptureReading(bookId: "PRO", bookName: "Proverbs", startChapter: 2)],
                devotionalThought: "Pursue wisdom as you would search for hidden treasure."
            ),
            ReadingPlanDay(
                dayNumber: 3,
                title: "Trust in the Lord",
                readings: [ScriptureReading(bookId: "PRO", bookName: "Proverbs", startChapter: 3, startVerse: 1, endVerse: 18)],
                devotionalThought: "Trust God with all your heart rather than leaning on your own understanding."
            ),
            ReadingPlanDay(
                dayNumber: 4,
                title: "Wisdom's Call",
                readings: [ScriptureReading(bookId: "PRO", bookName: "Proverbs", startChapter: 8, startVerse: 1, endVerse: 21)],
                devotionalThought: "Wisdom calls out to all who will listen."
            ),
            ReadingPlanDay(
                dayNumber: 5,
                title: "Ask God for Wisdom",
                readings: [ScriptureReading(bookId: "JAS", bookName: "James", startChapter: 1, startVerse: 1, endVerse: 18)],
                devotionalThought: "God gives wisdom generously to all who ask in faith."
            ),
            ReadingPlanDay(
                dayNumber: 6,
                title: "Wise Living",
                readings: [ScriptureReading(bookId: "JAS", bookName: "James", startChapter: 3, startVerse: 13, endVerse: 18)],
                devotionalThought: "Heavenly wisdom is pure, peace-loving, and full of mercy."
            ),
            ReadingPlanDay(
                dayNumber: 7,
                title: "The Wise Builder",
                readings: [ScriptureReading(bookId: "MAT", bookName: "Matthew", startChapter: 7, startVerse: 24, endVerse: 29)],
                devotionalThought: "Build your life on the solid foundation of God's Word."
            )
        ]
    )
    
    /// 7-day relationships plan
    static let relationshipsPlan = ReadingPlan(
        name: "Better Relationships",
        description: "Learn to love others well through God's guidance on relationships.",
        tagline: "Love others as you are loved",
        heroDescription: "Our relationships define our lives—yet they can be our greatest challenge. Journey through seven days of Scripture's most profound teachings on love, forgiveness, unity, and service. Discover how to strengthen bonds, heal wounds, and reflect God's love in every interaction.",
        theme: .relationships,
        duration: .week,
        days: [
            ReadingPlanDay(
                dayNumber: 1,
                title: "Love One Another",
                readings: [ScriptureReading(bookId: "1JN", bookName: "1 John", startChapter: 4, startVerse: 7, endVerse: 21)],
                devotionalThought: "We love because God first loved us."
            ),
            ReadingPlanDay(
                dayNumber: 2,
                title: "The Love Chapter",
                readings: [ScriptureReading(bookId: "1CO", bookName: "1 Corinthians", startChapter: 13)],
                devotionalThought: "Love is patient, kind, and never fails."
            ),
            ReadingPlanDay(
                dayNumber: 3,
                title: "Forgiveness",
                readings: [ScriptureReading(bookId: "MAT", bookName: "Matthew", startChapter: 18, startVerse: 21, endVerse: 35)],
                devotionalThought: "Forgive as you have been forgiven."
            ),
            ReadingPlanDay(
                dayNumber: 4,
                title: "Words That Build Up",
                readings: [ScriptureReading(bookId: "EPH", bookName: "Ephesians", startChapter: 4, startVerse: 25, endVerse: 32)],
                devotionalThought: "Let your words be gracious and build others up."
            ),
            ReadingPlanDay(
                dayNumber: 5,
                title: "Serving Others",
                readings: [ScriptureReading(bookId: "PHP", bookName: "Philippians", startChapter: 2, startVerse: 1, endVerse: 11)],
                devotionalThought: "Consider others more important than yourself, as Christ did."
            ),
            ReadingPlanDay(
                dayNumber: 6,
                title: "Bearing One Another's Burdens",
                readings: [ScriptureReading(bookId: "GAL", bookName: "Galatians", startChapter: 6, startVerse: 1, endVerse: 10)],
                devotionalThought: "Carry each other's burdens and fulfill the law of Christ."
            ),
            ReadingPlanDay(
                dayNumber: 7,
                title: "Unity in Christ",
                readings: [ScriptureReading(bookId: "COL", bookName: "Colossians", startChapter: 3, startVerse: 12, endVerse: 17)],
                devotionalThought: "Clothe yourself with compassion, kindness, humility, and patience."
            )
        ]
    )
    
    // MARK: - 30-Day Plans
    
    /// 30-day faith building plan
    static let faithPlan30Day = ReadingPlan(
        name: "30 Days of Faith",
        description: "A month-long journey through Scripture's greatest faith stories and teachings.",
        tagline: "Walk with the heroes of faith",
        heroDescription: "From Abraham leaving everything familiar to David facing his giant, from Moses at the burning bush to the disciples walking on water—these are the stories that have inspired believers for millennia. Over 30 days, witness faith tested, refined, and triumphant. Your own faith will never be the same.",
        theme: .faith,
        duration: .month,
        days: generateFaithPlan30Days()
    )
    
    /// 30-day Gospel of John plan
    static let gospelOfJohnPlan = ReadingPlan(
        name: "Journey Through John",
        description: "Experience the Gospel of John chapter by chapter over 30 days.",
        tagline: "Encounter Jesus like never before",
        heroDescription: "John walked with Jesus. Ate with him. Watched him transform water into wine and death into life. Now his intimate account invites you into that same closeness. Over 30 days, experience the 'I AM' statements, the tender moments, and the cosmic truth that 'the Word became flesh and dwelt among us.'",
        theme: .beginner,
        duration: .month,
        days: generateGospelOfJohnDays()
    )
    
    /// 30-day Psalms plan
    static let psalmsPlan30Day = ReadingPlan(
        name: "A Month in the Psalms",
        description: "Read through 5 Psalms each day for a month of worship and reflection.",
        tagline: "The prayer book of the ages",
        heroDescription: "For three thousand years, people have turned to the Psalms in joy and sorrow, triumph and despair. These ancient songs capture every human emotion and lift them to God. Spend a month immersed in poetry that has comforted the grieving, strengthened the weak, and given voice to the grateful.",
        theme: .peace,
        duration: .month,
        days: generatePsalmsPlanDays()
    )
    
    // MARK: - 90-Day Plans
    
    /// 90-day New Testament plan
    static let newTestamentPlan = ReadingPlan(
        name: "New Testament in 90 Days",
        description: "Read the entire New Testament in three months with daily readings.",
        tagline: "The story of Jesus and His church",
        heroDescription: "The New Testament changed the world. In 90 days, experience the complete narrative—from Jesus' birth in a humble manger to John's breathtaking vision of eternity. Meet the disciples, walk the roads of ancient Israel, witness the birth of the church, and read the letters that shaped civilization.",
        theme: .faith,
        duration: .quarter,
        days: generateNewTestamentDays()
    )
    
    /// 90-day Wisdom Books plan
    static let wisdomBooks90Day = ReadingPlan(
        name: "Wisdom Literature",
        description: "Deep dive into Job, Psalms, Proverbs, Ecclesiastes, and Song of Solomon.",
        tagline: "Poetry for the soul",
        heroDescription: "Suffering. Worship. Practical living. Life's meaning. Romantic love. The wisdom books explore the full spectrum of human experience with brutal honesty and transcendent beauty. Over 90 days, let these ancient poets and sages reshape how you see yourself, your relationships, and your God.",
        theme: .wisdom,
        duration: .quarter,
        days: generateWisdomBooksDays()
    )
    
    // MARK: - 365-Day Plans
    
    /// 365-day whole Bible plan
    static let wholeBiblePlan = ReadingPlan(
        name: "Bible in a Year",
        description: "Journey through the entire Bible with daily Old and New Testament readings.",
        tagline: "The complete epic",
        heroDescription: "One year. One book. One story. From 'In the beginning' to 'Amen,' experience the greatest narrative ever told. Each day blends Old and New Testament readings, revealing how every thread weaves into God's grand tapestry of redemption. This is not just reading—it's a pilgrimage through the Word that will transform your year and your life.",
        theme: .wholeBible,
        duration: .year,
        days: generateWholeBibleDays()
    )
    
    // MARK: - Plan Generators
    
    private static func generateFaithPlan30Days() -> [ReadingPlanDay] {
        let readings: [(title: String, book: String, bookId: String, chapter: Int, startV: Int?, endV: Int?, thought: String)] = [
            ("Abraham's Call", "Genesis", "GEN", 12, 1, 9, "Faith begins with trusting God's call."),
            ("Abraham's Promise", "Genesis", "GEN", 15, 1, 21, "God rewards those who believe His promises."),
            ("Abraham's Test", "Genesis", "GEN", 22, 1, 19, "True faith is willing to sacrifice everything."),
            ("Jacob's Dream", "Genesis", "GEN", 28, 10, 22, "God meets us even in unexpected places."),
            ("Joseph's Faith", "Genesis", "GEN", 50, 15, 26, "God works all things for good."),
            ("Moses at the Bush", "Exodus", "EXO", 3, 1, 22, "God calls ordinary people for extraordinary purposes."),
            ("Crossing the Sea", "Exodus", "EXO", 14, 10, 31, "When trapped, trust God to make a way."),
            ("Joshua's Charge", "Joshua", "JOS", 1, 1, 18, "Be strong and courageous in faith."),
            ("Walls of Jericho", "Joshua", "JOS", 6, 1, 27, "Obedience brings victory."),
            ("Gideon's Call", "Judges", "JDG", 6, 11, 40, "God uses the weak to confound the strong."),
            ("Ruth's Loyalty", "Ruth", "RUT", 1, 1, 22, "Faith expresses itself in faithful love."),
            ("Samuel Hears God", "1 Samuel", "1SA", 3, 1, 21, "Listen for God's voice."),
            ("David and Goliath", "1 Samuel", "1SA", 17, 31, 50, "Faith conquers giants."),
            ("Elijah's Stand", "1 Kings", "1KI", 18, 20, 40, "Bold faith brings God's fire."),
            ("Elijah's Whisper", "1 Kings", "1KI", 19, 1, 18, "God speaks in the stillness."),
            ("Naaman's Healing", "2 Kings", "2KI", 5, 1, 19, "Faith requires humble obedience."),
            ("Esther's Courage", "Esther", "EST", 4, 1, 17, "For such a time as this."),
            ("Job's Declaration", "Job", "JOB", 19, 13, 29, "Though He slay me, I will trust."),
            ("Daniel's Friends", "Daniel", "DAN", 3, 13, 30, "Faith stands firm in the fire."),
            ("Daniel's Lions", "Daniel", "DAN", 6, 10, 28, "Faithful devotion is rewarded."),
            ("Jonah's Second Chance", "Jonah", "JON", 3, 1, 10, "God gives second chances."),
            ("Faith Hall of Fame I", "Hebrews", "HEB", 11, 1, 16, "Faith is the substance of things hoped for."),
            ("Faith Hall of Fame II", "Hebrews", "HEB", 11, 17, 31, "By faith they conquered kingdoms."),
            ("Faith Hall of Fame III", "Hebrews", "HEB", 11, 32, 40, "The world was not worthy of them."),
            ("Jesus on Faith", "Matthew", "MAT", 17, 14, 21, "Faith as small as a mustard seed."),
            ("The Centurion", "Matthew", "MAT", 8, 5, 13, "Great faith recognized."),
            ("Woman of Faith", "Mark", "MRK", 5, 25, 34, "Your faith has healed you."),
            ("Peter's Walk", "Matthew", "MAT", 14, 22, 33, "Keep your eyes on Jesus."),
            ("Thomas Believes", "John", "JHN", 20, 24, 31, "Blessed are those who believe."),
            ("Faith That Works", "James", "JAS", 2, 14, 26, "Faith without works is dead.")
        ]
        
        return readings.enumerated().map { index, reading in
            ReadingPlanDay(
                dayNumber: index + 1,
                title: reading.title,
                readings: [ScriptureReading(
                    bookId: reading.bookId,
                    bookName: reading.book,
                    startChapter: reading.chapter,
                    startVerse: reading.startV,
                    endVerse: reading.endV
                )],
                devotionalThought: reading.thought
            )
        }
    }
    
    private static func generateGospelOfJohnDays() -> [ReadingPlanDay] {
        let chapters = [
            ("The Word Made Flesh", 1),
            ("Water to Wine", 2),
            ("Born Again", 3),
            ("Living Water", 4),
            ("Healing at the Pool", 5),
            ("Bread of Life", 6),
            ("Rivers of Living Water", 7),
            ("Light of the World", 8),
            ("Blind Man Sees", 9),
            ("The Good Shepherd", 10),
            ("Lazarus Lives", 11),
            ("Jesus Anointed", 12),
            ("Washing Feet", 13),
            ("The Way, Truth, Life", 14),
            ("The True Vine", 15),
            ("The Helper", 16),
            ("Jesus Prays", 17),
            ("Arrest and Trial", 18),
            ("Crucified", 19),
            ("Resurrection", 20),
            ("Restored Peter", 21)
        ]
        
        // Create 30 days, some chapters split into parts
        var days: [ReadingPlanDay] = []
        var dayNum = 1
        
        for (title, chapter) in chapters {
            if chapter == 1 || chapter == 6 || chapter == 17 {
                // Split longer chapters
                days.append(ReadingPlanDay(
                    dayNumber: dayNum,
                    title: "\(title) (Part 1)",
                    readings: [ScriptureReading(bookId: "JHN", bookName: "John", startChapter: chapter, startVerse: 1, endVerse: 24)]
                ))
                dayNum += 1
                days.append(ReadingPlanDay(
                    dayNumber: dayNum,
                    title: "\(title) (Part 2)",
                    readings: [ScriptureReading(bookId: "JHN", bookName: "John", startChapter: chapter, startVerse: 25, endVerse: nil)]
                ))
                dayNum += 1
            } else {
                days.append(ReadingPlanDay(
                    dayNumber: dayNum,
                    title: title,
                    readings: [ScriptureReading(bookId: "JHN", bookName: "John", startChapter: chapter)]
                ))
                dayNum += 1
            }
            
            if dayNum > 30 { break }
        }
        
        // Fill remaining days with reflection
        while days.count < 30 {
            days.append(ReadingPlanDay(
                dayNumber: days.count + 1,
                title: "Review Day \(days.count - 20)",
                readings: [ScriptureReading(bookId: "JHN", bookName: "John", startChapter: days.count - 20)],
                devotionalThought: "Review and reflect on what you've learned."
            ))
        }
        
        return days
    }
    
    private static func generatePsalmsPlanDays() -> [ReadingPlanDay] {
        return (1...30).map { day in
            let psalms = (0..<5).map { i in
                let psalmNum = day + (i * 30)
                return psalmNum <= 150 ? psalmNum : nil
            }.compactMap { $0 }
            
            let readings = psalms.map { psalm in
                ScriptureReading(bookId: "PSA", bookName: "Psalms", startChapter: psalm)
            }
            
            return ReadingPlanDay(
                dayNumber: day,
                title: "Psalms \(psalms.map { String($0) }.joined(separator: ", "))",
                readings: readings,
                devotionalThought: "Let these songs of worship fill your heart today."
            )
        }
    }
    
    private static func generateNewTestamentDays() -> [ReadingPlanDay] {
        // NT has 260 chapters - about 3 chapters per day for 90 days
        let books: [(name: String, id: String, chapters: Int)] = [
            ("Matthew", "MAT", 28),
            ("Mark", "MRK", 16),
            ("Luke", "LUK", 24),
            ("John", "JHN", 21),
            ("Acts", "ACT", 28),
            ("Romans", "ROM", 16),
            ("1 Corinthians", "1CO", 16),
            ("2 Corinthians", "2CO", 13),
            ("Galatians", "GAL", 6),
            ("Ephesians", "EPH", 6),
            ("Philippians", "PHP", 4),
            ("Colossians", "COL", 4),
            ("1 Thessalonians", "1TH", 5),
            ("2 Thessalonians", "2TH", 3),
            ("1 Timothy", "1TI", 6),
            ("2 Timothy", "2TI", 4),
            ("Titus", "TIT", 3),
            ("Philemon", "PHM", 1),
            ("Hebrews", "HEB", 13),
            ("James", "JAS", 5),
            ("1 Peter", "1PE", 5),
            ("2 Peter", "2PE", 3),
            ("1 John", "1JN", 5),
            ("2 John", "2JN", 1),
            ("3 John", "3JN", 1),
            ("Jude", "JUD", 1),
            ("Revelation", "REV", 22)
        ]
        
        var days: [ReadingPlanDay] = []
        var dayNum = 1
        var currentBook = 0
        var currentChapter = 1
        
        while dayNum <= 90 && currentBook < books.count {
            let book = books[currentBook]
            let chaptersToRead = min(3, book.chapters - currentChapter + 1)
            let endChapter = currentChapter + chaptersToRead - 1
            
            let reading = ScriptureReading(
                bookId: book.id,
                bookName: book.name,
                startChapter: currentChapter,
                endChapter: endChapter > currentChapter ? endChapter : nil
            )
            
            days.append(ReadingPlanDay(
                dayNumber: dayNum,
                title: "\(book.name) \(currentChapter)\(endChapter > currentChapter ? "-\(endChapter)" : "")",
                readings: [reading]
            ))
            
            currentChapter = endChapter + 1
            if currentChapter > book.chapters {
                currentBook += 1
                currentChapter = 1
            }
            dayNum += 1
        }
        
        return days
    }
    
    private static func generateWisdomBooksDays() -> [ReadingPlanDay] {
        // Job 42, Psalms 150, Proverbs 31, Ecclesiastes 12, Song of Solomon 8
        var days: [ReadingPlanDay] = []
        var dayNum = 1
        
        // Job (42 chapters over ~14 days, 3 per day)
        for i in stride(from: 1, through: 42, by: 3) {
            let endChapter = min(i + 2, 42)
            days.append(ReadingPlanDay(
                dayNumber: dayNum,
                title: "Job \(i)-\(endChapter)",
                readings: [ScriptureReading(bookId: "JOB", bookName: "Job", startChapter: i, endChapter: endChapter)]
            ))
            dayNum += 1
        }
        
        // Psalms (150 chapters over ~50 days, 3 per day)
        for i in stride(from: 1, through: 150, by: 3) {
            let endChapter = min(i + 2, 150)
            days.append(ReadingPlanDay(
                dayNumber: dayNum,
                title: "Psalms \(i)-\(endChapter)",
                readings: [ScriptureReading(bookId: "PSA", bookName: "Psalms", startChapter: i, endChapter: endChapter)]
            ))
            dayNum += 1
            if dayNum > 65 { break } // Leave room for other books
        }
        
        // Proverbs (31 chapters over ~10 days)
        for i in stride(from: 1, through: 31, by: 3) {
            let endChapter = min(i + 2, 31)
            days.append(ReadingPlanDay(
                dayNumber: dayNum,
                title: "Proverbs \(i)-\(endChapter)",
                readings: [ScriptureReading(bookId: "PRO", bookName: "Proverbs", startChapter: i, endChapter: endChapter)]
            ))
            dayNum += 1
        }
        
        // Ecclesiastes (12 chapters over 6 days)
        for i in stride(from: 1, through: 12, by: 2) {
            let endChapter = min(i + 1, 12)
            days.append(ReadingPlanDay(
                dayNumber: dayNum,
                title: "Ecclesiastes \(i)-\(endChapter)",
                readings: [ScriptureReading(bookId: "ECC", bookName: "Ecclesiastes", startChapter: i, endChapter: endChapter)]
            ))
            dayNum += 1
        }
        
        // Song of Solomon (8 chapters over 4 days)
        for i in stride(from: 1, through: 8, by: 2) {
            let endChapter = min(i + 1, 8)
            days.append(ReadingPlanDay(
                dayNumber: dayNum,
                title: "Song of Solomon \(i)-\(endChapter)",
                readings: [ScriptureReading(bookId: "SNG", bookName: "Song of Solomon", startChapter: i, endChapter: endChapter)]
            ))
            dayNum += 1
        }
        
        return Array(days.prefix(90))
    }
    
    private static func generateWholeBibleDays() -> [ReadingPlanDay] {
        // This creates a 365-day plan with OT and NT readings each day
        // Total: 929 OT chapters + 260 NT chapters = 1189 chapters
        // ~3-4 chapters per day
        
        let otBooks: [(name: String, id: String, chapters: Int)] = [
            ("Genesis", "GEN", 50), ("Exodus", "EXO", 40), ("Leviticus", "LEV", 27),
            ("Numbers", "NUM", 36), ("Deuteronomy", "DEU", 34), ("Joshua", "JOS", 24),
            ("Judges", "JDG", 21), ("Ruth", "RUT", 4), ("1 Samuel", "1SA", 31),
            ("2 Samuel", "2SA", 24), ("1 Kings", "1KI", 22), ("2 Kings", "2KI", 25),
            ("1 Chronicles", "1CH", 29), ("2 Chronicles", "2CH", 36), ("Ezra", "EZR", 10),
            ("Nehemiah", "NEH", 13), ("Esther", "EST", 10), ("Job", "JOB", 42),
            ("Psalms", "PSA", 150), ("Proverbs", "PRO", 31), ("Ecclesiastes", "ECC", 12),
            ("Song of Solomon", "SNG", 8), ("Isaiah", "ISA", 66), ("Jeremiah", "JER", 52),
            ("Lamentations", "LAM", 5), ("Ezekiel", "EZE", 48), ("Daniel", "DAN", 12),
            ("Hosea", "HOS", 14), ("Joel", "JOL", 3), ("Amos", "AMO", 9),
            ("Obadiah", "OBA", 1), ("Jonah", "JON", 4), ("Micah", "MIC", 7),
            ("Nahum", "NAM", 3), ("Habakkuk", "HAB", 3), ("Zephaniah", "ZEP", 3),
            ("Haggai", "HAG", 2), ("Zechariah", "ZEC", 14), ("Malachi", "MAL", 4)
        ]
        
        let ntBooks: [(name: String, id: String, chapters: Int)] = [
            ("Matthew", "MAT", 28), ("Mark", "MRK", 16), ("Luke", "LUK", 24),
            ("John", "JHN", 21), ("Acts", "ACT", 28), ("Romans", "ROM", 16),
            ("1 Corinthians", "1CO", 16), ("2 Corinthians", "2CO", 13), ("Galatians", "GAL", 6),
            ("Ephesians", "EPH", 6), ("Philippians", "PHP", 4), ("Colossians", "COL", 4),
            ("1 Thessalonians", "1TH", 5), ("2 Thessalonians", "2TH", 3), ("1 Timothy", "1TI", 6),
            ("2 Timothy", "2TI", 4), ("Titus", "TIT", 3), ("Philemon", "PHM", 1),
            ("Hebrews", "HEB", 13), ("James", "JAS", 5), ("1 Peter", "1PE", 5),
            ("2 Peter", "2PE", 3), ("1 John", "1JN", 5), ("2 John", "2JN", 1),
            ("3 John", "3JN", 1), ("Jude", "JUD", 1), ("Revelation", "REV", 22)
        ]
        
        var days: [ReadingPlanDay] = []
        var otBookIdx = 0
        var otChapter = 1
        var ntBookIdx = 0
        var ntChapter = 1
        
        for dayNum in 1...365 {
            var readings: [ScriptureReading] = []
            
            // OT reading (~2-3 chapters)
            if otBookIdx < otBooks.count {
                let book = otBooks[otBookIdx]
                let chaptersToRead = min(3, book.chapters - otChapter + 1)
                let endChapter = otChapter + chaptersToRead - 1
                
                readings.append(ScriptureReading(
                    bookId: book.id,
                    bookName: book.name,
                    startChapter: otChapter,
                    endChapter: endChapter > otChapter ? endChapter : nil
                ))
                
                otChapter = endChapter + 1
                if otChapter > book.chapters {
                    otBookIdx += 1
                    otChapter = 1
                }
            }
            
            // NT reading (~1 chapter)
            if ntBookIdx < ntBooks.count {
                let book = ntBooks[ntBookIdx]
                
                readings.append(ScriptureReading(
                    bookId: book.id,
                    bookName: book.name,
                    startChapter: ntChapter
                ))
                
                ntChapter += 1
                if ntChapter > book.chapters {
                    ntBookIdx += 1
                    ntChapter = 1
                }
            }
            
            let title: String
            if readings.count >= 2 {
                title = "\(readings[0].displayReference) + \(readings[1].displayReference)"
            } else if let first = readings.first {
                title = first.displayReference
            } else {
                title = "Day \(dayNum)"
            }
            
            days.append(ReadingPlanDay(
                dayNumber: dayNum,
                title: title,
                readings: readings
            ))
        }
        
        return days
    }
}

