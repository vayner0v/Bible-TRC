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
    
    /// Check if date is this week
    var isThisWeek: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
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




