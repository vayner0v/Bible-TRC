//
//  GratitudeEntry.swift
//  Bible v1
//
//  Spiritual Hub - Gratitude Tracker Model
//

import Foundation

/// Represents a daily gratitude entry with up to 3 items
struct GratitudeEntry: Identifiable, Codable, Hashable {
    let id: UUID
    let date: Date
    var items: [GratitudeItem]
    var reflection: String?
    let createdAt: Date
    var modifiedAt: Date
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        items: [GratitudeItem] = [],
        reflection: String? = nil,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.items = items
        self.reflection = reflection
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
    
    /// Add a gratitude item (max 3)
    mutating func addItem(_ text: String, category: GratitudeCategory = .general) {
        guard items.count < 3 else { return }
        items.append(GratitudeItem(text: text, category: category))
        modifiedAt = Date()
    }
    
    /// Remove an item at index
    mutating func removeItem(at index: Int) {
        guard index < items.count else { return }
        items.remove(at: index)
        modifiedAt = Date()
    }
    
    /// Check if entry is for today
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    /// Check if entry is complete (has 3 items)
    var isComplete: Bool {
        items.count >= 3
    }
    
    /// Formatted date for display
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    /// Day of week for display
    var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
}

/// Individual gratitude item
struct GratitudeItem: Identifiable, Codable, Hashable {
    let id: UUID
    var text: String
    var category: GratitudeCategory
    let createdAt: Date
    
    init(
        id: UUID = UUID(),
        text: String,
        category: GratitudeCategory = .general,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.text = text
        self.category = category
        self.createdAt = createdAt
    }
}

/// Categories for gratitude items
enum GratitudeCategory: String, Codable, CaseIterable, Identifiable {
    case people = "People"
    case experiences = "Experiences"
    case blessings = "Blessings"
    case nature = "Nature"
    case health = "Health"
    case provision = "Provision"
    case spiritual = "Spiritual"
    case general = "General"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .people: return "person.2.fill"
        case .experiences: return "star.fill"
        case .blessings: return "gift.fill"
        case .nature: return "leaf.fill"
        case .health: return "heart.fill"
        case .provision: return "house.fill"
        case .spiritual: return "sparkles"
        case .general: return "heart.circle"
        }
    }
}

/// Weekly gratitude summary for look-back feature
struct WeeklyGratitudeSummary: Identifiable {
    let id: UUID
    let weekStartDate: Date
    let entries: [GratitudeEntry]
    
    init(
        id: UUID = UUID(),
        weekStartDate: Date,
        entries: [GratitudeEntry]
    ) {
        self.id = id
        self.weekStartDate = weekStartDate
        self.entries = entries
    }
    
    /// Total gratitude items for the week
    var totalItems: Int {
        entries.reduce(0) { $0 + $1.items.count }
    }
    
    /// Number of days with entries
    var daysWithEntries: Int {
        entries.count
    }
    
    /// All items flattened for display
    var allItems: [GratitudeItem] {
        entries.flatMap { $0.items }
    }
    
    /// Most common category
    var topCategory: GratitudeCategory? {
        let categories = allItems.map { $0.category }
        let counts = Dictionary(grouping: categories, by: { $0 }).mapValues { $0.count }
        return counts.max(by: { $0.value < $1.value })?.key
    }
    
    /// Week date range for display
    var dateRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let endDate = Calendar.current.date(byAdding: .day, value: 6, to: weekStartDate) ?? weekStartDate
        return "\(formatter.string(from: weekStartDate)) - \(formatter.string(from: endDate))"
    }
}



