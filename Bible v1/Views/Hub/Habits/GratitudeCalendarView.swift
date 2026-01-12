//
//  GratitudeCalendarView.swift
//  Bible v1
//
//  Calendar view showing gratitude completion by day
//

import SwiftUI

struct GratitudeCalendarView: View {
    @ObservedObject var viewModel: HubViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedMonth: Date = Date()
    @State private var selectedEntry: GratitudeEntry?
    
    private let calendar = Calendar.current
    private let daysOfWeek: [String] = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        return formatter.veryShortWeekdaySymbols
    }()
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Month navigation
                        monthNavigationHeader
                        
                        // Stats summary for month
                        monthStatsCard
                        
                        // Calendar grid
                        calendarGrid
                        
                        // Legend
                        legendView
                        
                        // Selected day detail
                        if let entry = selectedEntry {
                            selectedDayDetail(entry: entry)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Gratitude Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        withAnimation {
                            selectedMonth = Date()
                            selectedEntry = viewModel.getGratitudeEntry(for: Date())
                        }
                    } label: {
                        Text("Today")
                            .font(.caption)
                    }
                }
            }
        }
    }
    
    // MARK: - Month Navigation
    
    private var monthNavigationHeader: some View {
        HStack {
            Button {
                withAnimation {
                    selectedMonth = calendar.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
                    selectedEntry = nil
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(themeManager.accentColor)
            }
            
            Spacer()
            
            Text(monthYearString)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(themeManager.textColor)
            
            Spacer()
            
            Button {
                withAnimation {
                    let nextMonth = calendar.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
                    // Don't go beyond current month
                    if nextMonth <= Date() {
                        selectedMonth = nextMonth
                        selectedEntry = nil
                    }
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundColor(canGoForward ? themeManager.accentColor : themeManager.dividerColor)
            }
            .disabled(!canGoForward)
        }
        .padding(.horizontal)
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedMonth)
    }
    
    private var canGoForward: Bool {
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
        return nextMonth <= Date()
    }
    
    // MARK: - Month Stats
    
    private var monthStatsCard: some View {
        let entries = viewModel.getGratitudeEntries(for: selectedMonth)
        let totalItems = entries.reduce(0) { $0 + $1.items.count }
        let completeDays = entries.filter { $0.isComplete }.count
        let daysInMonth = calendar.range(of: .day, in: .month, for: selectedMonth)?.count ?? 30
        
        return HStack(spacing: 16) {
            VStack(spacing: 4) {
                Text("\(entries.count)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.pink)
                Text("Days")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            .frame(maxWidth: .infinity)
            
            Divider()
                .frame(height: 40)
            
            VStack(spacing: 4) {
                Text("\(completeDays)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                Text("Complete")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            .frame(maxWidth: .infinity)
            
            Divider()
                .frame(height: 40)
            
            VStack(spacing: 4) {
                Text("\(totalItems)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.teal)
                Text("Gratitudes")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            .frame(maxWidth: .infinity)
            
            Divider()
                .frame(height: 40)
            
            VStack(spacing: 4) {
                let percentage = daysInMonth > 0 ? Int(Double(entries.count) / Double(daysInMonth) * 100) : 0
                Text("\(percentage)%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                Text("Active")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(16)
    }
    
    // MARK: - Calendar Grid
    
    private var calendarGrid: some View {
        VStack(spacing: 8) {
            // Days of week header (Mon-Sun)
            HStack(spacing: 0) {
                ForEach(weekdayLabels, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.secondaryTextColor)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar days grid
            let calendarDays = generateCalendarDays()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 8) {
                ForEach(Array(calendarDays.enumerated()), id: \.offset) { _, dayInfo in
                    CalendarDayCellWrapper(
                        dayInfo: dayInfo,
                        viewModel: viewModel,
                        selectedEntry: $selectedEntry,
                        isSelected: dayInfo.date.map { isSelected($0) } ?? false
                    )
                }
            }
        }
        .padding()
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(16)
    }
    
    // Monday through Sunday labels
    private var weekdayLabels: [String] {
        ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    }
    
    // Calendar day info struct for proper grid alignment
    struct CalendarDayInfo {
        let date: Date?
        let isCurrentMonth: Bool
        let isFuture: Bool
    }
    
    private func generateCalendarDays() -> [CalendarDayInfo] {
        var days: [CalendarDayInfo] = []
        
        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedMonth) else {
            return days
        }
        
        let firstDayOfMonth = monthInterval.start
        let today = calendar.startOfDay(for: Date())
        
        // Get the weekday of the first day (1 = Sunday, 2 = Monday, ..., 7 = Saturday)
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        
        // Convert to Monday-based index (Monday = 0, ..., Sunday = 6)
        // weekday 2 (Monday) -> 0, weekday 3 (Tuesday) -> 1, ..., weekday 1 (Sunday) -> 6
        let leadingEmptyCells = (firstWeekday - 2 + 7) % 7
        
        // Add leading empty cells (days from previous month)
        for _ in 0..<leadingEmptyCells {
            days.append(CalendarDayInfo(date: nil, isCurrentMonth: false, isFuture: false))
        }
        
        // Add all days of the current month
        var currentDate = firstDayOfMonth
        while currentDate < monthInterval.end {
            let isFuture = currentDate > today
            days.append(CalendarDayInfo(date: currentDate, isCurrentMonth: true, isFuture: isFuture))
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        // Add trailing empty cells to complete the last week
        let remainingCells = (7 - (days.count % 7)) % 7
        for _ in 0..<remainingCells {
            days.append(CalendarDayInfo(date: nil, isCurrentMonth: false, isFuture: false))
        }
        
        return days
    }
    
    private func isSelected(_ date: Date) -> Bool {
        guard let entry = selectedEntry else { return false }
        return calendar.isDate(entry.date, inSameDayAs: date)
    }
}

// MARK: - Calendar Day Cell Wrapper

struct CalendarDayCellWrapper: View {
    let dayInfo: GratitudeCalendarView.CalendarDayInfo
    @ObservedObject var viewModel: HubViewModel
    @Binding var selectedEntry: GratitudeEntry?
    let isSelected: Bool
    
    @ObservedObject private var themeManager = ThemeManager.shared
    private let calendar = Calendar.current
    
    var body: some View {
        if let date = dayInfo.date {
            CalendarDayCell(
                date: date,
                entry: viewModel.getGratitudeEntry(for: date),
                isSelected: isSelected,
                isToday: calendar.isDateInToday(date),
                isFuture: dayInfo.isFuture
            ) {
                if !dayInfo.isFuture {
                    withAnimation(.spring(response: 0.3)) {
                        selectedEntry = viewModel.getGratitudeEntry(for: date)
                    }
                }
            }
        } else {
            // Empty cell for grid alignment
            Color.clear
                .frame(height: 44)
        }
    }
}

extension GratitudeCalendarView {
    // MARK: - Legend
    
    private var legendView: some View {
        HStack(spacing: 20) {
            legendItem(color: .green, label: "Complete (3)")
            legendItem(color: .pink.opacity(0.6), label: "Partial")
            legendItem(color: themeManager.dividerColor, label: "No Entry")
        }
        .padding(.vertical, 8)
    }
    
    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            Text(label)
                .font(.caption)
                .foregroundColor(themeManager.secondaryTextColor)
        }
    }
    
    // MARK: - Selected Day Detail
    
    private func selectedDayDetail(entry: GratitudeEntry) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.dayOfWeek)
                        .font(.headline)
                        .foregroundColor(themeManager.textColor)
                    Text(entry.formattedDate)
                        .font(.subheadline)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                
                Spacer()
                
                if entry.isComplete {
                    Label("Complete", systemImage: "checkmark.seal.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Text("\(entry.items.count)/3")
                        .font(.caption)
                        .foregroundColor(themeManager.accentColor)
                }
            }
            
            Divider()
            
            ForEach(entry.items) { item in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: item.category.icon)
                        .font(.caption)
                        .foregroundColor(.pink)
                        .frame(width: 20)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.text)
                            .font(.subheadline)
                            .foregroundColor(themeManager.textColor)
                        
                        Text(item.category.rawValue)
                            .font(.caption2)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                }
            }
            
            if let reflection = entry.reflection, !reflection.isEmpty {
                Divider()
                
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "text.quote")
                        .font(.caption)
                        .foregroundColor(themeManager.accentColor)
                        .frame(width: 20)
                    
                    Text(reflection)
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                        .italic()
                }
            }
        }
        .padding()
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(16)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
}

