//
//  GratitudeHistoryView.swift
//  Bible v1
//
//  Full history view for gratitude entries with filtering and search
//

import SwiftUI

struct GratitudeHistoryView: View {
    @ObservedObject var viewModel: HubViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var selectedCategory: GratitudeCategory?
    @State private var showCategoryFilter = false
    @State private var sortOrder: SortOrder = .newest
    @State private var selectedEntry: GratitudeEntry?
    
    private let calendar = Calendar.current
    
    enum SortOrder: String, CaseIterable {
        case newest = "Newest First"
        case oldest = "Oldest First"
        case mostItems = "Most Items"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search and filters
                    searchAndFilterBar
                    
                    if filteredEntries.isEmpty {
                        emptyStateView
                    } else {
                        // Stats summary
                        statsSummary
                        
                        // Entries list grouped by month
                        entriesList
                    }
                }
            }
            .navigationTitle("Gratitude History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showCategoryFilter) {
                categoryFilterSheet
            }
            .sheet(item: $selectedEntry) { entry in
                GratitudeEntryDetailView(entry: entry, viewModel: viewModel)
            }
        }
    }
    
    // MARK: - Search and Filter Bar
    
    private var searchAndFilterBar: some View {
        VStack(spacing: 12) {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(themeManager.secondaryTextColor)
                
                TextField("Search gratitude entries...", text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                }
            }
            .padding()
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(12)
            
            // Filter pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // Sort order
                    Menu {
                        ForEach(SortOrder.allCases, id: \.self) { order in
                            Button {
                                sortOrder = order
                            } label: {
                                HStack {
                                    Text(order.rawValue)
                                    if sortOrder == order {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.arrow.down")
                            Text(sortOrder.rawValue)
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(themeManager.cardBackgroundColor)
                        .foregroundColor(themeManager.textColor)
                        .cornerRadius(20)
                    }
                    
                    // Category filter
                    Button {
                        showCategoryFilter = true
                    } label: {
                        HStack(spacing: 4) {
                            if let category = selectedCategory {
                                Image(systemName: category.icon)
                                Text(category.rawValue)
                            } else {
                                Image(systemName: "line.3.horizontal.decrease.circle")
                                Text("All Categories")
                            }
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(selectedCategory != nil ? Color.pink.opacity(0.2) : themeManager.cardBackgroundColor)
                        .foregroundColor(selectedCategory != nil ? .pink : themeManager.textColor)
                        .cornerRadius(20)
                    }
                    
                    // Clear filters
                    if selectedCategory != nil || !searchText.isEmpty {
                        Button {
                            selectedCategory = nil
                            searchText = ""
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "xmark")
                                Text("Clear")
                            }
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .cornerRadius(20)
                        }
                    }
                }
            }
        }
        .padding()
    }
    
    // MARK: - Stats Summary
    
    private var statsSummary: some View {
        let entries = filteredEntries
        let totalItems = entries.reduce(0) { $0 + $1.items.count }
        
        return HStack(spacing: 16) {
            VStack(spacing: 2) {
                Text("\(entries.count)")
                    .font(.headline)
                    .foregroundColor(.pink)
                Text("Entries")
                    .font(.caption2)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            Divider().frame(height: 24)
            
            VStack(spacing: 2) {
                Text("\(totalItems)")
                    .font(.headline)
                    .foregroundColor(.teal)
                Text("Gratitudes")
                    .font(.caption2)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            Divider().frame(height: 24)
            
            VStack(spacing: 2) {
                Text("\(entries.filter { $0.isComplete }.count)")
                    .font(.headline)
                    .foregroundColor(.green)
                Text("Complete")
                    .font(.caption2)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(themeManager.cardBackgroundColor)
    }
    
    // MARK: - Entries List
    
    private var entriesList: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                ForEach(groupedEntries.keys.sorted(by: sortOrder == .oldest ? (<) : (>)), id: \.self) { monthKey in
                    Section {
                        ForEach(groupedEntries[monthKey] ?? []) { entry in
                            GratitudeHistoryRow(entry: entry)
                                .onTapGesture {
                                    selectedEntry = entry
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 4)
                        }
                    } header: {
                        HStack {
                            Text(monthKey)
                                .font(.headline)
                                .foregroundColor(themeManager.textColor)
                            
                            Spacer()
                            
                            let monthEntries = groupedEntries[monthKey] ?? []
                            Text("\(monthEntries.count) entries")
                                .font(.caption)
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                        .padding()
                        .background(themeManager.backgroundColor)
                    }
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: searchText.isEmpty && selectedCategory == nil ? "heart.slash" : "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(themeManager.secondaryTextColor)
            
            if searchText.isEmpty && selectedCategory == nil {
                Text("No gratitude entries yet")
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
                
                Text("Start recording what you're thankful for!")
                    .font(.subheadline)
                    .foregroundColor(themeManager.secondaryTextColor)
            } else {
                Text("No matching entries")
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
                
                Text("Try adjusting your search or filters")
                    .font(.subheadline)
                    .foregroundColor(themeManager.secondaryTextColor)
                
                Button {
                    searchText = ""
                    selectedCategory = nil
                } label: {
                    Text("Clear Filters")
                        .font(.subheadline)
                        .foregroundColor(.pink)
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Category Filter Sheet
    
    private var categoryFilterSheet: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor.ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 8) {
                        // All categories option
                        Button {
                            selectedCategory = nil
                            showCategoryFilter = false
                        } label: {
                            HStack {
                                Image(systemName: "square.grid.2x2")
                                    .font(.title3)
                                    .foregroundColor(.pink)
                                    .frame(width: 36)
                                
                                Text("All Categories")
                                    .font(.body)
                                    .foregroundColor(themeManager.textColor)
                                
                                Spacer()
                                
                                if selectedCategory == nil {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.pink)
                                }
                            }
                            .padding()
                            .background(selectedCategory == nil ? Color.pink.opacity(0.1) : themeManager.cardBackgroundColor)
                            .cornerRadius(12)
                        }
                        
                        ForEach(GratitudeCategory.allCases) { category in
                            let count = entriesWithCategory(category).count
                            
                            Button {
                                selectedCategory = category
                                showCategoryFilter = false
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
                                    
                                    Text("\(count)")
                                        .font(.caption)
                                        .foregroundColor(themeManager.secondaryTextColor)
                                    
                                    if selectedCategory == category {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.pink)
                                    }
                                }
                                .padding()
                                .background(selectedCategory == category ? Color.pink.opacity(0.1) : themeManager.cardBackgroundColor)
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Filter by Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showCategoryFilter = false }
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    // MARK: - Computed Properties
    
    private var filteredEntries: [GratitudeEntry] {
        var entries = viewModel.getAllGratitudeEntries()
        
        // Filter by search text
        if !searchText.isEmpty {
            let lowercased = searchText.lowercased()
            entries = entries.filter { entry in
                entry.items.contains { $0.text.lowercased().contains(lowercased) } ||
                entry.reflection?.lowercased().contains(lowercased) == true
            }
        }
        
        // Filter by category
        if let category = selectedCategory {
            entries = entries.filter { entry in
                entry.items.contains { $0.category == category }
            }
        }
        
        // Sort
        switch sortOrder {
        case .newest:
            entries.sort { $0.date > $1.date }
        case .oldest:
            entries.sort { $0.date < $1.date }
        case .mostItems:
            entries.sort { $0.items.count > $1.items.count }
        }
        
        return entries
    }
    
    private var groupedEntries: [String: [GratitudeEntry]] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        
        return Dictionary(grouping: filteredEntries) { entry in
            formatter.string(from: entry.date)
        }
    }
    
    private func entriesWithCategory(_ category: GratitudeCategory) -> [GratitudeEntry] {
        viewModel.getAllGratitudeEntries().filter { entry in
            entry.items.contains { $0.category == category }
        }
    }
}

// MARK: - History Row

struct GratitudeHistoryRow: View {
    let entry: GratitudeEntry
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.dayOfWeek)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.accentColor)
                    
                    Text(entry.formattedDate)
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    if entry.isComplete {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    
                    // Category icons
                    let categories = Set(entry.items.map { $0.category })
                    HStack(spacing: 2) {
                        ForEach(Array(categories).prefix(3), id: \.self) { category in
                            Image(systemName: category.icon)
                                .font(.caption2)
                                .foregroundColor(.pink.opacity(0.7))
                        }
                    }
                    
                    Text("\(entry.items.count)/3")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
            
            // Preview of items
            ForEach(entry.items.prefix(2)) { item in
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "heart.fill")
                        .font(.caption2)
                        .foregroundColor(.pink.opacity(0.5))
                    
                    Text(item.text)
                        .font(.caption)
                        .foregroundColor(themeManager.textColor)
                        .lineLimit(1)
                }
            }
            
            if entry.items.count > 2 {
                Text("+\(entry.items.count - 2) more")
                    .font(.caption2)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
        }
        .padding()
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(12)
    }
}

