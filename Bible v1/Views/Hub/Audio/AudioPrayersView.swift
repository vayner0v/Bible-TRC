//
//  AudioPrayersView.swift
//  Bible v1
//
//  Spiritual Hub - Audio Prayers Browser
//

import SwiftUI

struct AudioPrayersView: View {
    @ObservedObject private var audioService = AudioPrayerService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedCategory: AudioPrayerCategory?
    @State private var showCreatePrayer = false
    @State private var showPlayer = false
    @State private var searchText = ""
    
    var filteredPrayers: [AudioPrayer] {
        var prayers = audioService.audioPrayers
        
        if let category = selectedCategory {
            prayers = prayers.filter { $0.category == category }
        }
        
        if !searchText.isEmpty {
            prayers = prayers.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return prayers
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Categories
                        categoriesSection
                        
                        // Recently Played
                        if !audioService.recentlyPlayed.isEmpty && selectedCategory == nil {
                            recentlyPlayedSection
                        }
                        
                        // Favorites
                        if !audioService.favoritePrayers.isEmpty && selectedCategory == nil {
                            favoritesSection
                        }
                        
                        // All/Filtered Prayers
                        prayersSection
                        
                        // User Audio Prayers
                        if !audioService.userAudioPrayers.isEmpty && selectedCategory == nil {
                            userPrayersSection
                        }
                    }
                    .padding()
                    .padding(.bottom, audioService.playbackState != .idle ? 80 : 0)
                }
                
                // Mini Player
                if audioService.playbackState != .idle {
                    VStack {
                        Spacer()
                        MiniPlayerView {
                            showPlayer = true
                        }
                    }
                }
            }
            .navigationTitle("Audio Prayers")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search prayers")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCreatePrayer = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showPlayer) {
                AudioPrayerPlayerView()
            }
            .sheet(isPresented: $showCreatePrayer) {
                CreateUserAudioPrayerSheet()
            }
        }
    }
    
    // MARK: - Categories
    
    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Categories")
                .font(.headline)
                .foregroundColor(themeManager.textColor)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    CategoryPill(
                        title: "All",
                        icon: "music.note.list",
                        color: themeManager.accentColor,
                        isSelected: selectedCategory == nil
                    ) {
                        selectedCategory = nil
                    }
                    
                    ForEach(AudioPrayerCategory.allCases) { category in
                        CategoryPill(
                            title: category.rawValue,
                            icon: category.icon,
                            color: category.color,
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = category
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Recently Played
    
    private var recentlyPlayedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(themeManager.accentColor)
                Text("Recently Played")
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(audioService.recentlyPlayed.prefix(5)) { prayer in
                        CompactAudioCard(prayer: prayer) {
                            audioService.play(prayer)
                            showPlayer = true
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Favorites
    
    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.pink)
                Text("Favorites")
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
            }
            
            ForEach(audioService.favoritePrayers.prefix(3)) { prayer in
                AudioPrayerCard(prayer: prayer) {
                    audioService.play(prayer)
                    showPlayer = true
                } onFavorite: {
                    audioService.toggleFavorite(prayer)
                }
            }
        }
    }
    
    // MARK: - All Prayers
    
    private var prayersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if let category = selectedCategory {
                    Image(systemName: category.icon)
                        .foregroundColor(category.color)
                    Text(category.rawValue)
                        .font(.headline)
                        .foregroundColor(themeManager.textColor)
                } else {
                    Image(systemName: "play.circle.fill")
                        .foregroundColor(themeManager.accentColor)
                    Text("All Prayers")
                        .font(.headline)
                        .foregroundColor(themeManager.textColor)
                }
                
                Spacer()
                
                Text("\(filteredPrayers.count)")
                    .font(.subheadline)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            if filteredPrayers.isEmpty {
                emptyState
            } else {
                ForEach(filteredPrayers) { prayer in
                    AudioPrayerCard(prayer: prayer) {
                        audioService.play(prayer)
                        showPlayer = true
                    } onFavorite: {
                        audioService.toggleFavorite(prayer)
                    }
                }
            }
        }
    }
    
    // MARK: - User Prayers
    
    private var userPrayersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.fill")
                    .foregroundColor(.green)
                Text("My Audio Prayers")
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
                
                Spacer()
                
                Button {
                    showCreatePrayer = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(themeManager.accentColor)
                }
            }
            
            ForEach(audioService.userAudioPrayers) { prayer in
                UserAudioPrayerCard(prayer: prayer) {
                    audioService.play(prayer)
                    showPlayer = true
                } onDelete: {
                    audioService.deleteUserAudioPrayer(id: prayer.id)
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note")
                .font(.system(size: 48))
                .foregroundColor(themeManager.accentColor.opacity(0.5))
            
            Text("No prayers found")
                .font(.headline)
                .foregroundColor(themeManager.textColor)
            
            Text("Try a different category or create your own")
                .font(.subheadline)
                .foregroundColor(themeManager.secondaryTextColor)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(16)
    }
}

