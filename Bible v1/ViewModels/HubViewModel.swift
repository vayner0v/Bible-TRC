//
//  HubViewModel.swift
//  Bible v1
//
//  Spiritual Hub - Main ViewModel
//

import Foundation
import Combine
import SwiftUI

/// Main ViewModel for the Hub tab
@MainActor
class HubViewModel: ObservableObject {
    
    // MARK: - Services
    
    private let storage = HubStorageService.shared
    private let widgetService = WidgetDataService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published Properties
    
    // Prayer
    @Published var prayerEntries: [PrayerEntry] = []
    @Published var guidedSessions: [GuidedPrayerSession] = []
    
    // Habits
    @Published var habitEntries: [HabitEntry] = []
    @Published var habitStreaks: [HabitStreak] = []
    @Published var trackedHabits: [SpiritualHabit] = []
    @Published var todayCompletedHabits: [SpiritualHabit] = []
    
    // Gratitude
    @Published var gratitudeEntries: [GratitudeEntry] = []
    @Published var todayGratitude: GratitudeEntry?
    
    // Mood
    @Published var moodEntries: [MoodEntry] = []
    @Published var todayMood: MoodEntry?
    
    // Reading Plans
    @Published var readingPlanProgress: [ReadingPlanProgress] = []
    @Published var activeReadingPlanId: UUID?
    @Published var activePlan: ReadingPlan?
    @Published var activeProgress: ReadingPlanProgress?
    
    // Routines
    @Published var didCompleteMorningRoutine: Bool = false
    @Published var didCompleteNightRoutine: Bool = false
    @Published var dailyIntention: String?
    
    // Stats
    @Published var weeklyStats: WeeklyStats?
    
    // UI State
    @Published var selectedSection: HubSection = .today
    
    // MARK: - Computed Properties
    
    var unansweredPrayers: [PrayerEntry] {
        prayerEntries.filter { !$0.isAnswered }
    }
    
    var answeredPrayers: [PrayerEntry] {
        prayerEntries.filter { $0.isAnswered }
    }
    
    var todayHabitProgress: Double {
        guard !trackedHabits.isEmpty else { return 0 }
        return Double(todayCompletedHabits.count) / Double(trackedHabits.count)
    }
    
    var hasCompletedTodayGratitude: Bool {
        todayGratitude?.isComplete ?? false
    }
    
    var hasCheckedInMoodToday: Bool {
        todayMood != nil
    }
    
    /// Total minutes spent in guided prayer sessions
    var totalPrayerMinutes: Int {
        storage.totalPrayerMinutes
    }
    
    /// Number of guided sessions completed this week
    var guidedSessionsThisWeek: Int {
        storage.guidedSessionsThisWeek
    }
    
