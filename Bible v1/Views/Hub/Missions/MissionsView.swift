//
//  MissionsView.swift
//  Bible v1
//
//  Spiritual Hub - Missions (Theme-aware)
//

import SwiftUI

struct MissionsView: View {
    @ObservedObject private var storageService = HubStorageService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var selectedType: MissionType? = nil
    @State private var selectedMission: Mission?
    
    var filteredMissions: [Mission] {
        if let type = selectedType {
            return Mission.allMissions.filter { $0.type == type }
        }
        return Mission.allMissions
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                // Today's mission
                todayMissionSection
                
                // Weekly progress
                weeklyProgressSection
                
                // Mission filters
                filterSection
                
                // All missions
                allMissionsSection
            }
            .padding()
        }
        .navigationTitle("Missions")
        .navigationBarTitleDisplayMode(.large)
        .background(themeManager.backgroundColor.ignoresSafeArea())
        .sheet(item: $selectedMission) { mission in
            MissionDetailSheet(mission: mission)
        }
    }
    
    // MARK: - Today's Mission
    
    private var todayMissionSection: some View {
        let todayMission = Mission.missionOfTheDay()
        let isCompleted = storageService.isMissionCompletedToday(todayMission.id)
        
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Today's Mission")
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
                Spacer()
                if isCompleted {
                    Label("Completed", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            TodayMissionCard(
                mission: todayMission,
                isCompleted: isCompleted,
                onTap: { selectedMission = todayMission }
            )
        }
    }
    
    // MARK: - Weekly Progress
    
    private var weeklyProgressSection: some View {
        let completedThisWeek = storageService.getMissionsCompletedThisWeek()
        
        return ThemedCard {
            VStack(alignment: .leading, spacing: 16) {
                ThemedSectionHeader(title: "This Week", icon: "calendar", iconColor: .blue)
                
                HStack(spacing: 12) {
                    ThemedStatPill(
                        icon: "checkmark.circle",
                        value: "\(completedThisWeek.count)",
                        label: "Missions Done",
                        color: .green
                    )
                    
                    ThemedStatPill(
                        icon: "trophy",
                        value: "\(storageService.totalMissionsCompleted)",
                        label: "Total Ever",
                        color: .yellow
                    )
                }
                
                // Encouraging message
                if completedThisWeek.count >= 5 {
                    EncouragementBanner(
                        message: "Amazing dedication! You're making a real difference.",
                        icon: "star.fill",
                        color: .yellow
                    )
                } else if completedThisWeek.count >= 3 {
                    EncouragementBanner(
                        message: "Great progress! Keep up the good work.",
                        icon: "hand.thumbsup.fill",
                        color: .green
                    )
                } else if completedThisWeek.count >= 1 {
                    EncouragementBanner(
                        message: "Every act of love matters. Well done!",
                        icon: "heart.fill",
                        color: .pink
                    )
                }
            }
        }
    }
    
    // MARK: - Filter Section
    
    private var filterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Browse Missions")
                .font(.headline)
                .foregroundColor(themeManager.textColor)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(title: "All", isSelected: selectedType == nil) {
                        selectedType = nil
                    }
                    
                    ForEach(MissionType.allCases) { type in
                        FilterChip(
                            title: type.rawValue,
                            isSelected: selectedType == type,
                            color: type.color
                        ) {
                            selectedType = type
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - All Missions
    
    private var allMissionsSection: some View {
        LazyVStack(spacing: 12) {
            ForEach(filteredMissions) { mission in
                MissionRow(
                    mission: mission,
                    isCompleted: storageService.missionCompletions.contains { $0.missionId == mission.id }
                ) {
                    selectedMission = mission
                }
            }
        }
    }
}

// MARK: - Today Mission Card

struct TodayMissionCard: View {
    let mission: Mission
    let isCompleted: Bool
    let onTap: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Image(systemName: mission.type.icon)
                        .font(.title2)
                        .foregroundColor(mission.type.color)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(mission.type.rawValue)
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                        Text(mission.title)
                            .font(.headline)
                            .foregroundColor(themeManager.textColor)
                    }
                    
                    Spacer()
                    
                    if isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "chevron.right")
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                }
                
                // Description
                Text(mission.description)
                    .font(.subheadline)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .lineLimit(2)
                
                // Scripture
                HStack(spacing: 4) {
                    Image(systemName: "book.fill")
                        .font(.caption)
                    Text(mission.relatedVerseReference)
                        .font(.caption)
                }
                .foregroundColor(themeManager.accentColor)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [mission.type.color.opacity(0.12), themeManager.hubElevatedSurface],
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

// MARK: - Week Stat Card (Removed - using ThemedStatPill instead)

// MARK: - Encouragement Banner

struct EncouragementBanner: View {
    let message: String
    let icon: String
    let color: Color
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(themeManager.textColor)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.12))
        .cornerRadius(12)
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    var color: Color = .accentColor
    let action: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? color : themeManager.cardBackgroundColor)
                .foregroundColor(isSelected ? .white : themeManager.textColor)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Mission Row

