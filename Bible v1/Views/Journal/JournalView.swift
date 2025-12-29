//
//  JournalView.swift
//  Bible v1
//
//  Spiritual Journal - Main View with Calendar and Entries
//

import SwiftUI

/// Main Journal view with calendar navigation and entry list
struct JournalView: View {
    @ObservedObject var viewModel: JournalViewModel
    @ObservedObject var favoritesViewModel: FavoritesViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    
    @State private var showingNewEntry = false
    @State private var selectedEntryForDetail: JournalEntry?
    
    var body: some View {
        ZStack {
            themeManager.backgroundColor
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Expandable Calendar header
                    CompactCalendarHeader(
                        viewModel: viewModel,
                        onSearchTap: { viewModel.showingSearch = true },
                        onFilterTap: { viewModel.showingFilterSheet = true }
                    )
                    
                    // Content
                    if viewModel.filteredEntries.isEmpty {
                        emptyStateContent
                    } else {
                        entriesListContent
                    }
                    
                    // Bottom padding for FAB
                    Color.clear.frame(height: 100)
                }
            }
            
            // Floating add button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    addButton
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                }
            }
        }
        .sheet(isPresented: $showingNewEntry) {
            JournalEntryEditorView(
                viewModel: viewModel,
                favoritesViewModel: favoritesViewModel,
                isPresented: $showingNewEntry
            )
        }
        .sheet(item: $selectedEntryForDetail) { entry in
            JournalEntryDetailView(
                entry: entry,
                viewModel: viewModel,
                favoritesViewModel: favoritesViewModel
            )
        }
        .sheet(isPresented: $viewModel.showingSearch) {
            JournalSearchView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showingFilterSheet) {
            JournalFilterSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showingPrompts) {
            PromptBrowserView(viewModel: viewModel, showingNewEntry: $showingNewEntry)
        }
    }
    
    // MARK: - Components
    
    private var streakBadge: some View {
        Group {
            if viewModel.currentStreak > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Text("\(viewModel.currentStreak)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.orange.opacity(0.15))
                .cornerRadius(12)
            }
        }
    }
    
    private var addButton: some View {
        Button {
            viewModel.startNewEntry()
            showingNewEntry = true
        } label: {
            Image(systemName: "plus")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(themeManager.accentGradient)
                .clipShape(Circle())
                .shadow(color: themeManager.hubShadowColor, radius: 8, y: 4)
        }
    }
    
    // MARK: - Content for ScrollView
    
    private var emptyStateContent: some View {
        VStack(spacing: 24) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 70))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            themeManager.accentColor.opacity(0.6),
                            themeManager.accentColor.opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: 8) {
                Text(viewModel.hasActiveFilters ? "No Matching Entries" : "Start Your Journal")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.textColor)
                
                Text(viewModel.hasActiveFilters ?
                     "Try adjusting your filters or search terms." :
                     "Capture your spiritual journey through reflection, prayer, and scripture study.")
                    .font(.subheadline)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            if !viewModel.hasActiveFilters {
                // Today's prompt suggestion
                VStack(spacing: 12) {
                    Text("Today's Prompt")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.accentColor)
                    
                    Text(viewModel.todaysPrompt.text)
                        .font(.subheadline)
                        .foregroundColor(themeManager.textColor)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(themeManager.cardBackgroundColor)
                        .cornerRadius(12)
                        .padding(.horizontal, 24)
                }
                
                Button {
                    viewModel.startNewEntry(withPrompt: viewModel.todaysPrompt)
                    showingNewEntry = true
                } label: {
                    HStack {
                        Image(systemName: "pencil.line")
                        Text("Start Writing")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(themeManager.accentGradient)
                    .cornerRadius(25)
                }
            } else {
                Button {
                    viewModel.clearFilters()
                } label: {
                    Text("Clear Filters")
                        .font(.headline)
                        .foregroundColor(themeManager.accentColor)
                }
            }
        }
        .padding(.top, 40)
        .padding(.bottom, 40)
    }
    
    private var entriesListContent: some View {
        LazyVStack(spacing: 16) {
            // Active filters indicator
            if viewModel.hasActiveFilters {
                activeFiltersBar
            }
            
            // Entries
            ForEach(viewModel.filteredEntries) { entry in
                JournalEntryCard(entry: entry, themeManager: themeManager)
                    .onTapGesture {
                        selectedEntryForDetail = entry
                    }
                    .contextMenu {
                        Button {
                            viewModel.toggleFavorite(entry)
                        } label: {
                            Label(
                                entry.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                                systemImage: entry.isFavorite ? "heart.slash" : "heart"
                            )
                        }
                        
                        Button {
                            viewModel.startEditing(entry)
                            showingNewEntry = true
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive) {
                            viewModel.deleteEntry(entry)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }
    
    private var activeFiltersBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if !viewModel.searchQuery.isEmpty {
                    filterChip(
                        icon: "magnifyingglass",
                        text: viewModel.searchQuery,
                        onRemove: { viewModel.searchQuery = "" }
                    )
                }
                
                if let mood = viewModel.selectedMood {
                    filterChip(
                        icon: mood.icon,
                        text: mood.displayName,
                        color: mood.color,
                        onRemove: { viewModel.selectedMood = nil }
                    )
                }
                
                ForEach(viewModel.selectedTags) { tag in
                    filterChip(
                        icon: tag.icon,
                        text: tag.name,
                        color: tag.color,
                        onRemove: { viewModel.toggleTagFilter(tag) }
                    )
                }
                
                if viewModel.showOnlyFavorites {
                    filterChip(
                        icon: "heart.fill",
                        text: "Favorites",
                        color: .red,
                        onRemove: { viewModel.showOnlyFavorites = false }
                    )
                }
                
                if viewModel.showOnlyWithPhotos {
                    filterChip(
                        icon: "photo",
                        text: "With Photos",
                        onRemove: { viewModel.showOnlyWithPhotos = false }
                    )
                }
                
                // Clear all button
                Button {
                    viewModel.clearFilters()
                } label: {
                    Text("Clear All")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.accentColor)
                }
            }
        }
    }
    
    private func filterChip(
        icon: String,
        text: String,
        color: Color? = nil,
        onRemove: @escaping () -> Void
    ) -> some View {
        let chipColor = color ?? themeManager.accentColor
        return HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption)
                .lineLimit(1)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
        }
        .foregroundColor(chipColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(chipColor.opacity(0.12))
        .cornerRadius(20)
    }
}

