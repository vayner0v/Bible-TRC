//
//  PrayerLibraryView.swift
//  Bible v1
//
//  Spiritual Hub - Advanced Prayer Library with Smart Suggestions
//

import SwiftUI

struct PrayerLibraryView: View {
    @ObservedObject private var storageService = HubStorageService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var searchText = ""
    @State private var selectedTab = 0
    @State private var selectedFeeling: PrayerFeeling?
    @State private var selectedCategory: PrayerSuggestionCategory?
    @State private var showNewPrayerSheet = false
    @State private var showNewCollectionSheet = false
    @State private var selectedPrayer: SavedPrayer?
    @State private var selectedSuggestion: PrayerSuggestion?
    @State private var showFeelingSelector = false
    
    var filteredPrayers: [SavedPrayer] {
        if searchText.isEmpty {
            return storageService.savedPrayers
        }
        return storageService.searchPrayers(query: searchText)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Hero section with daily suggested prayer
                dailySuggestionCard
                
                // How are you feeling section
                feelingSelector
                
                // Category quick picks
                categorySection
                
                // Tab selector for library content
                tabSelector
                
                // Content based on selected tab
                tabContent
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 100)
        }
        .background(themeManager.backgroundColor.ignoresSafeArea())
        .navigationTitle("Prayer Library")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Search prayers")
        .overlay(alignment: .bottomTrailing) {
            floatingActionButton
        }
        .sheet(isPresented: $showNewPrayerSheet) {
            NewPrayerSheet()
        }
        .sheet(isPresented: $showNewCollectionSheet) {
            NewCollectionSheet()
        }
        .sheet(item: $selectedPrayer) { prayer in
            PrayerDetailSheet(prayer: prayer)
        }
        .sheet(item: $selectedSuggestion) { suggestion in
            SuggestionDetailSheet(suggestion: suggestion)
        }
        .sheet(isPresented: $showFeelingSelector) {
            FeelingPickerSheet(selectedFeeling: $selectedFeeling)
        }
        .sheet(item: $selectedCategory) { category in
            CategoryPrayersView(category: category)
        }
    }
    
    // MARK: - Daily Suggestion Hero Card
    
    private var dailySuggestionCard: some View {
        let suggestion = PrayerSuggestionEngine.dailySuggestion
        
        return Button {
            selectedSuggestion = suggestion
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Today's Prayer")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text(suggestion.title)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.2))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: suggestion.category.icon)
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
                
                Text(suggestion.content.prefix(120) + "...")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                
                if let reference = suggestion.scriptureReference {
                    HStack {
                        Image(systemName: "book.fill")
                            .font(.caption)
                        Text(reference)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white.opacity(0.8))
                }
                
                HStack {
                    Label("\(suggestion.duration) min", systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Spacer()
                    
                    Text("Begin Prayer →")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
            }
            .padding(20)
            .background(
                LinearGradient(
                    colors: suggestion.category.gradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(20)
            .shadow(color: suggestion.category.color.opacity(0.3), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(TilePressStyle())
    }
    
    // MARK: - Feeling Selector
    
    private var feelingSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("How are you feeling?")
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
                
                Spacer()
                
                if selectedFeeling != nil {
                    Button {
                        selectedFeeling = nil
                    } label: {
                        Text("Clear")
                            .font(.caption)
                            .foregroundColor(themeManager.accentColor)
                    }
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(PrayerFeeling.allCases.prefix(8)) { feeling in
                        feelingChip(feeling)
                    }
                    
                    Button {
                        showFeelingSelector = true
                    } label: {
                        Text("More...")
                            .font(.subheadline)
                            .foregroundColor(themeManager.accentColor)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(themeManager.accentColor.opacity(0.1))
                            .cornerRadius(20)
                    }
                }
            }
            
            // Show suggested prayers if feeling is selected
            if let feeling = selectedFeeling {
                feelingSuggestions(for: feeling)
            }
        }
    }
    
    private func feelingChip(_ feeling: PrayerFeeling) -> some View {
        let isSelected = selectedFeeling == feeling
        
        return Button {
            withAnimation(.spring(response: 0.3)) {
                selectedFeeling = isSelected ? nil : feeling
            }
        } label: {
            HStack(spacing: 6) {
                Text(feeling.emoji)
                Text(feeling.displayName)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .foregroundColor(isSelected ? .white : themeManager.textColor)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                isSelected
                    ? AnyShapeStyle(themeManager.accentColor)
                    : AnyShapeStyle(themeManager.cardBackgroundColor)
            )
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.clear : themeManager.dividerColor, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func feelingSuggestions(for feeling: PrayerFeeling) -> some View {
        let suggestions = PrayerSuggestionEngine.suggestionsFor(feeling: feeling)
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("Suggested for you")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(themeManager.secondaryTextColor)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(suggestions.prefix(5)) { suggestion in
                        suggestionMiniCard(suggestion)
                    }
                }
            }
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    private func suggestionMiniCard(_ suggestion: PrayerSuggestion) -> some View {
        Button {
            selectedSuggestion = suggestion
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: suggestion.category.icon)
                        .font(.title3)
                        .foregroundColor(suggestion.category.color)
                    
                    Spacer()
                    
                    Text("\(suggestion.duration)m")
                        .font(.caption2)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                
                Text(suggestion.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.textColor)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(suggestion.category.displayName)
                    .font(.caption)
                    .foregroundColor(suggestion.category.color)
            }
            .padding(14)
            .frame(width: 150)
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(14)
            .shadow(color: themeManager.hubShadowColor, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(TilePressStyle())
    }
    
    // MARK: - Category Section
    
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Browse by Category")
                .font(.headline)
                .foregroundColor(themeManager.textColor)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(PrayerSuggestionEngine.featuredCategories) { category in
                    categoryCard(category)
                }
            }
        }
    }
    
    private func categoryCard(_ category: PrayerSuggestionCategory) -> some View {
        Button {
            selectedCategory = category
        } label: {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(category.color.opacity(0.15))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: category.icon)
                        .font(.title3)
                        .foregroundColor(category.color)
                }
                
                Text(category.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.textColor)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(14)
            .shadow(color: themeManager.hubShadowColor, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(TilePressStyle())
    }
    
    // MARK: - Tab Selector
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(["My Prayers", "Favorites", "Collections"], id: \.self) { tab in
                let index = ["My Prayers", "Favorites", "Collections"].firstIndex(of: tab) ?? 0
                
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedTab = index
                    }
                } label: {
                    VStack(spacing: 8) {
                        Text(tab)
                            .font(.subheadline)
                            .fontWeight(selectedTab == index ? .semibold : .regular)
                            .foregroundColor(selectedTab == index ? themeManager.accentColor : themeManager.secondaryTextColor)
                        
                        Rectangle()
                            .fill(selectedTab == index ? themeManager.accentColor : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Tab Content
    
    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case 0:
            myPrayersContent
        case 1:
            favoritesContent
        case 2:
            collectionsContent
        default:
            myPrayersContent
        }
    }
    
    private var myPrayersContent: some View {
        Group {
            if filteredPrayers.isEmpty {
                emptyStateView(
                    icon: "text.book.closed",
                    title: "No Prayers Yet",
                    message: "Add your first prayer to build your personal library"
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(filteredPrayers) { prayer in
                        PrayerRow(prayer: prayer) {
                            selectedPrayer = prayer
                        }
                    }
                }
            }
        }
    }
    
    private var favoritesContent: some View {
        Group {
            let favorites = storageService.favoritePrayers
            
            if favorites.isEmpty {
                emptyStateView(
                    icon: "heart",
                    title: "No Favorites",
                    message: "Mark prayers as favorites for quick access"
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(favorites) { prayer in
                        PrayerRow(prayer: prayer) {
                            selectedPrayer = prayer
                        }
                    }
                }
            }
        }
    }
    
    private var collectionsContent: some View {
        Group {
            if storageService.prayerCollections.isEmpty {
                emptyStateView(
                    icon: "folder",
                    title: "No Collections",
                    message: "Create collections to organize your prayers"
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(storageService.prayerCollections) { collection in
                        NavigationLink {
                            CollectionDetailView(collection: collection)
                        } label: {
                            CollectionRow(collection: collection)
                        }
                    }
                }
            }
        }
    }
    
    private func emptyStateView(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(themeManager.secondaryTextColor.opacity(0.5))
            
            Text(title)
                .font(.headline)
                .foregroundColor(themeManager.textColor)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(themeManager.secondaryTextColor)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    // MARK: - Floating Action Button
    
    private var floatingActionButton: some View {
        Menu {
            Button {
                showNewPrayerSheet = true
            } label: {
                Label("New Prayer", systemImage: "plus")
            }
            
            Button {
                showNewCollectionSheet = true
            } label: {
                Label("New Collection", systemImage: "folder.badge.plus")
            }
        } label: {
            ZStack {
                Circle()
                    .fill(themeManager.accentColor)
                    .frame(width: 56, height: 56)
                    .shadow(color: themeManager.accentColor.opacity(0.4), radius: 8, x: 0, y: 4)
                
                Image(systemName: "plus")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
        }
        .padding(.trailing, 20)
        .padding(.bottom, 20)
    }
}

// MARK: - Suggestion Detail Sheet

struct SuggestionDetailSheet: View {
    let suggestion: PrayerSuggestion
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var storageService = HubStorageService.shared
    @State private var isPraying = false
    @State private var showSaveSheet = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Scripture if available
                    if let reference = suggestion.scriptureReference,
                       let text = suggestion.scriptureText {
                        scriptureCard(reference: reference, text: text)
                    }
                    
                    // Prayer content
                    prayerContent
                    
                    // Tags
                    if !suggestion.tags.isEmpty {
                        tagsSection
                    }
                    
                    // Actions
                    actionButtons
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [suggestion.category.color.opacity(0.1), themeManager.backgroundColor],
                    startPoint: .top,
                    endPoint: .center
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Prayer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(themeManager.accentColor)
                }
            }
            .sheet(isPresented: $showSaveSheet) {
                SaveSuggestionSheet(suggestion: suggestion)
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(suggestion.category.color.opacity(0.15))
                    .frame(width: 80, height: 80)
                
                Image(systemName: suggestion.category.icon)
                    .font(.largeTitle)
                    .foregroundColor(suggestion.category.color)
            }
            
            Text(suggestion.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(themeManager.textColor)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 16) {
                Label(suggestion.category.displayName, systemImage: suggestion.category.icon)
                    .font(.caption)
                    .foregroundColor(suggestion.category.color)
                
                Label("\(suggestion.duration) min", systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
        }
    }
    
    private func scriptureCard(reference: String, text: String) -> some View {
        VStack(spacing: 12) {
            Text("\"\(text)\"")
                .font(.body)
                .italic()
                .foregroundColor(themeManager.textColor)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            
            Text("— \(reference)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(suggestion.category.color)
        }
        .padding(20)
        .background(suggestion.category.color.opacity(0.1))
        .cornerRadius(16)
    }
    
    private var prayerContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "hands.sparkles")
                    .foregroundColor(themeManager.accentColor)
                Text("Prayer")
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
            }
            
            Text(suggestion.content)
                .font(.body)
                .foregroundColor(themeManager.textColor)
                .lineSpacing(6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(14)
    }
    
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tags")
                .font(.caption)
                .foregroundColor(themeManager.secondaryTextColor)
            
            FlowLayout(spacing: 8) {
                ForEach(suggestion.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .foregroundColor(themeManager.accentColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(themeManager.accentColor.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                isPraying = true
            } label: {
                HStack {
                    Image(systemName: "hands.sparkles")
                    Text("Begin Prayer")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(suggestion.category.color)
                .cornerRadius(14)
            }
            
            HStack(spacing: 12) {
                Button {
                    showSaveSheet = true
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("Save to Library")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.accentColor)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(themeManager.accentColor.opacity(0.12))
                    .cornerRadius(12)
                }
                
                ShareLink(item: suggestion.content) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(themeManager.cardBackgroundColor)
                    .cornerRadius(12)
                }
            }
        }
    }
}