    var currentReadingDay: ReadingPlanDay? {
        guard let plan = activePlan, let progress = activeProgress else { return nil }
        let dayIndex = progress.currentDay - 1
        guard dayIndex >= 0 && dayIndex < plan.days.count else { return nil }
        return plan.days[dayIndex]
    }
    
    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        case 17..<21: return "Good Evening"
        default: return "Good Night"
        }
    }
    
    var todaySummary: String {
        var items: [String] = []
        
        if !todayCompletedHabits.isEmpty {
            items.append("\(todayCompletedHabits.count) habit\(todayCompletedHabits.count == 1 ? "" : "s")")
        }
        
        if let gratitude = todayGratitude, !gratitude.items.isEmpty {
            items.append("\(gratitude.items.count) gratitude\(gratitude.items.count == 1 ? "" : "s")")
        }
        
        if didCompleteMorningRoutine {
            items.append("morning routine")
        }
        
        if items.isEmpty {
            return "Start your spiritual journey today"
        }
        
        return "Today: " + items.joined(separator: ", ")
    }
    
    // MARK: - Initialization
    
    init() {
        setupBindings()
        refreshData()
    }
    
    private func setupBindings() {
        // Observe storage changes
        storage.$prayerEntries
            .receive(on: DispatchQueue.main)
            .assign(to: &$prayerEntries)
        
        storage.$guidedSessions
            .receive(on: DispatchQueue.main)
            .assign(to: &$guidedSessions)
        
        storage.$habitEntries
            .receive(on: DispatchQueue.main)
            .assign(to: &$habitEntries)
        
        storage.$habitStreaks
            .receive(on: DispatchQueue.main)
            .assign(to: &$habitStreaks)
        
        storage.$trackedHabits
            .receive(on: DispatchQueue.main)
            .assign(to: &$trackedHabits)
        
        storage.$gratitudeEntries
            .receive(on: DispatchQueue.main)
            .assign(to: &$gratitudeEntries)
        
        storage.$moodEntries
            .receive(on: DispatchQueue.main)
            .assign(to: &$moodEntries)
        
        storage.$readingPlanProgress
            .receive(on: DispatchQueue.main)
            .assign(to: &$readingPlanProgress)
        
        storage.$activeReadingPlanId
            .receive(on: DispatchQueue.main)
            .sink { [weak self] id in
                self?.activeReadingPlanId = id
                self?.updateActivePlan()
            }
            .store(in: &cancellables)
    }
    
    func refreshData() {
        todayCompletedHabits = storage.todayCompletedHabits()
        todayGratitude = storage.getTodayGratitude()
        todayMood = storage.getTodayMood()
        didCompleteMorningRoutine = storage.didCompleteMorningRoutineToday
        didCompleteNightRoutine = storage.didCompleteNightRoutineToday
        dailyIntention = storage.getTodayIntention()
        weeklyStats = storage.getWeeklyStats()
        updateActivePlan()
        
        // Sync widget data
        syncWidgetData()
    }
    
    /// Sync all relevant data to widgets
    private func syncWidgetData() {
        // Sync verse of the day
        let verse = verseOfTheDay
        widgetService.updateVerseOfDay(text: verse.text, reference: verse.reference)
        
        // Sync reading progress
        if let plan = activePlan, let progress = activeProgress {
            let totalDays = plan.days.count
            let completedCount = progress.completedDays.count
            let progressPercent = totalDays > 0 ? Double(completedCount) / Double(totalDays) : 0.0
            
            widgetService.updateReadingProgress(
                planName: plan.name,
                progress: progressPercent,
                streak: progress.currentStreak,
                currentDay: progress.currentDay,
                totalDays: totalDays
            )
        }
        
        // Sync prayer data
        widgetService.updatePrayerData(
            activeCount: unansweredPrayers.count,
            answeredCount: answeredPrayers.count,
            lastTime: prayerEntries.first?.dateCreated
        )
        
        // Sync habit data
        let maxStreak = trackedHabits.map { getStreak(for: $0) }.max() ?? 0
        widgetService.updateHabitData(
            progress: todayHabitProgress,
            completed: todayCompletedHabits.count,
            total: trackedHabits.count,
            streak: maxStreak
        )
        
        // Sync mood/gratitude
        let moodHistory = Array(moodEntries.prefix(5).compactMap { $0.mood.emoji })
        widgetService.updateMoodGratitude(
            lastMood: todayMood?.mood.emoji,
            moodHistory: moodHistory,
            lastDate: todayMood?.date,
            gratitudeStreak: gratitudeStreak,
            todayCompleted: hasCompletedTodayGratitude
        )
    }
    
    private func updateActivePlan() {
        if let planId = activeReadingPlanId {
            activePlan = ReadingPlan.allPlans.first { $0.id == planId }
            activeProgress = storage.getProgress(for: planId)
        } else {
            activePlan = nil
            activeProgress = nil
        }
    }
    
    // MARK: - Prayer Actions
    
    func addPrayer(title: String, content: String, category: PrayerCategory, linkedVerse: (reference: String, text: String)? = nil) {
        let entry = PrayerEntry(
            title: title,
            content: content,
            category: category,
            linkedVerseReference: linkedVerse?.reference,
            linkedVerseText: linkedVerse?.text
        )
        storage.addPrayerEntry(entry)
    }
    
    func updatePrayer(_ prayer: PrayerEntry) {
        storage.updatePrayerEntry(prayer)
    }
    
    func deletePrayer(_ prayer: PrayerEntry) {
        storage.deletePrayerEntry(prayer)
    }
    
    func markPrayerAnswered(_ prayer: PrayerEntry, note: String? = nil) {
        storage.markPrayerAnswered(prayer, note: note)
    }
    
    func recordGuidedSession(theme: GuidedPrayerTheme, duration: Int, notes: String? = nil) {
        let session = GuidedPrayerSession(theme: theme, duration: duration, notes: notes)
        storage.addGuidedSession(session)
        refreshData()
    }
    
    // MARK: - Habit Actions
    
    func toggleHabit(_ habit: SpiritualHabit) {
        if isHabitCompletedToday(habit) {
            // Can't un-complete for now (could add this feature later)
            return
        }
        storage.recordHabitCompletion(habit: habit)
        todayCompletedHabits = storage.todayCompletedHabits()
        refreshData()
    }
    
    func recordHabit(_ habit: SpiritualHabit, notes: String? = nil, duration: Int? = nil) {
        storage.recordHabitCompletion(habit: habit, notes: notes, duration: duration)
        todayCompletedHabits = storage.todayCompletedHabits()
        refreshData()
    }
    
    func isHabitCompletedToday(_ habit: SpiritualHabit) -> Bool {
        storage.isHabitCompletedToday(habit)
    }
    
    func getStreak(for habit: SpiritualHabit) -> Int {
        storage.getStreak(for: habit)?.currentStreak ?? 0
    }
    
    func setTrackedHabits(_ habits: [SpiritualHabit]) {
        storage.setTrackedHabits(habits)
    }
    
    // MARK: - Gratitude Actions
    
    func addGratitudeItem(_ text: String, category: GratitudeCategory = .general) {
        storage.addGratitudeItem(text, category: category)
        todayGratitude = storage.getTodayGratitude()
        refreshData()
    }
    
    func updateGratitude(_ entry: GratitudeEntry) {
        storage.updateGratitudeEntry(entry)
        todayGratitude = storage.getTodayGratitude()
    }
    
    func removeGratitudeItem(at index: Int, from entry: GratitudeEntry) {
        storage.removeGratitudeItem(at: index, from: entry)
        todayGratitude = storage.getTodayGratitude()
        refreshData()
    }
    
    func updateGratitudeItem(at index: Int, in entry: GratitudeEntry, text: String, category: GratitudeCategory) {
        storage.updateGratitudeItem(at: index, in: entry, text: text, category: category)
        todayGratitude = storage.getTodayGratitude()
        refreshData()
    }
    
    func updateGratitudeReflection(_ entry: GratitudeEntry, reflection: String?) {
        storage.updateGratitudeReflection(entry, reflection: reflection)
        todayGratitude = storage.getTodayGratitude()
        refreshData()
    }
    
    func deleteGratitudeEntry(_ entry: GratitudeEntry) {
        storage.deleteGratitudeEntry(entry)
        todayGratitude = storage.getTodayGratitude()
        refreshData()
    }
    
    func getGratitudeEntry(for date: Date) -> GratitudeEntry? {
        storage.getGratitudeEntry(for: date)
    }
    
    func getAllGratitudeEntries() -> [GratitudeEntry] {
        storage.getAllGratitudeEntries()
    }
    
    func getGratitudeEntries(for month: Date) -> [GratitudeEntry] {
        storage.getGratitudeEntries(for: month)
    }
    
    func getWeeklyGratitudeSummary(weekOffset: Int = 0) -> WeeklyGratitudeSummary {
        storage.getWeeklyGratitudeSummary(weekOffset: weekOffset)
    }
    
    func hasGratitudeEntriesBeforeWeek(offset: Int) -> Bool {
        storage.hasGratitudeEntriesBeforeWeek(offset: offset)
    }
    
    func getGratitudeActivity(days: Int = 7) -> [(date: Date, hasEntry: Bool, isComplete: Bool)] {
        storage.getGratitudeActivity(days: days)
    }
    
    var gratitudeStreak: Int {
        storage.gratitudeStreak
    }
    
    var longestGratitudeStreak: Int {
        storage.longestGratitudeStreak
    }
    
    // MARK: - Mood Actions
    
    func recordMood(_ mood: MoodLevel, note: String? = nil, factors: [MoodFactor] = []) {
        let entry = MoodEntry(mood: mood, note: note, factors: factors)
        storage.addMoodEntry(entry)
        todayMood = storage.getTodayMood()
        refreshData()
    }
    
    func getWeeklyMoodSummary() -> WeeklyMoodSummary {
        storage.getWeeklyMoodSummary()
    }
    
    // MARK: - Reading Plan Actions
    
    func startPlan(_ plan: ReadingPlan) {
        storage.startReadingPlan(plan)
        updateActivePlan()
        refreshData()
    }
    
    func completeReadingDay(_ day: Int) {
        guard let plan = activePlan else { return }
        storage.completeReadingDay(planId: plan.id, day: day, totalDays: plan.days.count)
        updateActivePlan()
        refreshData()
    }
    
    func addReadingNote(_ note: String, for day: Int) {
        guard let plan = activePlan else { return }
        storage.addReadingNote(planId: plan.id, day: day, note: note)
        updateActivePlan()
    }
    
    func switchActivePlan(to planId: UUID?) {
        storage.setActiveReadingPlan(planId)
        updateActivePlan()
    }
    
    // MARK: - Routine Actions (Legacy)
    
    func completeMorningRoutine() {
        storage.recordMorningRoutine()
        didCompleteMorningRoutine = true
        refreshData()
    }
    
    func completeNightRoutine() {
        storage.recordNightRoutine()
        didCompleteNightRoutine = true
        refreshData()
    }
    
    func setDailyIntention(_ intention: String) {
        storage.setDailyIntention(intention)
        dailyIntention = intention
    }
    
    /// Get weekly stats (used as fallback if cached stats are nil)
    func getWeeklyStats() -> WeeklyStats {
        storage.getWeeklyStats()
    }
    
    // MARK: - Enhanced Routine Actions
    
    /// Get all routine configurations
    func getAllRoutineConfigurations() -> [RoutineConfiguration] {
        storage.getAllRoutineConfigurations()
    }
    
    /// Get routines for a specific mode
    func getRoutineConfigurations(for mode: RoutineMode) -> [RoutineConfiguration] {
        storage.getRoutineConfigurations(for: mode)
    }
    
    /// Get the default routine for a mode
    func getDefaultRoutine(for mode: RoutineMode) -> RoutineConfiguration? {
        storage.getDefaultRoutine(for: mode)
    }
    
    /// Get a specific routine configuration
    func getRoutineConfiguration(id: UUID) -> RoutineConfiguration? {
        storage.getRoutineConfiguration(id: id)
    }
    
    /// Add a new routine configuration
    func addRoutineConfiguration(_ config: RoutineConfiguration) {
        storage.addRoutineConfiguration(config)
    }
    
    /// Update an existing routine configuration
    func updateRoutineConfiguration(_ config: RoutineConfiguration) {
        storage.updateRoutineConfiguration(config)
    }
    
    /// Delete a routine configuration
    func deleteRoutineConfiguration(_ config: RoutineConfiguration) {
        storage.deleteRoutineConfiguration(config)
    }
    
    /// Set the default routine for a mode
    func setDefaultRoutine(id: UUID, for mode: RoutineMode) {
        storage.setDefaultRoutine(id: id, for: mode)
    }
    
    /// Duplicate a routine
    func duplicateRoutineConfiguration(_ config: RoutineConfiguration, newName: String? = nil) -> RoutineConfiguration {
        storage.duplicateRoutineConfiguration(config, newName: newName)
    }
    
    /// Record a routine completion with full data and sync
    func recordRoutineCompletion(
        configuration: RoutineConfiguration,
        startTime: Date,
        stepsCompleted: Int,
        intentionText: String? = nil,
        gratitudeItems: [String] = [],
        reflectionNotes: String? = nil,
        moodAtStart: MoodLevel? = nil,
        moodAtEnd: MoodLevel? = nil
    ) {
        let completion = RoutineCompletion(
            configurationId: configuration.id,
            configurationName: configuration.name,
            mode: configuration.mode,
            startTime: startTime,
            stepsCompleted: stepsCompleted,
            totalSteps: configuration.enabledSteps.count,
            intentionText: intentionText,
            gratitudeItems: gratitudeItems,
            reflectionNotes: reflectionNotes,
            moodAtStart: moodAtStart,
            moodAtEnd: moodAtEnd,
            autoCheckedHabits: configuration.linkedHabits
        )
        
        // Record the completion
        storage.recordRoutineCompletion(completion)
        
        // Sync gratitude items to main gratitude tracker
        for item in gratitudeItems where !item.isEmpty {
            addGratitudeItem(item, category: .general)
        }
        
        // Record mood if provided
        if let mood = moodAtEnd {
            recordMood(mood)
        }
        
        // Auto-check linked habits
        for habit in configuration.linkedHabits {
            if !isHabitCompletedToday(habit) {
                recordHabit(habit, notes: "Completed via \(configuration.name)")
            }
        }
        
        // Update legacy tracking for backward compatibility
        if configuration.mode == .morning {
            didCompleteMorningRoutine = true
        } else if configuration.mode == .evening {
            didCompleteNightRoutine = true
        }
        
        if let intention = intentionText, !intention.isEmpty {
            setDailyIntention(intention)
        }
        
        refreshData()
    }
    
    /// Get routine analytics
    func getRoutineAnalytics(period: RoutineAnalytics.AnalyticsPeriod = .week) -> RoutineAnalytics {
        storage.getRoutineAnalytics(period: period)
    }
    
    /// Get streak for a specific mode
    func getRoutineStreak(for mode: RoutineMode) -> RoutineStreak {
        storage.getRoutineStreak(for: mode)
    }
    
    /// Get the best current streak
    var bestRoutineStreak: Int {
        storage.bestCurrentRoutineStreak
    }
    
    /// Get combined routine streak
    var combinedRoutineStreak: RoutineStreak {
        storage.combinedRoutineStreak
    }
    
    /// Get today's routine completions
    func getTodayRoutineCompletions() -> [RoutineCompletion] {
        storage.getTodayRoutineCompletions()
    }
    
    /// Get completion calendar for visualization
    func getRoutineCompletionCalendar(days: Int = 30) -> [(date: Date, completions: [RoutineCompletion])] {
        storage.getRoutineCompletionCalendar(days: days)
    }
    
    /// Check if a specific mode routine was completed today
    func didCompleteRoutineToday(mode: RoutineMode) -> Bool {
        storage.didCompleteRoutineToday(mode: mode)
    }
    
    // MARK: - Verse of the Day
    
    /// Verse of the day - uses the centralized HubStorageService to ensure consistency
    /// across all views (HubHeaderView, VerseOfDayView, MorningRoutineView)
    var verseOfTheDay: (reference: String, text: String) {
        let todayVerse = storage.getOrCreateTodayVerse()
        return (todayVerse.verseReference, todayVerse.verseText)
    }
    
    // MARK: - Daily Mission
    
    var dailyMission: String {
        let missions = [
            "Send an encouraging message to someone who might need it.",
            "Take 5 minutes to pray for a friend or family member.",
            "Find one opportunity to show kindness to a stranger.",
            "Write a note of gratitude to someone who has helped you.",
            "Practice patience in a frustrating situation today.",
            "Share a meal or coffee with someone you haven't connected with recently.",
            "Offer to help someone with a task without being asked."
        ]
        
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let index = (dayOfYear - 1) % missions.count
        return missions[index]
    }
}

// MARK: - Hub Sections

enum HubSection: String, CaseIterable, Identifiable {
    case today = "Today"
    case prayer = "Prayer"
    case habits = "Habits"
    case plans = "Plans"
    case routines = "Routines"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .today: return "sun.max.fill"
        case .prayer: return "hands.sparkles"
        case .habits: return "checkmark.circle.fill"
        case .plans: return "book.fill"
        case .routines: return "moon.stars.fill"
        }
    }
}


