//
//  PromptCarousel.swift
//  Bible v1
//
//  Spiritual Journal - Prompt Components
//

import SwiftUI

/// Prompt picker sheet
struct PromptPickerSheet: View {
    @Binding var selectedPrompt: JournalPrompt?
    let prompts: [JournalPrompt]
    let onSelect: (JournalPrompt) -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedCategory: PromptCategory = .reflection
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Category tabs
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(PromptCategory.allCases) { category in
                                CategoryTab(
                                    category: category,
                                    isSelected: selectedCategory == category,
                                    themeManager: themeManager
                                ) {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedCategory = category
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 12)
                    
                    Divider()
                    
                    // Prompts list
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredPrompts) { prompt in
                                PromptCard(
                                    prompt: prompt,
                                    isSelected: selectedPrompt?.id == prompt.id,
                                    themeManager: themeManager
                                ) {
                                    selectedPrompt = prompt
                                    onSelect(prompt)
                                    dismiss()
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Prompts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var filteredPrompts: [JournalPrompt] {
        prompts.filter { $0.category == selectedCategory }
    }
}

/// Prompt browser view (full page)
struct PromptBrowserView: View {
    @ObservedObject var viewModel: JournalViewModel
    @Binding var showingNewEntry: Bool
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedCategory: PromptCategory?
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Today's prompt highlight
                        todaysPromptCard
                        
                        // Categories
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Browse by Category")
                                .font(.headline)
                                .foregroundColor(themeManager.textColor)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)
                            ], spacing: 12) {
                                ForEach(PromptCategory.allCases) { category in
                                    CategoryCard(
                                        category: category,
                                        promptCount: viewModel.prompts(for: category).count,
                                        themeManager: themeManager
                                    ) {
                                        selectedCategory = category
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Prompts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedCategory) { category in
                CategoryPromptsSheet(
                    category: category,
                    prompts: viewModel.prompts(for: category),
                    onSelect: { prompt in
                        viewModel.startNewEntry(withPrompt: prompt)
                        dismiss()
                        showingNewEntry = true
                    }
                )
            }
        }
    }
    
    private var todaysPromptCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(themeManager.accentColor)
                Text("Today's Prompt")
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
            }
            
            let prompt = viewModel.todaysPrompt
            
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: prompt.category.icon)
                        .font(.caption)
                    Text(prompt.category.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(prompt.category.color)
                
                Text(prompt.text)
                    .font(.body)
                    .foregroundColor(themeManager.textColor)
                
                if let verse = prompt.relatedVerse, let ref = prompt.relatedVerseReference {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(verse)
                            .font(.caption)
                            .italic()
                            .foregroundColor(themeManager.secondaryTextColor)
                        
                        Text("— \(ref)")
                            .font(.caption2)
                            .foregroundColor(themeManager.accentColor)
                    }
                    .padding(.top, 4)
                }
                
                Button {
                    viewModel.startNewEntry(withPrompt: prompt)
                    dismiss()
                    showingNewEntry = true
                } label: {
                    HStack {
                        Image(systemName: "pencil.line")
                        Text("Start with this prompt")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [prompt.category.color, prompt.category.color.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .padding(.top, 8)
            }
            .padding()
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(16)
        }
        .padding(.horizontal)
    }
}

/// Category tab button
struct CategoryTab: View {
    let category: PromptCategory
    let isSelected: Bool
    let themeManager: ThemeManager
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.caption)
                Text(category.displayName)
                    .font(.subheadline)
            }
            .foregroundColor(isSelected ? .white : themeManager.textColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? category.color : themeManager.cardBackgroundColor)
            )
        }
        .buttonStyle(.plain)
    }
}

/// Category card for browsing
struct CategoryCard: View {
    let category: PromptCategory
    let promptCount: Int
    let themeManager: ThemeManager
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: category.icon)
                        .font(.title2)
                        .foregroundColor(category.color)
                    
                    Spacer()
                    
                    Text("\(promptCount)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.secondaryTextColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(themeManager.backgroundColor)
                        .cornerRadius(8)
                }
                
                Text(category.displayName)
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
                
                Text(category.description)
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .lineLimit(2)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

/// Individual prompt card
struct PromptCard: View {
    let prompt: JournalPrompt
    let isSelected: Bool
    let themeManager: ThemeManager
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                Text(prompt.text)
                    .font(.subheadline)
                    .foregroundColor(themeManager.textColor)
                    .multilineTextAlignment(.leading)
                
                if let verse = prompt.relatedVerse {
                    Text(verse)
                        .font(.caption)
                        .italic()
                        .foregroundColor(themeManager.secondaryTextColor)
                        .lineLimit(2)
                }
                
                if let ref = prompt.relatedVerseReference {
                    Text("— \(ref)")
                        .font(.caption2)
                        .foregroundColor(themeManager.accentColor)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.cardBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? prompt.category.color : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

/// Sheet showing prompts for a specific category
struct CategoryPromptsSheet: View {
    let category: PromptCategory
    let prompts: [JournalPrompt]
    let onSelect: (JournalPrompt) -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 12) {
                        // Category header
                        HStack(spacing: 12) {
                            Image(systemName: category.icon)
                                .font(.title)
                                .foregroundColor(category.color)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(category.displayName)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(themeManager.textColor)
                                
                                Text(category.description)
                                    .font(.caption)
                                    .foregroundColor(themeManager.secondaryTextColor)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(category.color.opacity(0.1))
                        .cornerRadius(16)
                        
                        // Prompts
                        ForEach(prompts) { prompt in
                            PromptCard(
                                prompt: prompt,
                                isSelected: false,
                                themeManager: themeManager
                            ) {
                                onSelect(prompt)
                                dismiss()
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(category.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// PromptCategory already conforms to Identifiable via JournalPrompt.swift

#Preview("Prompt Browser") {
    PromptBrowserView(viewModel: JournalViewModel(), showingNewEntry: .constant(false))
}

