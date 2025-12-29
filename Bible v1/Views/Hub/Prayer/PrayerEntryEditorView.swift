//
//  PrayerEntryEditorView.swift
//  Bible v1
//
//  Prayer Entry Editor - Create and edit prayers
//

import SwiftUI

struct PrayerEntryEditorView: View {
    @ObservedObject var viewModel: HubViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    let prayer: PrayerEntry?
    
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var selectedCategory: PrayerCategory = .other
    @State private var linkedVerseReference: String = ""
    @State private var linkedVerseText: String = ""
    @State private var showCategoryPicker = false
    
    private var isEditing: Bool { prayer != nil }
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Title field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Title")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(themeManager.secondaryTextColor)
                            
                            TextField("What are you praying for?", text: $title)
                                .font(.body)
                                .padding()
                                .background(themeManager.cardBackgroundColor)
                                .cornerRadius(10)
                        }
                        
                        // Category picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Category")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(themeManager.secondaryTextColor)
                            
                            Button {
                                showCategoryPicker = true
                            } label: {
                                HStack {
                                    Image(systemName: selectedCategory.icon)
                                        .foregroundColor(categoryColor)
                                    Text(selectedCategory.rawValue)
                                        .foregroundColor(themeManager.textColor)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                        .foregroundColor(themeManager.secondaryTextColor)
                                }
                                .padding()
                                .background(themeManager.cardBackgroundColor)
                                .cornerRadius(10)
                            }
                        }
                        
                        // Content field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Prayer")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(themeManager.secondaryTextColor)
                            
                            TextEditor(text: $content)
                                .frame(minHeight: 150)
                                .padding(8)
                                .background(themeManager.cardBackgroundColor)
                                .cornerRadius(10)
                                .scrollContentBackground(.hidden)
                            
                            Text("Write your prayer, request, or thoughts...")
                                .font(.caption)
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                        
                        // Linked verse (optional)
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Link a Verse (Optional)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(themeManager.secondaryTextColor)
                                
                                Spacer()
                                
                                if !linkedVerseReference.isEmpty {
                                    Button {
                                        linkedVerseReference = ""
                                        linkedVerseText = ""
                                    } label: {
                                        Text("Clear")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                            
                            TextField("e.g., John 3:16", text: $linkedVerseReference)
                                .font(.body)
                                .padding()
                                .background(themeManager.cardBackgroundColor)
                                .cornerRadius(10)
                            
                            if !linkedVerseReference.isEmpty {
                                TextField("Verse text (optional)", text: $linkedVerseText)
                                    .font(.subheadline)
                                    .padding()
                                    .background(themeManager.cardBackgroundColor)
                                    .cornerRadius(10)
                            }
                        }
                        
                        // Scripture prompts
                        if !isEditing {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Scripture for \(selectedCategory.rawValue)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(themeManager.secondaryTextColor)
                                
                                ForEach(scripturePrompts, id: \.0) { prompt in
                                    Button {
                                        linkedVerseReference = prompt.0
                                        linkedVerseText = prompt.1
                                    } label: {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(prompt.0)
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .foregroundColor(themeManager.accentColor)
                                            Text(prompt.1)
                                                .font(.caption)
                                                .foregroundColor(themeManager.secondaryTextColor)
                                                .lineLimit(2)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(10)
                                        .background(
                                            linkedVerseReference == prompt.0 ? themeManager.accentColor.opacity(0.15) : themeManager.cardBackgroundColor
                                        )
                                        .cornerRadius(8)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(isEditing ? "Edit Prayer" : "New Prayer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        savePrayer()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.isEmpty || content.isEmpty)
                }
            }
            .sheet(isPresented: $showCategoryPicker) {
                CategoryPickerSheet(selectedCategory: $selectedCategory)
            }
            .onAppear {
                if let prayer = prayer {
                    title = prayer.title
                    content = prayer.content
                    selectedCategory = prayer.category
                    linkedVerseReference = prayer.linkedVerseReference ?? ""
                    linkedVerseText = prayer.linkedVerseText ?? ""
                }
            }
        }
    }
    
    private var categoryColor: Color {
        switch selectedCategory {
        case .gratitude: return .pink
        case .repentance: return .teal
        case .guidance: return .blue
        case .anxiety: return .teal
        case .family: return .orange
        case .work: return .brown
        case .health: return .green
        case .relationships: return .red
        case .other: return .gray
        }
    }
    
    private var scripturePrompts: [(String, String)] {
        switch selectedCategory {
        case .gratitude:
            return [
                ("1 Thessalonians 5:18", "Give thanks in all circumstances; for this is God's will for you in Christ Jesus."),
                ("Psalm 107:1", "Give thanks to the Lord, for he is good; his love endures forever.")
            ]
        case .repentance:
            return [
                ("1 John 1:9", "If we confess our sins, he is faithful and just and will forgive us our sins."),
                ("Psalm 51:10", "Create in me a pure heart, O God, and renew a steadfast spirit within me.")
            ]
        case .guidance:
            return [
                ("Proverbs 3:5-6", "Trust in the Lord with all your heart and lean not on your own understanding."),
                ("James 1:5", "If any of you lacks wisdom, you should ask God, who gives generously.")
            ]
        case .anxiety:
            return [
                ("Philippians 4:6-7", "Do not be anxious about anything, but in every situation, by prayer and petition, with thanksgiving, present your requests to God."),
                ("1 Peter 5:7", "Cast all your anxiety on him because he cares for you.")
            ]
        case .family:
            return [
                ("Joshua 24:15", "As for me and my household, we will serve the Lord."),
                ("Proverbs 22:6", "Start children off on the way they should go, and even when they are old they will not turn from it.")
            ]
        case .work:
            return [
                ("Colossians 3:23", "Whatever you do, work at it with all your heart, as working for the Lord."),
                ("Proverbs 16:3", "Commit to the Lord whatever you do, and he will establish your plans.")
            ]
        case .health:
            return [
                ("Jeremiah 17:14", "Heal me, Lord, and I will be healed; save me and I will be saved."),
                ("3 John 1:2", "Dear friend, I pray that you may enjoy good health.")
            ]
        case .relationships:
            return [
                ("Colossians 3:13", "Bear with each other and forgive one another if any of you has a grievance."),
                ("1 Corinthians 13:4", "Love is patient, love is kind. It does not envy, it does not boast.")
            ]
        case .other:
            return [
                ("Jeremiah 29:12", "Then you will call on me and come and pray to me, and I will listen to you."),
                ("Matthew 7:7", "Ask and it will be given to you; seek and you will find.")
            ]
        }
    }
    
    private func savePrayer() {
        if var existingPrayer = prayer {
            existingPrayer.update(title: title, content: content, category: selectedCategory)
            existingPrayer.linkedVerseReference = linkedVerseReference.isEmpty ? nil : linkedVerseReference
            existingPrayer.linkedVerseText = linkedVerseText.isEmpty ? nil : linkedVerseText
            viewModel.updatePrayer(existingPrayer)
        } else {
            viewModel.addPrayer(
                title: title,
                content: content,
                category: selectedCategory,
                linkedVerse: linkedVerseReference.isEmpty ? nil : (linkedVerseReference, linkedVerseText)
            )
        }
        dismiss()
    }
}

