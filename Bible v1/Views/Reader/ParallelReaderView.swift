//
//  ParallelReaderView.swift
//  Bible v1
//
//  Advanced Bible Reader App
//

import SwiftUI

/// Parallel translation reading view
struct ParallelReaderView: View {
    @ObservedObject var viewModel: BibleViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    
    @State private var showSecondaryTranslationPicker = false
    @State private var displayMode: ParallelDisplayMode = .interleaved
    
    enum ParallelDisplayMode: String, CaseIterable {
        case sideBySide = "Side by Side"
        case interleaved = "Interleaved"
        
        var icon: String {
            switch self {
            case .sideBySide: return "rectangle.split.2x1"
            case .interleaved: return "rectangle.split.1x2"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Translation headers
                    translationHeaders
                    
                    Divider()
                        .background(themeManager.dividerColor)
                    
                    // Content
                    if viewModel.isLoadingChapter {
                        LoadingView("Loading...")
                    } else if let primaryChapter = viewModel.currentChapter {
                        if viewModel.secondaryTranslation == nil {
                            selectSecondaryPrompt
                        } else if displayMode == .sideBySide {
                            sideBySideView(primary: primaryChapter)
                        } else {
                            interleavedView(primary: primaryChapter)
                        }
                    } else {
                        EmptyStateView(
                            icon: "book.closed",
                            title: "No Chapter Selected",
                            message: "Select a chapter in the Read tab to compare translations"
                        )
                    }
                }
            }
            .navigationTitle("Compare")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Display Mode", selection: $displayMode) {
                            ForEach(ParallelDisplayMode.allCases, id: \.self) { mode in
                                Label(mode.rawValue, systemImage: mode.icon)
                                    .tag(mode)
                            }
                        }
                    } label: {
                        Image(systemName: displayMode.icon)
                    }
                }
            }
            .sheet(isPresented: $showSecondaryTranslationPicker) {
                SecondaryTranslationPicker(viewModel: viewModel)
            }
        }
    }
    
    private var selectSecondaryPrompt: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "rectangle.split.2x1")
                .font(.system(size: 56))
                .foregroundColor(themeManager.secondaryTextColor.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("Compare Translations")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.textColor)
                
                Text("Select a second translation to compare with \(viewModel.selectedTranslation?.id ?? "the current translation")")
                    .font(.body)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button {
                showSecondaryTranslationPicker = true
            } label: {
                Text("Select Translation")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(themeManager.accentColor)
                    .cornerRadius(25)
            }
            
            Spacer()
        }
    }
    
    private var translationHeaders: some View {
        HStack(spacing: 0) {
            // Primary translation
            VStack(spacing: 4) {
                Text(viewModel.selectedTranslation?.id ?? "Primary")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.textColor)
                
                Text(viewModel.currentReference)
                    .font(.caption2)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(themeManager.accentColor.opacity(0.1))
            
            Divider()
                .background(themeManager.dividerColor)
            
            // Secondary translation
            Button {
                showSecondaryTranslationPicker = true
            } label: {
                VStack(spacing: 4) {
                    if let secondary = viewModel.secondaryTranslation {
                        Text(secondary.id)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.textColor)
                    } else {
                        Text("Select Translation")
                            .font(.caption)
                            .foregroundColor(themeManager.accentColor)
                    }
                    
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(themeManager.cardBackgroundColor)
            }
            .buttonStyle(.plain)
        }
    }
    
    @ViewBuilder
    private func sideBySideView(primary: Chapter) -> some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Primary column
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(primary.verses) { verse in
                            VerseRow(
                                verse: verse,
                                isRTL: viewModel.selectedTranslation?.isRTL ?? false
                            )
                            .id("primary-\(verse.verse)")
                        }
                    }
                }
                .frame(width: geometry.size.width / 2)
                
                Divider()
                    .background(themeManager.dividerColor)
                
                // Secondary column
                ScrollView {
                    LazyVStack(spacing: 0) {
                        if let secondary = viewModel.secondaryChapter {
                            ForEach(secondary.verses) { verse in
                                VerseRow(
                                    verse: verse,
                                    isRTL: viewModel.secondaryTranslation?.isRTL ?? false
                                )
                                .id("secondary-\(verse.verse)")
                            }
                        }
                    }
                }
                .frame(width: geometry.size.width / 2)
            }
        }
    }
    
    @ViewBuilder
    private func interleavedView(primary: Chapter) -> some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(primary.verses) { verse in
                    VStack(alignment: .leading, spacing: 12) {
                        // Verse number header
                        Text("Verse \(verse.verse)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.accentColor)
                            .padding(.horizontal, 4)
                        
                        // Primary text
                        VStack(alignment: .leading, spacing: 6) {
                            Text(viewModel.selectedTranslation?.id ?? "")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(themeManager.secondaryTextColor)
                            
                            Text(verse.text)
                                .font(themeManager.verseFont)
                                .foregroundColor(themeManager.textColor)
                                .lineSpacing(themeManager.lineSpacing)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(themeManager.cardBackgroundColor)
                        .cornerRadius(10)
                        
                        // Secondary text
                        if let secondary = viewModel.secondaryChapter,
                           let secondaryVerse = secondary.verses.first(where: { $0.verse == verse.verse }) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(viewModel.secondaryTranslation?.id ?? "")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(themeManager.secondaryTextColor)
                                
                                Text(secondaryVerse.text)
                                    .font(themeManager.verseFont)
                                    .foregroundColor(themeManager.textColor)
                                    .lineSpacing(themeManager.lineSpacing)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(themeManager.accentColor.opacity(0.08))
                            .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
}

/// Picker for secondary translation
struct SecondaryTranslationPicker: View {
    @ObservedObject var viewModel: BibleViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    
    private var filteredTranslations: [Translation] {
        if searchText.isEmpty {
            return viewModel.translations.filter { $0.id != viewModel.selectedTranslation?.id }
        }
        return viewModel.searchTranslations(searchText)
            .filter { $0.id != viewModel.selectedTranslation?.id }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // Clear selection option
                        if viewModel.secondaryTranslation != nil {
                            Button {
                                Task {
                                    await viewModel.setSecondaryTranslation(nil)
                                    dismiss()
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "xmark.circle")
                                        .foregroundColor(.red)
                                    Text("Clear Selection")
                                        .foregroundColor(.red)
                                    Spacer()
                                }
                                .padding()
                                .background(themeManager.cardBackgroundColor)
                            }
                            .padding(.horizontal)
                            .padding(.top)
                        }
                        
                        ForEach(filteredTranslations) { translation in
                            TranslationRowThemed(
                                translation: translation,
                                isSelected: translation.id == viewModel.secondaryTranslation?.id,
                                themeManager: themeManager
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                Task {
                                    await viewModel.setSecondaryTranslation(translation)
                                    dismiss()
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Compare With")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search translations")
        }
    }
}

#Preview {
    ParallelReaderView(viewModel: BibleViewModel())
}
