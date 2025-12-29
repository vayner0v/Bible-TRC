//
//  RoutineStep.swift
//  Bible v1
//
//  Model for customizable routine steps in Daily Routine
//

import Foundation
import SwiftUI

// MARK: - Routine Mode

/// Represents the time of day for the routine
enum RoutineMode: String, Codable, CaseIterable, Identifiable {
    case morning
    case evening
    case anytime
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .morning: return "Morning"
        case .evening: return "Evening"
        case .anytime: return "Anytime"
        }
    }
    
    var icon: String {
        switch self {
        case .morning: return "sunrise.fill"
        case .evening: return "moon.stars.fill"
        case .anytime: return "clock.fill"
        }
    }
    
    var gradient: [Color] {
        switch self {
        case .morning: return [Color.orange.opacity(0.3), Color.yellow.opacity(0.1)]
        case .evening: return [Color.indigo.opacity(0.3), Color.teal.opacity(0.1)]
        case .anytime: return [Color.blue.opacity(0.2), Color.cyan.opacity(0.1)]
        }
    }
    
    var accentColor: Color {
        switch self {
        case .morning: return .orange
        case .evening: return .indigo
        case .anytime: return .blue
        }
    }
    
    /// Determines current mode based on time of day
    static var current: RoutineMode {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return .morning
        case 18..<24, 0..<4: return .evening
        default: return .anytime
        }
    }
    
    /// Check if this mode is appropriate for current time
    var isCurrentlyAppropriate: Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        switch self {
        case .morning: return hour >= 5 && hour < 12
        case .evening: return hour >= 18 || hour < 4
        case .anytime: return true
        }
    }
}

// MARK: - Step Category

/// Categories of routine steps
enum RoutineStepCategory: String, Codable, CaseIterable, Identifiable {
    case prayer
    case scripture
    case breathing
    case reflection
    case gratitude
    case intention
    case meditation
    case custom
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .prayer: return "Prayer"
        case .scripture: return "Scripture"
        case .breathing: return "Breathing"
        case .reflection: return "Reflection"
        case .gratitude: return "Gratitude"
        case .intention: return "Intention"
        case .meditation: return "Meditation"
        case .custom: return "Custom"
        }
    }
    
    var icon: String {
        switch self {
        case .prayer: return "hands.sparkles"
        case .scripture: return "book.fill"
        case .breathing: return "wind"
        case .reflection: return "sparkles"
        case .gratitude: return "heart.fill"
        case .intention: return "target"
        case .meditation: return "figure.mind.and.body"
        case .custom: return "star.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .prayer: return .teal
        case .scripture: return .blue
        case .breathing: return .cyan
        case .reflection: return .indigo
        case .gratitude: return .pink
        case .intention: return .green
        case .meditation: return .teal
        case .custom: return .orange
        }
    }
}

// MARK: - Routine Step

/// A single step in a routine
struct RoutineStep: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var title: String
    var description: String
    var category: RoutineStepCategory
    var durationSeconds: Int?
    var isEnabled: Bool
    var order: Int
    var mode: RoutineMode
    var content: RoutineStepContent
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        category: RoutineStepCategory,
        durationSeconds: Int? = nil,
        isEnabled: Bool = true,
        order: Int = 0,
        mode: RoutineMode = .anytime,
        content: RoutineStepContent = .text("")
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.durationSeconds = durationSeconds
        self.isEnabled = isEnabled
        self.order = order
        self.mode = mode
        self.content = content
    }
    
    var formattedDuration: String? {
        guard let seconds = durationSeconds else { return nil }
        if seconds < 60 {
            return "\(seconds)s"
        } else {
            let minutes = seconds / 60
            return "\(minutes) min"
        }
    }
}

// MARK: - Step Content

/// Content types for routine steps
enum RoutineStepContent: Codable, Equatable, Hashable {
    case text(String)
    case scripture(reference: String, text: String)
    case breathing(inhaleSeconds: Int, holdSeconds: Int, exhaleSeconds: Int, cycles: Int)
    case gratitudePrompt(count: Int)
    case intentionSetter
    case prayerPrompts([String])
    case reflectionQuestions([String])
    case custom(instructions: String)
    
    var displayType: String {
        switch self {
        case .text: return "Text"
        case .scripture: return "Scripture"
        case .breathing: return "Breathing Exercise"
        case .gratitudePrompt: return "Gratitude"
        case .intentionSetter: return "Intention"
        case .prayerPrompts: return "Prayer Prompts"
        case .reflectionQuestions: return "Reflection"
        case .custom: return "Custom"
        }
    }
}

// MARK: - Routine Configuration

/// User's saved routine configuration
struct RoutineConfiguration: Identifiable, Codable {
    let id: UUID
    var name: String
    var steps: [RoutineStep]
    var mode: RoutineMode
    var createdAt: Date
    var lastUsedAt: Date?
    var completionCount: Int
    
    init(
        id: UUID = UUID(),
        name: String,
        steps: [RoutineStep],
        mode: RoutineMode,
        createdAt: Date = Date(),
        lastUsedAt: Date? = nil,
        completionCount: Int = 0
    ) {
        self.id = id
        self.name = name
        self.steps = steps
        self.mode = mode
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
        self.completionCount = completionCount
    }
    
    var enabledSteps: [RoutineStep] {
        steps.filter { $0.isEnabled }.sorted { $0.order < $1.order }
    }
    
