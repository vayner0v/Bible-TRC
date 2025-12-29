//
//  VerseOfDayView.swift
//  Bible v1
//
//  Spiritual Hub - Enhanced Verse of the Day (Theme-aware)
//

import SwiftUI

struct VerseOfDayView: View {
    @ObservedObject private var storageService = HubStorageService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var todayVerse: VerseOfDayEntry?
    @State private var showReflectionSheet = false
    @State private var showMemorizeSheet = false
    @State private var showHistorySheet = false
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                // Today's verse card
                if let verse = todayVerse {
                    TodayVerseCard(
                        verse: verse,
                        onSave: { saveVerse() },
                        onReflect: { showReflectionSheet = true },
                        onMemorize: { showMemorizeSheet = true }
                    )
                }
                
                // Actions section
                actionsSection
                
                // Saved verses preview
                savedVersesSection
                
                // Memorized verses preview
                memorizedVersesSection
            }
            .padding()
        }
        .navigationTitle("Verse of the Day")
        .navigationBarTitleDisplayMode(.large)
        .background(themeManager.backgroundColor.ignoresSafeArea())
        .onAppear {
            loadTodayVerse()
        }
        .sheet(isPresented: $showReflectionSheet) {
            if let verse = todayVerse {
                ReflectionSheet(verse: verse)
            }
        }
        .sheet(isPresented: $showMemorizeSheet) {
            if let verse = todayVerse {
                MemorizeView(verseReference: verse.verseReference, verseText: verse.verseText)
            }
        }
        .sheet(isPresented: $showHistorySheet) {
            VerseHistorySheet()
        }
    }
    
    private func loadTodayVerse() {
        todayVerse = storageService.getOrCreateTodayVerse()
    }
    
    private func saveVerse() {
        guard var verse = todayVerse else { return }
        verse.toggleSaved()
        storageService.updateVerseOfDayEntry(verse)
        todayVerse = verse
    }
    
    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(themeManager.textColor)
            
            HStack(spacing: 12) {
                ActionButton(
                    title: "History",
                    icon: "clock.arrow.circlepath",
                    color: .blue
                ) {
                    showHistorySheet = true
                }
                
                if let verse = todayVerse {
                    ShareLink(
                        item: "\"\(verse.verseText)\"\n— \(verse.verseReference)",
                        subject: Text("Verse of the Day"),
                        message: Text(verse.verseReference)
                    ) {
                        VStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.title2)
                            Text("Share")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(0.15))
                        .foregroundColor(.green)
                        .cornerRadius(12)
                    }
                }
                
                ActionButton(
                    title: "Memorize",
                    icon: "brain.head.profile",
                    color: ThemeManager.shared.accentColor
                ) {
                    showMemorizeSheet = true
                }
            }
        }
    }
    
    private var savedVersesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Saved Verses")
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
                Spacer()
                if !storageService.savedVerses.isEmpty {
                    NavigationLink("See All") {
                        SavedVersesView()
                    }
                    .font(.subheadline)
                    .foregroundColor(themeManager.accentColor)
                }
            }
            
            if storageService.savedVerses.isEmpty {
                Text("Save verses you want to revisit")
                    .font(.subheadline)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(storageService.savedVerses.prefix(3)) { verse in
                    SavedVerseRow(verse: verse)
                }
            }
        }
    }
    
    private var memorizedVersesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Memorized Verses")
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
                
                Spacer()
                
                Text("\(storageService.masteredVerses.count) mastered")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            if storageService.masteredVerses.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "brain.head.profile")
                        .font(.title)
                        .foregroundColor(themeManager.secondaryTextColor)
                    Text("Start memorizing verses")
                        .font(.subheadline)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                ForEach(storageService.masteredVerses.prefix(3)) { session in
                    MasteredVerseRow(session: session)
                }
            }
        }
    }
}

// MARK: - Today Verse Card

struct TodayVerseCard: View {
    let verse: VerseOfDayEntry
    let onSave: () -> Void
    let onReflect: () -> Void
    let onMemorize: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        ThemedCard {
            VStack(spacing: 20) {
                // Date badge
                HStack {
                    Text(verse.formattedDate)
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                    Spacer()
                    if verse.isSaved {
                        Image(systemName: "bookmark.fill")
                            .foregroundColor(.yellow)
                    }
                }
                
                // Verse text
                Text("\"\(verse.verseText)\"")
                    .font(.title3)
                    .foregroundColor(themeManager.textColor)
                    .italic()
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                
                // Reference
                Text("— \(verse.verseReference)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.accentColor)
                
                // Action buttons
                HStack(spacing: 12) {
                    ThemedSecondaryButton(
                        title: verse.isSaved ? "Saved" : "Save",
                        icon: verse.isSaved ? "bookmark.fill" : "bookmark"
                    ) {
                        onSave()
                    }
                    
                    ThemedSecondaryButton(title: "Reflect", icon: "pencil.line") {
                        onReflect()
                    }
                    
                    ThemedSecondaryButton(title: "Memorize", icon: "brain") {
                        onMemorize()
                    }
                }
            }
        }
    }
}