// MARK: - Journal Calendar Header

struct JournalCalendarHeader: View {
    @ObservedObject var viewModel: JournalViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    
    let onSearchTap: () -> Void
    let onFilterTap: () -> Void
    
    private let calendar = Calendar.current
    private let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]
    
    var body: some View {
        VStack(spacing: 12) {
            // Month navigation
            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.previousMonth()
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(themeManager.accentColor)
                }
                
                Spacer()
                
                Text(monthYearString)
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
                
                Spacer()
                
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.nextMonth()
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundColor(themeManager.accentColor)
                }
            }
            .padding(.horizontal, 20)
            
            // Week view
            HStack(spacing: 0) {
                ForEach(weekDates, id: \.self) { date in
                    dayCell(for: date)
                }
            }
            .padding(.horizontal, 8)
            
            // Action buttons
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
        .padding(.vertical, 12)
        .background(themeManager.backgroundColor)
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: viewModel.selectedMonth)
    }
    
    private var weekDates: [Date] {
        let today = calendar.startOfDay(for: viewModel.selectedDate)
        let weekday = calendar.component(.weekday, from: today)
        let startOfWeek = calendar.date(byAdding: .day, value: -(weekday - 1), to: today) ?? today
        
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: startOfWeek)
        }
    }
    
    private func dayCell(for date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: viewModel.selectedDate)
        let isToday = calendar.isDateInToday(date)
        let hasEntry = viewModel.datesWithEntriesInMonth.contains(calendar.startOfDay(for: date))
        
        // Get mood for entries on this date
        let entriesForDay = viewModel.entries.filter { calendar.isDate($0.dateCreated, inSameDayAs: date) }
        let moodColor = entriesForDay.first?.mood?.color
        
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.selectDate(date)
            }
        } label: {
            VStack(spacing: 4) {
                Text(daysOfWeek[calendar.component(.weekday, from: date) - 1])
                    .font(.caption2)
                    .foregroundColor(themeManager.secondaryTextColor)
                
                ZStack {
                    Circle()
                        .fill(isSelected ? themeManager.accentColor : Color.clear)
                        .frame(width: 36, height: 36)
                    
                    if isToday && !isSelected {
                        Circle()
                            .stroke(themeManager.accentColor, lineWidth: 2)
                            .frame(width: 36, height: 36)
                    }
                    
                    Text("\(calendar.component(.day, from: date))")
                        .font(.subheadline)
                        .fontWeight(isToday ? .bold : .regular)
                        .foregroundColor(isSelected ? .white : themeManager.textColor)
                }
                
                // Entry indicator
                Circle()
                    .fill(hasEntry ? (moodColor ?? themeManager.accentColor) : Color.clear)
                    .frame(width: 6, height: 6)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Journal Entry Card

struct JournalEntryCard: View {
    let entry: JournalEntry
    let themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                // Date and time
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.formattedDate)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.accentColor)
                    
                    Text(entry.timeOfDay)
                        .font(.caption2)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                
                Spacer()
                
                // Mood indicator
                if let mood = entry.mood {
                    HStack(spacing: 4) {
                        Image(systemName: mood.icon)
                            .font(.caption)
                        Text(mood.displayName)
                            .font(.caption)
                    }
                    .foregroundColor(mood.color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(mood.lightColor)
                    .cornerRadius(12)
                }
                
                // Favorite indicator
                if entry.isFavorite {
                    Image(systemName: "heart.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            // Title
            if !entry.title.isEmpty {
                Text(entry.title)
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
                    .lineLimit(2)
            }
            
            // Content preview
            Text(entry.previewText)
                .font(.subheadline)
                .foregroundColor(themeManager.secondaryTextColor)
                .lineLimit(3)
            
            // Tags
            if !entry.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(entry.tags.prefix(3)) { tag in
                            HStack(spacing: 4) {
                                Image(systemName: tag.icon)
                                    .font(.caption2)
                                Text(tag.name)
                                    .font(.caption2)
                            }
                            .foregroundColor(tag.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(tag.lightColor)
                            .cornerRadius(8)
                        }
                        
                        if entry.tags.count > 3 {
                            Text("+\(entry.tags.count - 3)")
                                .font(.caption2)
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                    }
                }
            }
            
            // Footer with linked items and photos
            if entry.hasLinkedContent || entry.hasPhotos {
                HStack(spacing: 12) {
                    if !entry.linkedVerses.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "book.fill")
                                .font(.caption2)
                            Text("\(entry.linkedVerses.count)")
                                .font(.caption)
                        }
                        .foregroundColor(themeManager.secondaryTextColor)
                    }
                    
                    if entry.hasPhotos {
                        HStack(spacing: 4) {
                            Image(systemName: "photo.fill")
                                .font(.caption2)
                            Text("\(entry.photoFileNames.count)")
                                .font(.caption)
                        }
                        .foregroundColor(themeManager.secondaryTextColor)
                    }
                    
                    Spacer()
                    
                    // Word count
                    Text("\(entry.wordCount) words")
                        .font(.caption2)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
        }
        .padding(16)
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(16)
        .shadow(color: themeManager.hubShadowColor, radius: 4, y: 2)
    }
}

#Preview {
    JournalView(
        viewModel: JournalViewModel(),
        favoritesViewModel: FavoritesViewModel()
    )
}

