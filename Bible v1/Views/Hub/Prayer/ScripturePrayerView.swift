//
//  ScripturePrayerView.swift
//  Bible v1
//
//  Spiritual Hub - Scripture-backed Prayer Generator (Theme-aware)
//

import SwiftUI

struct ScripturePrayerView: View {
    @ObservedObject private var storageService = HubStorageService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var selectedTemplate: QuickPrayerTemplate?
    @State private var customVerse = ""
    @State private var customReference = ""
    @State private var selectedType: PrayerTemplateType = .praise
    @State private var showGeneratedPrayer = false
    @State private var generatedPrayer: ScripturePrayer?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                // Header section
                headerSection
                
                // Quick templates
                quickTemplatesSection
                
                // Custom verse section
                customVerseSection
                
                // Recent generated prayers
                recentPrayersSection
            }
            .padding()
        }
        .navigationTitle("Scripture Prayers")
        .navigationBarTitleDisplayMode(.large)
        .background(themeManager.backgroundColor.ignoresSafeArea())
        .sheet(isPresented: $showGeneratedPrayer) {
            if let prayer = generatedPrayer {
                GeneratedPrayerSheet(prayer: prayer)
            }
        }
    }
    
    private var headerSection: some View {
        ThemedCard {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.indigo.opacity(0.15))
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.indigo)
                }
                
                Text("Turn Scripture into Prayer")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.textColor)
                
                Text("Select a verse or enter your own to generate a personalized prayer")
                    .font(.subheadline)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private var quickTemplatesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            ThemedSectionHeader(title: "Quick Templates", icon: "sparkles", iconColor: ThemeManager.shared.accentColor)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(QuickPrayerTemplate.templates) { template in
                    QuickTemplateCard(template: template) {
                        generatePrayer(from: template)
                    }
                }
            }
        }
    }
    
    private var customVerseSection: some View {
        ThemedCard {
            VStack(alignment: .leading, spacing: 16) {
                ThemedSectionHeader(title: "Create from Your Verse", icon: "pencil", iconColor: .blue)
                
                ThemedTextField(placeholder: "Verse Reference (e.g., John 3:16)", text: $customReference, icon: "bookmark")
                
                ThemedTextEditor(placeholder: "Enter the verse text...", text: $customVerse, minHeight: 80)
                
                // Prayer type picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Prayer Type")
                        .font(.subheadline)
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(PrayerTemplateType.allCases) { type in
                                PrayerTypeChip(
                                    type: type,
                                    isSelected: selectedType == type
                                ) {
                                    selectedType = type
                                }
                            }
                        }
                    }
                }
                
                ThemedPrimaryButton(title: "Generate Prayer", icon: "sparkles") {
                    generateCustomPrayer()
                }
                .opacity(customVerse.isEmpty || customReference.isEmpty ? 0.5 : 1.0)
                .disabled(customVerse.isEmpty || customReference.isEmpty)
            }
        }
    }
    
    private var recentPrayersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Prayers")
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
                Spacer()
                NavigationLink {
                    PrayerLibraryView()
                } label: {
                    Text("Library")
                        .font(.subheadline)
                        .foregroundColor(themeManager.accentColor)
                }
            }
            
            if storageService.scripturePrayers.isEmpty {
                ThemedEmptyState(
                    icon: "text.quote",
                    title: "No Prayers Yet",
                    message: "Generated prayers will appear here"
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(storageService.scripturePrayers.prefix(3)) { prayer in
                        RecentScripturePrayerRow(prayer: prayer) {
                            generatedPrayer = prayer
                            showGeneratedPrayer = true
                        }
                    }
                }
            }
        }
    }
    
    private func generatePrayer(from template: QuickPrayerTemplate) {
        let prayerText = ScripturePrayer.generatePrayer(
            from: template.suggestedVerse,
            reference: template.verseReference,
            type: template.templateType
        )
        
        let prayer = ScripturePrayer(
            verseReference: template.verseReference,
            verseText: template.suggestedVerse,
            prayerText: prayerText,
            templateType: template.templateType
        )
        
        storageService.addScripturePrayer(prayer)
        generatedPrayer = prayer
        showGeneratedPrayer = true
    }
    
    private func generateCustomPrayer() {
        let prayerText = ScripturePrayer.generatePrayer(
            from: customVerse,
            reference: customReference,
            type: selectedType
        )
        
        let prayer = ScripturePrayer(
            verseReference: customReference,
            verseText: customVerse,
            prayerText: prayerText,
            templateType: selectedType
        )
        
        storageService.addScripturePrayer(prayer)
        generatedPrayer = prayer
        showGeneratedPrayer = true
        
        // Clear inputs
        customVerse = ""
        customReference = ""
    }
}

