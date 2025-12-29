//
//  HubStorageService.swift
//  Bible v1
//
//  Spiritual Hub - Storage Service for Hub-related data
//

import Foundation
import Combine

/// Service for storing all Hub-related user data
class HubStorageService: ObservableObject {
    static let shared = HubStorageService()
    
    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    // Storage Keys
    private enum Keys {
        static let prayerEntries = "hub_prayer_entries"
        static let guidedPrayerSessions = "hub_guided_sessions"
        static let habitEntries = "hub_habit_entries"
        static let habitStreaks = "hub_habit_streaks"
        static let gratitudeEntries = "hub_gratitude_entries"
        static let moodEntries = "hub_mood_entries"
        static let readingPlanProgress = "hub_reading_plan_progress"
        static let activeReadingPlanId = "hub_active_reading_plan"
        static let lastMorningRoutine = "hub_last_morning_routine"
        static let lastNightRoutine = "hub_last_night_routine"
        static let routineStreak = "hub_routine_streak"
        static let dailyIntention = "hub_daily_intention"
        static let trackedHabits = "hub_tracked_habits"
        // Phase 2 Keys
        static let fastingEntries = "hub_fasting_entries"
        static let activeFastingId = "hub_active_fasting"
        static let savedPrayers = "hub_saved_prayers"
        static let prayerCollections = "hub_prayer_collections"
        static let scripturePrayers = "hub_scripture_prayers"
        static let missionCompletions = "hub_mission_completions"
        static let devotionalProgress = "hub_devotional_progress"
        static let activeDevotionalId = "hub_active_devotional"
        static let sermonNotes = "hub_sermon_notes"
        static let verseOfDayEntries = "hub_verse_of_day_entries"
        static let memorizedVerses = "hub_memorized_verses"
    }
    
    // MARK: - Published Properties
    
    @Published private(set) var prayerEntries: [PrayerEntry] = []
    @Published private(set) var guidedSessions: [GuidedPrayerSession] = []
    @Published private(set) var habitEntries: [HabitEntry] = []
    @Published private(set) var habitStreaks: [HabitStreak] = []
    @Published private(set) var gratitudeEntries: [GratitudeEntry] = []
    @Published private(set) var moodEntries: [MoodEntry] = []
    @Published private(set) var readingPlanProgress: [ReadingPlanProgress] = []
    @Published private(set) var activeReadingPlanId: UUID?
    @Published private(set) var trackedHabits: [SpiritualHabit] = []
    
    // Phase 2 Published Properties
    @Published private(set) var fastingEntries: [FastingEntry] = []
    @Published private(set) var activeFastingId: UUID?
    @Published private(set) var savedPrayers: [SavedPrayer] = []
    @Published private(set) var prayerCollections: [PrayerCollection] = []
    @Published private(set) var scripturePrayers: [ScripturePrayer] = []
    @Published private(set) var missionCompletions: [MissionCompletion] = []
    @Published private(set) var devotionalProgress: [DevotionalProgress] = []
    @Published private(set) var activeDevotionalId: UUID?
    @Published private(set) var sermonNotes: [SermonNote] = []
    @Published private(set) var verseOfDayEntries: [VerseOfDayEntry] = []
    @Published private(set) var memorizedVerses: [MemorizationSession] = []
    
    init() {
        loadAll()
    }
    
    private func loadAll() {
        prayerEntries = load(key: Keys.prayerEntries) ?? []
        guidedSessions = load(key: Keys.guidedPrayerSessions) ?? []
        habitEntries = load(key: Keys.habitEntries) ?? []
        habitStreaks = load(key: Keys.habitStreaks) ?? initializeHabitStreaks()
        gratitudeEntries = load(key: Keys.gratitudeEntries) ?? []
        moodEntries = load(key: Keys.moodEntries) ?? []
        readingPlanProgress = load(key: Keys.readingPlanProgress) ?? []
        trackedHabits = load(key: Keys.trackedHabits) ?? defaultTrackedHabits
        
        if let idString = defaults.string(forKey: Keys.activeReadingPlanId) {
            activeReadingPlanId = UUID(uuidString: idString)
        }
        
        // Phase 2 Data Loading
        fastingEntries = load(key: Keys.fastingEntries) ?? []
        savedPrayers = load(key: Keys.savedPrayers) ?? DefaultPrayer.allDefaults
        prayerCollections = load(key: Keys.prayerCollections) ?? []
        scripturePrayers = load(key: Keys.scripturePrayers) ?? []
        missionCompletions = load(key: Keys.missionCompletions) ?? []
        devotionalProgress = load(key: Keys.devotionalProgress) ?? []
        sermonNotes = load(key: Keys.sermonNotes) ?? []
        verseOfDayEntries = load(key: Keys.verseOfDayEntries) ?? []
        memorizedVerses = load(key: Keys.memorizedVerses) ?? []
        
        if let idString = defaults.string(forKey: Keys.activeFastingId) {
            activeFastingId = UUID(uuidString: idString)
        }
        if let idString = defaults.string(forKey: Keys.activeDevotionalId) {
            activeDevotionalId = UUID(uuidString: idString)
        }
        
        // Check for expired active fasts
        checkActiveFastStatus()
    }
    
