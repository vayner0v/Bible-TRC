//
//  GratitudeTrackerView.swift
//  Bible v1
//
//  Gratitude Tracker - Daily gratitude entries with weekly lookback
//

import SwiftUI

struct GratitudeTrackerView: View {
    @ObservedObject var viewModel: HubViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var newGratitudeText = ""
    @State private var selectedCategory: GratitudeCategory = .general
    @State private var showWeeklyLookback = false
    @State private var showCategoryPicker = false
    @State private var showCalendarView = false
    @State private var showHistoryView = false
    @State private var editingItem: EditingGratitudeItem?
    @State private var reflectionText = ""
    @State private var isEditingReflection = false
    @FocusState private var isInputFocused: Bool
    @FocusState private var isReflectionFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header with streak visualization
                        headerSection
                        
                        // Streak activity visualization
                        streakVisualization
                        
                        // Today's gratitude card
                        todaysGratitudeCard
                        
                        // Reflection section
                        reflectionSection
                        
                        // Input section
                        if !todayIsComplete {
                            inputSection
                        }
                        
                        // Action buttons row
                        actionButtonsRow
                        
                        // Recent entries
                        recentEntriesSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Gratitude")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showWeeklyLookback) {
                WeeklyGratitudeLookbackView(viewModel: viewModel)
            }
            .sheet(isPresented: $showCategoryPicker) {
                GratitudeCategoryPicker(selectedCategory: $selectedCategory)
            }
            .sheet(isPresented: $showCalendarView) {
                GratitudeCalendarView(viewModel: viewModel)
            }
            .sheet(isPresented: $showHistoryView) {
                GratitudeHistoryView(viewModel: viewModel)
            }
            .sheet(item: $editingItem) { item in
                GratitudeItemEditorView(
                    viewModel: viewModel,
                    entry: item.entry,
                    itemIndex: item.index
                )
            }
            .onAppear {
                if let todayEntry = viewModel.todayGratitude {
                    reflectionText = todayEntry.reflection ?? ""
                }
            }
        }
    }
    
    private var todayIsComplete: Bool {
        viewModel.todayGratitude?.isComplete ?? false
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("What are you thankful for?")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.textColor)
                
                Text("Write 3 things you're grateful for today")
                    .font(.subheadline)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            Spacer()
            
            // Streak badge with enhanced info
            VStack(spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.title3)
                    Text("\(viewModel.gratitudeStreak)")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                .foregroundColor(viewModel.gratitudeStreak > 0 ? .orange : themeManager.secondaryTextColor)
                
                Text("day streak")
                    .font(.caption2)
                    .foregroundColor(themeManager.secondaryTextColor)
                
                if viewModel.longestGratitudeStreak > viewModel.gratitudeStreak {
                    Text("Best: \(viewModel.longestGratitudeStreak)")
                        .font(.caption2)
                        .foregroundColor(themeManager.accentColor)
                }
            }
        }
    }
    
    // MARK: - Streak Visualization
    
    private var streakVisualization: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Last 7 Days")
                .font(.caption)
                .foregroundColor(themeManager.secondaryTextColor)
            
            HStack(spacing: 6) {
                ForEach(viewModel.getGratitudeActivity(days: 7), id: \.date) { activity in
                    VStack(spacing: 4) {
                        // Day indicator
                        ZStack {
                            Circle()
                                .fill(activityColor(for: activity))
                                .frame(width: 36, height: 36)
                            
                            if activity.isComplete {
                                Image(systemName: "checkmark")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            } else if activity.hasEntry {
                                Text("\(gratitudeCountFor(activity.date))")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                        }
                        
                        // Day label
                        Text(dayAbbreviation(for: activity.date))
                            .font(.caption2)
                            .foregroundColor(
                                Calendar.current.isDateInToday(activity.date) 
                                    ? themeManager.accentColor 
                                    : themeManager.secondaryTextColor
                            )
                    }
                }
            }
            .frame(maxWidth: .infinity)
            
            // Milestone celebration
            if shouldShowMilestone {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text(milestoneMessage)
                        .font(.caption)
                        .foregroundColor(themeManager.textColor)
                }
                .padding(8)
                .background(Color.yellow.opacity(0.15))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(16)
    }
    
    private func activityColor(for activity: (date: Date, hasEntry: Bool, isComplete: Bool)) -> Color {
        if activity.isComplete {
            return .green
        } else if activity.hasEntry {
            return .pink.opacity(0.7)
        } else {
            return themeManager.dividerColor
        }
    }
    
    private func gratitudeCountFor(_ date: Date) -> Int {
        viewModel.getGratitudeEntry(for: date)?.items.count ?? 0
    }
    
    private func dayAbbreviation(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return String(formatter.string(from: date).prefix(2))
    }
    
    private var shouldShowMilestone: Bool {
        let streak = viewModel.gratitudeStreak
        return [7, 14, 21, 30, 60, 90, 100, 365].contains(streak)
    }
    
    private var milestoneMessage: String {
        switch viewModel.gratitudeStreak {
        case 7: return "One week of gratitude! Keep it up!"
        case 14: return "Two weeks strong! You're building a habit."
        case 21: return "21 days! Gratitude is becoming part of you."
        case 30: return "One month! What an incredible journey."
        case 60: return "Two months of daily gratitude. Amazing!"
        case 90: return "90 days! You're a gratitude master."
        case 100: return "100 days! A true milestone!"
        case 365: return "One whole year! Extraordinary dedication."
        default: return ""
        }
    }
    
    // MARK: - Today's Gratitude Card
    
    private var todaysGratitudeCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Today")
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
                
                Spacer()
                
                Text("\(viewModel.todayGratitude?.items.count ?? 0)/3")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(todayIsComplete ? .green : themeManager.accentColor)
            }
            
            // Progress dots
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(index < (viewModel.todayGratitude?.items.count ?? 0) ? Color.pink : themeManager.dividerColor)
                        .frame(width: 12, height: 12)
                        .animation(.spring(), value: viewModel.todayGratitude?.items.count)
                }
                
                Spacer()
                
                if todayIsComplete {
                    Label("Complete!", systemImage: "checkmark.seal.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            // Gratitude items with edit/delete
            if let gratitude = viewModel.todayGratitude, !gratitude.items.isEmpty {
                VStack(spacing: 10) {
                    ForEach(Array(gratitude.items.enumerated()), id: \.element.id) { index, item in
                        GratitudeItemRow(
                            index: index + 1,
                            item: item,
                            onEdit: {
                                editingItem = EditingGratitudeItem(entry: gratitude, index: index)
                            },
                            onDelete: {
                                withAnimation {
                                    viewModel.removeGratitudeItem(at: index, from: gratitude)
                                }
                            }
                        )
                    }
                }
            } else {
                Text("No gratitude items yet today. Start by adding what you're thankful for!")
                    .font(.subheadline)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .italic()
                    .padding(.vertical, 8)
            }
        }
        .padding()
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(16)
    }
    
    // MARK: - Reflection Section
    
    private var reflectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Daily Reflection", systemImage: "text.quote")
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
                
                Spacer()
                
                if !reflectionText.isEmpty && !isEditingReflection {
                    Button {
                        isEditingReflection = true
                        isReflectionFocused = true
                    } label: {
                        Image(systemName: "pencil")
                            .font(.caption)
                            .foregroundColor(themeManager.accentColor)
                    }
                }
            }
            
            if isEditingReflection || reflectionText.isEmpty {
                VStack(alignment: .trailing, spacing: 8) {
                    TextField("What's on your heart today?", text: $reflectionText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(themeManager.backgroundColor)
                        .cornerRadius(10)
                        .focused($isReflectionFocused)
                        .lineLimit(3...6)
                    
                    if isEditingReflection {
                        HStack {
                            Button("Cancel") {
                                reflectionText = viewModel.todayGratitude?.reflection ?? ""
                                isEditingReflection = false
                            }
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                            
                            Button("Save") {
                                saveReflection()
                            }
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.pink)
                        }
                    }
                }
            } else {
                Text(reflectionText)
                    .font(.subheadline)
                    .foregroundColor(themeManager.textColor)
                    .italic()
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(themeManager.backgroundColor.opacity(0.5))
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(16)
    }
    
    private func saveReflection() {
        if let entry = viewModel.todayGratitude {
            viewModel.updateGratitudeReflection(entry, reflection: reflectionText.isEmpty ? nil : reflectionText)
        } else {
            // Create entry if it doesn't exist
            var newEntry = GratitudeEntry()
            newEntry.reflection = reflectionText.isEmpty ? nil : reflectionText
            viewModel.updateGratitude(newEntry)
        }
        isEditingReflection = false
    }
    
    // MARK: - Input Section
    
    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add Gratitude")
                .font(.headline)
                .foregroundColor(themeManager.textColor)
            
            // Category selector
            Button {
                showCategoryPicker = true
            } label: {
                HStack {
                    Image(systemName: selectedCategory.icon)
                        .foregroundColor(.pink)
                    Text(selectedCategory.rawValue)
                        .font(.subheadline)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
                .foregroundColor(themeManager.textColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(themeManager.cardBackgroundColor)
                .cornerRadius(10)
            }
            
            // Text input
            HStack(spacing: 12) {
                TextField("I'm grateful for...", text: $newGratitudeText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(themeManager.cardBackgroundColor)
                    .cornerRadius(12)
                    .focused($isInputFocused)
                    .lineLimit(1...3)
                
                Button {
                    addGratitude()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                        .foregroundColor(newGratitudeText.isEmpty ? themeManager.dividerColor : .pink)
                }
                .disabled(newGratitudeText.isEmpty)
            }
            
            // Quick prompts
            VStack(alignment: .leading, spacing: 8) {
                Text("Need inspiration?")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(prompts, id: \.self) { prompt in
                            Button {
                                newGratitudeText = prompt
                                isInputFocused = true
                            } label: {
                                Text(prompt)
                                    .font(.caption)
                                    .foregroundColor(themeManager.accentColor)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(themeManager.accentColor.opacity(0.1))
                                    .cornerRadius(20)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var prompts: [String] {
        [
            "A person who helped me",
            "Something that made me smile",
            "A challenge I overcame",
            "My health",
            "A small pleasure today",
            "Something I learned"
        ]
    }
    
    // MARK: - Action Buttons Row
    
    private var actionButtonsRow: some View {
        HStack(spacing: 12) {
            // Weekly Lookback
            Button {
                showWeeklyLookback = true
            } label: {
                VStack(spacing: 6) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.title2)
                    Text("Weekly")
                        .font(.caption)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.pink, .teal],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(14)
            }
            
            // Calendar View
            Button {
                showCalendarView = true
            } label: {
                VStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.title2)
                    Text("Calendar")
                        .font(.caption)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.teal, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(14)
            }
            
            // Full History
            Button {
                showHistoryView = true
            } label: {
                VStack(spacing: 6) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.title2)
                    Text("History")
                        .font(.caption)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.orange, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(14)
            }
        }
    }
    
    // MARK: - Recent Entries Section
    
    private var recentEntriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Gratitude")
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
                
                Spacer()
                
                Button {
                    showHistoryView = true
                } label: {
                    Text("See All")
                        .font(.caption)
                        .foregroundColor(themeManager.accentColor)
                }
            }
            
            let recentEntries = viewModel.gratitudeEntries
                .filter { !$0.isToday }
                .prefix(5)
            
            if recentEntries.isEmpty {
                Text("Your past gratitude entries will appear here")
                    .font(.subheadline)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .italic()
            } else {
                ForEach(Array(recentEntries)) { entry in
                    RecentGratitudeEntryRow(entry: entry)
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func addGratitude() {
        guard !newGratitudeText.isEmpty else { return }
        viewModel.addGratitudeItem(newGratitudeText, category: selectedCategory)
        newGratitudeText = ""
        selectedCategory = .general
    }
}

// MARK: - Editing Item Identifier

struct EditingGratitudeItem: Identifiable {
    let id = UUID()
    let entry: GratitudeEntry
    let index: Int
}

// MARK: - Gratitude Item Row (with edit/delete)

struct GratitudeItemRow: View {
    let index: Int
    let item: GratitudeItem
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var showingActions = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(index)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 22, height: 22)
                .background(Color.pink)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.text)
                    .font(.subheadline)
                    .foregroundColor(themeManager.textColor)
                
                HStack(spacing: 4) {
                    Image(systemName: item.category.icon)
                        .font(.caption2)
                    Text(item.category.rawValue)
                        .font(.caption2)
                }
                .foregroundColor(themeManager.secondaryTextColor)
            }
            
            Spacer()
            
            if onEdit != nil || onDelete != nil {
                Menu {
                    if let onEdit = onEdit {
                        Button {
                            onEdit()
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                    }
                    
                    if let onDelete = onDelete {
                        Button(role: .destructive) {
                            onDelete()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                        .padding(8)
                }
            }
        }
        .padding()
        .background(themeManager.backgroundColor)
        .cornerRadius(10)
    }
}

