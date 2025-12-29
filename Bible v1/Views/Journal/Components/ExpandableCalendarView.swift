//
//  ExpandableCalendarView.swift
//  Bible v1
//
//  Spiritual Journal - Expandable Calendar with Week/Month Toggle
//

import SwiftUI

/// Expandable calendar that shows week view by default and expands to full month
struct ExpandableCalendarView: View {
    @ObservedObject var viewModel: JournalViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    
    @State private var isExpanded = false
    @State private var dragOffset: CGFloat = 0
    @Namespace private var animation
    
    private let calendar = Calendar.current
    private let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Month navigation header inside a card
            VStack(spacing: 0) {
                monthNavigationHeader
                
                // Days of week header
                daysOfWeekHeader
                    .padding(.top, 12)
                
                // Calendar grid
                if isExpanded {
                    monthGridView
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .top)),
                            removal: .opacity.combined(with: .move(edge: .top))
                        ))
                } else {
                    weekRowView
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .bottom)),
                            removal: .opacity.combined(with: .move(edge: .bottom))
                        ))
                }
                
                // Expand/collapse indicator
                expandCollapseButton
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation.height
                }
                .onEnded { value in
                    let threshold: CGFloat = 50
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        if value.translation.height > threshold && !isExpanded {
                            isExpanded = true
                        } else if value.translation.height < -threshold && isExpanded {
                            isExpanded = false
                        }
                        dragOffset = 0
                    }
                }
        )
    }
    
    // MARK: - Month Navigation Header
    
    private var monthNavigationHeader: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    viewModel.previousMonth()
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.accentColor)
                    .frame(width: 44, height: 44)
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text(monthYearString)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.textColor)
                
                if !isExpanded {
                    Text(weekRangeString)
                        .font(.caption2)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
            
            Spacer()
            
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    viewModel.nextMonth()
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.accentColor)
                    .frame(width: 44, height: 44)
            }
        }
    }
    
    // MARK: - Days of Week Header
    
    private var daysOfWeekHeader: some View {
        HStack(spacing: 0) {
            ForEach(daysOfWeek.indices, id: \.self) { index in
                Text(daysOfWeek[index])
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    // MARK: - Week Row View (Collapsed)
    
    private var weekRowView: some View {
        HStack(spacing: 0) {
            ForEach(weekDates, id: \.self) { date in
                dayCell(for: date)
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Month Grid View (Expanded)
    
    private var monthGridView: some View {
        let weeks = monthWeeks
        
        return VStack(spacing: 4) {
            ForEach(weeks.indices, id: \.self) { weekIndex in
                HStack(spacing: 0) {
                    ForEach(weeks[weekIndex], id: \.self) { date in
                        dayCell(for: date, isInCurrentMonth: isInCurrentMonth(date))
                    }
                }
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Day Cell
    
    private func dayCell(for date: Date, isInCurrentMonth: Bool = true) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: viewModel.selectedDate)
        let isToday = calendar.isDateInToday(date)
        let hasEntry = viewModel.datesWithEntriesInMonth.contains(calendar.startOfDay(for: date))
        
        // Get mood for entries on this date
        let entriesForDay = viewModel.entries.filter { calendar.isDate($0.dateCreated, inSameDayAs: date) }
        let moodColor = entriesForDay.first?.mood?.color
        let entryCount = entriesForDay.count
        
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.selectDate(date)
                // Update month if needed
                if !calendar.isDate(date, equalTo: viewModel.selectedMonth, toGranularity: .month) {
                    viewModel.selectedMonth = date
                }
            }
            HapticManager.shared.lightImpact()
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    // Selection background
                    if isSelected {
                        Circle()
                            .fill(themeManager.accentColor)
                            .frame(width: 36, height: 36)
                            .matchedGeometryEffect(id: "selection", in: animation)
                    }
                    
                    // Today indicator
                    if isToday && !isSelected {
                        Circle()
                            .stroke(themeManager.accentColor, lineWidth: 2)
                            .frame(width: 36, height: 36)
                    }
                    
                    Text("\(calendar.component(.day, from: date))")
                        .font(.subheadline)
                        .fontWeight(isToday ? .bold : .regular)
                        .foregroundColor(
                            isSelected ? .white :
                            isInCurrentMonth ? themeManager.textColor :
                            themeManager.secondaryTextColor.opacity(0.5)
                        )
                }
                
                // Entry indicator(s)
                HStack(spacing: 2) {
                    if hasEntry {
                        if entryCount == 1 {
                            Circle()
                                .fill(moodColor ?? themeManager.accentColor)
                                .frame(width: 6, height: 6)
                        } else {
                            // Multiple entries indicator
                            ForEach(0..<min(entryCount, 3), id: \.self) { _ in
                                Circle()
                                    .fill(moodColor ?? themeManager.accentColor)
                                    .frame(width: 4, height: 4)
                            }
                        }
                    } else {
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 6, height: 6)
                    }
                }
                .frame(height: 6)
            }
            .frame(maxWidth: .infinity)
            .frame(height: isExpanded ? 52 : 60)
        }
        .buttonStyle(.plain)
        .disabled(!isInCurrentMonth && !isExpanded)
    }
    
    // MARK: - Expand/Collapse Button
    
    private var expandCollapseButton: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                isExpanded.toggle()
            }
            HapticManager.shared.lightImpact()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.secondaryTextColor)
                
                if !isExpanded {
                    Text("Show month")
                        .font(.caption2)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
            .padding(.bottom, 4)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Helper Properties
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: viewModel.selectedMonth)
    }
    
    private var weekRangeString: String {
        let dates = weekDates
        guard let first = dates.first, let last = dates.last else { return "" }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        return "\(formatter.string(from: first)) - \(formatter.string(from: last))"
    }
    
    private var weekDates: [Date] {
        let today = calendar.startOfDay(for: viewModel.selectedDate)
        let weekday = calendar.component(.weekday, from: today)
        let startOfWeek = calendar.date(byAdding: .day, value: -(weekday - 1), to: today) ?? today
        
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: startOfWeek)
        }
    }
    
    private var monthWeeks: [[Date]] {
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: viewModel.selectedMonth)),
              let monthRange = calendar.range(of: .day, in: .month, for: startOfMonth) else {
            return []
        }
        
        // Find the first day of the week containing the first day of the month
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let daysToSubtract = firstWeekday - 1
        guard let calendarStart = calendar.date(byAdding: .day, value: -daysToSubtract, to: startOfMonth) else {
            return []
        }
        
        // Calculate number of weeks needed
        let totalDays = daysToSubtract + monthRange.count
        let numberOfWeeks = Int(ceil(Double(totalDays) / 7.0))
        
        var weeks: [[Date]] = []
        var currentDate = calendarStart
        
        for _ in 0..<numberOfWeeks {
            var week: [Date] = []
            for _ in 0..<7 {
                week.append(currentDate)
                guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                    break
                }
                currentDate = nextDate
            }
            weeks.append(week)
        }
        
        return weeks
    }
    
    private func isInCurrentMonth(_ date: Date) -> Bool {
        calendar.isDate(date, equalTo: viewModel.selectedMonth, toGranularity: .month)
    }
}

