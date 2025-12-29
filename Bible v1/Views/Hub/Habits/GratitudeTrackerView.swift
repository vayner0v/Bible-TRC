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
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header with streak
                        headerSection
                        
                        // Today's gratitude card
                        todaysGratitudeCard
                        
                        // Input section
                        if !todayIsComplete {
                            inputSection
                        }
                        
                        // Weekly lookback button
                        weeklyLookbackButton
                        
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
            
            // Streak badge
            if viewModel.gratitudeStreak > 0 {
                VStack(spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.title3)
                        Text("\(viewModel.gratitudeStreak)")
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.orange)
                    
                    Text("day streak")
                        .font(.caption2)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
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
            
            // Gratitude items
            if let gratitude = viewModel.todayGratitude, !gratitude.items.isEmpty {
                VStack(spacing: 10) {
                    ForEach(Array(gratitude.items.enumerated()), id: \.element.id) { index, item in
                        GratitudeItemRow(
                            index: index + 1,
                            item: item
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
    
    // MARK: - Weekly Lookback Button
    
    private var weeklyLookbackButton: some View {
        Button {
            showWeeklyLookback = true
        } label: {
            HStack {
                Image(systemName: "calendar")
                    .font(.title3)
                Text("Weekly Lookback")
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
            }
            .foregroundColor(.white)
            .padding()
            .background(
                LinearGradient(
                    colors: [.pink, .teal],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(14)
        }
    }
    
    // MARK: - Recent Entries Section
    
    private var recentEntriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Gratitude")
                .font(.headline)
                .foregroundColor(themeManager.textColor)
            
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
                    }
                    .padding()
                    .background(themeManager.cardBackgroundColor)
                    .cornerRadius(12)
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

// MARK: - Gratitude Item Row

struct GratitudeItemRow: View {
    let index: Int
    let item: GratitudeItem
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
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
        }
        .padding()
        .background(themeManager.backgroundColor)
        .cornerRadius(10)
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

// MARK: - Weekly Gratitude Lookback View

struct WeeklyGratitudeLookbackView: View {
    @ObservedObject var viewModel: HubViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    private var summary: WeeklyGratitudeSummary {
        viewModel.getWeeklyGratitudeSummary()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 50))
                                .foregroundStyle(
                                    LinearGradient(colors: [.pink, .teal], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                            
                            Text("Your Week of Gratitude")
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
                                value: "\(summary.daysWithEntries)",
                                label: "Days",
                                icon: "calendar",
                                color: .teal
                            )
                            
                            if let topCategory = summary.topCategory {
                                GratitudeStatBox(
                                    value: topCategory.rawValue,
                                    label: "Top Theme",
                                    icon: topCategory.icon,
                                    color: .orange
                                )
                            }
                        }
                        
                        // All items
                        if !summary.allItems.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("All Your Gratitudes")
                                    .font(.headline)
                                    .foregroundColor(themeManager.textColor)
                                
                                ForEach(summary.allItems) { item in
                                    HStack(alignment: .top, spacing: 12) {
                                        Image(systemName: item.category.icon)
                                            .font(.caption)
                                            .foregroundColor(.pink)
                                        
                                        Text(item.text)
                                            .font(.subheadline)
                                            .foregroundColor(themeManager.textColor)
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(themeManager.cardBackgroundColor)
                                    .cornerRadius(10)
                                }
                            }
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "heart.slash")
                                    .font(.system(size: 40))
                                    .foregroundColor(themeManager.secondaryTextColor)
                                
                                Text("No gratitude entries this week")
                                    .font(.subheadline)
                                    .foregroundColor(themeManager.secondaryTextColor)
                            }
                            .padding(.vertical, 40)
                        }
                        
                        // Encouragement
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