// MARK: - Recent Entry Row

struct RecentGratitudeEntryRow: View {
    let entry: GratitudeEntry
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.dayOfWeek)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.accentColor)
                
                Text(entry.formattedDate)
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
                
                Spacer()
                
                if entry.isComplete {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                
                Text("\(entry.items.count) items")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            ForEach(entry.items) { item in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "heart.fill")
                        .font(.caption2)
                        .foregroundColor(.pink.opacity(0.6))
                    Text(item.text)
                        .font(.subheadline)
                        .foregroundColor(themeManager.textColor)
                        .lineLimit(1)
                }
            }
            
            if let reflection = entry.reflection, !reflection.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "text.quote")
                        .font(.caption2)
                        .foregroundColor(themeManager.accentColor.opacity(0.6))
                    Text(reflection)
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                        .italic()
                        .lineLimit(2)
                }
            }
        }
        .padding()
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(12)
    }
}

// MARK: - Gratitude Item Editor View

struct GratitudeItemEditorView: View {
    @ObservedObject var viewModel: HubViewModel
    let entry: GratitudeEntry
    let itemIndex: Int
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var text: String = ""
    @State private var category: GratitudeCategory = .general
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Category selector
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(.headline)
                            .foregroundColor(themeManager.textColor)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(GratitudeCategory.allCases) { cat in
                                    Button {
                                        category = cat
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: cat.icon)
                                            Text(cat.rawValue)
                                        }
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(category == cat ? Color.pink : themeManager.cardBackgroundColor)
                                        .foregroundColor(category == cat ? .white : themeManager.textColor)
                                        .cornerRadius(20)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Text editor
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Gratitude")
                            .font(.headline)
                            .foregroundColor(themeManager.textColor)
                        