    private var defaultTrackedHabits: [SpiritualHabit] {
        [.prayer, .bibleReading, .gratitude, .service]
    }
    
    private func initializeHabitStreaks() -> [HabitStreak] {
        SpiritualHabit.allCases.map { HabitStreak(habit: $0) }
    }
    
    // MARK: - Generic Load/Save
    
    private func load<T: Codable>(key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? decoder.decode(T.self, from: data)
    }
    
    private func save<T: Codable>(_ value: T, key: String) {
        guard let data = try? encoder.encode(value) else { return }
        defaults.set(data, forKey: key)
    }
    
    // MARK: - Prayer Entries
    
    func addPrayerEntry(_ entry: PrayerEntry) {
        prayerEntries.insert(entry, at: 0)
        save(prayerEntries, key: Keys.prayerEntries)
    }
    
    func updatePrayerEntry(_ entry: PrayerEntry) {
        if let index = prayerEntries.firstIndex(where: { $0.id == entry.id }) {
            prayerEntries[index] = entry
            save(prayerEntries, key: Keys.prayerEntries)
        }
    }
    
    func deletePrayerEntry(_ entry: PrayerEntry) {
        prayerEntries.removeAll { $0.id == entry.id }
        save(prayerEntries, key: Keys.prayerEntries)
    }
    
    func markPrayerAnswered(_ entry: PrayerEntry, note: String? = nil) {
        if let index = prayerEntries.firstIndex(where: { $0.id == entry.id }) {
            var updated = entry
            updated.markAnswered(note: note)
            prayerEntries[index] = updated
            save(prayerEntries, key: Keys.prayerEntries)
        }
    }
    
    var answeredPrayersCount: Int {
        prayerEntries.filter { $0.isAnswered }.count
    }
    
    var unansweredPrayersCount: Int {
        prayerEntries.filter { !$0.isAnswered }.count
    }
    
    // MARK: - Guided Prayer Sessions
    
    func addGuidedSession(_ session: GuidedPrayerSession) {
        guidedSessions.insert(session, at: 0)
        save(guidedSessions, key: Keys.guidedPrayerSessions)
    }
    
    var totalPrayerMinutes: Int {
        guidedSessions.reduce(0) { $0 + ($1.duration / 60) }
    }
    
