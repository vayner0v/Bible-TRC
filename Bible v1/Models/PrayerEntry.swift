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
    
    var phaseCount: Int {
        switch self {
        case .twoMinutes: return 3
        case .fiveMinutes: return 5
        case .tenMinutes: return 6
        }
    }
    
    var tagline: String {
        switch self {
        case .twoMinutes: return "A quick moment to center your heart"
        case .fiveMinutes: return "A balanced journey through prayer"
        case .tenMinutes: return "A deep, contemplative experience"
        }
    }
}

/// A single phase in a guided prayer session with rich content
struct GuidedPrayerPhase: Identifiable {
    let id = UUID()
    let title: String
    let scriptureReference: String
    let scriptureText: String
    let prompt: String
    let tip: String
    let durationWeight: Double // Relative weight for time allocation (1.0 = standard)
    
    /// Convenience initializer
    init(title: String, scripture: (ref: String, text: String), prompt: String, tip: String, weight: Double = 1.0) {
        self.title = title
        self.scriptureReference = scripture.ref
        self.scriptureText = scripture.text
        self.prompt = prompt
        self.tip = tip
        self.durationWeight = weight
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
    
    /// Short description for theme preview
    var subtitle: String {
        switch self {
        case .gratitude: return "Give thanks for blessings"
        case .repentance: return "Seek forgiveness and renewal"
        case .guidance: return "Ask for wisdom and direction"
        case .peace: return "Release anxiety, find rest"
        case .family: return "Bless and protect loved ones"
        case .work: return "Dedicate your work to God"
        }
    }
    
    /// Verse to carry with you after the session (varies by duration)
    func closingVerse(for duration: GuidedPrayerDuration) -> (reference: String, text: String) {
        switch self {
        case .gratitude:
            switch duration {
            case .twoMinutes:
                return ("Colossians 3:17", "And whatever you do, whether in word or deed, do it all in the name of the Lord Jesus, giving thanks to God the Father through him.")
            case .fiveMinutes:
                return ("Psalm 107:1", "Give thanks to the Lord, for he is good; his love endures forever.")
            case .tenMinutes:
                return ("Ephesians 5:20", "Always giving thanks to God the Father for everything, in the name of our Lord Jesus Christ.")
            }
        case .repentance:
            switch duration {
            case .twoMinutes:
                return ("Acts 3:19", "Repent, then, and turn to God, so that your sins may be wiped out, that times of refreshing may come from the Lord.")
            case .fiveMinutes:
                return ("1 John 1:9", "If we confess our sins, he is faithful and just and will forgive us our sins and purify us from all unrighteousness.")
            case .tenMinutes:
                return ("2 Chronicles 7:14", "If my people, who are called by my name, will humble themselves and pray and seek my face and turn from their wicked ways, then I will hear from heaven.")
            }
        case .guidance:
            switch duration {
            case .twoMinutes:
                return ("James 1:5", "If any of you lacks wisdom, you should ask God, who gives generously to all without finding fault.")
            case .fiveMinutes:
                return ("Proverbs 3:5-6", "Trust in the Lord with all your heart and lean not on your own understanding; in all your ways submit to him, and he will make your paths straight.")
            case .tenMinutes:
                return ("Isaiah 58:11", "The Lord will guide you always; he will satisfy your needs in a sun-scorched land and will strengthen your frame.")
            }
        case .peace:
            switch duration {
            case .twoMinutes:
                return ("John 14:27", "Peace I leave with you; my peace I give you. I do not give to you as the world gives.")
            case .fiveMinutes:
                return ("Philippians 4:7", "And the peace of God, which transcends all understanding, will guard your hearts and your minds in Christ Jesus.")
            case .tenMinutes:
                return ("Isaiah 26:3", "You will keep in perfect peace those whose minds are steadfast, because they trust in you.")
            }
        case .family:
            switch duration {
            case .twoMinutes:
                return ("Proverbs 22:6", "Start children off on the way they should go, and even when they are old they will not turn from it.")
            case .fiveMinutes:
                return ("Joshua 24:15", "But as for me and my household, we will serve the Lord.")
            case .tenMinutes:
                return ("Deuteronomy 6:6-7", "These commandments that I give you today are to be on your hearts. Impress them on your children.")
            }
        case .work:
            switch duration {
            case .twoMinutes:
                return ("Proverbs 16:3", "Commit to the Lord whatever you do, and he will establish your plans.")
            case .fiveMinutes:
                return ("Colossians 3:23", "Whatever you do, work at it with all your heart, as working for the Lord, not for human masters.")
            case .tenMinutes:
                return ("Ecclesiastes 9:10", "Whatever your hand finds to do, do it with all your might.")
            }
        }
    }
    
    /// Legacy accessor - uses 10 minute phases
    var closingVerse: (reference: String, text: String) {
        closingVerse(for: .tenMinutes)
    }
    
    /// Get phases for a specific duration - each duration has unique content
    func phases(for duration: GuidedPrayerDuration) -> [GuidedPrayerPhase] {
        switch self {
        case .gratitude:
            return Self.gratitudePhases(for: duration)
        case .repentance:
            return Self.repentancePhases(for: duration)
        case .guidance:
            return Self.guidancePhases(for: duration)
        case .peace:
            return Self.peacePhases(for: duration)
        case .family:
            return Self.familyPhases(for: duration)
        case .work:
            return Self.workPhases(for: duration)
        }
    }
    
    /// Legacy accessor - uses 10 minute phases
    var phases: [GuidedPrayerPhase] {
        phases(for: .tenMinutes)
    }
    
    /// Legacy prompts for backward compatibility
    var prompts: [String] {
        phases.map { $0.prompt }
    }
    
    // MARK: - Gratitude Theme Phases (OT/NT balanced)
    
    private static func gratitudePhases(for duration: GuidedPrayerDuration) -> [GuidedPrayerPhase] {
        switch duration {
        case .twoMinutes:
            return [
                GuidedPrayerPhase(
                    title: "Center",
                    scripture: ("Psalm 100:4", "Enter his gates with thanksgiving and his courts with praise; give thanks to him and praise his name."),
                    prompt: "Pause and enter God's presence with a thankful heart.",
                    tip: "Take one deep breath. You are stepping into sacred space.",
                    weight: 1.0
                ),
                GuidedPrayerPhase(
                    title: "Give Thanks",
                    scripture: ("1 Thessalonians 5:18", "Give thanks in all circumstances; for this is God's will for you in Christ Jesus."),
                    prompt: "Name three blessings—big or small—and thank God for each.",
                    tip: "Even the simplest gifts matter: breath, sight, a kind word today.",
                    weight: 1.2
                ),
                GuidedPrayerPhase(
                    title: "Carry Gratitude",
                    scripture: ("Colossians 3:17", "And whatever you do, whether in word or deed, do it all in the name of the Lord Jesus, giving thanks."),
                    prompt: "Commit to carrying gratitude into the next hour.",
                    tip: "Let this thankfulness color your words and actions.",
                    weight: 0.8
                )
            ]
        case .fiveMinutes:
            return [
                GuidedPrayerPhase(
                    title: "Opening",
                    scripture: ("Psalm 95:2", "Let us come before him with thanksgiving and extol him with music and song."),
                    prompt: "Enter God's presence with a spirit of celebration.",
                    tip: "Close your eyes. Let the noise of the day fade away.",
                    weight: 0.8
                ),
                GuidedPrayerPhase(
                    title: "Daily Blessings",
                    scripture: ("James 1:17", "Every good and perfect gift is from above, coming down from the Father of the heavenly lights."),
                    prompt: "Consider what gifts today has brought. Thank God specifically.",
                    tip: "Morning coffee, a text from a friend, sunshine—nothing is too small.",
                    weight: 1.0
                ),
                GuidedPrayerPhase(
                    title: "People",
                    scripture: ("Philippians 1:3", "I thank my God every time I remember you."),
                    prompt: "Think of someone who has blessed your life. Offer thanks for them.",
                    tip: "Picture their face. What have they meant to you?",
                    weight: 1.0
                ),
                GuidedPrayerPhase(
                    title: "God's Character",
                    scripture: ("Psalm 136:1", "Give thanks to the Lord, for he is good. His love endures forever."),
                    prompt: "Thank God for who He is—His faithfulness, His love.",
                    tip: "His goodness isn't based on circumstances. Thank Him for His unchanging nature.",
                    weight: 1.0
                ),
                GuidedPrayerPhase(
                    title: "Closing",
                    scripture: ("Ephesians 5:20", "Always giving thanks to God the Father for everything, in the name of our Lord Jesus Christ."),
                    prompt: "Seal this prayer with one final expression of gratitude.",
                    tip: "Carry this thankful heart into your next moments.",
                    weight: 0.8
                )
            ]
        case .tenMinutes:
            return [
                GuidedPrayerPhase(
                    title: "Opening",
                    scripture: ("Psalm 100:4-5", "Enter his gates with thanksgiving and his courts with praise; give thanks to him and praise his name. For the Lord is good."),
                    prompt: "Begin by taking a deep breath and centering yourself in God's presence.",
                    tip: "Close your eyes. Let the busyness of the day fade away. You are entering sacred space with your Creator.",
                    weight: 0.8
                ),
                GuidedPrayerPhase(
                    title: "Count Your Blessings",
                    scripture: ("1 Thessalonians 5:16-18", "Rejoice always, pray continually, give thanks in all circumstances; for this is God's will for you in Christ Jesus."),
                    prompt: "Think of three specific blessings from today. Thank God for each one.",
                    tip: "Picture each blessing clearly in your mind. Feel the warmth of gratitude in your heart as you offer thanks. Even small mercies matter.",
                    weight: 1.2
                ),
                GuidedPrayerPhase(
                    title: "People in Your Life",
                    scripture: ("Philippians 1:3-4", "I thank my God every time I remember you. In all my prayers for all of you, I always pray with joy."),
                    prompt: "Consider the people who have shown you kindness. Offer thanks for them.",
                    tip: "Think of a specific face. What have they done for you? How have they blessed your life? Thank God for placing them in your path.",
                    weight: 1.0
                ),
                GuidedPrayerPhase(
                    title: "Hidden Blessings",
                    scripture: ("Romans 8:28", "And we know that in all things God works for the good of those who love him, who have been called according to his purpose."),
                    prompt: "Reflect on a challenge that became a blessing in disguise.",
                    tip: "Sometimes our greatest growth comes from difficulty. Ask God to help you see His hand even in hard seasons.",
                    weight: 1.0
                ),
                GuidedPrayerPhase(
                    title: "God's Faithfulness",
                    scripture: ("Lamentations 3:22-23", "Because of the Lord's great love we are not consumed, for his compassions never fail. They are new every morning; great is your faithfulness."),
                    prompt: "Thank God for His constant love and faithfulness in your life.",
                    tip: "Reflect on how God has been faithful through seasons of your life. His love never wavers, even when we struggle to feel it.",
                    weight: 1.0
                ),
                GuidedPrayerPhase(
                    title: "Closing",
                    scripture: ("Psalm 103:2", "Praise the Lord, my soul, and forget not all his benefits."),
                    prompt: "Close by expressing gratitude for this moment of prayer.",
                    tip: "Thank God for the gift of prayer itself—direct access to the Creator of the universe. Carry this gratitude with you.",
                    weight: 0.8
                )
            ]
        }
    }
    
    // MARK: - Repentance Theme Phases (OT/NT balanced)
    
    private static func repentancePhases(for duration: GuidedPrayerDuration) -> [GuidedPrayerPhase] {
        switch duration {
        case .twoMinutes:
            return [
                GuidedPrayerPhase(
                    title: "Approach",
                    scripture: ("Hebrews 4:16", "Let us then approach God's throne of grace with confidence, so that we may receive mercy."),
                    prompt: "Come before God knowing He welcomes you with grace.",
                    tip: "You're approaching a loving Father, not a harsh judge.",
                    weight: 0.9
                ),
                GuidedPrayerPhase(
                    title: "Confess",
                    scripture: ("Psalm 51:10", "Create in me a pure heart, O God, and renew a steadfast spirit within me."),
                    prompt: "Acknowledge one area where you need forgiveness today.",
                    tip: "Be honest. God already knows—confession brings freedom.",
                    weight: 1.2
                ),
                GuidedPrayerPhase(
                    title: "Receive",
                    scripture: ("1 John 1:9", "If we confess our sins, he is faithful and just and will forgive us our sins."),
                    prompt: "Accept God's complete forgiveness. You are cleansed.",
                    tip: "Don't hold onto guilt—release it. Walk forward clean.",
                    weight: 0.9
                )
            ]
        case .fiveMinutes:
            return [
                GuidedPrayerPhase(
                    title: "Approach Grace",
                    scripture: ("Joel 2:13", "Return to the Lord your God, for he is gracious and compassionate, slow to anger and abounding in love."),
                    prompt: "Come to God knowing His heart is for restoration.",
                    tip: "He doesn't delight in punishment but in mercy.",
                    weight: 0.8
                ),
                GuidedPrayerPhase(
                    title: "Examine",
                    scripture: ("Psalm 139:23-24", "Search me, God, and know my heart; test me and know my anxious thoughts. See if there is any offensive way in me."),
                    prompt: "Ask the Spirit to gently reveal where you've fallen short.",
                    tip: "Don't defend—simply listen. Let His light illuminate.",
                    weight: 1.0
                ),
                GuidedPrayerPhase(
                    title: "Confess",
                    scripture: ("James 5:16", "Therefore confess your sins to each other and pray for each other so that you may be healed."),
                    prompt: "Name your sins honestly before God.",
                    tip: "Confession is the doorway to healing. Be specific.",
                    weight: 1.2
                ),
                GuidedPrayerPhase(
                    title: "Receive Forgiveness",
                    scripture: ("Micah 7:18-19", "Who is a God like you, who pardons sin? You will tread our sins underfoot and hurl all our iniquities into the depths of the sea."),
                    prompt: "Accept that your sins are forgiven—completely removed.",
                    tip: "Imagine them sinking to the bottom of the ocean, never to return.",
                    weight: 1.0
                ),
                GuidedPrayerPhase(
                    title: "Walk Forward",
                    scripture: ("Romans 8:1", "Therefore, there is now no condemnation for those who are in Christ Jesus."),
                    prompt: "Thank God for His mercy. Step forward in freedom.",
                    tip: "No more guilt. No more shame. Walk in the light.",
                    weight: 0.8
                )
            ]
        case .tenMinutes:
            return [
                GuidedPrayerPhase(
                    title: "Approaching God",
                    scripture: ("Hebrews 4:16", "Let us then approach God's throne of grace with confidence, so that we may receive mercy and find grace to help us in our time of need."),
                    prompt: "Come before God with a humble heart, knowing He is gracious.",
                    tip: "You are not coming to a harsh judge, but to a loving Father who delights in mercy. He already knows your heart.",
                    weight: 0.8
                ),
                GuidedPrayerPhase(
                    title: "Examination",
                    scripture: ("Psalm 139:23-24", "Search me, God, and know my heart; test me and know my anxious thoughts. See if there is any offensive way in me."),
                    prompt: "Ask the Holy Spirit to reveal areas where you've fallen short.",
                    tip: "Be still and listen. Don't defend or justify—simply allow God's gentle light to illuminate what needs attention.",
                    weight: 1.2
                ),
                GuidedPrayerPhase(
                    title: "Confession",
                    scripture: ("Psalm 32:5", "Then I acknowledged my sin to you and did not cover up my iniquity. I said, 'I will confess my transgressions to the Lord.'"),
                    prompt: "Confess specific actions or attitudes that have grieved God's heart.",
                    tip: "Name them honestly. Confession is not about shame—it's about freedom. Bring everything into the light where healing happens.",
                    weight: 1.2
                ),
                GuidedPrayerPhase(
                    title: "Receiving Forgiveness",
                    scripture: ("1 John 1:9", "If we confess our sins, he is faithful and just and will forgive us our sins and purify us from all unrighteousness."),
                    prompt: "Release any guilt or shame, accepting God's complete forgiveness.",
                    tip: "Forgiveness is not earned—it's received. Picture your sins washed away, as far as the east is from the west.",
                    weight: 1.0
                ),
                GuidedPrayerPhase(
                    title: "Strength to Change",
                    scripture: ("Philippians 4:13", "I can do all this through him who gives me strength."),
                    prompt: "Ask for strength to turn away from these patterns.",
                    tip: "Transformation is a partnership. God provides the power; we provide the willingness. Ask for both strength and desire to change.",
                    weight: 1.0
                ),
                GuidedPrayerPhase(
                    title: "Walking Forward",
                    scripture: ("Micah 6:8", "He has shown you, O mortal, what is good. And what does the Lord require of you? To act justly and to love mercy and to walk humbly with your God."),
                    prompt: "Thank God for His mercy and commit to walking in His ways.",
                    tip: "Leave this prayer lighter than you came. The past is forgiven—now walk forward in freedom and grace.",
                    weight: 0.8
                )
            ]
        }
    }
    
    // MARK: - Guidance Theme Phases (OT/NT balanced)
    
    private static func guidancePhases(for duration: GuidedPrayerDuration) -> [GuidedPrayerPhase] {
        switch duration {
        case .twoMinutes:
            return [
                GuidedPrayerPhase(
                    title: "Be Still",
                    scripture: ("Psalm 46:10", "Be still, and know that I am God."),
                    prompt: "Quiet your racing thoughts. Create space for God's voice.",
                    tip: "Silence the noise. Just for this moment, be still.",
                    weight: 0.9
                ),
                GuidedPrayerPhase(
                    title: "Ask",
                    scripture: ("James 1:5", "If any of you lacks wisdom, you should ask God, who gives generously to all without finding fault."),
                    prompt: "Present your situation to God. Ask for wisdom.",
                    tip: "Be specific about what you need. He gives generously.",
                    weight: 1.2
                ),
                GuidedPrayerPhase(
                    title: "Trust",
                    scripture: ("Proverbs 3:5", "Trust in the Lord with all your heart and lean not on your own understanding."),
                    prompt: "Release control. Trust God to guide your steps.",
                    tip: "You don't need all the answers right now. Just the next step.",
                    weight: 0.9
                )
            ]
        case .fiveMinutes:
            return [
                GuidedPrayerPhase(
                    title: "Quiet",
                    scripture: ("Isaiah 30:21", "Whether you turn to the right or to the left, your ears will hear a voice behind you, saying, 'This is the way; walk in it.'"),
                    prompt: "Still your mind. Invite God into your decision.",
                    tip: "Turn down the volume on fear and others' opinions.",
                    weight: 0.8
                ),
                GuidedPrayerPhase(
                    title: "Present",
                    scripture: ("Philippians 4:6", "Do not be anxious about anything, but in every situation, by prayer and petition, with thanksgiving, present your requests to God."),
                    prompt: "Lay out your situation clearly before God.",
                    tip: "Tell Him everything—He can handle the complexity.",
                    weight: 1.0
                ),
                GuidedPrayerPhase(
                    title: "Seek Wisdom",
                    scripture: ("Proverbs 2:6", "For the Lord gives wisdom; from his mouth come knowledge and understanding."),
                    prompt: "Ask for wisdom to see as God sees.",
                    tip: "Wisdom isn't just information—it's divine perspective.",
                    weight: 1.0
                ),
                GuidedPrayerPhase(
                    title: "Listen",
                    scripture: ("John 10:27", "My sheep listen to my voice; I know them, and they follow me."),
                    prompt: "Be still. Listen for the Shepherd's voice.",
                    tip: "He may speak through peace, scripture, or quiet impression.",
                    weight: 1.2
                ),
                GuidedPrayerPhase(
                    title: "Surrender",
                    scripture: ("Proverbs 16:9", "In their hearts humans plan their course, but the Lord establishes their steps."),
                    prompt: "Release your grip on the outcome. Trust His plan.",
                    tip: "Say: 'Your way, Lord, not mine.'",
                    weight: 0.8
                )
            ]
        case .tenMinutes:
            return [
                GuidedPrayerPhase(
                    title: "Quieting Your Mind",
                    scripture: ("Psalm 46:10", "Be still, and know that I am God."),
                    prompt: "Still your mind and invite God into your decision-making.",
                    tip: "Release the noise of opinions, fears, and pressures. Create space for God's voice to speak clearly.",
                    weight: 0.8
                ),
                GuidedPrayerPhase(
                    title: "Presenting Your Situation",
                    scripture: ("Philippians 4:6-7", "Do not be anxious about anything, but in every situation, by prayer and petition, with thanksgiving, present your requests to God."),
                    prompt: "Present your situation clearly to God, holding nothing back.",
                    tip: "God already knows, but speaking it aloud or in your heart helps you process and surrender. Be completely honest.",
                    weight: 1.2
                ),
                GuidedPrayerPhase(
                    title: "Asking for Wisdom",
                    scripture: ("James 1:5-6", "If any of you lacks wisdom, you should ask God, who gives generously to all without finding fault, and it will be given to you."),
                    prompt: "Ask for wisdom to see the path He has prepared for you.",
                    tip: "Wisdom is not just knowledge—it's seeing situations as God sees them. Ask for His perspective, not just His answer.",
                    weight: 1.0
                ),
                GuidedPrayerPhase(
                    title: "Listening",
                    scripture: ("Isaiah 30:21", "Whether you turn to the right or to the left, your ears will hear a voice behind you, saying, 'This is the way; walk in it.'"),
                    prompt: "Listen quietly for His gentle direction.",
                    tip: "God rarely shouts. Be still and attentive. Direction may come as peace, a thought, a scripture, or a growing clarity.",
                    weight: 1.2
                ),
                GuidedPrayerPhase(
                    title: "Surrendering",
                    scripture: ("Proverbs 16:9", "In their hearts humans plan their course, but the Lord establishes their steps."),
                    prompt: "Surrender your own preferences and trust His perfect plan.",
                    tip: "The hardest part of guidance is releasing our grip on the outcome. Tell God: 'Your way, not mine.'",
                    weight: 1.0
                ),
                GuidedPrayerPhase(
                    title: "Trusting the Guide",
                    scripture: ("Proverbs 3:5-6", "Trust in the Lord with all your heart and lean not on your own understanding; in all your ways submit to him, and he will make your paths straight."),
                    prompt: "Thank God for being your guide and faithful counselor.",
                    tip: "Even if clarity doesn't come immediately, trust that God will direct your steps. He is faithful.",
                    weight: 0.8
                )
            ]
        }
    }
    
    // MARK: - Peace & Anxiety Theme Phases (OT/NT balanced)
    
    private static func peacePhases(for duration: GuidedPrayerDuration) -> [GuidedPrayerPhase] {
        switch duration {
        case .twoMinutes:
            return [
                GuidedPrayerPhase(
                    title: "Breathe",
                    scripture: ("John 14:27", "Peace I leave with you; my peace I give you. Do not let your hearts be troubled."),
                    prompt: "Take a slow, deep breath. Invite Christ's peace.",
                    tip: "Feel your shoulders drop. Unclench your jaw. Breathe.",
                    weight: 1.0
                ),
                GuidedPrayerPhase(
                    title: "Release",
                    scripture: ("1 Peter 5:7", "Cast all your anxiety on him because he cares for you."),
                    prompt: "Name your biggest worry. Hand it to God right now.",
                    tip: "Imagine placing it in His hands. He's got it.",
                    weight: 1.2
                ),
                GuidedPrayerPhase(
                    title: "Rest",
                    scripture: ("Matthew 11:28", "Come to me, all you who are weary and burdened, and I will give you rest."),
                    prompt: "Receive His rest. Let peace settle over you.",
                    tip: "You are held. You are safe. You are loved.",
                    weight: 0.8
                )
            ]
        case .fiveMinutes:
            return [
                GuidedPrayerPhase(
                    title: "Arrive",
                    scripture: ("Psalm 46:1", "God is our refuge and strength, an ever-present help in trouble."),
                    prompt: "Step out of the chaos. Enter God's presence.",
                    tip: "You are entering a sanctuary of peace. Breathe deeply.",
                    weight: 0.8
                ),
                GuidedPrayerPhase(
                    title: "Cast Your Cares",
                    scripture: ("1 Peter 5:7", "Cast all your anxiety on him because he cares for you."),
                    prompt: "Name what's weighing on you. Give it to God.",
                    tip: "One by one, hand each worry over. He wants to carry it.",
                    weight: 1.0
                ),
                GuidedPrayerPhase(
                    title: "Remember Truth",
                    scripture: ("Isaiah 41:10", "So do not fear, for I am with you; do not be dismayed, for I am your God. I will strengthen you."),
                    prompt: "Let God's promises anchor your anxious heart.",
                    tip: "He is with you. He will strengthen you. This is true.",
                    weight: 1.0
                ),
                GuidedPrayerPhase(
                    title: "Picture Rest",
                    scripture: ("Psalm 23:2-3", "He makes me lie down in green pastures, he leads me beside quiet waters, he refreshes my soul."),
                    prompt: "Imagine yourself in a place of complete safety and rest.",
                    tip: "Green pastures. Still waters. The Good Shepherd beside you.",
                    weight: 1.2
                ),
                GuidedPrayerPhase(
                    title: "Receive Peace",
                    scripture: ("Philippians 4:7", "And the peace of God, which transcends all understanding, will guard your hearts and minds."),
                    prompt: "Let His peace wash over you. Receive it as a gift.",
                    tip: "This peace doesn't depend on circumstances. It's yours.",
                    weight: 0.8
                )
            ]
        case .tenMinutes:
            return [
                GuidedPrayerPhase(
                    title: "Invitation to Peace",
                    scripture: ("John 14:27", "Peace I leave with you; my peace I give you. I do not give to you as the world gives. Do not let your hearts be troubled and do not be afraid."),
                    prompt: "Take a slow, deep breath. Invite God's peace into this moment.",
                    tip: "Breathe deeply. With each breath, release tension. You are safe in God's presence. His peace is not dependent on circumstances.",
                    weight: 0.8
                ),
                GuidedPrayerPhase(
                    title: "Casting Your Cares",
                    scripture: ("1 Peter 5:7", "Cast all your anxiety on him because he cares for you."),
                    prompt: "Cast your anxieties on Him, for He cares for you deeply.",
                    tip: "Imagine physically handing your worries to God—a heavy bag you no longer need to carry. He wants to hold it for you.",
                    weight: 1.0
                ),
                GuidedPrayerPhase(
                    title: "Naming Your Worries",
                    scripture: ("Psalm 55:22", "Cast your cares on the Lord and he will sustain you; he will never let the righteous be shaken."),
                    prompt: "Name your worries one by one, releasing each to God's care.",
                    tip: "Don't rush. Name each anxiety specifically: finances, health, relationships, the future. As you name each one, consciously release it.",
                    weight: 1.2
                ),
                GuidedPrayerPhase(
                    title: "God's Promises",
                    scripture: ("Isaiah 41:10", "So do not fear, for I am with you; do not be dismayed, for I am your God. I will strengthen you and help you."),
                    prompt: "Meditate on God's promises of protection and provision.",
                    tip: "God has made promises He will keep. He has never failed anyone who trusted Him. Let these truths anchor your soul.",
                    weight: 1.0
                ),
                GuidedPrayerPhase(
                    title: "Resting in His Hands",
                    scripture: ("Psalm 23:1-2", "The Lord is my shepherd, I lack nothing. He makes me lie down in green pastures, he leads me beside quiet waters."),
                    prompt: "Picture yourself resting in the palm of God's hand.",
                    tip: "Visualize a place of complete safety and rest. You are held by hands that created the universe yet count the hairs on your head.",
                    weight: 1.2
                ),
                GuidedPrayerPhase(
                    title: "Receiving Peace",
                    scripture: ("Philippians 4:6-7", "Do not be anxious about anything... And the peace of God, which transcends all understanding, will guard your hearts and your minds."),
                    prompt: "Receive His peace that surpasses all understanding.",
                    tip: "Peace is a gift. Simply receive it. Let it settle into your heart like warmth spreading through your body.",
                    weight: 0.8
                )
            ]
        }
    }
    
    // MARK: - Family Theme Phases (OT/NT balanced)
    
    private static func familyPhases(for duration: GuidedPrayerDuration) -> [GuidedPrayerPhase] {
        switch duration {
        case .twoMinutes:
            return [
                GuidedPrayerPhase(
                    title: "Gather",
                    scripture: ("Matthew 18:20", "For where two or three gather in my name, there am I with them."),
                    prompt: "Bring your family before God's throne in your heart.",
                    tip: "Picture each face. God loves them even more than you do.",
                    weight: 0.9
                ),
                GuidedPrayerPhase(
                    title: "Bless",
                    scripture: ("Numbers 6:24-26", "The Lord bless you and keep you; the Lord make his face shine on you."),
                    prompt: "Speak blessing over each family member by name.",
                    tip: "Lord, bless [name]. Keep them. Let your face shine on them.",
                    weight: 1.3
                ),
                GuidedPrayerPhase(
                    title: "Protect",
                    scripture: ("Psalm 121:7-8", "The Lord will keep you from all harm—he will watch over your life."),
                    prompt: "Ask God's protection over your family today.",
                    tip: "Physical safety. Spiritual protection. Guard their hearts.",
                    weight: 0.8
                )
            ]
        case .fiveMinutes:
            return [
                GuidedPrayerPhase(
                    title: "Approach",
                    scripture: ("Hebrews 4:16", "Let us then approach God's throne of grace with confidence, so that we may receive mercy."),
                    prompt: "Come confidently to God on behalf of your family.",
                    tip: "You have access to the King. Use it for those you love.",
                    weight: 0.8
                ),
                GuidedPrayerPhase(
                    title: "Individual Prayer",
                    scripture: ("3 John 1:4", "I have no greater joy than to hear that my children are walking in the truth."),
                    prompt: "Pray for each family member by name and their specific needs.",
                    tip: "Take time with each name. What do they need most right now?",
                    weight: 1.3
                ),
                GuidedPrayerPhase(
                    title: "Unity",
                    scripture: ("Colossians 3:14", "And over all these virtues put on love, which binds them all together in perfect unity."),
                    prompt: "Pray for love and unity in your home.",
                    tip: "Families face friction. Ask for patience, grace, and love.",
                    weight: 1.0
                ),
                GuidedPrayerPhase(
                    title: "Protection",
                    scripture: ("Psalm 91:11", "For he will command his angels concerning you to guard you in all your ways."),
                    prompt: "Ask for God's protection—physical, emotional, spiritual.",
                    tip: "Cover them with prayer. Guard their hearts and minds.",
                    weight: 1.0
                ),
                GuidedPrayerPhase(
                    title: "Thanksgiving",
                    scripture: ("Psalm 127:3", "Children are a heritage from the Lord, offspring a reward from him."),
                    prompt: "Thank God for the gift of family.",
                    tip: "Despite imperfections, they are a gift. Thank God for them.",
                    weight: 0.8
                )
            ]
        case .tenMinutes:
            return [
                GuidedPrayerPhase(
                    title: "Approaching the Throne",
                    scripture: ("Matthew 18:19-20", "Again, truly I tell you that if two of you on earth agree about anything they ask for, it will be done for them by my Father in heaven."),
                    prompt: "Bring your family members before God's throne of grace.",
                    tip: "Picture each family member standing with you before God's throne. He loves them even more than you do.",
                    weight: 0.8
                ),
                GuidedPrayerPhase(
                    title: "Individual Blessings",
                    scripture: ("Numbers 6:24-26", "The Lord bless you and keep you; the Lord make his face shine on you and be gracious to you; the Lord turn his face toward you and give you peace."),
                    prompt: "Pray for each person by name, lifting their specific needs.",
                    tip: "Take time with each name. What do they need right now? Pray specifically—God cares about the details of their lives.",
                    weight: 1.4
                ),
                GuidedPrayerPhase(
                    title: "Unity and Love",
                    scripture: ("Colossians 3:13-14", "Bear with each other and forgive one another... And over all these virtues put on love, which binds them all together in perfect unity."),
                    prompt: "Ask for unity, love, and understanding in your home.",
                    tip: "Families face friction. Pray for patience with differences, grace in conflicts, and love that covers offenses.",
                    weight: 1.0
                ),
                GuidedPrayerPhase(
                    title: "Protection",
                    scripture: ("Psalm 91:11-12", "For he will command his angels concerning you to guard you in all your ways; they will lift you up in their hands."),
                    prompt: "Pray for protection over your family's hearts and minds.",
                    tip: "Pray protection from physical harm, spiritual attacks, harmful influences, and anything that would draw them from God.",
                    weight: 1.0
                ),
                GuidedPrayerPhase(
                    title: "Healing",
                    scripture: ("Jeremiah 30:17", "'But I will restore you to health and heal your wounds,' declares the Lord."),
                    prompt: "Ask God to heal any broken relationships or hurts.",
                    tip: "Family wounds run deep. Ask God to heal old hurts, mend broken trust, and restore what has been damaged.",
                    weight: 1.0
                ),
                GuidedPrayerPhase(
                    title: "Thanksgiving",
                    scripture: ("Psalm 127:3", "Children are a heritage from the Lord, offspring a reward from him."),
                    prompt: "Thank God for the gift of family and His design for it.",
                    tip: "Despite imperfections, family is a gift. Thank God for the people He's placed in your life. They are part of His plan for you.",
                    weight: 0.8
                )
            ]
        }
    }
    
    // MARK: - Work & Purpose Theme Phases (OT/NT balanced)
    
    private static func workPhases(for duration: GuidedPrayerDuration) -> [GuidedPrayerPhase] {
        switch duration {
        case .twoMinutes:
            return [
                GuidedPrayerPhase(
                    title: "Dedicate",
                    scripture: ("Colossians 3:23", "Whatever you do, work at it with all your heart, as working for the Lord."),
                    prompt: "Offer your work today to God as an act of worship.",
                    tip: "Every task can be worship. Dedicate this day to Him.",
                    weight: 1.0
                ),
                GuidedPrayerPhase(
                    title: "Ask Wisdom",
                    scripture: ("Proverbs 2:6", "For the Lord gives wisdom; from his mouth come knowledge and understanding."),
                    prompt: "Ask for wisdom for today's challenges and decisions.",
                    tip: "What's hard today? Ask specifically for help.",
                    weight: 1.2
                ),
                GuidedPrayerPhase(
                    title: "Trust",
                    scripture: ("Proverbs 16:3", "Commit to the Lord whatever you do, and he will establish your plans."),
                    prompt: "Commit today's outcomes to God. Trust Him with results.",
                    tip: "Do your best. Leave results to Him.",
                    weight: 0.8
                )
            ]
        case .fiveMinutes:
            return [
                GuidedPrayerPhase(
                    title: "Acknowledge",
                    scripture: ("James 1:17", "Every good and perfect gift is from above, coming down from the Father of the heavenly lights."),
                    prompt: "Acknowledge God as the source of your skills and opportunities.",
                    tip: "Your abilities, your position—all gifts from Him.",
                    weight: 0.8
                ),
                GuidedPrayerPhase(
                    title: "Offer",
                    scripture: ("Romans 12:1", "Offer your bodies as a living sacrifice, holy and pleasing to God—this is your true and proper worship."),
                    prompt: "Offer your work as worship. Dedicate this day to God.",
                    tip: "Every email, meeting, task—an offering to Him.",
                    weight: 1.0
                ),
                GuidedPrayerPhase(
                    title: "Seek Wisdom",
                    scripture: ("Ecclesiastes 2:26", "To the person who pleases him, God gives wisdom, knowledge and happiness."),
                    prompt: "Ask for wisdom in your specific challenges today.",
                    tip: "Name the hard things. Ask for divine insight.",
                    weight: 1.0
                ),
                GuidedPrayerPhase(
                    title: "Be Light",
                    scripture: ("Matthew 5:16", "Let your light shine before others, that they may see your good deeds and glorify your Father in heaven."),
                    prompt: "Ask to be a light—through your words and actions.",
                    tip: "How you treat people speaks louder than any words.",
                    weight: 1.0
                ),
                GuidedPrayerPhase(
                    title: "Release Outcomes",
                    scripture: ("Proverbs 16:9", "In their hearts humans plan their course, but the Lord establishes their steps."),
                    prompt: "Do your best, then trust God with the results.",
                    tip: "Work faithfully. Release the outcomes.",
                    weight: 0.8
                )
            ]
        case .tenMinutes:
            return [
                GuidedPrayerPhase(
                    title: "Acknowledging the Source",
                    scripture: ("James 1:17", "Every good and perfect gift is from above, coming down from the Father of the heavenly lights."),
                    prompt: "Acknowledge God as the source of your talents and opportunities.",
                    tip: "Your abilities, your job, your opportunities—all gifts from God. Begin with humble gratitude for what He has provided.",
                    weight: 0.8
                ),
                GuidedPrayerPhase(
                    title: "Offering Your Work",
                    scripture: ("Colossians 3:23-24", "Whatever you do, work at it with all your heart, as working for the Lord, not for human masters... It is the Lord Christ you are serving."),
                    prompt: "Offer your work today as an act of worship to Him.",
                    tip: "Every task, meeting, and project can be worship. Dedicate your efforts to God's glory, not just personal gain.",
                    weight: 1.0
                ),
                GuidedPrayerPhase(
                    title: "Wisdom for Challenges",
                    scripture: ("Proverbs 2:6-7", "For the Lord gives wisdom; from his mouth come knowledge and understanding. He holds success in store for the upright."),
                    prompt: "Pray for wisdom in challenges and decisions you face.",
                    tip: "What challenges are you facing? Deadlines, difficult people, complex decisions? Ask specifically for God's wisdom in each.",
                    weight: 1.2
                ),
                GuidedPrayerPhase(
                    title: "Being a Light",
                    scripture: ("Matthew 5:14-16", "You are the light of the world... let your light shine before others, that they may see your good deeds and glorify your Father in heaven."),
                    prompt: "Ask God to use you as a light in your workplace.",
                    tip: "Your character, kindness, and integrity speak louder than words. Pray to reflect Christ in how you treat others.",
                    weight: 1.0
                ),
                GuidedPrayerPhase(
                    title: "Blessing Others",
                    scripture: ("Hebrews 6:10", "God is not unjust; he will not forget your work and the love you have shown him as you have helped his people."),
                    prompt: "Pray for your colleagues and those you serve.",
                    tip: "Think of specific coworkers, clients, or customers. What do they need? Pray blessing over them—even difficult ones.",
                    weight: 1.0
                ),
                GuidedPrayerPhase(
                    title: "Trusting Outcomes",
                    scripture: ("Ecclesiastes 9:10", "Whatever your hand finds to do, do it with all your might."),
                    prompt: "Commit your plans to the Lord and trust Him with the outcomes.",
                    tip: "We control effort, not outcomes. Release the results to God. Work faithfully and trust Him with what comes.",
                    weight: 0.8
                )
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