// MARK: - Category Pill

struct CategoryPill: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : themeManager.textColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? color : themeManager.cardBackgroundColor)
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Compact Audio Card

struct CompactAudioCard: View {
    let prayer: AudioPrayer
    let action: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(prayer.category.color.opacity(0.2))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: prayer.category.icon)
                        .font(.system(size: 32))
                        .foregroundColor(prayer.category.color)
                }
                
                Text(prayer.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.textColor)
                    .lineLimit(2)
                
                Text(prayer.shortDuration)
                    .font(.caption2)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            .frame(width: 100)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Audio Prayer Card

struct AudioPrayerCard: View {
    let prayer: AudioPrayer
    let onPlay: () -> Void
    let onFavorite: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var audioService = AudioPrayerService.shared
    
    var isCurrentlyPlaying: Bool {
        audioService.currentPrayer?.id == prayer.id && audioService.playbackState == .playing
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Play button
            Button(action: onPlay) {
                ZStack {
                    Circle()
                        .fill(prayer.category.color.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: isCurrentlyPlaying ? "pause.fill" : "play.fill")
                        .font(.title3)
                        .foregroundColor(prayer.category.color)
                }
            }
            .buttonStyle(.plain)
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(prayer.title)
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
                    .lineLimit(1)
                
                Text(prayer.description)
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    Label(prayer.shortDuration, systemImage: "clock")
                    
                    if prayer.playCount > 0 {
                        Text("•")
                        Text("\(prayer.playCount) plays")
                    }
                }
                .font(.caption2)
                .foregroundColor(themeManager.secondaryTextColor)
            }
            
            Spacer()
            
            // Favorite
            Button(action: onFavorite) {
                Image(systemName: prayer.isFavorite ? "heart.fill" : "heart")
                    .foregroundColor(prayer.isFavorite ? .pink : themeManager.secondaryTextColor)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(12)
    }
}

// MARK: - User Audio Prayer Card

struct UserAudioPrayerCard: View {
    let prayer: UserAudioPrayer
    let onPlay: () -> Void
    let onDelete: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        HStack(spacing: 16) {
            Button(action: onPlay) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "play.fill")
                        .font(.title3)
                        .foregroundColor(.green)
                }
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(prayer.title)
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
                
                Text(prayer.content.prefix(50) + "...")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .lineLimit(1)
                
                Text("~\(prayer.formattedDuration)")
                    .font(.caption2)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            Spacer()
            
            Button {
                showDeleteConfirmation = true
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(.red.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(12)
        .confirmationDialog("Delete Prayer", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) { onDelete() }
            Button("Cancel", role: .cancel) { }
        }
    }
}

// MARK: - Mini Player

struct MiniPlayerView: View {
    let onTap: () -> Void
    