    var totalDurationSeconds: Int {
        enabledSteps.compactMap { $0.durationSeconds }.reduce(0, +)
    }
    
    var formattedTotalDuration: String {
        let minutes = totalDurationSeconds / 60
        if minutes < 1 {
            return "< 1 min"
        }
        return "\(minutes) min"
    }
}

// MARK: - Default Steps Library

/// Library of pre-built routine steps users can choose from
struct RoutineStepLibrary {
    
    // MARK: - Morning Steps
    
    static let morningPrayer = RoutineStep(
        title: "Morning Prayer",
        description: "Start your day with gratitude and surrender",
        category: .prayer,
        durationSeconds: 120,
        mode: .morning,
        content: .prayerPrompts([
            "Thank God for the gift of a new day",
            "Ask for His guidance in all you do today",
            "Surrender any worries or anxieties",
            "Ask for opportunities to serve others"
        ])
    )
    
    static let morningScripture = RoutineStep(
        title: "Daily Scripture",
        description: "Meditate on God's Word",
        category: .scripture,
        durationSeconds: 180,
        mode: .morning,
        content: .scripture(
            reference: "Psalm 118:24",
            text: "This is the day the Lord has made; let us rejoice and be glad in it."
        )
    )
    
    static let setIntention = RoutineStep(
        title: "Set Your Intention",
        description: "Choose one focus for today",
        category: .intention,
        durationSeconds: 60,
        mode: .morning,
        content: .intentionSetter
    )
    
    static let morningBreathing = RoutineStep(
        title: "Centering Breath",
        description: "Center yourself before starting your day",
        category: .breathing,
        durationSeconds: 60,
        mode: .morning,
        content: .breathing(inhaleSeconds: 4, holdSeconds: 4, exhaleSeconds: 4, cycles: 4)
    )
    
    static let morningGratitude = RoutineStep(
        title: "Morning Gratitude",
        description: "Name three things you're grateful for",
        category: .gratitude,
        durationSeconds: 90,
        mode: .morning,
        content: .gratitudePrompt(count: 3)
    )
    
    // MARK: - Evening Steps
    
    static let eveningReflection = RoutineStep(
        title: "Daily Reflection",
        description: "Reflect on your day",
        category: .reflection,
        durationSeconds: 180,
        mode: .evening,
        content: .reflectionQuestions([
            "Where did you see God at work today?",
            "What moments brought you joy?",
            "What challenged you?",
            "What would you do differently?"
        ])
    )
    
    static let releaseAndForgive = RoutineStep(
        title: "Release & Forgive",
        description: "Let go of anything weighing on your heart",
        category: .reflection,
        durationSeconds: 120,
        mode: .evening,
        content: .reflectionQuestions([
            "Is there anyone you need to forgive?",
            "Do you need to forgive yourself?",
            "Is there anything you need to confess?"
        ])
    )
    
    static let eveningGratitude = RoutineStep(
        title: "Evening Gratitude",
        description: "Count today's blessings",
        category: .gratitude,
        durationSeconds: 120,
        mode: .evening,
        content: .gratitudePrompt(count: 3)
    )
    
    static let sleepPrayer = RoutineStep(
        title: "Sleep Prayer",
        description: "Commit your rest to the Lord",
        category: .prayer,
        durationSeconds: 120,
        mode: .evening,
        content: .prayerPrompts([
            "Thank God for this day and all its moments",
            "Release any worries into His hands",
            "Ask for peaceful, restful sleep",
            "Trust Him with tomorrow"
        ])
    )
    
    static let eveningScripture = RoutineStep(
        title: "Peaceful Scripture",
        description: "Rest in God's promises",
        category: .scripture,
        durationSeconds: 120,
        mode: .evening,
        content: .scripture(
            reference: "Psalm 4:8",
            text: "In peace I will lie down and sleep, for you alone, Lord, make me dwell in safety."
        )
    )
    
    static let eveningBreathing = RoutineStep(
        title: "Relaxation Breath",
        description: "Calm your mind for sleep",
        category: .breathing,
        durationSeconds: 90,
        mode: .evening,
        content: .breathing(inhaleSeconds: 4, holdSeconds: 7, exhaleSeconds: 8, cycles: 3)
    )
    
    // MARK: - All Steps
    
    static var morningSteps: [RoutineStep] {
        [morningPrayer, morningScripture, setIntention, morningGratitude, morningBreathing]
    }
    
    static var eveningSteps: [RoutineStep] {
        [eveningReflection, releaseAndForgive, eveningGratitude, eveningScripture, sleepPrayer, eveningBreathing]
    }
    
    static var allSteps: [RoutineStep] {
        morningSteps + eveningSteps
    }
    
    // MARK: - Default Configurations
    
    static var defaultMorningRoutine: RoutineConfiguration {
        var steps = morningSteps
        for i in 0..<steps.count {
            steps[i].order = i
        }
        return RoutineConfiguration(
            name: "Default Morning Routine",
            steps: steps,
            mode: .morning
        )
    }
    
    static var defaultEveningRoutine: RoutineConfiguration {
        var steps = eveningSteps
        for i in 0..<steps.count {
            steps[i].order = i
        }
        return RoutineConfiguration(
            name: "Default Evening Routine",
            steps: steps,
            mode: .evening
        )
    }
}