// MARK: - Save Suggestion Sheet

struct SaveSuggestionSheet: View {
    let suggestion: PrayerSuggestion
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var storageService = HubStorageService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    
    @State private var title: String
    @State private var isFavorite = false
    
    init(suggestion: PrayerSuggestion) {
        self.suggestion = suggestion
        self._title = State(initialValue: suggestion.title)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Prayer Title") {
                    TextField("Title", text: $title)
                }
                
                Section {
                    Toggle("Add to Favorites", isOn: $isFavorite)
                }
            }
            .navigationTitle("Save Prayer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        savePrayer()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func savePrayer() {
        var prayer = SavedPrayer(
            title: title,
            content: suggestion.content,
            sourceVerseReference: suggestion.scriptureReference,
            sourceVerseText: suggestion.scriptureText,
            tags: suggestion.tags
        )
        prayer.isFavorite = isFavorite
        storageService.addSavedPrayer(prayer)
        dismiss()
    }
}

// MARK: - Feeling Picker Sheet

struct FeelingPickerSheet: View {
    @Binding var selectedFeeling: PrayerFeeling?
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(PrayerFeeling.allCases) { feeling in
                        Button {
                            selectedFeeling = feeling
                            dismiss()
                        } label: {
                            VStack(spacing: 8) {
                                Text(feeling.emoji)
                                    .font(.largeTitle)
                                
                                Text(feeling.displayName)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(themeManager.textColor)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(themeManager.cardBackgroundColor)
                            .cornerRadius(14)
                        }
                        .buttonStyle(TilePressStyle())
                    }
                }
                .padding()
            }
            .navigationTitle("How are you feeling?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Category Prayers View

struct CategoryPrayersView: View {
    let category: PrayerSuggestionCategory
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var selectedSuggestion: PrayerSuggestion?
    
    var prayers: [PrayerSuggestion] {
        PrayerSuggestionEngine.suggestionsFor(category: category)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(category.color.opacity(0.15))
                                .frame(width: 70, height: 70)
                            
                            Image(systemName: category.icon)
                                .font(.title)
                                .foregroundColor(category.color)
                        }
                        
                        Text(category.displayName)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.textColor)
                        
                        Text("\(prayers.count) prayers available")
                            .font(.subheadline)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    .padding(.top)
                    
                    // Prayer list
                    LazyVStack(spacing: 12) {
                        ForEach(prayers) { prayer in
                            Button {
                                selectedSuggestion = prayer
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: category.icon)
                                        .font(.title3)
                                        .foregroundColor(category.color)
                                        .frame(width: 40)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(prayer.title)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(themeManager.textColor)
                                        
                                        if let reference = prayer.scriptureReference {
                                            Text(reference)
                                                .font(.caption)
                                                .foregroundColor(themeManager.accentColor)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Text("\(prayer.duration)m")
                                        .font(.caption)
                                        .foregroundColor(themeManager.secondaryTextColor)
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(themeManager.secondaryTextColor)
                                }
                                .padding()
                                .background(themeManager.cardBackgroundColor)
                                .cornerRadius(14)
                            }
                            .buttonStyle(TilePressStyle())
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .navigationTitle(category.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $selectedSuggestion) { suggestion in
                SuggestionDetailSheet(suggestion: suggestion)
            }
        }
    }
}