    var guidedSessionsThisWeek: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return guidedSessions.filter { $0.completedAt >= weekAgo }.count
    }
    
    // MARK: - Habit Entries
    
    func recordHabitCompletion(habit: SpiritualHabit, notes: String? = nil, duration: Int? = nil) {
        let entry = HabitEntry(habit: habit, notes: notes, duration: duration)
        habitEntries.insert(entry, at: 0)
        save(habitEntries, key: Keys.habitEntries)
        
        // Update streak
        updateStreak(for: habit)
    }
    
    func removeHabitEntry(_ entry: HabitEntry) {
        habitEntries.removeAll { $0.id == entry.id }
        save(habitEntries, key: Keys.habitEntries)
    }
    
    func isHabitCompletedToday(_ habit: SpiritualHabit) -> Bool {
        habitEntries.contains { $0.habit == habit && $0.isToday && $0.isCompleted }
    }
    
    func todayCompletedHabits() -> [SpiritualHabit] {
        let todayEntries = habitEntries.filter { $0.isToday && $0.isCompleted }
        return Array(Set(todayEntries.map { $0.habit }))
    }
    
    private func updateStreak(for habit: SpiritualHabit) {
        if let index = habitStreaks.firstIndex(where: { $0.habit == habit }) {
            habitStreaks[index].recordCompletion()
        } else {
            var newStreak = HabitStreak(habit: habit)
            newStreak.recordCompletion()
            habitStreaks.append(newStreak)
        }
        save(habitStreaks, key: Keys.habitStreaks)
    }
    
    func getStreak(for habit: SpiritualHabit) -> HabitStreak? {
        habitStreaks.first { $0.habit == habit }
    }
    
    func setTrackedHabits(_ habits: [SpiritualHabit]) {
        trackedHabits = habits
        save(trackedHabits, key: Keys.trackedHabits)
    }
    
    // MARK: - Gratitude Entries
    
    func getTodayGratitude() -> GratitudeEntry? {
        gratitudeEntries.first { $0.isToday }
    }
    
    func addGratitudeEntry(_ entry: GratitudeEntry) {
        // Replace if one exists for today
        if let index = gratitudeEntries.firstIndex(where: { $0.isToday }) {
            gratitudeEntries[index] = entry
        } else {
            gratitudeEntries.insert(entry, at: 0)
        }
        save(gratitudeEntries, key: Keys.gratitudeEntries)
    }
    
    func updateGratitudeEntry(_ entry: GratitudeEntry) {
        if let index = gratitudeEntries.firstIndex(where: { $0.id == entry.id }) {
            gratitudeEntries[index] = entry
            save(gratitudeEntries, key: Keys.gratitudeEntries)
        }
    }
    
    func addGratitudeItem(_ text: String, category: GratitudeCategory = .general) {
        var entry = getTodayGratitude() ?? GratitudeEntry()
        entry.addItem(text, category: category)
        addGratitudeEntry(entry)
    }
    
    func getWeeklyGratitudeSummary() -> WeeklyGratitudeSummary {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekStart = calendar.date(byAdding: .day, value: -6, to: today) ?? today
        
        let weekEntries = gratitudeEntries.filter { entry in
            entry.date >= weekStart && entry.date <= today
        }
        
        return WeeklyGratitudeSummary(weekStartDate: weekStart, entries: weekEntries)
    }
    
    var gratitudeStreak: Int {
        var streak = 0
        let calendar = Calendar.current
        var checkDate = calendar.startOfDay(for: Date())
        
        // Check if today has an entry first
        let todayEntry = gratitudeEntries.first { calendar.isDate($0.date, inSameDayAs: checkDate) }
        if todayEntry == nil {
            // Check yesterday instead
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }
        
        while true {
            let hasEntry = gratitudeEntries.contains { calendar.isDate($0.date, inSameDayAs: checkDate) }
            if hasEntry {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else {
                break
            }
        }
        
        return streak
    }
    
    // MARK: - Mood Entries
    
    func getTodayMood() -> MoodEntry? {
        moodEntries.first { $0.isToday }
    }
    
    func addMoodEntry(_ entry: MoodEntry) {
        // Replace if one exists for today
        if let index = moodEntries.firstIndex(where: { $0.isToday }) {
            moodEntries[index] = entry
        } else {
            moodEntries.insert(entry, at: 0)
        }
        save(moodEntries, key: Keys.moodEntries)
    }
    
    func getWeeklyMoodSummary() -> WeeklyMoodSummary {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekStart = calendar.date(byAdding: .day, value: -6, to: today) ?? today
        
        let weekEntries = moodEntries.filter { entry in
            entry.date >= weekStart && entry.date <= today
        }
        
        return WeeklyMoodSummary(weekStartDate: weekStart, entries: weekEntries)
    }
    
    // MARK: - Reading Plan Progress
    
    func startReadingPlan(_ plan: ReadingPlan) {
        let progress = ReadingPlanProgress(planId: plan.id, planName: plan.name)
        readingPlanProgress.append(progress)
        activeReadingPlanId = plan.id
        
        save(readingPlanProgress, key: Keys.readingPlanProgress)
        defaults.set(plan.id.uuidString, forKey: Keys.activeReadingPlanId)
    }
    
    func getActiveProgress() -> ReadingPlanProgress? {
        guard let activeId = activeReadingPlanId else { return nil }
        return readingPlanProgress.first { $0.planId == activeId }
    }
    
    func getProgress(for planId: UUID) -> ReadingPlanProgress? {
        readingPlanProgress.first { $0.planId == planId }
    }
    
    func completeReadingDay(planId: UUID, day: Int, totalDays: Int) {
        if let index = readingPlanProgress.firstIndex(where: { $0.planId == planId }) {
            readingPlanProgress[index].completeDay(day, totalDays: totalDays)
            save(readingPlanProgress, key: Keys.readingPlanProgress)
        }
    }
    
    func addReadingNote(planId: UUID, day: Int, note: String) {
        if let index = readingPlanProgress.firstIndex(where: { $0.planId == planId }) {
            readingPlanProgress[index].notes[day] = note
            save(readingPlanProgress, key: Keys.readingPlanProgress)
        }
    }
    
    func setActiveReadingPlan(_ planId: UUID?) {
        activeReadingPlanId = planId
        if let id = planId {
            defaults.set(id.uuidString, forKey: Keys.activeReadingPlanId)
        } else {
            defaults.removeObject(forKey: Keys.activeReadingPlanId)
        }
    }
    
    // MARK: - Routines
    
    func getLastMorningRoutineDate() -> Date? {
        guard let timestamp = defaults.object(forKey: Keys.lastMorningRoutine) as? Double else { return nil }
        return Date(timeIntervalSince1970: timestamp)
    }
    
    func recordMorningRoutine() {
        defaults.set(Date().timeIntervalSince1970, forKey: Keys.lastMorningRoutine)
    }
    
    func getLastNightRoutineDate() -> Date? {
        guard let timestamp = defaults.object(forKey: Keys.lastNightRoutine) as? Double else { return nil }
        return Date(timeIntervalSince1970: timestamp)
    }
    
    func recordNightRoutine() {
        defaults.set(Date().timeIntervalSince1970, forKey: Keys.lastNightRoutine)
    }
    
    var didCompleteMorningRoutineToday: Bool {
        guard let lastDate = getLastMorningRoutineDate() else { return false }
        return Calendar.current.isDateInToday(lastDate)
    }
    
    var didCompleteNightRoutineToday: Bool {
        guard let lastDate = getLastNightRoutineDate() else { return false }
        return Calendar.current.isDateInToday(lastDate)
    }
    
    // MARK: - Daily Intention
    
    func setDailyIntention(_ intention: String) {
        let today = Calendar.current.startOfDay(for: Date())
        let data: [String: Any] = [
            "intention": intention,
            "date": today.timeIntervalSince1970
        ]
        defaults.set(data, forKey: Keys.dailyIntention)
    }
    
    func getTodayIntention() -> String? {
        guard let data = defaults.dictionary(forKey: Keys.dailyIntention),
              let intention = data["intention"] as? String,
              let timestamp = data["date"] as? Double else { return nil }
        
        let date = Date(timeIntervalSince1970: timestamp)
        guard Calendar.current.isDateInToday(date) else { return nil }
        return intention
    }
    
    // MARK: - Weekly Stats
    
    func getWeeklyStats() -> WeeklyStats {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekStart = calendar.date(byAdding: .day, value: -6, to: today) ?? today
        
        // Prayer stats
        let prayersThisWeek = prayerEntries.filter { $0.dateCreated >= weekStart }.count
        let answeredThisWeek = prayerEntries.filter { 
            $0.isAnswered && ($0.answeredDate ?? Date.distantPast) >= weekStart 
        }.count
        
        // Habit stats
        let habitDaysCompleted = Set(habitEntries
            .filter { $0.date >= weekStart && $0.isCompleted }
            .map { calendar.startOfDay(for: $0.date) }
        ).count
        
        // Gratitude stats
        let gratitudeDays = gratitudeEntries.filter { $0.date >= weekStart }.count
        let totalGratitudeItems = gratitudeEntries
            .filter { $0.date >= weekStart }
            .reduce(0) { $0 + $1.items.count }
        
        // Reading stats
        var readingDaysCompleted = 0
        if let progress = getActiveProgress() {
            readingDaysCompleted = progress.completedDays
                .filter { day in
                    // This is simplified - in real app you'd track actual dates
                    day > 0
                }.count
        }
        
        // Mood stats
        let moodSummary = getWeeklyMoodSummary()
        
        // Phase 2 stats
        let fastsThisWeek = fastingEntries.filter { 
            $0.status == .completed && ($0.actualEndDate ?? Date.distantPast) >= weekStart 
        }.count
        
        let missionsThisWeek = missionCompletions.filter { $0.completedAt >= weekStart }.count
        
        var devotionalDays = 0
        if let progress = getActiveDevotionalProgress() {
            devotionalDays = progress.completedDays.count
        }
        
        let versesMemorizedThisWeek = memorizedVerses.filter { 
            $0.mastered && $0.lastPracticed >= weekStart 
        }.count
        
        return WeeklyStats(
            weekStartDate: weekStart,
            prayersWritten: prayersThisWeek,
            prayersAnswered: answeredThisWeek,
            guidedSessionsCompleted: guidedSessionsThisWeek,
            habitDaysCompleted: habitDaysCompleted,
            gratitudeDaysCompleted: gratitudeDays,
            gratitudeItemsWritten: totalGratitudeItems,
            readingDaysCompleted: readingDaysCompleted,
            averageMood: moodSummary.averageMood,
            morningRoutinesCompleted: didCompleteMorningRoutineToday ? 1 : 0,
            nightRoutinesCompleted: didCompleteNightRoutineToday ? 1 : 0,
            fastsCompleted: fastsThisWeek,
            missionsCompleted: missionsThisWeek,
            devotionalDaysCompleted: devotionalDays,
            versesMemorized: versesMemorizedThisWeek
        )
    }
    
    // MARK: - Fasting Entries
    
    private func checkActiveFastStatus() {
        guard let activeId = activeFastingId,
              let index = fastingEntries.firstIndex(where: { $0.id == activeId }) else { return }
        
        if fastingEntries[index].shouldAutoComplete {
            fastingEntries[index].complete()
            activeFastingId = nil
            save(fastingEntries, key: Keys.fastingEntries)
            defaults.removeObject(forKey: Keys.activeFastingId)
        }
    }
    
    func startFast(_ entry: FastingEntry) {
        var newEntry = entry
        newEntry.status = .active
        fastingEntries.insert(newEntry, at: 0)
        activeFastingId = newEntry.id
        save(fastingEntries, key: Keys.fastingEntries)
        defaults.set(newEntry.id.uuidString, forKey: Keys.activeFastingId)
    }
    
    func completeFast(reflection: String? = nil, insights: String? = nil) {
        guard let activeId = activeFastingId,
              let index = fastingEntries.firstIndex(where: { $0.id == activeId }) else { return }
        
        fastingEntries[index].complete(reflection: reflection, insights: insights)
        activeFastingId = nil
        save(fastingEntries, key: Keys.fastingEntries)
        defaults.removeObject(forKey: Keys.activeFastingId)
    }
    
    func endFastEarly(reflection: String? = nil) {
        guard let activeId = activeFastingId,
              let index = fastingEntries.firstIndex(where: { $0.id == activeId }) else { return }
        
        fastingEntries[index].endEarly(reflection: reflection)
        activeFastingId = nil
        save(fastingEntries, key: Keys.fastingEntries)
        defaults.removeObject(forKey: Keys.activeFastingId)
    }
    
    func getActiveFast() -> FastingEntry? {
        guard let activeId = activeFastingId else { return nil }
        return fastingEntries.first { $0.id == activeId }
    }
    
    func deleteFastingEntry(_ entry: FastingEntry) {
        fastingEntries.removeAll { $0.id == entry.id }
        if activeFastingId == entry.id {
            activeFastingId = nil
            defaults.removeObject(forKey: Keys.activeFastingId)
        }
        save(fastingEntries, key: Keys.fastingEntries)
    }
    
    func getFastingStats() -> FastingStats {
        let completed = fastingEntries.filter { $0.status == .completed }
        let totalHours = completed.reduce(0) { $0 + ($1.actualDurationHours ?? 0) }
        let longest = completed.map { $0.actualDurationHours ?? 0 }.max() ?? 0
        
        let typeCounts = Dictionary(grouping: completed, by: { $0.type }).mapValues { $0.count }
        let mostCommon = typeCounts.max(by: { $0.value < $1.value })?.key
        
        return FastingStats(
            totalFasts: fastingEntries.count,
            completedFasts: completed.count,
            totalHoursFasted: totalHours,
            longestFast: longest,
            currentStreak: calculateFastingStreak(),
            mostCommonType: mostCommon
        )
    }
    
    private func calculateFastingStreak() -> Int {
        // Simple streak: count consecutive weeks with a completed fast
        var streak = 0
        let calendar = Calendar.current
        var checkDate = Date()
        
        for _ in 0..<52 {
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: checkDate))!
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!
            
            let hasCompletedFast = fastingEntries.contains { entry in
                entry.status == .completed &&
                entry.startDate >= weekStart &&
                entry.startDate < weekEnd
            }
            
            if hasCompletedFast {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -7, to: checkDate)!
            } else {
                break
            }
        }
        
        return streak
    }
    
    // MARK: - Prayer Library
    
    func addSavedPrayer(_ prayer: SavedPrayer) {
        savedPrayers.insert(prayer, at: 0)
        save(savedPrayers, key: Keys.savedPrayers)
    }
    
    func updateSavedPrayer(_ prayer: SavedPrayer) {
        if let index = savedPrayers.firstIndex(where: { $0.id == prayer.id }) {
            savedPrayers[index] = prayer
            save(savedPrayers, key: Keys.savedPrayers)
        }
    }
    
    func deleteSavedPrayer(_ prayer: SavedPrayer) {
        savedPrayers.removeAll { $0.id == prayer.id }
        // Also remove from collections
        for i in 0..<prayerCollections.count {
            prayerCollections[i].removePrayer(prayer.id)
        }
        save(savedPrayers, key: Keys.savedPrayers)
        save(prayerCollections, key: Keys.prayerCollections)
    }
    
    func togglePrayerFavorite(_ prayer: SavedPrayer) {
        if let index = savedPrayers.firstIndex(where: { $0.id == prayer.id }) {
            savedPrayers[index].toggleFavorite()
            save(savedPrayers, key: Keys.savedPrayers)
        }
    }
    
    func recordPrayerUsage(_ prayer: SavedPrayer) {
        if let index = savedPrayers.firstIndex(where: { $0.id == prayer.id }) {
            savedPrayers[index].recordUsage()
            save(savedPrayers, key: Keys.savedPrayers)
        }
    }
    
    var favoritePrayers: [SavedPrayer] {
        savedPrayers.filter { $0.isFavorite }
    }
    
    func searchPrayers(query: String) -> [SavedPrayer] {
        let lowercased = query.lowercased()
        return savedPrayers.filter {
            $0.title.lowercased().contains(lowercased) ||
            $0.content.lowercased().contains(lowercased) ||
            $0.tags.contains { $0.lowercased().contains(lowercased) }
        }
    }
    
    // MARK: - Prayer Collections
    
    func createCollection(_ collection: PrayerCollection) {
        prayerCollections.append(collection)
        save(prayerCollections, key: Keys.prayerCollections)
    }
    
    func updateCollection(_ collection: PrayerCollection) {
        if let index = prayerCollections.firstIndex(where: { $0.id == collection.id }) {
            prayerCollections[index] = collection
            save(prayerCollections, key: Keys.prayerCollections)
        }
    }
    
    func deleteCollection(_ collection: PrayerCollection) {
        prayerCollections.removeAll { $0.id == collection.id }
        save(prayerCollections, key: Keys.prayerCollections)
    }
    
    func addPrayerToCollection(_ prayerId: UUID, collectionId: UUID) {
        if let index = prayerCollections.firstIndex(where: { $0.id == collectionId }) {
            prayerCollections[index].addPrayer(prayerId)
            save(prayerCollections, key: Keys.prayerCollections)
        }
    }
    
    func removePrayerFromCollection(_ prayerId: UUID, collectionId: UUID) {
        if let index = prayerCollections.firstIndex(where: { $0.id == collectionId }) {
            prayerCollections[index].removePrayer(prayerId)
            save(prayerCollections, key: Keys.prayerCollections)
        }
    }
    
    func getPrayersInCollection(_ collectionId: UUID) -> [SavedPrayer] {
        guard let collection = prayerCollections.first(where: { $0.id == collectionId }) else { return [] }
        return savedPrayers.filter { collection.prayerIds.contains($0.id) }
    }
    
    // MARK: - Scripture Prayers
    
    func addScripturePrayer(_ prayer: ScripturePrayer) {
        scripturePrayers.insert(prayer, at: 0)
        save(scripturePrayers, key: Keys.scripturePrayers)
    }
    
    func saveScripturePrayerToLibrary(_ prayer: ScripturePrayer, title: String? = nil) {
        let savedPrayer = SavedPrayer(from: prayer, title: title)
        addSavedPrayer(savedPrayer)
    }
    
    // MARK: - Missions
    
    func completeMission(_ mission: Mission, reflection: String? = nil, notes: String? = nil) {
        let completion = MissionCompletion(
            missionId: mission.id,
            missionTitle: mission.title,
            reflection: reflection,
            experienceNotes: notes
        )
        missionCompletions.insert(completion, at: 0)
        save(missionCompletions, key: Keys.missionCompletions)
    }
    
    func isMissionCompletedToday(_ missionId: UUID) -> Bool {
        missionCompletions.contains { completion in
            completion.missionId == missionId &&
            Calendar.current.isDateInToday(completion.completedAt)
        }
    }
    
    func getMissionsCompletedThisWeek() -> [MissionCompletion] {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return missionCompletions.filter { $0.completedAt >= weekAgo }
    }
    
    var totalMissionsCompleted: Int {
        missionCompletions.count
    }
    
    // MARK: - Devotionals
    
    func startDevotional(_ series: DevotionalSeries) {
        let progress = DevotionalProgress(seriesId: series.id, seriesTitle: series.title)
        devotionalProgress.append(progress)
        activeDevotionalId = series.id
        save(devotionalProgress, key: Keys.devotionalProgress)
        defaults.set(series.id.uuidString, forKey: Keys.activeDevotionalId)
    }
    
    func getActiveDevotionalProgress() -> DevotionalProgress? {
        guard let activeId = activeDevotionalId else { return nil }
        return devotionalProgress.first { $0.seriesId == activeId }
    }
    
    func completeDevotionalDay(seriesId: UUID, day: Int, totalDays: Int) {
        if let index = devotionalProgress.firstIndex(where: { $0.seriesId == seriesId }) {
            devotionalProgress[index].completeDay(day, totalDays: totalDays)
            save(devotionalProgress, key: Keys.devotionalProgress)
        }
    }
    
    func addDevotionalNote(seriesId: UUID, day: Int, note: String) {
        if let index = devotionalProgress.firstIndex(where: { $0.seriesId == seriesId }) {
            devotionalProgress[index].notes[day] = note
            save(devotionalProgress, key: Keys.devotionalProgress)
        }
    }
    
    func setActiveDevotional(_ seriesId: UUID?) {
        activeDevotionalId = seriesId
        if let id = seriesId {
            defaults.set(id.uuidString, forKey: Keys.activeDevotionalId)
        } else {
            defaults.removeObject(forKey: Keys.activeDevotionalId)
        }
    }
    
    // MARK: - Sermon Notes
    
    func addSermonNote(_ note: SermonNote) {
        sermonNotes.insert(note, at: 0)
        save(sermonNotes, key: Keys.sermonNotes)
    }
    
    func updateSermonNote(_ note: SermonNote) {
        if let index = sermonNotes.firstIndex(where: { $0.id == note.id }) {
            sermonNotes[index] = note
            save(sermonNotes, key: Keys.sermonNotes)
        }
    }
    
    func deleteSermonNote(_ note: SermonNote) {
        sermonNotes.removeAll { $0.id == note.id }
        save(sermonNotes, key: Keys.sermonNotes)
    }
    
    func searchSermonNotes(query: String) -> [SermonNote] {
        let lowercased = query.lowercased()
        return sermonNotes.filter {
            $0.title.lowercased().contains(lowercased) ||
            $0.speaker.lowercased().contains(lowercased) ||
            $0.mainScripture.lowercased().contains(lowercased) ||
            $0.personalNotes.lowercased().contains(lowercased)
        }
    }
    
    // MARK: - Verse of Day
    
    func getTodayVerseEntry() -> VerseOfDayEntry? {
        verseOfDayEntries.first { $0.isToday }
    }
    
    func getOrCreateTodayVerse() -> VerseOfDayEntry {
        if let existing = getTodayVerseEntry() {
            return existing
        }
        
        let todaysVerse = VerseOfDayCollection.todaysVerse
        let newEntry = VerseOfDayEntry(
            verseReference: todaysVerse.reference,
            verseText: todaysVerse.text
        )
        verseOfDayEntries.insert(newEntry, at: 0)
        save(verseOfDayEntries, key: Keys.verseOfDayEntries)
        return newEntry
    }
    
    func updateVerseOfDayEntry(_ entry: VerseOfDayEntry) {
        if let index = verseOfDayEntries.firstIndex(where: { $0.id == entry.id }) {
            verseOfDayEntries[index] = entry
            save(verseOfDayEntries, key: Keys.verseOfDayEntries)
        }
    }
    
    func saveVerseOfDay(_ entry: VerseOfDayEntry) {
        if let index = verseOfDayEntries.firstIndex(where: { $0.id == entry.id }) {
            verseOfDayEntries[index].isSaved = true
            save(verseOfDayEntries, key: Keys.verseOfDayEntries)
        }
    }
    
    func addVerseReflection(_ entry: VerseOfDayEntry, reflection: String) {
        if let index = verseOfDayEntries.firstIndex(where: { $0.id == entry.id }) {
            verseOfDayEntries[index].addReflection(reflection)
            save(verseOfDayEntries, key: Keys.verseOfDayEntries)
        }
    }
    
    var savedVerses: [VerseOfDayEntry] {
        verseOfDayEntries.filter { $0.isSaved }
    }
    
    // MARK: - Memorization
    
    func startMemorization(verseReference: String, verseText: String) -> MemorizationSession {
        let session = MemorizationSession(verseReference: verseReference, verseText: verseText)
        memorizedVerses.append(session)
        save(memorizedVerses, key: Keys.memorizedVerses)
        return session
    }
    
    func recordMemorizationAttempt(sessionId: UUID, correct: Bool) {
        if let index = memorizedVerses.firstIndex(where: { $0.id == sessionId }) {
            memorizedVerses[index].recordAttempt(correct: correct)
            save(memorizedVerses, key: Keys.memorizedVerses)
        }
    }
    
    func getMemorizationSession(for verseReference: String) -> MemorizationSession? {
        memorizedVerses.first { $0.verseReference == verseReference }
    }
    
    var masteredVerses: [MemorizationSession] {
        memorizedVerses.filter { $0.mastered }
    }
    
    // MARK: - Clear Data
    
    func clearAllHubData() {
        prayerEntries = []
        guidedSessions = []
        habitEntries = []
        habitStreaks = initializeHabitStreaks()
        gratitudeEntries = []
        moodEntries = []
        readingPlanProgress = []
        activeReadingPlanId = nil
        trackedHabits = defaultTrackedHabits
        
        // Phase 2 data
        fastingEntries = []
        activeFastingId = nil
        savedPrayers = DefaultPrayer.allDefaults
        prayerCollections = []
        scripturePrayers = []
        missionCompletions = []
        devotionalProgress = []
        activeDevotionalId = nil
        sermonNotes = []
        verseOfDayEntries = []
        memorizedVerses = []
        
        defaults.removeObject(forKey: Keys.prayerEntries)
        defaults.removeObject(forKey: Keys.guidedPrayerSessions)
        defaults.removeObject(forKey: Keys.habitEntries)
        defaults.removeObject(forKey: Keys.habitStreaks)
        defaults.removeObject(forKey: Keys.gratitudeEntries)
        defaults.removeObject(forKey: Keys.moodEntries)
        defaults.removeObject(forKey: Keys.readingPlanProgress)
        defaults.removeObject(forKey: Keys.activeReadingPlanId)
        defaults.removeObject(forKey: Keys.lastMorningRoutine)
        defaults.removeObject(forKey: Keys.lastNightRoutine)
        defaults.removeObject(forKey: Keys.dailyIntention)
        defaults.removeObject(forKey: Keys.trackedHabits)
        
        // Phase 2 keys
        defaults.removeObject(forKey: Keys.fastingEntries)
        defaults.removeObject(forKey: Keys.activeFastingId)
        defaults.removeObject(forKey: Keys.savedPrayers)
        defaults.removeObject(forKey: Keys.prayerCollections)
        defaults.removeObject(forKey: Keys.scripturePrayers)
        defaults.removeObject(forKey: Keys.missionCompletions)
        defaults.removeObject(forKey: Keys.devotionalProgress)
        defaults.removeObject(forKey: Keys.activeDevotionalId)
        defaults.removeObject(forKey: Keys.sermonNotes)
        defaults.removeObject(forKey: Keys.verseOfDayEntries)
        defaults.removeObject(forKey: Keys.memorizedVerses)
    }
}

