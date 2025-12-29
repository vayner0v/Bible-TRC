//
//  JournalFilterSheet.swift
//  Bible v1
//
//  Spiritual Journal - Filter Sheet
//

import SwiftUI

/// Sheet for filtering journal entries
struct JournalFilterSheet: View {
    @ObservedObject var viewModel: JournalViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Quick filters
                        quickFiltersSection
                        
                        // Mood filter
                        moodFilterSection
                        
                        // Tags filter
                        tagsFilterSection
                        
                        // Date range
                        dateRangeSection
                        
                        // Clear all button
                        if viewModel.hasActiveFilters {
                            Button {
                                viewModel.clearFilters()
                            } label: {
                                HStack {
                                    Image(systemName: "xmark.circle")
                                    Text("Clear All Filters")
                                }
                                .font(.subheadline)
                                .foregroundColor(.red)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    // MARK: - Sections
    
    private var quickFiltersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Filters")
                .font(.headline)
                .foregroundColor(themeManager.textColor)
            
            HStack(spacing: 12) {
                QuickFilterButton(
                    icon: "heart.fill",
                    title: "Favorites",
                    isActive: viewModel.showOnlyFavorites,
                    color: .red,
                    themeManager: themeManager
                ) {
                    viewModel.showOnlyFavorites.toggle()
                }
                
                QuickFilterButton(
                    icon: "photo.fill",
                    title: "With Photos",
                    isActive: viewModel.showOnlyWithPhotos,
                    color: themeManager.accentColor,
                    themeManager: themeManager
                ) {
                    viewModel.showOnlyWithPhotos.toggle()
                }
            }
        }
    }
    
    private var moodFilterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Mood")
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
                
                Spacer()
                
