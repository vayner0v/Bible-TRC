//
//  HubNavigationManager.swift
//  Bible v1
//
//  Centralized navigation management for Hub
//

import SwiftUI
import Combine

/// All possible navigation destinations from the Hub
enum HubDestination: String, CaseIterable, Identifiable, Hashable {
    // Prayer
    case prayerJournal
    case guidedPrayer
    case addPrayer
    case scripturePrayer
    case prayerLibrary
    case prayerSchedule
    case audioPrayers
    
    // Habits & Wellness
    case habitsTracker
    case gratitudeTracker
    case moodCheckIn
    
    // Reading & Study
    case readingPlans
    case devotionals
    case verseOfDay
    
    // Routines (unified)
    case dailyRoutine
    case routineManager
    case routineAnalytics
    case weeklyRecap
    
    // Other Features
    case fasting
    case missions
    case widgets
    
    var id: String { rawValue }
    
    /// Display title for the destination
    var title: String {
        switch self {
        case .prayerJournal: return "Prayer Journal"
        case .guidedPrayer: return "Guided Prayer"
        case .addPrayer: return "Add Prayer"
        case .scripturePrayer: return "Scripture Prayer"
        case .prayerLibrary: return "Prayer Library"
        case .prayerSchedule: return "Prayer Schedule"
        case .audioPrayers: return "Audio Prayers"
        case .habitsTracker: return "Daily Habits"
        case .gratitudeTracker: return "Gratitude"
        case .moodCheckIn: return "Mood Check-in"
        case .readingPlans: return "Reading Plans"
        case .devotionals: return "Devotionals"
        case .verseOfDay: return "Verse of the Day"
        case .dailyRoutine: return dynamicRoutineTitle
        case .routineManager: return "My Routines"
        case .routineAnalytics: return "Routine Analytics"
        case .weeklyRecap: return "Weekly Recap"
        case .fasting: return "Fasting"
        case .missions: return "Missions"
        case .widgets: return "Widgets"
        }
    }
    
    /// Dynamic title based on time of day
    private var dynamicRoutineTitle: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Morning Routine"
        case 18..<24, 0..<4: return "Evening Routine"
        default: return "Daily Routine"
        }
    }
    
    /// SF Symbol icon for the destination
    var icon: String {
        switch self {
        case .prayerJournal: return "book.closed.fill"
        case .guidedPrayer: return "hands.sparkles"
        case .addPrayer: return "plus.circle.fill"
        case .scripturePrayer: return "text.book.closed.fill"
        case .prayerLibrary: return "books.vertical.fill"
        case .prayerSchedule: return "bell.badge.fill"
        case .audioPrayers: return "headphones"
        case .habitsTracker: return "checkmark.circle.fill"
        case .gratitudeTracker: return "heart.fill"
        case .moodCheckIn: return "face.smiling"
        case .readingPlans: return "book.fill"
        case .devotionals: return "sun.max.fill"
        case .verseOfDay: return "sparkles"
        case .dailyRoutine: return dynamicRoutineIcon
        case .routineManager: return "list.bullet"
        case .routineAnalytics: return "chart.xyaxis.line"
        case .weeklyRecap: return "chart.bar.fill"
        case .fasting: return "leaf.fill"
        case .missions: return "target"
        case .widgets: return "square.grid.2x2.fill"
        }
    }
    
    /// Dynamic icon based on time of day
    private var dynamicRoutineIcon: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "sunrise.fill"
        case 18..<24, 0..<4: return "moon.stars.fill"
        default: return "clock.fill"
        }
    }
    
    /// Primary color for the destination tile
    var color: Color {
        switch self {
        case .prayerJournal: return ThemeManager.shared.accentColor
        case .guidedPrayer: return .teal
        case .addPrayer: return ThemeManager.shared.accentColor
        case .scripturePrayer: return .teal
        case .prayerLibrary: return ThemeManager.shared.accentColor.opacity(0.8)
        case .prayerSchedule: return .orange
        case .audioPrayers: return .cyan
        case .habitsTracker: return .green
        case .gratitudeTracker: return .pink
        case .moodCheckIn: return .teal
        case .readingPlans: return ThemeManager.shared.accentColor
        case .devotionals: return .orange
        case .verseOfDay: return .yellow
        case .dailyRoutine: return dynamicRoutineColor
        case .routineManager: return Color.Journal.warmBrown
        case .routineAnalytics: return .indigo
        case .weeklyRecap: return ThemeManager.shared.accentColor
        case .fasting: return .mint
        case .missions: return .red
        case .widgets: return .purple
        }
    }
    
    /// Dynamic color based on time of day
    private var dynamicRoutineColor: Color {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return .orange
        case 18..<24, 0..<4: return .indigo
        default: return .blue
        }
    }
    
    /// Short description for the destination
    var subtitle: String {
        switch self {
        case .prayerJournal: return "Track your prayers"
        case .guidedPrayer: return "Peaceful sessions"
        case .addPrayer: return "New request"
        case .scripturePrayer: return "Bible-based prayers"
        case .prayerLibrary: return "Saved prayers"
        case .prayerSchedule: return "Set reminders"
        case .audioPrayers: return "Listen & meditate"
        case .habitsTracker: return "Build consistency"
        case .gratitudeTracker: return "Count blessings"
        case .moodCheckIn: return "How are you?"
        case .readingPlans: return "Stay on track"
        case .devotionals: return "Daily inspiration"
        case .verseOfDay: return "Daily scripture"
        case .dailyRoutine: return dynamicRoutineSubtitle
        case .routineManager: return "Customize & create"
        case .routineAnalytics: return "Track your progress"
        case .weeklyRecap: return "Your progress"
        case .fasting: return "Spiritual discipline"
        case .missions: return "Acts of faith"
        case .widgets: return "Customize your home screen"
        }
    }
    
    /// Dynamic subtitle based on time of day
    private var dynamicRoutineSubtitle: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Start your day right"
        case 18..<24, 0..<4: return "Rest & reflect"
        default: return "Morning or evening"
        }
    }
}

/// Manages navigation state for the Hub
@MainActor
final class HubNavigationManager: ObservableObject {
    /// Currently presented sheet destination
    @Published var presentedSheet: HubDestination?
    
    /// Navigation path for push navigation (if using NavigationStack)
    @Published var navigationPath: [HubDestination] = []
    
    /// Dismiss any presented sheet
    func dismissSheet() {
        presentedSheet = nil
    }
    
    /// Navigate to a destination via sheet
    func present(_ destination: HubDestination) {
        presentedSheet = destination
    }
    
    /// Push a destination onto the navigation stack
    func push(_ destination: HubDestination) {
        navigationPath.append(destination)
    }
    
    /// Pop the last destination from the navigation stack
    func pop() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }
    
    /// Clear the entire navigation stack
    func popToRoot() {
        navigationPath.removeAll()
    }
}

/// Violet color extension for consistency
extension Color {
    static let violet = Color(red: 0.55, green: 0.35, blue: 0.85)
}