// MARK: - Prayer Row

struct PrayerRow: View {
    let prayer: SavedPrayer
    let onTap: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(prayer.title)
                            .font(.headline)
                            .foregroundColor(themeManager.textColor)
                        
                        if prayer.isFavorite {
                            Image(systemName: "heart.fill")
                                .font(.caption)
                                .foregroundColor(.pink)
                        }
                    }
                    
                    if let reference = prayer.sourceVerseReference {
                        Text(reference)
                            .font(.caption)
                            .foregroundColor(themeManager.accentColor)
                    }
                    
                    Text(prayer.content)
                        .font(.subheadline)
                        .foregroundColor(themeManager.secondaryTextColor)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.hubElevatedSurface)
                    .shadow(color: themeManager.hubShadowColor, radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(TilePressStyle())
    }
}

// MARK: - Collection Row

struct CollectionRow: View {
    let collection: PrayerCollection
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(collection.collectionType.color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: collection.icon)
                    .font(.title3)
                    .foregroundColor(collection.collectionType.color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(collection.name)
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
                
                Text("\(collection.prayerCount) prayer\(collection.prayerCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(themeManager.secondaryTextColor)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.hubElevatedSurface)
                .shadow(color: themeManager.hubShadowColor, radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - New Prayer Sheet

struct NewPrayerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var storageService = HubStorageService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    
    @State private var title = ""
    @State private var content = ""
    @State private var sourceReference = ""
    @State private var sourceText = ""
    @State private var tags = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Prayer Details
                    ThemedCard {
                        VStack(alignment: .leading, spacing: 16) {
                            ThemedSectionHeader(title: "Prayer Details", icon: "pencil", iconColor: .blue)
                            
                            ThemedTextField(placeholder: "Title", text: $title, icon: "text.alignleft")
                            ThemedTextEditor(placeholder: "Write your prayer...", text: $content, minHeight: 120)
                        }
                    }
                    
                    // Source Scripture
                    ThemedCard {
                        VStack(alignment: .leading, spacing: 16) {
                            ThemedSectionHeader(title: "Source Scripture (Optional)", icon: "book.fill", iconColor: ThemeManager.shared.accentColor)
                            
                            ThemedTextField(placeholder: "Reference (e.g., Psalm 23:1)", text: $sourceReference, icon: "bookmark")
                            ThemedTextEditor(placeholder: "Verse text", text: $sourceText, minHeight: 60)
                        }
                    }
                    
                    // Tags
                    ThemedCard {
                        VStack(alignment: .leading, spacing: 12) {
                            ThemedSectionHeader(title: "Tags (Optional)", icon: "tag", iconColor: .orange)
                            
                            ThemedTextField(placeholder: "morning, peace, family", text: $tags, icon: "tag")
                            
                            Text("Separate tags with commas")
                                .font(.caption)
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                    }
                    
                    ThemedPrimaryButton(title: "Save Prayer", icon: "checkmark.circle.fill") {
                        savePrayer()
                    }
                    .opacity(title.isEmpty || content.isEmpty ? 0.5 : 1.0)
                    .disabled(title.isEmpty || content.isEmpty)
                }
                .padding()
            }
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .navigationTitle("New Prayer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(themeManager.accentColor)
                }
            }
        }
    }
    
    private func savePrayer() {
        let tagArray = tags.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
        
        let prayer = SavedPrayer(
            title: title,
            content: content,
            sourceVerseReference: sourceReference.isEmpty ? nil : sourceReference,
            sourceVerseText: sourceText.isEmpty ? nil : sourceText,
            tags: tagArray
        )
        
        storageService.addSavedPrayer(prayer)
        dismiss()
    }
}