// MARK: - Entry Detail View

struct GratitudeEntryDetailView: View {
    let entry: GratitudeEntry
    @ObservedObject var viewModel: HubViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(entry.dayOfWeek)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(themeManager.textColor)
                                
                                Spacer()
                                
                                if entry.isComplete {
                                    Label("Complete", systemImage: "checkmark.seal.fill")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                            }
                            
                            Text(entry.formattedDate)
                                .font(.subheadline)
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                        
                        Divider()
                        
                        // Gratitude items
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Gratitude Items")
                                .font(.headline)
                                .foregroundColor(themeManager.textColor)
                            
                            ForEach(Array(entry.items.enumerated()), id: \.element.id) { index, item in
                                HStack(alignment: .top, spacing: 12) {
                                    Text("\(index + 1)")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .frame(width: 22, height: 22)
                                        .background(Color.pink)
                                        .clipShape(Circle())
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.text)
                                            .font(.body)
                                            .foregroundColor(themeManager.textColor)
                                        
                                        HStack(spacing: 4) {
                                            Image(systemName: item.category.icon)
                                                .font(.caption2)
                                            Text(item.category.rawValue)
                                                .font(.caption)
                                        }
                                        .foregroundColor(themeManager.secondaryTextColor)
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(themeManager.cardBackgroundColor)
                                .cornerRadius(12)
                            }
                        }
                        
                        // Reflection
                        if let reflection = entry.reflection, !reflection.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Reflection")
                                    .font(.headline)
                                    .foregroundColor(themeManager.textColor)
                                
                                Text(reflection)
                                    .font(.body)
                                    .foregroundColor(themeManager.textColor)
                                    .italic()
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(themeManager.cardBackgroundColor)
                                    .cornerRadius(12)
                            }
                        }
                        
                        // Metadata
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Details")
                                .font(.headline)
                                .foregroundColor(themeManager.textColor)
                            
                            HStack {
                                Text("Created")
                                    .font(.caption)
                                    .foregroundColor(themeManager.secondaryTextColor)
                                Spacer()
                                Text(formatDateTime(entry.createdAt))
                                    .font(.caption)
                                    .foregroundColor(themeManager.textColor)
                            }
                            
                            if entry.modifiedAt != entry.createdAt {
                                HStack {
                                    Text("Modified")
                                        .font(.caption)
                                        .foregroundColor(themeManager.secondaryTextColor)
                                    Spacer()
                                    Text(formatDateTime(entry.modifiedAt))
                                        .font(.caption)
                                        .foregroundColor(themeManager.textColor)
                                }
                            }
                        }
                        .padding()
                        .background(themeManager.cardBackgroundColor)
                        .cornerRadius(12)
                        
                        // Delete button
                        if !entry.isToday {
                            Button(role: .destructive) {
                                showDeleteConfirmation = true
                            } label: {
                                Label("Delete Entry", systemImage: "trash")
                                    .font(.subheadline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red.opacity(0.1))
                                    .foregroundColor(.red)
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Entry Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog("Delete this gratitude entry?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    viewModel.deleteGratitudeEntry(entry)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    GratitudeHistoryView(viewModel: HubViewModel())
}