struct MissionRow: View {
    let mission: Mission
    let isCompleted: Bool
    let onTap: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(mission.type.color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: mission.type.icon)
                        .foregroundColor(mission.type.color)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(mission.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(themeManager.textColor)
                        
                        if isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                    
                    Text(mission.type.rawValue)
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    // Difficulty badge
                    HStack(spacing: 4) {
                        Circle()
                            .fill(mission.difficulty.color)
                            .frame(width: 6, height: 6)
                        Text(mission.difficulty.rawValue)
                            .font(.caption2)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
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

// MARK: - Mission Detail Sheet

struct MissionDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var storageService = HubStorageService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    let mission: Mission
    
    @State private var reflection = ""
    @State private var notes = ""
    @State private var showCompletionForm = false
    
    var isCompletedToday: Bool {
        storageService.isMissionCompletedToday(mission.id)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Scripture
                    scriptureSection
                    
                    // Suggested actions
                    actionsSection
                    
                    // Reflection prompt
                    reflectionSection
                    
                    // Complete button
                    if !isCompletedToday {
                        if showCompletionForm {
                            completionFormSection
                        } else {
                            ThemedPrimaryButton(
                                title: "Mark as Complete",
                                icon: "checkmark.circle",
                                gradient: [.green, .teal]
                            ) {
                                showCompletionForm = true
                            }
                        }
                    } else {
                        completedBanner
                    }
                }
                .padding()
            }
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .navigationTitle(mission.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(themeManager.accentColor)
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(mission.type.color.opacity(0.15))
                    .frame(width: 80, height: 80)
                
                Image(systemName: mission.type.icon)
                    .font(.largeTitle)
                    .foregroundColor(mission.type.color)
            }
            
            VStack(spacing: 4) {
                Text(mission.type.rawValue)
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
                
                Text(mission.description)
                    .font(.body)
                    .foregroundColor(themeManager.textColor)
                    .multilineTextAlignment(.center)
            }
            
            // Difficulty badge
            HStack(spacing: 4) {
                Circle()
                    .fill(mission.difficulty.color)
                    .frame(width: 8, height: 8)
                Text(mission.difficulty.rawValue)
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(themeManager.cardBackgroundColor)
            .clipShape(Capsule())
        }
    }
    
    private var scriptureSection: some View {
        ThemedCard {
            VStack(alignment: .leading, spacing: 8) {
                ThemedSectionHeader(title: "Scripture", icon: "book.fill", iconColor: .blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\"\(mission.relatedVerseText)\"")
                        .font(.body)
                        .foregroundColor(themeManager.textColor)
                        .italic()
                    
                    Text("— \(mission.relatedVerseReference)")
                        .font(.caption)
                        .foregroundColor(themeManager.accentColor)
                }
            }
        }
    }
    
    private var actionsSection: some View {
        ThemedCard {
            VStack(alignment: .leading, spacing: 12) {
                ThemedSectionHeader(title: "Suggested Actions", icon: "list.bullet", iconColor: .orange)
                
                ForEach(mission.suggestedActions, id: \.self) { action in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "circle")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                        
                        Text(action)
                            .font(.subheadline)
                            .foregroundColor(themeManager.textColor)
                    }
                }
            }
        }
    }
    
    private var reflectionSection: some View {
        ThemedCard {
            VStack(alignment: .leading, spacing: 8) {
                ThemedSectionHeader(title: "Reflection Prompt", icon: "sparkles", iconColor: ThemeManager.shared.accentColor)
                
                Text(mission.reflectionPrompt)
                    .font(.subheadline)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
        }
    }
    
    private var completionFormSection: some View {
        ThemedCard {
            VStack(alignment: .leading, spacing: 16) {
                ThemedSectionHeader(title: "Share Your Experience", icon: "pencil", iconColor: .blue)
                
                ThemedTextEditor(placeholder: "How did it go?", text: $reflection, minHeight: 80)
                
                ThemedTextEditor(placeholder: "Any notes? (optional)", text: $notes, minHeight: 60)
                
                ThemedPrimaryButton(
                    title: "Complete Mission",
                    icon: "checkmark.circle.fill",
                    gradient: [.green, .teal]
                ) {
                    completeMission()
                }
                .opacity(reflection.isEmpty ? 0.5 : 1.0)
                .disabled(reflection.isEmpty)
            }
        }
    }
    
    private var completedBanner: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text("You completed this mission today!")
                .font(.subheadline)
                .foregroundColor(themeManager.textColor)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.green.opacity(0.12))
        .cornerRadius(12)
    }
    
    private func completeMission() {
        storageService.completeMission(
            mission,
            reflection: reflection.isEmpty ? nil : reflection,
            notes: notes.isEmpty ? nil : notes
        )
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MissionsView()
    }
}