// MARK: - New Collection Sheet

struct NewCollectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var storageService = HubStorageService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    
    @State private var name = ""
    @State private var selectedType: PrayerCollectionType = .custom
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    ThemedCard {
                        VStack(alignment: .leading, spacing: 16) {
                            ThemedSectionHeader(title: "Collection Name", icon: "folder", iconColor: .blue)
                            ThemedTextField(placeholder: "Name", text: $name, icon: "text.alignleft")
                        }
                    }
                    
                    ThemedCard {
                        VStack(alignment: .leading, spacing: 16) {
                            ThemedSectionHeader(title: "Type", icon: "tag", iconColor: ThemeManager.shared.accentColor)
                            
                            ForEach(PrayerCollectionType.allCases) { type in
                                Button {
                                    selectedType = type
                                } label: {
                                    HStack {
                                        Image(systemName: type.icon)
                                            .foregroundColor(type.color)
                                            .frame(width: 30)
                                        
                                        Text(type.rawValue)
                                            .foregroundColor(themeManager.textColor)
                                        
                                        Spacer()
                                        
                                        if selectedType == type {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(themeManager.accentColor)
                                        }
                                    }
                                    .padding(.vertical, 8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    ThemedPrimaryButton(title: "Create Collection", icon: "plus.circle.fill") {
                        createCollection()
                    }
                    .opacity(name.isEmpty ? 0.5 : 1.0)
                    .disabled(name.isEmpty)
                }
                .padding()
            }
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .navigationTitle("New Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(themeManager.accentColor)
                }
            }
        }
    }
    
    private func createCollection() {
        let collection = PrayerCollection(
            name: name,
            collectionType: selectedType
        )
        storageService.createCollection(collection)
        dismiss()
    }
}