// MARK: - Quick Template Card

struct QuickTemplateCard: View {
    let template: QuickPrayerTemplate
    let onTap: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: template.templateType.icon)
                    .font(.title2)
                    .foregroundColor(template.templateType.color)
                
                Text(template.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.textColor)
                
                Text(template.verseReference)
                    .font(.caption)
                    .foregroundColor(themeManager.accentColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
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

// MARK: - Prayer Type Chip

struct PrayerTypeChip: View {
    let type: PrayerTemplateType
    let isSelected: Bool
    let onTap: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: type.icon)
                    .font(.caption)
                Text(type.rawValue)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? type.color : themeManager.cardBackgroundColor)
            .foregroundColor(isSelected ? .white : themeManager.textColor)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Recent Scripture Prayer Row

struct RecentScripturePrayerRow: View {
    let prayer: ScripturePrayer
    let onTap: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(prayer.templateType.color.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: prayer.templateType.icon)
                        .font(.body)
                        .foregroundColor(prayer.templateType.color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(prayer.verseReference)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.textColor)
                    
                    Text(prayer.templateType.rawValue)
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
        .buttonStyle(TilePressStyle())
    }
}

// MARK: - Generated Prayer Sheet

struct GeneratedPrayerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var storageService = HubStorageService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    let prayer: ScripturePrayer
    
    @State private var showSaveOptions = false
    @State private var saveTitle = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(prayer.templateType.color.opacity(0.15))
                                .frame(width: 70, height: 70)
                            
                            Image(systemName: prayer.templateType.icon)
                                .font(.largeTitle)
                                .foregroundColor(prayer.templateType.color)
                        }
                        
                        Text(prayer.templateType.rawValue + " Prayer")
                            .font(.headline)
                            .foregroundColor(themeManager.textColor)
                        
                        Text("Based on \(prayer.verseReference)")
                            .font(.subheadline)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    .padding()
                    
                    // Scripture
                    ThemedCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Scripture")
                                .font(.caption)
                                .foregroundColor(themeManager.secondaryTextColor)
                            
                            Text("\"\(prayer.verseText)\"")
                                .font(.body)
                                .foregroundColor(themeManager.textColor)
                                .italic()
                            
                            Text("— \(prayer.verseReference)")
                                .font(.caption)
                                .foregroundColor(themeManager.accentColor)
                        }
                    }
                    
                    // Generated prayer
                    ThemedCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Prayer")
                                .font(.caption)
                                .foregroundColor(themeManager.secondaryTextColor)
                            
                            Text(prayer.prayerText)
                                .font(.body)
                                .foregroundColor(themeManager.textColor)
                                .lineSpacing(4)
                        }
                    }
                    
                    // Actions
                    HStack(spacing: 12) {
                        ThemedSecondaryButton(title: "Save to Library", icon: "bookmark") {
                            showSaveOptions = true
                        }
                        
                        ShareLink(
                            item: prayer.prayerText,
                            subject: Text("Prayer from \(prayer.verseReference)"),
                            message: Text("Based on \(prayer.verseReference)")
                        ) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share")
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(themeManager.accentColor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(themeManager.accentColor.opacity(0.12))
                            .cornerRadius(12)
                        }
                    }
                }
                .padding()
            }
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .navigationTitle("Your Prayer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(themeManager.accentColor)
                }
            }
            .alert("Save Prayer", isPresented: $showSaveOptions) {
                TextField("Prayer title", text: $saveTitle)
                Button("Save") {
                    let title = saveTitle.isEmpty ? "Prayer from \(prayer.verseReference)" : saveTitle
                    storageService.saveScripturePrayerToLibrary(prayer, title: title)
                    dismiss()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Give your prayer a name")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ScripturePrayerView()
    }
}