// MARK: - Weekly Stats Model

struct WeeklyStats {
    let weekStartDate: Date
    let prayersWritten: Int
    let prayersAnswered: Int
    let guidedSessionsCompleted: Int
    let habitDaysCompleted: Int
    let gratitudeDaysCompleted: Int
    let gratitudeItemsWritten: Int
    let readingDaysCompleted: Int
    let averageMood: Double
    let morningRoutinesCompleted: Int
    let nightRoutinesCompleted: Int
    // Phase 2 stats
    let fastsCompleted: Int
    let missionsCompleted: Int
    let devotionalDaysCompleted: Int
    let versesMemorized: Int
    
    init(
        weekStartDate: Date,
        prayersWritten: Int,
        prayersAnswered: Int,
        guidedSessionsCompleted: Int,
        habitDaysCompleted: Int,
        gratitudeDaysCompleted: Int,
        gratitudeItemsWritten: Int,
        readingDaysCompleted: Int,
        averageMood: Double,
        morningRoutinesCompleted: Int,
        nightRoutinesCompleted: Int,
        fastsCompleted: Int = 0,
        missionsCompleted: Int = 0,
        devotionalDaysCompleted: Int = 0,
        versesMemorized: Int = 0
    ) {
        self.weekStartDate = weekStartDate
        self.prayersWritten = prayersWritten
        self.prayersAnswered = prayersAnswered
        self.guidedSessionsCompleted = guidedSessionsCompleted
        self.habitDaysCompleted = habitDaysCompleted
        self.gratitudeDaysCompleted = gratitudeDaysCompleted
        self.gratitudeItemsWritten = gratitudeItemsWritten
        self.readingDaysCompleted = readingDaysCompleted
        self.averageMood = averageMood
        self.morningRoutinesCompleted = morningRoutinesCompleted
        self.nightRoutinesCompleted = nightRoutinesCompleted
        self.fastsCompleted = fastsCompleted
        self.missionsCompleted = missionsCompleted
        self.devotionalDaysCompleted = devotionalDaysCompleted
        self.versesMemorized = versesMemorized
    }
    
    var totalActivities: Int {
        prayersWritten + guidedSessionsCompleted + habitDaysCompleted + gratitudeDaysCompleted + readingDaysCompleted + missionsCompleted + devotionalDaysCompleted
    }
    
    var encouragingMessage: String {
        if totalActivities >= 20 {
            return "Amazing week! Your dedication to spiritual growth is inspiring."
        } else if totalActivities >= 10 {
            return "Great progress this week! Keep building those spiritual habits."
        } else if totalActivities >= 5 {
            return "Good start! Every step toward God matters."
        } else {
            return "A new week is a fresh opportunity. God's mercies are new every morning!"
        }
    }
}