// MARK: - Prayer Detail Sheet

struct PrayerDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var storageService = HubStorageService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    let prayer: SavedPrayer
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(prayer.title)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(themeManager.textColor)
                            
                            Spacer()
                            
                            Button {
                                storageService.togglePrayerFavorite(prayer)
                            } label: {
                                Image(systemName: prayer.isFavorite ? "heart.fill" : "heart")
                                    .font(.title2)
                                    .foregroundColor(prayer.isFavorite ? .pink : themeManager.secondaryTextColor)
                            }
                        }
                        
                        if let reference = prayer.sourceVerseReference {
                            Text(reference)
                                .font(.subheadline)
                                .foregroundColor(themeManager.accentColor)
                        }
                    }
                    
                    // Source verse if present
                    if let verseText = prayer.sourceVerseText {
                        ThemedCard {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Scripture")
                                    .font(.caption)
                                    .foregroundColor(themeManager.secondaryTextColor)
                                
                                Text("\"\(verseText)\"")
                                    .font(.body)
                                    .foregroundColor(themeManager.textColor)
                                    .italic()
                            }
                        }
                    }
                    
                    // Prayer content
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Prayer")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                        
                        Text(prayer.content)
                            .font(.body)
                            .foregroundColor(themeManager.textColor)
                            .lineSpacing(6)
                    }
                    
                    // Tags
                    if !prayer.tags.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tags")
                                .font(.caption)
                                .foregroundColor(themeManager.secondaryTextColor)
                            
                            FlowLayout(spacing: 8) {
                                ForEach(prayer.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .foregroundColor(themeManager.accentColor)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(themeManager.accentColor.opacity(0.15))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                    
                    // Usage stats
                    HStack {
                        Label("\(prayer.usageCount) uses", systemImage: "clock")
                        Spacer()
                        if let lastUsed = prayer.lastUsedAt {
                            Text("Last: \(lastUsed, style: .relative) ago")
                        }
                    }
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
                    
                    // Actions
                    HStack(spacing: 12) {
                        ThemedPrimaryButton(title: "Pray Now", icon: "hands.sparkles") {
                            storageService.recordPrayerUsage(prayer)
                        }
                        
                        ShareLink(item: prayer.content) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share")
                            }
                            .font(.headline)
                            .foregroundColor(themeManager.accentColor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(themeManager.accentColor.opacity(0.12))
                            .cornerRadius(14)
                        }
                    }
                }
                .padding()
            }
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .navigationTitle("Prayer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(themeManager.accentColor)
                }
            }
        }
    }
}

