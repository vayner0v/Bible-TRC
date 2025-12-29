//
//  DevotionalsView.swift
//  Bible v1
//
//  Spiritual Hub - Devotionals & Sermon Notes (Theme-aware)
//

import SwiftUI

struct DevotionalsView: View {
    @ObservedObject private var storageService = HubStorageService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var selectedTab = 0
    @State private var selectedSeries: DevotionalSeries?
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab selector
            Picker("View", selection: $selectedTab) {
                Text("Devotionals").tag(0)
                Text("Sermon Notes").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()
            
            // Content based on tab
            Group {
                if selectedTab == 0 {
                    devotionalsContent
                } else {
                    sermonNotesContent
                }
            }
        }
        .navigationTitle("Devotionals & Notes")
        .navigationBarTitleDisplayMode(.large)
        .background(themeManager.backgroundColor.ignoresSafeArea())
    }
    
    // MARK: - Devotionals Content
    
    private var devotionalsContent: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                // Active devotional
                if let activeProgress = storageService.getActiveDevotionalProgress(),
                   let activeSeries = DevotionalSeries.allSeries.first(where: { $0.id == activeProgress.seriesId }) {
                    ActiveDevotionalCard(
                        series: activeSeries,
                        progress: activeProgress
                    )
                }
                
                // Browse all series
                VStack(alignment: .leading, spacing: 16) {
                    Text("Devotional Series")
                        .font(.headline)
                        .foregroundColor(themeManager.textColor)
                    
                    ForEach(DevotionalSeries.allSeries) { series in
                        DevotionalSeriesRow(series: series) {
                            selectedSeries = series
                        }
                    }
                }
            }
            .padding()
        }
        .sheet(item: $selectedSeries) { series in
            DevotionalSeriesSheet(series: series)
        }
    }
    
    // MARK: - Sermon Notes Content
    
    private var sermonNotesContent: some View {
        SermonNotesListView()
    }
}

// MARK: - Active Devotional Card

struct ActiveDevotionalCard: View {
    let series: DevotionalSeries
    let progress: DevotionalProgress
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        NavigationLink {
            DevotionalDayView(series: series, progress: progress)
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: series.topic.icon)
                        .font(.title2)
                        .foregroundColor(series.topic.color)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Continue Reading")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                        Text(series.title)
                            .font(.headline)
                            .foregroundColor(themeManager.textColor)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                
                // Progress bar
                VStack(alignment: .leading, spacing: 4) {
                    ThemedProgressBar(progress: progress.progressPercentage(totalDays: series.totalDays))
                    
                    HStack {
                        Text("Day \(progress.currentDay) of \(series.totalDays)")
                        Spacer()
                        Text("\(Int(progress.progressPercentage(totalDays: series.totalDays) * 100))%")
                    }
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [series.topic.color.opacity(0.12), themeManager.hubElevatedSurface],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: themeManager.hubShadowColor, radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(TilePressStyle())
    }
}

// MARK: - Devotional Series Row

struct DevotionalSeriesRow: View {
    let series: DevotionalSeries
    let onTap: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(series.topic.color.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: series.topic.icon)
                        .font(.title3)
                        .foregroundColor(series.topic.color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(series.title)
                        .font(.headline)
                        .foregroundColor(themeManager.textColor)
                    
                    Text(series.description)
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                        .lineLimit(2)
                    
                    Text("\(series.totalDays) days")
                        .font(.caption2)
                        .foregroundColor(themeManager.accentColor)
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

// MARK: - Devotional Series Sheet

struct DevotionalSeriesSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var storageService = HubStorageService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    let series: DevotionalSeries
    
    var existingProgress: DevotionalProgress? {
        storageService.devotionalProgress.first { $0.seriesId == series.id }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(series.topic.color.opacity(0.15))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: series.topic.icon)
                                .font(.largeTitle)
                                .foregroundColor(series.topic.color)
                        }
                        
                        Text(series.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.textColor)
                        
                        Text(series.description)
                            .font(.body)
                            .foregroundColor(themeManager.secondaryTextColor)
                            .multilineTextAlignment(.center)
                        
                        HStack(spacing: 16) {
                            Label("\(series.totalDays) days", systemImage: "calendar")
                            Label("~5 min/day", systemImage: "clock")
                        }
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                    }
                    .padding()
                    
                    // Day list
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Daily Readings")
                            .font(.headline)
                            .foregroundColor(themeManager.textColor)
                        
                        ForEach(series.days) { day in
                            DayPreviewRow(
                                day: day,
                                isCompleted: existingProgress?.completedDays.contains(day.dayNumber) ?? false
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Start/Continue button
                    if let progress = existingProgress {
                        NavigationLink {
                            DevotionalDayView(series: series, progress: progress)
                        } label: {
                            HStack {
                                Image(systemName: "book.fill")
                                Text("Continue Reading")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [themeManager.accentColor, themeManager.hubTileSecondaryColor],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(14)
                        }
                        .padding()
                    } else {
                        ThemedPrimaryButton(title: "Start Devotional", icon: "play.fill") {
                            startDevotional()
                        }
                        .padding()
                    }
                }
            }
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .navigationTitle("Devotional")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(themeManager.accentColor)
                }
            }
        }
    }
    
    private func startDevotional() {
        storageService.startDevotional(series)
        dismiss()
    }
}

