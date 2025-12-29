//
//  FastingTrackerView.swift
//  Bible v1
//
//  Spiritual Hub - Fasting Tracker (Theme-aware)
//

import SwiftUI

struct FastingTrackerView: View {
    @ObservedObject private var storageService = HubStorageService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var showNewFastSheet = false
    @State private var showCompletionSheet = false
    @State private var showHistorySheet = false
    @State private var showHealthDisclaimer = false
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                // Health disclaimer banner
                healthDisclaimerBanner
                
                // Active fast or start new fast
                if let activeFast = storageService.getActiveFast() {
                    ActiveFastCard(fast: activeFast, onComplete: {
                        showCompletionSheet = true
                    })
                } else {
                    StartFastCard(onStart: {
                        showNewFastSheet = true
                    })
                }
                
                // Statistics
                FastingStatsView(stats: storageService.getFastingStats())
                
                // Recent fasts
                RecentFastsSection(
                    fasts: Array(storageService.fastingEntries.prefix(5)),
                    onViewAll: { showHistorySheet = true }
                )
            }
            .padding()
        }
        .navigationTitle("Fasting Tracker")
        .navigationBarTitleDisplayMode(.large)
        .background(themeManager.backgroundColor.ignoresSafeArea())
        .sheet(isPresented: $showNewFastSheet) {
            NewFastSheet()
        }
        .sheet(isPresented: $showCompletionSheet) {
            FastCompletionSheet()
        }
        .sheet(isPresented: $showHistorySheet) {
            FastingHistoryView()
        }
        .alert("Health & Safety", isPresented: $showHealthDisclaimer) {
            Button("I Understand", role: .cancel) { }
        } message: {
            Text(FastingDisclaimer.general)
        }
    }
    
    private var healthDisclaimerBanner: some View {
        Button {
            showHealthDisclaimer = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "heart.text.square.fill")
                    .font(.title2)
                    .foregroundColor(.pink)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Health & Safety")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.textColor)
                    Text("Read important guidance before fasting")
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
                    .fill(Color.pink.opacity(0.12))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Active Fast Card

struct ActiveFastCard: View {
    let fast: FastingEntry
    let onComplete: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var timeRemaining: String = ""
    @State private var timer: Timer?
    
    var body: some View {
        ThemedCard {
            VStack(spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Active Fast")
                            .font(.headline)
                            .foregroundColor(themeManager.textColor)
                        Text(fast.type.rawValue)
                            .font(.subheadline)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    
                    Spacer()
                    
                    Image(systemName: fast.type.icon)
                        .font(.title)
                        .foregroundColor(fast.type.color)
                }
                
                // Progress ring
                ZStack {
                    Circle()
                        .stroke(themeManager.dividerColor, lineWidth: 12)
                    
                    Circle()
                        .trim(from: 0, to: fast.progress)
                        .stroke(
                            fast.type.color,
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut, value: fast.progress)
                    
                    VStack(spacing: 4) {
                        Text(timeRemaining)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.textColor)
                            .monospacedDigit()
                        Text("remaining")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                        
                        Text("\(Int(fast.progress * 100))%")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(fast.type.color)
                    }
                }
                .frame(height: 180)
                .padding(.vertical)
                
                // Intention
                if !fast.intention.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Intention")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                        Text(fast.intention)
                            .font(.subheadline)
                            .foregroundColor(themeManager.textColor)
                            .italic()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(themeManager.cardBackgroundColor)
                    .cornerRadius(8)
                }
                
                // Actions
                HStack(spacing: 12) {
                    ThemedSecondaryButton(title: "End Early", icon: "xmark.circle") {
                        HubStorageService.shared.endFastEarly()
                    }
                    
                    ThemedPrimaryButton(title: "Complete", icon: "checkmark.circle.fill") {
                        onComplete()
                    }
                    .opacity(fast.progress < 1.0 ? 0.5 : 1.0)
                    .disabled(fast.progress < 1.0)
                }
            }
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func startTimer() {
        updateTimeRemaining()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            updateTimeRemaining()
        }
    }
    
    private func updateTimeRemaining() {
        let seconds = fast.timeRemainingSeconds
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        
        if hours > 0 {
            timeRemaining = String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            timeRemaining = String(format: "%02d:%02d", minutes, secs)
        }
    }
}

// MARK: - Start Fast Card