    @ObservedObject private var audioService = AudioPrayerService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var title: String {
        audioService.currentPrayer?.title ?? audioService.currentUserPrayer?.title ?? "Unknown"
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Now playing indicator
                ZStack {
                    Circle()
                        .fill(themeManager.accentColor.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    if audioService.playbackState == .playing {
                        AudioWaveform()
                            .frame(width: 20, height: 20)
                    } else {
                        Image(systemName: "pause.fill")
                            .foregroundColor(themeManager.accentColor)
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.textColor)
                        .lineLimit(1)
                    
                    Text("\(audioService.formattedCurrentTime) / \(audioService.formattedDuration)")
                        .font(.caption2)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                
                Spacer()
                
                // Play/Pause
                Button {
                    audioService.togglePlayPause()
                } label: {
                    Image(systemName: audioService.playbackState == .playing ? "pause.fill" : "play.fill")
                        .font(.title2)
                        .foregroundColor(themeManager.textColor)
                }
                .buttonStyle(.plain)
                
                // Stop
                Button {
                    audioService.stop()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(
                themeManager.cardBackgroundColor
                    .shadow(color: .black.opacity(0.1), radius: 10, y: -5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Audio Waveform Animation

struct AudioWaveform: View {
    @State private var animating = false
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<4) { i in
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.accentColor)
                    .frame(width: 3)
                    .scaleEffect(y: animating ? CGFloat.random(in: 0.3...1.0) : 0.5, anchor: .bottom)
                    .animation(
                        .easeInOut(duration: 0.3)
                            .repeatForever()
                            .delay(Double(i) * 0.1),
                        value: animating
                    )
            }
        }
        .onAppear { animating = true }
    }
}

// MARK: - Full Audio Player

struct AudioPrayerPlayerView: View {
    @ObservedObject private var audioService = AudioPrayerService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var showTranscript = false
    @State private var showSleepTimer = false
    
    var prayer: AudioPrayer? { audioService.currentPrayer }
    var userPrayer: UserAudioPrayer? { audioService.currentUserPrayer }
    
    var title: String {
        prayer?.title ?? userPrayer?.title ?? "Unknown"
    }
    
    var category: AudioPrayerCategory? {
        prayer?.category
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        (category?.color ?? themeManager.accentColor).opacity(0.3),
                        themeManager.backgroundColor
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    Spacer()
                    
                    // Album art / Icon
                    ZStack {
                        Circle()
                            .fill((category?.color ?? themeManager.accentColor).opacity(0.2))
                            .frame(width: 200, height: 200)
                        
                        Image(systemName: category?.icon ?? "music.note")
                            .font(.system(size: 80))
                            .foregroundColor(category?.color ?? themeManager.accentColor)
                    }
                    .shadow(color: (category?.color ?? themeManager.accentColor).opacity(0.3), radius: 20)
                    
                    // Title & Info
                    VStack(spacing: 8) {
                        Text(title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.textColor)
                            .multilineTextAlignment(.center)
                        
                        if let cat = category {
                            Text(cat.rawValue)
                                .font(.subheadline)
                                .foregroundColor(cat.color)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Progress
                    VStack(spacing: 8) {
                        ProgressView(value: audioService.progress)
                            .tint(category?.color ?? themeManager.accentColor)
                        
                        HStack {
                            Text(audioService.formattedCurrentTime)
                            Spacer()
                            Text("-\(audioService.formattedRemainingTime)")
                        }
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                    }
                    .padding(.horizontal, 32)
                    
                    // Controls
                    HStack(spacing: 40) {
                        // Rewind
                        Button {
                            audioService.skipBackward()
                        } label: {
                            Image(systemName: "gobackward.15")
                                .font(.title)
                                .foregroundColor(themeManager.textColor)
                        }
                        
                        // Play/Pause
                        Button {
                            audioService.togglePlayPause()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(category?.color ?? themeManager.accentColor)
                                    .frame(width: 70, height: 70)
                                
                                Image(systemName: audioService.playbackState == .playing ? "pause.fill" : "play.fill")
                                    .font(.title)
                                    .foregroundColor(.white)
                            }
                        }
                        
                        // Forward
                        Button {
                            audioService.skipForward()
                        } label: {
                            Image(systemName: "goforward.15")
                                .font(.title)
                                .foregroundColor(themeManager.textColor)
                        }
                    }
                    
                    // Secondary controls
                    HStack(spacing: 32) {
                        // Speed
                        Menu {
                            ForEach([0.5, 0.75, 1.0, 1.25, 1.5], id: \.self) { speed in
                                Button {
                                    audioService.playbackSpeed = Float(speed)
                                } label: {
                                    HStack {
                                        Text("\(speed, specifier: "%.2g")x")
                                        if audioService.playbackSpeed == Float(speed) {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "speedometer")
                                    .font(.title3)
                                Text("\(audioService.playbackSpeed, specifier: "%.2g")x")
                                    .font(.caption2)
                            }
                            .foregroundColor(themeManager.textColor)
                        }
                        
                        // Sleep Timer
                        Button {
                            showSleepTimer = true
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "moon.fill")
                                    .font(.title3)
                                Text(audioService.sleepTimer == .off ? "Timer" : "\(Int(audioService.sleepTimerRemaining/60))m")
                                    .font(.caption2)
                            }
                            .foregroundColor(audioService.sleepTimer == .off ? themeManager.textColor : themeManager.accentColor)
                        }
                        
                        // Transcript
                        if prayer?.transcript != nil || userPrayer?.content != nil {
                            Button {
                                showTranscript = true
                            } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: "text.alignleft")
                                        .font(.title3)
                                    Text("Text")
                                        .font(.caption2)
                                }
                                .foregroundColor(themeManager.textColor)
                            }
                        }
                        
                        // Favorite
                        if let p = prayer {
                            Button {
                                audioService.toggleFavorite(p)
                            } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: p.isFavorite ? "heart.fill" : "heart")
                                        .font(.title3)
                                    Text("Favorite")
                                        .font(.caption2)
                                }
                                .foregroundColor(p.isFavorite ? .pink : themeManager.textColor)
                            }
                        }
                    }
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.down")
                            .foregroundColor(themeManager.textColor)
                    }
                }
            }
            .sheet(isPresented: $showTranscript) {
                TranscriptView(
                    title: title,
                    text: prayer?.transcript ?? userPrayer?.content ?? ""
                )
            }
            .sheet(isPresented: $showSleepTimer) {
                SleepTimerSheet()
            }
        }
    }
}