                        TextField("I'm grateful for...", text: $text, axis: .vertical)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(themeManager.cardBackgroundColor)
                            .cornerRadius(12)
                            .lineLimit(3...6)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Edit Gratitude")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        viewModel.updateGratitudeItem(at: itemIndex, in: entry, text: text, category: category)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(text.isEmpty)
                }
            }
            .onAppear {
                if itemIndex < entry.items.count {
                    text = entry.items[itemIndex].text
                    category = entry.items[itemIndex].category
                }
            }
        }
    }
}

// MARK: - Gratitude Category Picker

struct GratitudeCategoryPicker: View {
    @Binding var selectedCategory: GratitudeCategory
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor.ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(GratitudeCategory.allCases) { category in
                            Button {
                                selectedCategory = category
                                dismiss()
                            } label: {
                                HStack {
                                    Image(systemName: category.icon)
                                        .font(.title3)
                                        .foregroundColor(.pink)
                                        .frame(width: 36)
                                    
                                    Text(category.rawValue)
                                        .font(.body)
                                        .foregroundColor(themeManager.textColor)
                                    
                                    Spacer()
                                    
                                    if category == selectedCategory {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.pink)
                                    }
                                }
                                .padding()
                                .background(
                                    category == selectedCategory ? Color.pink.opacity(0.1) : themeManager.cardBackgroundColor
                                )
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Weekly Gratitude Lookback View (with navigation)

struct WeeklyGratitudeLookbackView: View {
    @ObservedObject var viewModel: HubViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var weekOffset: Int = 0
    
    private var summary: WeeklyGratitudeSummary {
        viewModel.getWeeklyGratitudeSummary(weekOffset: weekOffset)
    }
    
    private var canGoBack: Bool {
        viewModel.hasGratitudeEntriesBeforeWeek(offset: weekOffset)
    }
    
    private var canGoForward: Bool {
        weekOffset < 0
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Week navigation
                        weekNavigationHeader
                        
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 50))
                                .foregroundStyle(
                                    LinearGradient(colors: [.pink, .teal], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                            
                            Text(summary.weekLabel)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(themeManager.textColor)
                            
                            Text(summary.dateRangeText)
                                .font(.subheadline)
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                        .padding(.top)
                        
                        // Stats
                        HStack(spacing: 20) {
                            GratitudeStatBox(
                                value: "\(summary.totalItems)",
                                label: "Gratitudes",
                                icon: "heart.fill",
                                color: .pink
                            )
                            
                            GratitudeStatBox(
                                value: "\(summary.completeDays)/7",
                                label: "Complete Days",
                                icon: "checkmark.circle.fill",
                                color: .green
                            )
                            
                            GratitudeStatBox(
                                value: "\(summary.daysWithEntries)",
                                label: "Active Days",
                                icon: "calendar",
                                color: .teal
                            )
                        }
                        
                        // Category breakdown
                        if !summary.categoryDistribution.isEmpty {
                            categoryBreakdownSection
                        }
                        
                        // Entries by day
                        if !summary.sortedEntries.isEmpty {
                            entriesByDaySection
                        } else {
                            emptyStateView
                        }
                        
                        // Encouragement
                        encouragementSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Weekly Lookback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private var weekNavigationHeader: some View {
        HStack {
            Button {
                withAnimation {
                    weekOffset -= 1
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(canGoBack ? themeManager.accentColor : themeManager.dividerColor)
            }
            .disabled(!canGoBack)
            
            Spacer()
            
            if weekOffset != 0 {
                Button {
                    withAnimation {
                        weekOffset = 0
                    }
                } label: {
                    Text("Go to This Week")
                        .font(.caption)
                        .foregroundColor(themeManager.accentColor)
                }
            }
            
            Spacer()
            
            Button {
                withAnimation {
                    weekOffset += 1
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
    
    private var categoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Categories")
                .font(.headline)
                .foregroundColor(themeManager.textColor)
            
            ForEach(summary.categoryDistribution, id: \.category) { item in
                HStack {
                    Image(systemName: item.category.icon)
                        .font(.caption)
                        .foregroundColor(.pink)
                        .frame(width: 24)
                    
                    Text(item.category.rawValue)
                        .font(.subheadline)
                        .foregroundColor(themeManager.textColor)
                    
                    Spacer()
                    
                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(themeManager.dividerColor)
                                .frame(height: 6)
                                .cornerRadius(3)
                            
                            Rectangle()
                                .fill(Color.pink)
                                .frame(width: geo.size.width * CGFloat(item.count) / CGFloat(max(summary.totalItems, 1)), height: 6)
                                .cornerRadius(3)
                        }
                    }
                    .frame(width: 80, height: 6)
                    
                    Text("\(item.count)")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                        .frame(width: 24, alignment: .trailing)
                }
            }
        }
        .padding()
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(12)
    }
    
    private var entriesByDaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Gratitudes")
                .font(.headline)
                .foregroundColor(themeManager.textColor)
            
            ForEach(summary.sortedEntries) { entry in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(entry.dayOfWeek)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(themeManager.accentColor)
                        
                        Text(entry.formattedDate)
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                        
                        Spacer()
                        
                        if entry.isComplete {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                    
                    ForEach(entry.items) { item in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: item.category.icon)
                                .font(.caption)
                                .foregroundColor(.pink)
                            
                            Text(item.text)
                                .font(.subheadline)
                                .foregroundColor(themeManager.textColor)
                        }
                    }
                    
                    if let reflection = entry.reflection, !reflection.isEmpty {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "text.quote")
                                .font(.caption)
                                .foregroundColor(themeManager.accentColor.opacity(0.6))
                            Text(reflection)
                                .font(.caption)
                                .foregroundColor(themeManager.secondaryTextColor)
                                .italic()
                        }
                    }
                }
                .padding()
                .background(themeManager.backgroundColor)
                .cornerRadius(10)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "heart.slash")
                .font(.system(size: 40))
                .foregroundColor(themeManager.secondaryTextColor)
            