// MARK: - Compact Calendar Header (for use with search/filter buttons)

struct CompactCalendarHeader: View {
    @ObservedObject var viewModel: JournalViewModel
    let onSearchTap: () -> Void
    let onFilterTap: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 12) {
            // Expandable calendar
            ExpandableCalendarView(viewModel: viewModel)
            
            // Action buttons row
            HStack(spacing: 12) {
                Button(action: onSearchTap) {
                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                        Text("Search")
                    }
                    .font(.subheadline)
                    .foregroundColor(themeManager.textColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(themeManager.cardBackgroundColor)
                    .cornerRadius(10)
                }
                
                Button(action: onFilterTap) {
                    HStack(spacing: 6) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                        Text("Filter")
                        if viewModel.hasActiveFilters {
                            Circle()
                                .fill(themeManager.accentColor)
                                .frame(width: 6, height: 6)
                        }
                    }
                    .font(.subheadline)
                    .foregroundColor(themeManager.textColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(themeManager.cardBackgroundColor)
                    .cornerRadius(10)
                }
                
                Spacer()
                
                // Entry count for selected date
                if !viewModel.entriesForSelectedDate.isEmpty {
                    Text("\(viewModel.entriesForSelectedDate.count) entries")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 8)
    }
}

#Preview("Expandable Calendar") {
    ExpandableCalendarView(viewModel: JournalViewModel())
}

#Preview("Compact Calendar Header") {
    CompactCalendarHeader(
        viewModel: JournalViewModel(),
        onSearchTap: {},
        onFilterTap: {}
    )
}