struct StartFastCard: View {
    let onStart: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        ThemedCard {
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.indigo.opacity(0.15))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.indigo)
                }
                
                Text("Start a Spiritual Fast")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.textColor)
                
                Text("Fasting is a powerful spiritual discipline. Set your intention and track your journey.")
                    .font(.subheadline)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .multilineTextAlignment(.center)
                
                ThemedPrimaryButton(
                    title: "Begin Fast",
                    icon: "play.circle.fill",
                    gradient: [.indigo, .teal]
                ) {
                    onStart()
                }
            }
        }
    }
}

// MARK: - Fasting Stats View

struct FastingStatsView: View {
    let stats: FastingStats
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        ThemedCard {
            VStack(alignment: .leading, spacing: 16) {
                ThemedSectionHeader(title: "Your Fasting Journey", icon: "chart.bar.fill", iconColor: .blue)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ThemedStatPill(
                        icon: "number",
                        value: "\(stats.totalFasts)",
                        label: "Total Fasts",
                        color: .blue
                    )
                    
                    ThemedStatPill(
                        icon: "checkmark.circle",
                        value: "\(stats.completedFasts)",
                        label: "Completed",
                        color: .green
                    )
                    
                    ThemedStatPill(
                        icon: "clock",
                        value: "\(stats.totalHoursFasted)",
                        label: "Hours Fasted",
                        color: .orange
                    )
                    
                    ThemedStatPill(
                        icon: "trophy",
                        value: "\(stats.longestFast)h",
                        label: "Longest Fast",
                        color: .yellow
                    )
                }
                
                if stats.completionRate > 0 {
                    HStack {
                        Text("Completion Rate")
                            .font(.subheadline)
                            .foregroundColor(themeManager.textColor)
                        Spacer()
                        Text("\(Int(stats.completionRate * 100))%")
                            .fontWeight(.semibold)
                            .foregroundColor(stats.completionRate >= 0.7 ? .green : .orange)
                    }
                    .padding()
                    .background(themeManager.cardBackgroundColor)
                    .cornerRadius(8)
                }
            }
        }
    }
}

// MARK: - Recent Fasts Section

struct RecentFastsSection: View {
    let fasts: [FastingEntry]
    let onViewAll: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        ThemedCard {
            VStack(alignment: .leading, spacing: 16) {
                ThemedSectionHeader(
                    title: "Recent Fasts",
                    actionTitle: "View All",
                    action: onViewAll
                )
                
                if fasts.isEmpty {
                    ThemedEmptyState(
                        icon: "moon.zzz",
                        title: "No Fasts Yet",
                        message: "Start your first spiritual fast to see your history here"
                    )
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(fasts) { fast in
                            FastHistoryRow(fast: fast)
                            
                            if fast.id != fasts.last?.id {
                                ThemedDivider()
                            }
                        }
                    }
                }
            }
        }
    }
}

struct FastHistoryRow: View {
    let fast: FastingEntry
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: fast.type.icon)
                .font(.title3)
                .foregroundColor(fast.type.color)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(fast.type.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.textColor)
                Text(fast.durationString)
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                statusBadge
                Text(fast.startDate, style: .date)
                    .font(.caption2)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
        }
        .padding(.vertical, 8)
    }
    
    private var statusBadge: some View {
        Text(fast.status.rawValue)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(statusColor.opacity(0.15))
            .foregroundColor(statusColor)
            .clipShape(Capsule())
    }
    
    private var statusColor: Color {
        switch fast.status {
        case .completed: return .green
        case .active: return .blue
        case .broken: return .orange
        case .scheduled: return themeManager.secondaryTextColor
        }
    }
}

// MARK: - New Fast Sheet