// MARK: - Transcript View

struct TranscriptView: View {
    let title: String
    let text: String
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                Text(text)
                    .font(.body)
                    .foregroundColor(themeManager.textColor)
                    .padding()
            }
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Sleep Timer Sheet

struct SleepTimerSheet: View {
    @ObservedObject private var audioService = AudioPrayerService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(SleepTimerOption.allCases) { option in
                    Button {
                        audioService.sleepTimer = option
                        dismiss()
                    } label: {
                        HStack {
                            Text(option.displayName)
                                .foregroundColor(themeManager.textColor)
                            Spacer()
                            if audioService.sleepTimer == option {
                                Image(systemName: "checkmark")
                                    .foregroundColor(themeManager.accentColor)
                            }
                        }
                    }
                    .listRowBackground(themeManager.cardBackgroundColor)
                }
            }
            .scrollContentBackground(.hidden)
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .navigationTitle("Sleep Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Create User Audio Prayer

struct CreateUserAudioPrayerSheet: View {
    @ObservedObject private var audioService = AudioPrayerService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var content = ""
    @State private var speechRate: Float = 0.5
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor.ignoresSafeArea()
                
                Form {
                    Section {
                        TextField("Prayer Title", text: $title)
                            .foregroundColor(themeManager.textColor)
                    } header: {
                        Text("Title")
                    }
                    .listRowBackground(themeManager.cardBackgroundColor)
                    
                    Section {
                        TextEditor(text: $content)
                            .frame(minHeight: 200)
                            .foregroundColor(themeManager.textColor)
                            .scrollContentBackground(.hidden)
                    } header: {
                        Text("Prayer Text")
                    } footer: {
                        Text("This text will be read aloud using text-to-speech")
                    }
                    .listRowBackground(themeManager.cardBackgroundColor)
                    
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Speech Speed")
                                Spacer()
                                Text(speedLabel)
                                    .foregroundColor(themeManager.secondaryTextColor)
                            }
                            
                            Slider(value: $speechRate, in: 0.25...1.0)
                                .tint(themeManager.accentColor)
                        }
                    } header: {
                        Text("Voice Settings")
                    }
                    .listRowBackground(themeManager.cardBackgroundColor)
                    
                    Section {
                        Button {
                            previewPrayer()
                        } label: {
                            Label("Preview", systemImage: "play.circle")
                        }
                        .disabled(content.isEmpty)
                    }
                    .listRowBackground(themeManager.cardBackgroundColor)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Create Audio Prayer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        savePrayer()
                        dismiss()
                    }
                    .disabled(title.isEmpty || content.isEmpty)
                }
            }
        }
    }
    
    private var speedLabel: String {
        if speechRate < 0.4 {
            return "Slow"
        } else if speechRate < 0.6 {
            return "Normal"
        } else if speechRate < 0.8 {
            return "Fast"
        } else {
            return "Very Fast"
        }
    }
    
    private func previewPrayer() {
        let preview = UserAudioPrayer(
            title: title.isEmpty ? "Preview" : title,
            content: content,
            speechRate: speechRate
        )
        audioService.play(preview)
    }
    
    private func savePrayer() {
        let prayer = UserAudioPrayer(
            title: title,
            content: content,
            speechRate: speechRate
        )
        audioService.addUserAudioPrayer(prayer)
    }
}

#Preview {
    AudioPrayersView()
}


