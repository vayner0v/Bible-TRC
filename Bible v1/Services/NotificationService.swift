//
//  NotificationService.swift
//  Bible v1
//
//  Spiritual Hub - Notification Service for Prayer Reminders
//

import Foundation
import UserNotifications
import SwiftUI
import Combine

/// Manages local notifications for prayer schedules and reminders
class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()
    
    @Published private(set) var isAuthorized = false
    @Published private(set) var pendingNotifications: [UNNotificationRequest] = []
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private let defaults = UserDefaults.standard
    private var cancellables = Set<AnyCancellable>()
    
    // Keys
    private enum Keys {
        static let prayerSchedules = "notification_prayer_schedules"
        static let preferences = "notification_preferences"
        static let engagementData = "notification_engagement_data"
        static let journalReminderEnabled = "journal_reminder_enabled"
        static let journalReminderTime = "journal_reminder_time"
        static let journalReminderDays = "journal_reminder_days"
    }
    
    @Published var prayerSchedules: [PrayerSchedule] = []
    @Published var preferences: NotificationPreferences = NotificationPreferences()
    @Published var engagementData: UserEngagementData = UserEngagementData()
    
    // Journal reminder properties
    @Published var journalReminderEnabled: Bool = false
    @Published var journalReminderTime: Date = Calendar.current.date(from: DateComponents(hour: 20, minute: 0)) ?? Date()
    @Published var journalReminderDays: Set<Weekday> = Set(Weekday.allCases)
    
    override init() {
        super.init()
        notificationCenter.delegate = self
        loadData()
        checkAuthorization()
        setupAutoSave()
    }
    
    /// Set up automatic saving and scheduling when preferences change
    private func setupAutoSave() {
        // Automatically save preferences and update scheduled notifications
        // Uses debounce to avoid excessive updates during rapid toggle changes
        $preferences
            .dropFirst() // Skip the initial value
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] newPreferences in
                self?.savePreferences()
                // Schedule or cancel notifications based on new preferences
                self?.updateScheduledNotifications(for: newPreferences)
            }
            .store(in: &cancellables)
    }
    
    /// Update scheduled notifications based on preference changes
    private func updateScheduledNotifications(for preferences: NotificationPreferences) {
        guard preferences.isEnabled else {
            // Cancel all scheduled notifications if master toggle is off
            cancelAllScheduledNotifications()
            return
        }
        
        // Schedule notifications for enabled types
        scheduleEnabledNotifications(preferences: preferences)
    }
    
    /// Cancel all app-scheduled notifications
    private func cancelAllScheduledNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        refreshPendingNotifications()
    }
    
    /// Schedule notifications for all enabled notification types
    private func scheduleEnabledNotifications(preferences: NotificationPreferences) {
        // Verse of the Day - 8 AM daily
        if preferences.verseOfDayEnabled {
            scheduleRepeatingNotification(
                id: "verse_of_day",
                title: "Verse of the Day",
                body: "Start your day with God's Word",
                hour: 8,
                minute: 0,
                categoryId: "VERSE_OF_DAY"
            )
        } else {
            cancelNotification(withId: "verse_of_day")
        }
        
        // Reading plan reminder - 9 AM daily
        if preferences.readingPlanRemindersEnabled {
            scheduleRepeatingNotification(
                id: "reading_plan",
                title: "Daily Reading",
                body: "Continue your reading plan today",
                hour: 9,
                minute: 0,
                categoryId: "READING_PLAN"
            )
        } else {
            cancelNotification(withId: "reading_plan")
        }
        
        // Habit reminders - 10 AM daily
        if preferences.habitRemindersEnabled {
            scheduleRepeatingNotification(
                id: "habit_reminder",
                title: "Habit Check-in",
                body: "How are your spiritual habits going?",
                hour: 10,
                minute: 0,
                categoryId: "HABIT_REMINDER"
            )
        } else {
            cancelNotification(withId: "habit_reminder")
        }
        
        // Encouragement - 2 PM daily
        if preferences.encouragementEnabled {
            let encouragements = [
                "God is with you today!",
                "You are loved beyond measure",
                "Trust in the Lord with all your heart",
                "His grace is sufficient for you",
                "Take heart, for He has overcome the world"
            ]
            scheduleRepeatingNotification(
                id: "encouragement",
                title: "Daily Encouragement",
                body: encouragements.randomElement() ?? "God loves you!",
                hour: 14,
                minute: 0,
                categoryId: "ENCOURAGEMENT"
            )
        } else {
            cancelNotification(withId: "encouragement")
        }
        
        // Weekly recap - Sunday at 7 PM
        if preferences.weeklyRecapEnabled {
            scheduleWeeklyNotification(
                id: "weekly_recap",
                title: "Weekly Recap",
                body: "See how you grew spiritually this week",
                weekday: 1, // Sunday
                hour: 19,
                minute: 0
            )
        } else {
            cancelNotification(withId: "weekly_recap")
        }
        
        refreshPendingNotifications()
    }
    
    /// Schedule a repeating daily notification
    private func scheduleRepeatingNotification(id: String, title: String, body: String, hour: Int, minute: Int, categoryId: String) {
        // Check quiet hours
        if preferences.quietHoursEnabled {
            let start = preferences.quietHoursStart
            let end = preferences.quietHoursEnd
            
            if isHourInQuietPeriod(hour: hour, start: start, end: end) {
                return // Don't schedule during quiet hours
            }
        }
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = categoryId
        content.userInfo = ["type": id]
        
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling notification \(id): \(error)")
            }
        }
    }
    
    /// Schedule a weekly notification
    private func scheduleWeeklyNotification(id: String, title: String, body: String, weekday: Int, hour: Int, minute: Int) {
        var dateComponents = DateComponents()
        dateComponents.weekday = weekday
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = ["type": id]
        
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling weekly notification \(id): \(error)")
            }
        }
    }
    
    /// Cancel a notification with specific ID
    private func cancelNotification(withId id: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [id])
    }
    
    /// Check if an hour falls within quiet period
    private func isHourInQuietPeriod(hour: Int, start: Int, end: Int) -> Bool {
        if start <= end {
            return hour >= start && hour < end
        } else {
            // Quiet period crosses midnight
            return hour >= start || hour < end
        }
    }
    
    // MARK: - Authorization
    
    /// Request notification authorization
    func requestAuthorization() async -> Bool {
        do {
            let options: UNAuthorizationOptions = [.alert, .sound, .badge]
            let granted = try await notificationCenter.requestAuthorization(options: options)
            
            await MainActor.run {
                self.isAuthorized = granted
            }
            
            return granted
        } catch {
            print("Notification authorization error: \(error)")
            return false
        }
    }
    
    /// Check current authorization status
    func checkAuthorization() {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Prayer Schedules
    
    /// Add a new prayer schedule
    func addSchedule(_ schedule: PrayerSchedule) {
        prayerSchedules.append(schedule)
        saveSchedules()
        
        if schedule.isEnabled {
            scheduleNotification(for: schedule)
        }
    }
    
    /// Update an existing schedule
    func updateSchedule(_ schedule: PrayerSchedule) {
        if let index = prayerSchedules.firstIndex(where: { $0.id == schedule.id }) {
            // Cancel old notifications
            cancelNotification(for: prayerSchedules[index])
            
            prayerSchedules[index] = schedule
            saveSchedules()
            
            // Schedule new if enabled
            if schedule.isEnabled {
                scheduleNotification(for: schedule)
            }
        }
    }
    
    /// Delete a schedule
    func deleteSchedule(id: UUID) {
        if let schedule = prayerSchedules.first(where: { $0.id == id }) {
            cancelNotification(for: schedule)
        }
        prayerSchedules.removeAll { $0.id == id }
        saveSchedules()
    }
    
    /// Toggle schedule enabled state
    func toggleSchedule(id: UUID) {
        if let index = prayerSchedules.firstIndex(where: { $0.id == id }) {
            prayerSchedules[index].isEnabled.toggle()
            
            if prayerSchedules[index].isEnabled {
                scheduleNotification(for: prayerSchedules[index])
            } else {
                cancelNotification(for: prayerSchedules[index])
            }
            
            saveSchedules()
        }
    }
    
    /// Mark schedule as completed
    func completeSchedule(id: UUID) {
        if let index = prayerSchedules.firstIndex(where: { $0.id == id }) {
            prayerSchedules[index].markCompleted()
            saveSchedules()
            
            // Record engagement
            recordEngagement(
                type: .prayerReminder,
                wasOpened: true,
                wasActedOn: true,
                wasSnoozed: false
            )
        }
    }
    
    /// Snooze a schedule
    func snoozeSchedule(id: UUID, minutes: Int = 10) {
        if let index = prayerSchedules.firstIndex(where: { $0.id == id }) {
            prayerSchedules[index].snooze()
            saveSchedules()
            
            // Schedule snooze notification
            let snoozeDate = Date().addingTimeInterval(TimeInterval(minutes * 60))
            scheduleOneTimeNotification(
                for: prayerSchedules[index],
                at: snoozeDate,
                isSnooze: true
            )
            
            // Record engagement
            recordEngagement(
                type: .prayerReminder,
                wasOpened: true,
                wasActedOn: false,
                wasSnoozed: true
            )
        }
    }
    
    // MARK: - Notification Scheduling
    
    /// Schedule recurring notification for a prayer schedule
    private func scheduleNotification(for schedule: PrayerSchedule) {
        guard schedule.isEnabled else { return }
        
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: schedule.time)
        
        // Create notification for each repeat day
        for weekday in schedule.repeatWeekdays {
            var dateComponents = DateComponents()
            dateComponents.weekday = weekday.rawValue
            dateComponents.hour = timeComponents.hour
            dateComponents.minute = timeComponents.minute
            
            // Apply reminder offset
            if schedule.reminderOffset != .none {
                if let minute = dateComponents.minute {
                    var newMinute = minute - schedule.reminderOffset.rawValue
                    if newMinute < 0 {
                        newMinute += 60
                        dateComponents.hour = (dateComponents.hour ?? 0) - 1
                        if dateComponents.hour ?? 0 < 0 {
                            dateComponents.hour = 23
                        }
                    }
                    dateComponents.minute = newMinute
                }
            }
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            
            let content = UNMutableNotificationContent()
            content.title = schedule.name
            content.body = getNotificationBody(for: schedule)
            content.sound = .default
            content.categoryIdentifier = "PRAYER_REMINDER"
            content.userInfo = [
                "scheduleId": schedule.id.uuidString,
                "type": "prayer_reminder"
            ]
            
            let identifier = "\(schedule.id.uuidString)_\(weekday.rawValue)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            notificationCenter.add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error)")
                }
            }
        }
        
        refreshPendingNotifications()
    }
    
    /// Schedule one-time notification (for snooze)
    private func scheduleOneTimeNotification(for schedule: PrayerSchedule, at date: Date, isSnooze: Bool) {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        let content = UNMutableNotificationContent()
        content.title = isSnooze ? "⏰ \(schedule.name)" : schedule.name
        content.body = isSnooze ? "Your snoozed prayer time is here" : getNotificationBody(for: schedule)
        content.sound = .default
        content.categoryIdentifier = "PRAYER_REMINDER"
        content.userInfo = [
            "scheduleId": schedule.id.uuidString,
            "type": "prayer_reminder",
            "isSnooze": isSnooze
        ]
        
        let identifier = "\(schedule.id.uuidString)_snooze_\(date.timeIntervalSince1970)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        notificationCenter.add(request)
    }
    
    /// Cancel notification for a schedule
    private func cancelNotification(for schedule: PrayerSchedule) {
        // Cancel all notifications for this schedule
        let identifiers = (1...7).map { "\(schedule.id.uuidString)_\($0)" }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
        refreshPendingNotifications()
    }
    
    /// Get notification body text
    private func getNotificationBody(for schedule: PrayerSchedule) -> String {
        switch schedule.prayerType {
        case .guided:
            return "Time for \(schedule.duration) minutes of guided prayer"
        case .free:
            return "Take a moment to connect with God"
        case .scriptureBased:
            return "Pray through Scripture today"
        case .gratitude:
            return "Count your blessings in prayer"
        case .intercession:
            return "Lift others up in prayer"
        case .meditation:
            return "Be still and know that He is God"
        }
    }
    
    /// Refresh list of pending notifications
    func refreshPendingNotifications() {
        notificationCenter.getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                self.pendingNotifications = requests
            }
        }
    }
    
    // MARK: - Engagement Tracking
    
    /// Record a notification engagement
    func recordEngagement(
        type: NotificationType,
        wasOpened: Bool,
        wasActedOn: Bool,
        wasSnoozed: Bool,
        responseDelay: TimeInterval? = nil
    ) {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        let day = calendar.component(.weekday, from: Date())
        
        let response = NotificationResponse(
            notificationType: type,
            scheduledHour: hour,
            scheduledDay: day,
            wasOpened: wasOpened,
            responseDelay: responseDelay,
            wasActedOn: wasActedOn,
            wasSnoozed: wasSnoozed,
            wasDismissed: !wasOpened && !wasSnoozed
        )
        
        engagementData.recordResponse(response)
        
        // Analyze patterns if we have enough data
        if engagementData.notificationResponses.count % 10 == 0 {
            engagementData.analyzePatterns()
        }
        
        saveEngagementData()
    }
    
    // MARK: - Adaptive Suggestions
    
    /// Get suggested time based on user patterns
    func getSuggestedTime(for hour: Int, isMorning: Bool) -> Int? {
        guard preferences.adaptiveTimingEnabled else { return nil }
        return engagementData.suggestBetterTime(for: hour, isMorning: isMorning)
    }
    
    /// Check if we should suggest changing notification time
    func shouldSuggestTimeChange(for schedule: PrayerSchedule) -> Bool {
        guard preferences.adaptiveTimingEnabled else { return false }
        
        let hour = Calendar.current.component(.hour, from: schedule.time)
        return engagementData.isLowEngagementHour(hour)
    }
    
    // MARK: - Persistence
    
    private func loadData() {
        // Load schedules
        if let data = defaults.data(forKey: Keys.prayerSchedules),
           let schedules = try? JSONDecoder().decode([PrayerSchedule].self, from: data) {
            prayerSchedules = schedules
        }
        
        // Load preferences
        if let data = defaults.data(forKey: Keys.preferences),
           let prefs = try? JSONDecoder().decode(NotificationPreferences.self, from: data) {
            preferences = prefs
        }
        
        // Load engagement data
        if let data = defaults.data(forKey: Keys.engagementData),
           let engagement = try? JSONDecoder().decode(UserEngagementData.self, from: data) {
            engagementData = engagement
        }
        
        // Load journal reminder settings
        journalReminderEnabled = defaults.bool(forKey: Keys.journalReminderEnabled)
        if let timeInterval = defaults.object(forKey: Keys.journalReminderTime) as? TimeInterval {
            journalReminderTime = Date(timeIntervalSince1970: timeInterval)
        }
        if let daysData = defaults.data(forKey: Keys.journalReminderDays),
           let days = try? JSONDecoder().decode(Set<Weekday>.self, from: daysData) {
            journalReminderDays = days
        }
    }
    
    private func saveSchedules() {
        if let encoded = try? JSONEncoder().encode(prayerSchedules) {
            defaults.set(encoded, forKey: Keys.prayerSchedules)
        }
    }
    
    func savePreferences() {
        if let encoded = try? JSONEncoder().encode(preferences) {
            defaults.set(encoded, forKey: Keys.preferences)
        }
    }
    
    private func saveEngagementData() {
        if let encoded = try? JSONEncoder().encode(engagementData) {
            defaults.set(encoded, forKey: Keys.engagementData)
        }
    }
    
    // MARK: - Journal Reminders
    
    /// Save journal reminder settings
    func saveJournalReminderSettings() {
        defaults.set(journalReminderEnabled, forKey: Keys.journalReminderEnabled)
        defaults.set(journalReminderTime.timeIntervalSince1970, forKey: Keys.journalReminderTime)
        if let daysData = try? JSONEncoder().encode(journalReminderDays) {
            defaults.set(daysData, forKey: Keys.journalReminderDays)
        }
        
        // Update notifications
        if journalReminderEnabled {
            scheduleJournalReminders()
        } else {
            cancelJournalReminders()
        }
    }
    
    /// Schedule journal reminder notifications
    func scheduleJournalReminders() {
        // Cancel existing journal reminders first
        cancelJournalReminders()
        
        guard journalReminderEnabled else { return }
        
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: journalReminderTime)
        
        for weekday in journalReminderDays {
            var dateComponents = DateComponents()
            dateComponents.weekday = weekday.rawValue
            dateComponents.hour = timeComponents.hour
            dateComponents.minute = timeComponents.minute
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            
            let content = UNMutableNotificationContent()
            content.title = "Time to Journal ✍️"
            content.body = getJournalReminderBody()
            content.sound = .default
            content.categoryIdentifier = "JOURNAL_REMINDER"
            content.userInfo = ["type": "journal_reminder"]
            
            let identifier = "journal_reminder_\(weekday.rawValue)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            notificationCenter.add(request) { error in
                if let error = error {
                    print("Error scheduling journal reminder: \(error)")
                }
            }
        }
        
        refreshPendingNotifications()
    }
    
    /// Cancel all journal reminder notifications
    func cancelJournalReminders() {
        let identifiers = Weekday.allCases.map { "journal_reminder_\($0.rawValue)" }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
        refreshPendingNotifications()
    }
    
    /// Toggle journal reminder on/off
    func toggleJournalReminder() {
        journalReminderEnabled.toggle()
        saveJournalReminderSettings()
    }
    
    /// Update journal reminder time
    func updateJournalReminderTime(_ time: Date) {
        journalReminderTime = time
        saveJournalReminderSettings()
    }
    
    /// Update journal reminder days
    func updateJournalReminderDays(_ days: Set<Weekday>) {
        journalReminderDays = days
        saveJournalReminderSettings()
    }
    
    /// Toggle a specific day for journal reminder
    func toggleJournalReminderDay(_ day: Weekday) {
        if journalReminderDays.contains(day) {
            journalReminderDays.remove(day)
        } else {
            journalReminderDays.insert(day)
        }
        saveJournalReminderSettings()
    }
    
    /// Get journal reminder notification body
    private func getJournalReminderBody() -> String {
        let prompts = [
            "Take a moment to reflect on your day.",
            "What are you grateful for today?",
            "How did you see God working in your life?",
            "Write down your thoughts and prayers.",
            "Capture your spiritual journey today.",
            "A few minutes of journaling can change your perspective."
        ]
        return prompts.randomElement() ?? "Take a moment to reflect on your day."
    }
    
    // MARK: - Notification Categories
    
    /// Setup notification categories and actions
    func setupNotificationCategories() {
        let prayAction = UNNotificationAction(
            identifier: "PRAY_NOW",
            title: "Pray Now",
            options: [.foreground]
        )
        
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE",
            title: "Snooze 10 min",
            options: []
        )
        
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS",
            title: "Dismiss",
            options: [.destructive]
        )
        
        let prayerCategory = UNNotificationCategory(
            identifier: "PRAYER_REMINDER",
            actions: [prayAction, snoozeAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Journal reminder category
        let journalAction = UNNotificationAction(
            identifier: "JOURNAL_NOW",
            title: "Open Journal",
            options: [.foreground]
        )
        
        let journalSnoozeAction = UNNotificationAction(
            identifier: "JOURNAL_SNOOZE",
            title: "Remind in 1 hour",
            options: []
        )
        
        let journalCategory = UNNotificationCategory(
            identifier: "JOURNAL_REMINDER",
            actions: [journalAction, journalSnoozeAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        notificationCenter.setNotificationCategories([prayerCategory, journalCategory])
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let notificationType = userInfo["type"] as? String
        
        // Handle journal reminders
        if notificationType == "journal_reminder" {
            switch response.actionIdentifier {
            case "JOURNAL_NOW", UNNotificationDefaultActionIdentifier:
                NotificationCenter.default.post(
                    name: .journalReminderTapped,
                    object: nil
                )
                recordEngagement(
                    type: .journalReminder,
                    wasOpened: true,
                    wasActedOn: true,
                    wasSnoozed: false
                )
                
            case "JOURNAL_SNOOZE":
                // Schedule a one-time reminder in 1 hour
                scheduleOneTimeJournalReminder(in: 60)
                recordEngagement(
                    type: .journalReminder,
                    wasOpened: true,
                    wasActedOn: false,
                    wasSnoozed: true
                )
                
            case "DISMISS", UNNotificationDismissActionIdentifier:
                recordEngagement(
                    type: .journalReminder,
                    wasOpened: false,
                    wasActedOn: false,
                    wasSnoozed: false
                )
                
            default:
                break
            }
            
            completionHandler()
            return
        }
        
        // Handle prayer reminders
        guard let scheduleIdString = userInfo["scheduleId"] as? String,
              let scheduleId = UUID(uuidString: scheduleIdString) else {
            completionHandler()
            return
        }
        
        switch response.actionIdentifier {
        case "PRAY_NOW", UNNotificationDefaultActionIdentifier:
            completeSchedule(id: scheduleId)
            // Post notification for UI to respond
            NotificationCenter.default.post(
                name: .prayerReminderTapped,
                object: nil,
                userInfo: ["scheduleId": scheduleId]
            )
            
        case "SNOOZE":
            snoozeSchedule(id: scheduleId)
            
        case "DISMISS", UNNotificationDismissActionIdentifier:
            recordEngagement(
                type: .prayerReminder,
                wasOpened: false,
                wasActedOn: false,
                wasSnoozed: false
            )
            
        default:
            break
        }
        
        completionHandler()
    }
    
    /// Schedule a one-time journal reminder
    private func scheduleOneTimeJournalReminder(in minutes: Int) {
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(minutes * 60), repeats: false)
        
        let content = UNMutableNotificationContent()
        content.title = "Time to Journal ✍️"
        content.body = "Your snoozed journal reminder is here."
        content.sound = .default
        content.categoryIdentifier = "JOURNAL_REMINDER"
        content.userInfo = ["type": "journal_reminder"]
        
        let identifier = "journal_reminder_snooze_\(Date().timeIntervalSince1970)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        notificationCenter.add(request)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let prayerReminderTapped = Notification.Name("prayerReminderTapped")
    static let journalReminderTapped = Notification.Name("journalReminderTapped")
}