// MARK: - Category Picker Sheet

struct CategoryPickerSheet: View {
    @Binding var selectedCategory: PrayerCategory
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor.ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(PrayerCategory.allCases) { category in
                            Button {
                                selectedCategory = category
                                dismiss()
                            } label: {
                                HStack {
                                    Image(systemName: category.icon)
                                        .font(.title3)
                                        .foregroundColor(colorFor(category))
                                        .frame(width: 40)
                                    
                                    Text(category.rawValue)
                                        .font(.body)
                                        .foregroundColor(themeManager.textColor)
                                    
                                    Spacer()
                                    
                                    if category == selectedCategory {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(themeManager.accentColor)
                                    }
                                }
                                .padding()
                                .background(
                                    category == selectedCategory ? themeManager.accentColor.opacity(0.1) : themeManager.cardBackgroundColor
                                )
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Select Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func colorFor(_ category: PrayerCategory) -> Color {
        switch category {
        case .gratitude: return .pink
        case .repentance: return .teal
        case .guidance: return .blue
        case .anxiety: return .teal
        case .family: return .orange
        case .work: return .brown
        case .health: return .green
        case .relationships: return .red
        case .other: return .gray
        }
    }
}

#Preview {
    PrayerEntryEditorView(viewModel: HubViewModel(), prayer: nil)
}



