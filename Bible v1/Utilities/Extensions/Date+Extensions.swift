//
//  Date+Extensions.swift
//  Bible v1
//
//  Advanced Bible Reader App
//

import Foundation

extension Date {
    /// Relative time string (e.g., "2 hours ago")
    var relativeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    /// Short date string
    var shortDateString: String {
        formatted(date: .abbreviated, time: .omitted)
    }
    
    /// Short time string
    var shortTimeString: String {
        formatted(date: .omitted, time: .shortened)
    }
    
    /// Full date and time string
    var fullString: String {
        formatted(date: .long, time: .shortened)
    }
    
    /// Check if date is today
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    /// Check if date is yesterday
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }
    
    /// Check if date is this week (Monday-Sunday)
    var isThisWeek: Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let thisDate = calendar.startOfDay(for: self)
        
        // Get the Monday of the current week
        let todayWeekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (todayWeekday - 2 + 7) % 7
        guard let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: today),
              let sunday = calendar.date(byAdding: .day, value: 6, to: monday) else {
            return false
        }
        
        return thisDate >= monday && thisDate <= sunday
    }
    
    /// Smart date string based on recency
    var smartDateString: String {
        if isToday {
            return "Today"
        } else if isYesterday {
            return "Yesterday"
        } else if isThisWeek {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE" // Day name
            return formatter.string(from: self)
        } else {
            return shortDateString
        }
    }
}







