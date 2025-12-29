//
//  TranslationPicker.swift
//  Bible v1
//
//  Advanced Bible Reader App
//

import SwiftUI

/// A picker for selecting Bible translations
struct TranslationPicker: View {
    @ObservedObject var viewModel: BibleViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var selectedLanguage: String?
    
    private var filteredTranslations: [Translation] {
        var translations = viewModel.translations
        
        // Filter by language if selected
        if let language = selectedLanguage {
            translations = translations.filter { $0.language == language }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            translations = viewModel.searchTranslations(searchText)
        }
        
        return translations
    }
    
    private var groupedTranslations: [String: [Translation]] {
        Dictionary(grouping: filteredTranslations) { $0.language }
    }
    
    private var sortedLanguages: [String] {
        groupedTranslations.keys.sorted()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor
                    .ignoresSafeArea()
                
                Group {
                    if viewModel.isLoadingTranslations {
                        LoadingView("Loading translations...")
                    } else {
                        translationList
                    }
                }
            }
            .navigationTitle("Select Translation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                if selectedLanguage != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("All Languages") {
                            selectedLanguage = nil
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search translations")
        }
    }
    
    private var translationList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Recent translations section
                if !viewModel.translations.isEmpty && searchText.isEmpty && selectedLanguage == nil {
                    recentTranslationsSection
                }
                
                // Language filter chips
                if selectedLanguage == nil && searchText.isEmpty {
                    languageFilterSection
                }
                
                // All translations by language
                ForEach(sortedLanguages, id: \.self) { language in
                    VStack(alignment: .leading, spacing: 0) {
                        // Section header
                        Text(languageDisplayName(language))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(themeManager.secondaryTextColor)
                            .padding(.horizontal, 20)
                            .padding(.top, 24)
                            .padding(.bottom, 8)
                        
                        // Translations
                        ForEach(groupedTranslations[language] ?? []) { translation in
                            TranslationRowThemed(
                                translation: translation,
                                isSelected: translation.id == viewModel.selectedTranslation?.id,
                                themeManager: themeManager
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectTranslation(translation)
                            }
                        }
                    }
                }
                
                // Bottom padding
                Color.clear.frame(height: 40)
            }
        }
    }
    
    private var recentTranslationsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Recent")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.secondaryTextColor)
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 8)
            
            let recentIds = StorageService.shared.getRecentTranslations()
            ForEach(recentIds.prefix(3), id: \.self) { id in
                if let translation = viewModel.translations.first(where: { $0.id == id }) {
                    TranslationRowThemed(
                        translation: translation,
                        isSelected: translation.id == viewModel.selectedTranslation?.id,
                        themeManager: themeManager
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectTranslation(translation)
                    }
                }
            }
        }
    }
    
    private var languageFilterSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Filter by Language")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.secondaryTextColor)
                .padding(.horizontal, 20)
                .padding(.top, 16)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(popularLanguages, id: \.self) { language in
                        Button {
                            selectedLanguage = language
                        } label: {
                            Text(languageDisplayName(language))
                                .font(.subheadline)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(themeManager.accentColor.opacity(0.15))
                                .foregroundColor(themeManager.accentColor)
                                .cornerRadius(20)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private var popularLanguages: [String] {
        // Return most common languages
        let languageCounts = Dictionary(grouping: viewModel.translations) { $0.language }
            .mapValues { $0.count }
        
        return languageCounts
            .sorted { $0.value > $1.value }
            .prefix(10)
            .map { $0.key }
    }
    
    private func languageDisplayName(_ code: String) -> String {
        let locale = Locale(identifier: "en")
        return locale.localizedString(forLanguageCode: code) ?? code
    }
    
    private func selectTranslation(_ translation: Translation) {
        Task {
            await viewModel.selectTranslation(translation)
            dismiss()
        }
    }
}

/// A themed row displaying a translation
struct TranslationRowThemed: View {
    let translation: Translation
    let isSelected: Bool
    let themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(translation.name)
                    .font(.headline)
                    .foregroundColor(isSelected ? themeManager.accentColor : themeManager.textColor)
                
                if let englishName = translation.englishName, englishName != translation.name {
                    Text(englishName)
                        .font(.subheadline)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                
                HStack(spacing: 8) {
                    Text(translation.id)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(themeManager.accentColor.opacity(0.1))
                        .foregroundColor(themeManager.accentColor)
                        .cornerRadius(4)
                    
                    if translation.isRTL {
                        Label("RTL", systemImage: "arrow.left")
                            .font(.caption2)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                }
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(themeManager.accentColor)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(isSelected ? themeManager.accentColor.opacity(0.08) : Color.clear)
    }
}

// Keep old TranslationRow for backward compatibility
struct TranslationRow: View {
    let translation: Translation
    let isSelected: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(translation.name)
                    .font(.headline)
                
                if let englishName = translation.englishName, englishName != translation.name {
                    Text(englishName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 8) {
                    Text(translation.id)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if translation.isRTL {
                        Label("RTL", systemImage: "arrow.left")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.accentColor)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    TranslationPicker(viewModel: BibleViewModel())
}