struct DayPreviewRow: View {
    let day: DevotionalDay
    let isCompleted: Bool
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isCompleted ? Color.green : themeManager.cardBackgroundColor)
                    .frame(width: 32, height: 32)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .foregroundColor(.white)
                } else {
                    Text("\(day.dayNumber)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.textColor)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(day.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.textColor)
                
                Text(day.verseReference)
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Devotional Day View

struct DevotionalDayView: View {
    @ObservedObject private var storageService = HubStorageService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    let series: DevotionalSeries
    let progress: DevotionalProgress
    
    var currentDay: DevotionalDay? {
        series.days.first { $0.dayNumber == progress.currentDay }
    }
    
    @State private var personalNote = ""
    
    var body: some View {
        ScrollView {
            if let day = currentDay {
                VStack(spacing: 24) {
                    // Day header
                    VStack(spacing: 8) {
                        Text("Day \(day.dayNumber) of \(series.totalDays)")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                        
                        Text(day.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.textColor)
                    }
                    .padding()
                    
                    // Scripture reading
                    ThemedCard {
                        VStack(alignment: .leading, spacing: 12) {
                            ThemedSectionHeader(title: "Scripture Reading", icon: "book.fill", iconColor: .blue)
                            
                            Text(day.verseReference)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(themeManager.accentColor)
                            
                            Text(day.verseText)
                                .font(.body)
                                .foregroundColor(themeManager.textColor)
                                .italic()
                        }
                    }
                    .padding(.horizontal)
                    
                    // Devotional thought
                    ThemedCard {
                        VStack(alignment: .leading, spacing: 8) {
                            ThemedSectionHeader(title: "Reflection", icon: "lightbulb.fill", iconColor: .yellow)
                            
                            Text(day.reflection)
                                .font(.body)
                                .foregroundColor(themeManager.textColor)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Prayer Prompt
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Prayer")
                            .font(.headline)
                            .foregroundColor(themeManager.textColor)
                        
                        Text(day.prayerPrompt)
                            .font(.body)
                            .italic()
                            .foregroundColor(themeManager.textColor)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(ThemeManager.shared.accentColor.opacity(0.12))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // Application Question
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Application")
                            .font(.headline)
                            .foregroundColor(themeManager.textColor)
                        
                        Text(day.applicationQuestion)
                            .font(.body)
                            .foregroundColor(themeManager.textColor)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.orange.opacity(0.12))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // Personal notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Notes")
                            .font(.headline)
                            .foregroundColor(themeManager.textColor)
                        
                        ThemedTextEditor(placeholder: "What spoke to you today?", text: $personalNote, minHeight: 80)
                    }
                    .padding(.horizontal)
                    
                    // Complete button
                    ThemedPrimaryButton(
                        title: "Complete Day \(day.dayNumber)",
                        icon: "checkmark.circle.fill",
                        gradient: [.green, .teal]
                    ) {
                        completeDay(day.dayNumber)
                    }
                    .opacity(progress.completedDays.contains(day.dayNumber) ? 0.5 : 1.0)
                    .disabled(progress.completedDays.contains(day.dayNumber))
                    .padding()
                }
            }
        }
        .background(themeManager.backgroundColor.ignoresSafeArea())
        .navigationTitle(series.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            personalNote = progress.notes[progress.currentDay] ?? ""
        }
    }
    
    private func completeDay(_ dayNumber: Int) {
        if !personalNote.isEmpty {
            storageService.addDevotionalNote(seriesId: series.id, day: dayNumber, note: personalNote)
        }
        storageService.completeDevotionalDay(seriesId: series.id, day: dayNumber, totalDays: series.totalDays)
    }
}

// MARK: - Sermon Notes List View

struct SermonNotesListView: View {
    @ObservedObject private var storageService = HubStorageService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var showNewNoteSheet = false
    @State private var selectedNote: SermonNote?
    
    var body: some View {
        Group {
            if storageService.sermonNotes.isEmpty {
                ThemedEmptyState(
                    icon: "note.text",
                    title: "No Sermon Notes",
                    message: "Capture insights from sermons",
                    actionTitle: "Add Note"
                ) {
                    showNewNoteSheet = true
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(storageService.sermonNotes) { note in
                            SermonNoteRow(note: note) {
                                selectedNote = note
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showNewNoteSheet = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(themeManager.accentColor)
                }
            }
        }
        .sheet(isPresented: $showNewNoteSheet) {
            SermonNoteEditorSheet()
        }
        .sheet(item: $selectedNote) { note in
            SermonNoteEditorSheet(existingNote: note)
        }
    }
}

// MARK: - Sermon Note Row

struct SermonNoteRow: View {
    let note: SermonNote
    let onTap: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(note.title.isEmpty ? "Untitled" : note.title)
                        .font(.headline)
                        .foregroundColor(themeManager.textColor)
                    
                    Spacer()
                    
                    Text(note.formattedDate)
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                
                if !note.mainScripture.isEmpty {
                    Text(note.mainScripture)
                        .font(.subheadline)
                        .foregroundColor(themeManager.accentColor)
                }
                
                if !note.speaker.isEmpty {
                    Text("by \(note.speaker)")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
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

// MARK: - Sermon Note Editor Sheet

struct SermonNoteEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var storageService = HubStorageService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var existingNote: SermonNote?
    
    @State private var title = ""
    @State private var speaker = ""
    @State private var church = ""
    @State private var mainScripture = ""
    @State private var mainPoints: [String] = [""]
    @State private var personalNotes = ""
    @State private var applicationPoints: [String] = [""]
    @State private var prayerResponse = ""
    
    var isEditing: Bool { existingNote != nil }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    ThemedCard {
                        VStack(alignment: .leading, spacing: 16) {
                            ThemedSectionHeader(title: "Basic Info", icon: "info.circle", iconColor: .blue)
                            
                            ThemedTextField(placeholder: "Sermon Title", text: $title, icon: "text.alignleft")
                            ThemedTextField(placeholder: "Speaker", text: $speaker, icon: "person")
                            ThemedTextField(placeholder: "Church/Event", text: $church, icon: "building.2")
                            ThemedTextField(placeholder: "Main Scripture", text: $mainScripture, icon: "book")
                        }
                    }
                    
                    ThemedCard {
                        VStack(alignment: .leading, spacing: 16) {
                            ThemedSectionHeader(title: "Main Points", icon: "list.number", iconColor: .orange)
                            
                            ForEach(mainPoints.indices, id: \.self) { index in
                                ThemedTextField(placeholder: "Point \(index + 1)", text: $mainPoints[index])
                            }
                            
                            ThemedSecondaryButton(title: "Add Point", icon: "plus") {
                                mainPoints.append("")
                            }
                        }
                    }
                    
                    ThemedCard {
                        VStack(alignment: .leading, spacing: 16) {
                            ThemedSectionHeader(title: "Personal Notes", icon: "pencil", iconColor: ThemeManager.shared.accentColor)
                            ThemedTextEditor(placeholder: "Your thoughts...", text: $personalNotes, minHeight: 100)
                        }
                    }
                    
                    ThemedCard {
                        VStack(alignment: .leading, spacing: 16) {
                            ThemedSectionHeader(title: "Application", icon: "sparkles", iconColor: .yellow)
                            
                            ForEach(applicationPoints.indices, id: \.self) { index in
                                ThemedTextField(placeholder: "How will I apply this?", text: $applicationPoints[index])
                            }
                            
                            ThemedSecondaryButton(title: "Add Application", icon: "plus") {
                                applicationPoints.append("")
                            }
                        }
                    }
                    
                    ThemedCard {
                        VStack(alignment: .leading, spacing: 16) {
                            ThemedSectionHeader(title: "Prayer Response", icon: "hands.sparkles", iconColor: .pink)
                            ThemedTextEditor(placeholder: "Your prayer...", text: $prayerResponse, minHeight: 60)
                        }
                    }
                    
                    ThemedPrimaryButton(title: "Save Note", icon: "checkmark.circle.fill") {
                        saveNote()
                    }
                }
                .padding()
            }
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .navigationTitle(isEditing ? "Edit Note" : "New Sermon Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(themeManager.accentColor)
                }
            }
            .onAppear {
                if let note = existingNote {
                    title = note.title
                    speaker = note.speaker
                    church = note.church
                    mainScripture = note.mainScripture
                    mainPoints = note.mainPoints.isEmpty ? [""] : note.mainPoints
                    personalNotes = note.personalNotes
                    applicationPoints = note.applicationPoints.isEmpty ? [""] : note.applicationPoints
                    prayerResponse = note.prayerResponse ?? ""
                }
            }
        }
    }
    
    private func saveNote() {
        let filteredMainPoints = mainPoints.filter { !$0.isEmpty }
        let filteredApplicationPoints = applicationPoints.filter { !$0.isEmpty }
        
        if var note = existingNote {
            note.title = title
            note.speaker = speaker
            note.church = church
            note.mainScripture = mainScripture
            note.mainPoints = filteredMainPoints
            note.personalNotes = personalNotes
            note.applicationPoints = filteredApplicationPoints
            note.prayerResponse = prayerResponse.isEmpty ? nil : prayerResponse
            note.modifiedAt = Date()
            storageService.updateSermonNote(note)
        } else {
            let note = SermonNote(
                title: title,
                speaker: speaker,
                church: church,
                mainScripture: mainScripture,
                mainPoints: filteredMainPoints,
                personalNotes: personalNotes,
                applicationPoints: filteredApplicationPoints,
                prayerResponse: prayerResponse.isEmpty ? nil : prayerResponse
            )
            storageService.addSermonNote(note)
        }
        
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DevotionalsView()
    }
}
