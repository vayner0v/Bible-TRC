//
//  FastingEntry.swift
//  Bible v1
//
//  Spiritual Hub - Fasting Tracker Model
//

import Foundation
import SwiftUI

/// Types of fasting practices
enum FastingType: String, Codable, CaseIterable, Identifiable {
    case intermittent = "Intermittent"
    case danielFast = "Daniel Fast"
    case waterOnly = "Water Only"
    case juiceFast = "Juice Fast"
    case partialFast = "Partial Fast"
    case sunriseSunset = "Sunrise to Sunset"
    case custom = "Custom"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .intermittent: return "clock.fill"
        case .danielFast: return "leaf.fill"
        case .waterOnly: return "drop.fill"
        case .juiceFast: return "cup.and.saucer.fill"
        case .partialFast: return "fork.knife"
        case .sunriseSunset: return "sun.and.horizon.fill"
        case .custom: return "slider.horizontal.3"
        }
    }
    
    var description: String {
        switch self {
        case .intermittent:
            return "Time-restricted eating (e.g., 16:8 or 18:6)"
        case .danielFast:
            return "Vegetables, fruits, and water only - based on Daniel 1:12"
        case .waterOnly:
            return "Complete food abstinence, water permitted"
        case .juiceFast:
            return "Fresh juices and water only"
        case .partialFast:
            return "Abstaining from specific foods or meals"
        case .sunriseSunset:
            return "No food from sunrise to sunset"
        case .custom:
            return "Define your own fasting parameters"
        }
    }
    
    var color: Color {
        switch self {
        case .intermittent: return .blue
        case .danielFast: return .green
        case .waterOnly: return .cyan
        case .juiceFast: return .orange
        case .partialFast: return .teal
        case .sunriseSunset: return .yellow
        case .custom: return .gray
        }
    }
    
    var healthGuidance: String {
        switch self {
        case .intermittent:
            return "Generally safe for healthy adults. Stay hydrated and listen to your body."
        case .danielFast:
            return "Ensure adequate nutrition through diverse plant foods. May be practiced for 7-21 days."
        case .waterOnly:
            return "Consult a healthcare provider before extended water fasts. Not recommended beyond 24-48 hours without supervision."
        case .juiceFast:
            return "Fresh, natural juices provide nutrients. Limit to 1-3 days for beginners."
        case .partialFast:
            return "Flexible approach suitable for most people. Maintain balanced nutrition in eating periods."
        case .sunriseSunset:
            return "Traditional practice. Ensure adequate hydration and nutrition during eating hours."
        case .custom:
            return "Design your fast thoughtfully. Consider consulting a healthcare provider for extended fasts."
        }
    }
}

/// Status of a fasting entry
enum FastingStatus: String, Codable {
    case active = "Active"
    case completed = "Completed"
    case broken = "Ended Early"
    case scheduled = "Scheduled"
}

/// Represents a fasting entry/session
struct FastingEntry: Identifiable, Codable, Hashable {
    let id: UUID
    var type: FastingType
    var intention: String
    var startDate: Date
    var plannedEndDate: Date
    var actualEndDate: Date?
    var status: FastingStatus
    var reflection: String?
    var spiritualInsights: String?
    let createdAt: Date
    var customDescription: String?
    
    init(
        id: UUID = UUID(),
        type: FastingType,
        intention: String,
        startDate: Date = Date(),
        plannedEndDate: Date,
        actualEndDate: Date? = nil,
        status: FastingStatus = .active,
        reflection: String? = nil,
        spiritualInsights: String? = nil,
        createdAt: Date = Date(),
        customDescription: String? = nil
    ) {
        self.id = id
        self.type = type
        self.intention = intention
        self.startDate = startDate
        self.plannedEndDate = plannedEndDate
        self.actualEndDate = actualEndDate
        self.status = status
        self.reflection = reflection
        self.spiritualInsights = spiritualInsights
        self.createdAt = createdAt
        self.customDescription = customDescription
    }
    
    /// Duration in hours (planned)
    var plannedDurationHours: Int {
        let interval = plannedEndDate.timeIntervalSince(startDate)
        return Int(interval / 3600)
    }
    
    /// Actual duration in hours
    var actualDurationHours: Int? {
        guard let endDate = actualEndDate else { return nil }
        let interval = endDate.timeIntervalSince(startDate)
        return Int(interval / 3600)
    }
    
    /// Current progress (0.0 to 1.0)
    var progress: Double {
        guard status == .active else {
            return status == .completed ? 1.0 : 0.0
        }
        
        let totalDuration = plannedEndDate.timeIntervalSince(startDate)
        let elapsed = Date().timeIntervalSince(startDate)
        return min(max(elapsed / totalDuration, 0), 1.0)
    }
    
    /// Time remaining in seconds
    var timeRemainingSeconds: Int {
        guard status == .active else { return 0 }
        let remaining = plannedEndDate.timeIntervalSince(Date())
        return max(Int(remaining), 0)
    }
    
    /// Check if fast is currently active
    var isActive: Bool {
        status == .active && Date() < plannedEndDate
    }
    
    /// Check if fast should auto-complete
    var shouldAutoComplete: Bool {
        status == .active && Date() >= plannedEndDate
    }
    
    /// Complete the fast
    mutating func complete(reflection: String? = nil, insights: String? = nil) {
        actualEndDate = Date()
        status = .completed
        self.reflection = reflection
        self.spiritualInsights = insights
    }
    
    /// End the fast early
    mutating func endEarly(reflection: String? = nil) {
        actualEndDate = Date()
        status = .broken
        self.reflection = reflection
    }
    
    /// Formatted duration string
    var durationString: String {
        let hours = plannedDurationHours
        if hours < 24 {
            return "\(hours) hours"
        } else {
            let days = hours / 24
            let remainingHours = hours % 24
            if remainingHours == 0 {
                return "\(days) day\(days == 1 ? "" : "s")"
            }
            return "\(days) day\(days == 1 ? "" : "s"), \(remainingHours) hr"
        }
    }
}

/// Fasting statistics summary
struct FastingStats {
    let totalFasts: Int
    let completedFasts: Int
    let totalHoursFasted: Int
    let longestFast: Int // hours
    let currentStreak: Int
    let mostCommonType: FastingType?
    
    var completionRate: Double {
        guard totalFasts > 0 else { return 0 }
        return Double(completedFasts) / Double(totalFasts)
    }
}

/// Health disclaimer for fasting
struct FastingDisclaimer {
    static let general = """
    Fasting is a spiritual discipline practiced throughout Scripture. However, it's important to approach it safely:
    
    • Consult a healthcare provider before extended fasts
    • Stay well hydrated during any fast
    • Break your fast gently with light foods
    • Listen to your body and stop if you feel unwell
    • Pregnant or nursing women, children, elderly, and those with medical conditions should consult a doctor first
    
    This app is for spiritual tracking only and does not provide medical advice.
    """
    
    static let shortVersion = "Consult a healthcare provider before extended fasts. Stay hydrated and listen to your body."
}