// MARK: - Action Button

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(12)
        }
        .buttonStyle(TilePressStyle())
    }
}

// MARK: - Saved Verse Row

struct SavedVerseRow: View {
    let verse: VerseOfDayEntry
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(verse.verseReference)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.accentColor)
            
            Text(verse.verseText)
                .font(.caption)
                .foregroundColor(themeManager.secondaryTextColor)
                .lineLimit(2)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.hubElevatedSurface)
                .shadow(color: themeManager.hubShadowColor, radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Mastered Verse Row

struct MasteredVerseRow: View {
    let session: MemorizationSession
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack {
            Image(systemName: "checkmark.seal.fill")
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(session.verseReference)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.textColor)
                Text("\(Int(session.accuracy * 100))% accuracy")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            Spacer()
            
            Text("Mastered")
                .font(.caption)
                .foregroundColor(.green)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.hubElevatedSurface)
                .shadow(color: themeManager.hubShadowColor, radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Reflection Sheet

struct ReflectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var storageService = HubStorageService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    let verse: VerseOfDayEntry
    @State private var reflection = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Verse display
                    ThemedCard {
                        VStack(spacing: 12) {
                            Text("\"\(verse.verseText)\"")
                                .font(.body)
                                .foregroundColor(themeManager.textColor)
                                .italic()
                                .multilineTextAlignment(.center)
                            
                            Text("— \(verse.verseReference)")
                                .font(.caption)
                                .foregroundColor(themeManager.accentColor)
                        }
                    }
                    
                    // Reflection prompts
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Reflection Prompts")
                            .font(.headline)
                            .foregroundColor(themeManager.textColor)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• What does this verse say about God?")
                            Text("• How does this apply to my life today?")
                            Text("• What action can I take based on this?")
                        }
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                    }
                    
                    // Reflection input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Reflection")
                            .font(.headline)
                            .foregroundColor(themeManager.textColor)
                        
                        ThemedTextEditor(placeholder: "Write your thoughts...", text: $reflection, minHeight: 150)
                    }
                    
                    ThemedPrimaryButton(title: "Save Reflection", icon: "checkmark.circle.fill") {
                        storageService.addVerseReflection(verse, reflection: reflection)
                        dismiss()
                    }
                    .opacity(reflection.isEmpty ? 0.5 : 1.0)
                    .disabled(reflection.isEmpty)
                }
                .padding()
            }
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .navigationTitle("Reflect")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(themeManager.accentColor)
                }
            }
            .onAppear {
                reflection = verse.reflection ?? ""
            }
        }
    }
}

// MARK: - Verse History Sheet

struct VerseHistorySheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var storageService = HubStorageService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(storageService.verseOfDayEntries) { verse in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(verse.formattedDate)
                                    .font(.caption)
                                    .foregroundColor(themeManager.secondaryTextColor)
                                
                                Spacer()
                                
                                if verse.isSaved {
                                    Image(systemName: "bookmark.fill")
                                        .font(.caption)
                                        .foregroundColor(.yellow)
                                }
                            }
                            
                            Text(verse.verseReference)
                                .font(.headline)
                                .foregroundColor(themeManager.textColor)
                            
                            Text(verse.verseText)
                                .font(.subheadline)
                                .foregroundColor(themeManager.secondaryTextColor)
                                .lineLimit(2)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(themeManager.hubElevatedSurface)
                                .shadow(color: themeManager.hubShadowColor, radius: 4, x: 0, y: 2)
                        )
                    }
                }
                .padding()
            }
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .navigationTitle("Verse History")
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

// MARK: - Saved Verses View

struct SavedVersesView: View {
    @ObservedObject private var storageService = HubStorageService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(storageService.savedVerses) { verse in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(verse.verseReference)
                            .font(.headline)
                            .foregroundColor(themeManager.textColor)
                        
                        Text(verse.verseText)
                            .font(.body)
                            .foregroundColor(themeManager.secondaryTextColor)
                        
                        if let reflection = verse.reflection, !reflection.isEmpty {
                            Text("Reflection: \(reflection)")
                                .font(.caption)
                                .foregroundColor(themeManager.secondaryTextColor)
                                .italic()
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(themeManager.hubElevatedSurface)
                            .shadow(color: themeManager.hubShadowColor, radius: 4, x: 0, y: 2)
                    )
                }
            }
            .padding()
        }
        .background(themeManager.backgroundColor.ignoresSafeArea())
        .navigationTitle("Saved Verses")
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        VerseOfDayView()
    }
}