struct NewFastSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var storageService = HubStorageService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    
    @State private var selectedType: FastingType = .intermittent
    @State private var intention = ""
    @State private var duration: Double = 16
    @State private var customDescription = ""
    @State private var showGuidance = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Fast Type
                    ThemedCard {
                        VStack(alignment: .leading, spacing: 16) {
                            ThemedSectionHeader(title: "Fast Type", icon: "list.bullet", iconColor: ThemeManager.shared.accentColor)
                            
                            ForEach(FastingType.allCases) { type in
                                Button {
                                    selectedType = type
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: type.icon)
                                            .font(.title2)
                                            .foregroundColor(type.color)
                                            .frame(width: 40)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(type.rawValue)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(themeManager.textColor)
                                            Text(type.description)
                                                .font(.caption)
                                                .foregroundColor(themeManager.secondaryTextColor)
                                                .lineLimit(2)
                                        }
                                        
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
                            
                            ThemedSecondaryButton(title: "View Health Guidance", icon: "heart.text.square") {
                                showGuidance = true
                            }
                        }
                    }
                    
                    // Duration
                    ThemedCard {
                        VStack(alignment: .leading, spacing: 16) {
                            ThemedSectionHeader(title: "Duration", icon: "clock", iconColor: .orange)
                            
                            HStack {
                                Text("Duration")
                                    .foregroundColor(themeManager.textColor)
                                Spacer()
                                Text(durationString)
                                    .fontWeight(.semibold)
                                    .foregroundColor(themeManager.accentColor)
                            }
                            
                            Slider(value: $duration, in: 1...168, step: 1)
                                .tint(themeManager.accentColor)
                            
                            Text("Ends: \(endDateString)")
                                .font(.caption)
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                    }
                    
                    // Intention
                    ThemedCard {
                        VStack(alignment: .leading, spacing: 12) {
                            ThemedSectionHeader(title: "Intention", icon: "sparkles", iconColor: .yellow)
                            
                            ThemedTextEditor(placeholder: "Why are you fasting?", text: $intention, minHeight: 80)
                            
                            Text("Setting an intention helps focus your fast on spiritual growth")
                                .font(.caption)
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                    }
                    
                    // Start Button
                    ThemedPrimaryButton(
                        title: "Start Fast",
                        icon: "play.circle.fill",
                        gradient: [.indigo, .teal]
                    ) {
                        startFast()
                    }
                    .opacity(intention.isEmpty ? 0.5 : 1.0)
                    .disabled(intention.isEmpty)
                }
                .padding()
            }
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .navigationTitle("New Fast")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(themeManager.accentColor)
                }
            }
            .alert("Health Guidance", isPresented: $showGuidance) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(selectedType.healthGuidance)
            }
        }
    }
    
    private var durationString: String {
        let hours = Int(duration)
        if hours < 24 {
            return "\(hours) hours"
        } else {
            let days = hours / 24
            let remaining = hours % 24
            if remaining == 0 {
                return "\(days) day\(days == 1 ? "" : "s")"
            }
            return "\(days)d \(remaining)h"
        }
    }
    
    private var endDateString: String {
        let endDate = Calendar.current.date(byAdding: .hour, value: Int(duration), to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: endDate)
    }
    
    private func startFast() {
        let endDate = Calendar.current.date(byAdding: .hour, value: Int(duration), to: Date()) ?? Date()
        let entry = FastingEntry(
            type: selectedType,
            intention: intention,
            plannedEndDate: endDate,
            customDescription: selectedType == .custom ? customDescription : nil
        )
        storageService.startFast(entry)
        dismiss()
    }
}

// MARK: - Fast Completion Sheet

struct FastCompletionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var storageService = HubStorageService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    
    @State private var reflection = ""
    @State private var insights = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Success header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.15))
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.green)
                        }
                        
                        Text("Congratulations!")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.textColor)
                        
                        Text("You've completed your fast")
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    .padding(.vertical)
                    
                    // Reflection
                    ThemedCard {
                        VStack(alignment: .leading, spacing: 12) {
                            ThemedSectionHeader(title: "Reflection", icon: "heart", iconColor: .pink)
                            ThemedTextEditor(placeholder: "How do you feel?", text: $reflection, minHeight: 80)
                        }
                    }
                    
                    // Insights
                    ThemedCard {
                        VStack(alignment: .leading, spacing: 12) {
                            ThemedSectionHeader(title: "Spiritual Insights", icon: "sparkles", iconColor: .yellow)
                            ThemedTextEditor(placeholder: "What did God reveal to you?", text: $insights, minHeight: 80)
                        }
                    }
                    
                    ThemedPrimaryButton(title: "Complete Fast", gradient: [.green, .teal]) {
                        storageService.completeFast(reflection: reflection, insights: insights)
                        dismiss()
                    }
                }
                .padding()
            }
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .navigationTitle("Complete Fast")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(themeManager.accentColor)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        FastingTrackerView()
    }
}