// MARK: - Calendar Day Cell

struct CalendarDayCell: View {
    let date: Date
    let entry: GratitudeEntry?
    let isSelected: Bool
    let isToday: Bool
    var isFuture: Bool = false
    let onTap: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    private let calendar = Calendar.current
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 40, height: 40)
                
                // Selection ring
                if isSelected && !isFuture {
                    Circle()
                        .stroke(themeManager.accentColor, lineWidth: 2)
                        .frame(width: 40, height: 40)
                }
                
                // Today ring
                if isToday && !isSelected {
                    Circle()
                        .stroke(themeManager.accentColor, lineWidth: 2)
                        .frame(width: 40, height: 40)
                }
                
                // Day number
                Text("\(calendar.component(.day, from: date))")
                    .font(.subheadline)
                    .fontWeight(isToday ? .bold : .regular)
                    .foregroundColor(textColor)
                
                // Complete indicator
                if entry?.isComplete == true && !isFuture {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                        .offset(x: 12, y: -12)
                }
            }
        }
        .frame(height: 44)
        .disabled(isFuture || (entry == nil && !isToday))
    }
    
    private var backgroundColor: Color {
        if isFuture {
            return Color.clear
        }
        if let entry = entry {
            if entry.isComplete {
                return .green.opacity(0.3)
            } else {
                return .pink.opacity(0.2 + Double(entry.items.count) * 0.1)
            }
        }
        return themeManager.dividerColor.opacity(0.3)
    }
    
    private var textColor: Color {
        if isFuture {
            return themeManager.secondaryTextColor.opacity(0.3)
        }
        if entry != nil || isToday {
            return themeManager.textColor
        }
        return themeManager.secondaryTextColor.opacity(0.5)
    }
}

#Preview {
    GratitudeCalendarView(viewModel: HubViewModel())
}