            Text("No gratitude entries this week")
                .font(.subheadline)
                .foregroundColor(themeManager.secondaryTextColor)
            
            if weekOffset == 0 {
                Text("Start adding what you're thankful for!")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
        }
        .padding(.vertical, 40)
    }
    
    private var encouragementSection: some View {
        VStack(spacing: 8) {
            Text(encouragementMessage)
                .font(.subheadline)
                .italic()
                .foregroundColor(themeManager.textColor)
                .multilineTextAlignment(.center)
            
            Text("— 1 Thessalonians 5:18")
                .font(.caption)
                .foregroundColor(themeManager.accentColor)
        }
        .padding()
        .background(themeManager.accentColor.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var encouragementMessage: String {
        if summary.totalItems >= 15 {
            return "\"Give thanks in all circumstances; for this is God's will for you in Christ Jesus.\" You've been wonderfully consistent!"
        } else if summary.totalItems >= 7 {
            return "\"Give thanks in all circumstances; for this is God's will for you in Christ Jesus.\" Great progress this week!"
        } else {
            return "\"Give thanks in all circumstances; for this is God's will for you in Christ Jesus.\" Every grateful moment matters."
        }
    }
}

// MARK: - Gratitude Stat Box

struct GratitudeStatBox: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(themeManager.secondaryTextColor)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(10)
    }
}

#Preview {
    GratitudeTrackerView(viewModel: HubViewModel())
}