                if viewModel.selectedMood != nil {
                    Button {
                        viewModel.selectedMood = nil
                    } label: {
                        Text("Clear")
                            .font(.caption)
                            .foregroundColor(themeManager.accentColor)
                    }
                }
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 10) {
                ForEach(JournalMood.allCases) { mood in
                    MoodFilterButton(
                        mood: mood,
                        isSelected: viewModel.selectedMood == mood,
                        themeManager: themeManager
                    ) {
                        if viewModel.selectedMood == mood {
                            viewModel.selectedMood = nil
                        } else {
                            viewModel.selectedMood = mood
                        }
                    }
                }
            }
        }
    }
    
    private var tagsFilterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Tags")
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
                
                Spacer()
                
                if !viewModel.selectedTags.isEmpty {
                    Button {
                        viewModel.selectedTags = []
                    } label: {
                        Text("Clear")
                            .font(.caption)
                            .foregroundColor(themeManager.accentColor)
                    }
                }
            }
            
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 100), spacing: 8)
            ], spacing: 8) {
                ForEach(viewModel.allTags) { tag in
                    let isSelected = viewModel.selectedTags.contains { $0.id == tag.id }
                    
                    Button {
                        viewModel.toggleTagFilter(tag)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: tag.icon)
                                .font(.caption)
                            Text(tag.name)
                                .font(.caption)
                        }
                        .foregroundColor(isSelected ? .white : tag.color)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(isSelected ? tag.color : tag.lightColor)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private var dateRangeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Date Range")
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
                
                Spacer()
                
                if viewModel.dateRangeStart != nil || viewModel.dateRangeEnd != nil {
                    Button {
                        viewModel.dateRangeStart = nil
                        viewModel.dateRangeEnd = nil
                    } label: {
                        Text("Clear")
                            .font(.caption)
                            .foregroundColor(themeManager.accentColor)
                    }
                }
            }
            
            VStack(spacing: 12) {
                // Preset buttons
                HStack(spacing: 8) {
                    DatePresetButton(
                        title: "Today",
                        isActive: isToday,
                        themeManager: themeManager
                    ) {
                        setDateRange(days: 0)
                    }
                    
                    DatePresetButton(
                        title: "Week",
                        isActive: isThisWeek,
                        themeManager: themeManager
                    ) {
                        setDateRange(days: 7)
                    }
                    
                    DatePresetButton(
                        title: "Month",
                        isActive: isThisMonth,
                        themeManager: themeManager
                    ) {
                        setDateRange(days: 30)
                    }
                    
                    DatePresetButton(
                        title: "Year",
                        isActive: isThisYear,
                        themeManager: themeManager
                    ) {
                        setDateRange(days: 365)
                    }
                }
                
                // Custom date pickers
                VStack(spacing: 8) {
                    HStack {
                        Text("From")
                            .font(.subheadline)
                            .foregroundColor(themeManager.secondaryTextColor)
                        
                        Spacer()
                        
                        DatePicker(
                            "",
                            selection: Binding(
                                get: { viewModel.dateRangeStart ?? Date() },
                                set: { viewModel.dateRangeStart = $0 }
                            ),
                            displayedComponents: .date
                        )
                        .labelsHidden()
                    }
                    
                    HStack {
                        Text("To")
                            .font(.subheadline)
                            .foregroundColor(themeManager.secondaryTextColor)
                        
                        Spacer()
                        
                        DatePicker(
                            "",
                            selection: Binding(
                                get: { viewModel.dateRangeEnd ?? Date() },
                                set: { viewModel.dateRangeEnd = $0 }
                            ),
                            displayedComponents: .date
                        )
                        .labelsHidden()
                    }
                }
                .padding()
                .background(themeManager.cardBackgroundColor)
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Helpers
    
    private var isToday: Bool {
        guard let start = viewModel.dateRangeStart else { return false }
        return Calendar.current.isDateInToday(start)
    }
    
    private var isThisWeek: Bool {
        guard let start = viewModel.dateRangeStart else { return false }
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        return Calendar.current.isDate(start, inSameDayAs: weekAgo)
    }
    
    private var isThisMonth: Bool {
        guard let start = viewModel.dateRangeStart else { return false }
        let monthAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        return Calendar.current.isDate(start, inSameDayAs: monthAgo)
    }
    
    private var isThisYear: Bool {
        guard let start = viewModel.dateRangeStart else { return false }
        let yearAgo = Calendar.current.date(byAdding: .day, value: -365, to: Date())!
        return Calendar.current.isDate(start, inSameDayAs: yearAgo)
    }
    
    private func setDateRange(days: Int) {
        if days == 0 {
            viewModel.dateRangeStart = Calendar.current.startOfDay(for: Date())
            viewModel.dateRangeEnd = Date()
        } else {
            viewModel.dateRangeStart = Calendar.current.date(byAdding: .day, value: -days, to: Date())
            viewModel.dateRangeEnd = Date()
        }
    }
}

// MARK: - Supporting Components

struct QuickFilterButton: View {
    let icon: String
    let title: String
    let isActive: Bool
    let color: Color
    let themeManager: ThemeManager
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline)
                Text(title)
                    .font(.subheadline)
            }
            .foregroundColor(isActive ? .white : themeManager.textColor)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isActive ? color : themeManager.cardBackgroundColor)
            )
        }
        .buttonStyle(.plain)
    }
}

struct MoodFilterButton: View {
    let mood: JournalMood
    let isSelected: Bool
    let themeManager: ThemeManager
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: mood.icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : mood.color)
                
                Text(mood.displayName)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white : themeManager.textColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? mood.color : themeManager.cardBackgroundColor)
            )
        }
        .buttonStyle(.plain)
    }
}

struct DatePresetButton: View {
    let title: String
    let isActive: Bool
    let themeManager: ThemeManager
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isActive ? .semibold : .regular)
                .foregroundColor(isActive ? .white : themeManager.textColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isActive ? themeManager.accentColor : themeManager.cardBackgroundColor)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    JournalFilterSheet(viewModel: JournalViewModel())
}