// MARK: - Collection Detail View

struct CollectionDetailView: View {
    @ObservedObject private var storageService = HubStorageService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    let collection: PrayerCollection
    @State private var selectedPrayer: SavedPrayer?
    
    var prayers: [SavedPrayer] {
        storageService.getPrayersInCollection(collection.id)
    }
    
    var body: some View {
        Group {
            if prayers.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "folder")
                        .font(.system(size: 48))
                        .foregroundColor(themeManager.secondaryTextColor.opacity(0.5))
                    
                    Text("Empty Collection")
                        .font(.headline)
                        .foregroundColor(themeManager.textColor)
                    
                    Text("Add prayers from your library to this collection")
                        .font(.subheadline)
                        .foregroundColor(themeManager.secondaryTextColor)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(prayers) { prayer in
                            PrayerRow(prayer: prayer) {
                                selectedPrayer = prayer
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .background(themeManager.backgroundColor.ignoresSafeArea())
        .navigationTitle(collection.name)
        .sheet(item: $selectedPrayer) { prayer in
            PrayerDetailSheet(prayer: prayer)
        }
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return CGSize(width: proposal.width ?? 0, height: result.height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, row) in result.rows.enumerated() {
            for (itemIndex, item) in row.enumerated() {
                let x = result.positions[index][itemIndex]
                let y = result.yOffsets[index]
                item.place(at: CGPoint(x: bounds.minX + x, y: bounds.minY + y), proposal: .unspecified)
            }
        }
    }
    
    struct FlowResult {
        var rows: [[LayoutSubviews.Element]] = []
        var positions: [[CGFloat]] = []
        var yOffsets: [CGFloat] = []
        var height: CGFloat = 0
        
        init(in width: CGFloat, subviews: LayoutSubviews, spacing: CGFloat) {
            var currentRow: [LayoutSubviews.Element] = []
            var currentPositions: [CGFloat] = []
            var x: CGFloat = 0
            var y: CGFloat = 0
            var maxHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > width && !currentRow.isEmpty {
                    rows.append(currentRow)
                    positions.append(currentPositions)
                    yOffsets.append(y)
                    
                    y += maxHeight + spacing
                    currentRow = []
                    currentPositions = []
                    x = 0
                    maxHeight = 0
                }
                
                currentRow.append(subview)
                currentPositions.append(x)
                x += size.width + spacing
                maxHeight = max(maxHeight, size.height)
            }
            
            if !currentRow.isEmpty {
                rows.append(currentRow)
                positions.append(currentPositions)
                yOffsets.append(y)
                height = y + maxHeight
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PrayerLibraryView()
    }
}
