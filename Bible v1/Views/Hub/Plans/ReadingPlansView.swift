//
//  ReadingPlansView.swift
//  Bible v1
//
//  Reading Plans - Apple Music-inspired immersive design
//

import SwiftUI

struct ReadingPlansView: View {
    @ObservedObject var viewModel: HubViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedPlan: ReadingPlan?
    @State private var showActivePlan = false
    @State private var scrollOffset: CGFloat = 0
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Active plan hero section (if exists)
                    if let plan = viewModel.activePlan, let progress = viewModel.activeProgress {
                        ActivePlanHeroSection(
                            plan: plan,
                            progress: progress,
                            viewModel: viewModel
                        ) {
                            showActivePlan = true
                        }
                    }
                    
                    // Plan discovery section
                    PlanDiscoverySection(
                        viewModel: viewModel,
                        onPlanSelect: { plan in
                            selectedPlan = plan
                        }
                    )
                    .padding(.top, viewModel.activePlan != nil ? 0 : 20)
                }
            }
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .navigationTitle("Reading Plans")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(themeManager.accentColor)
                }
            }
            .sheet(item: $selectedPlan) { plan in
                ImmersivePlanDetailSheet(plan: plan, viewModel: viewModel)
            }
            .sheet(isPresented: $showActivePlan) {
                if let plan = viewModel.activePlan, let progress = viewModel.activeProgress {
                    ImmersiveActivePlanView(plan: plan, progress: progress, viewModel: viewModel)
                }
            }
        }
    }
}

// MARK: - Active Plan Hero Section

struct ActivePlanHeroSection: View {
    let plan: ReadingPlan
    let progress: ReadingPlanProgress
    @ObservedObject var viewModel: HubViewModel
    let onContinue: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var hasAppeared = false
    
    var body: some View {
        ZStack {
            // Atmospheric gradient background
            AtmosphericBackground(colors: plan.theme.gradientColors)
                .frame(height: 380)
            
            VStack(spacing: 24) {
                Spacer()
                
                // Progress ring and title
                HStack(spacing: 24) {
                    ProgressRing(
                        progress: progress.progressPercentage(totalDays: plan.days.count),
                        size: 90,
                        lineWidth: 10,
                        gradient: [plan.theme.accentColor, plan.theme.color]
                    )
                    .opacity(hasAppeared ? 1 : 0)
                    .scaleEffect(hasAppeared ? 1 : 0.8)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("CURRENT PLAN")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.7))
                            .tracking(1.2)
                        
                        Text(plan.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Day \(progress.currentDay) of \(plan.days.count)")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        
                        if progress.isDueToday {
                            HStack(spacing: 4) {
                                Image(systemName: "bell.fill")
                                    .font(.caption2)
                                Text("Reading available")
                            }
                            .font(.caption)
                            .foregroundColor(plan.theme.accentColor)
                        }
                    }
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(x: hasAppeared ? 0 : 20)
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                
                // Today's reading card
                if let today = viewModel.currentReadingDay {
                    GlassmorphicCard(
                        padding: 16,
                        cornerRadius: 16,
                        glowColor: plan.theme.color,
                        intensity: .subtle
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "book.fill")
                                    .foregroundColor(plan.theme.accentColor)
                                Text("Today's Reading")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            
                            Text(today.title)
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(today.readings) { reading in
                                        Text(reading.displayReference)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(plan.theme.accentColor)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(
                                                Capsule()
                                                    .fill(plan.theme.accentColor.opacity(0.2))
                                            )
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : 20)
                }
                
                // Continue button
                FloatingActionButton(
                    title: "Continue Reading",
                    icon: "arrow.right",
                    gradient: [plan.theme.color, plan.theme.accentColor]
                ) {
                    onContinue()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : 15)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.1)) {
                hasAppeared = true
            }
        }
    }
}

// MARK: - Plan Discovery Section

struct PlanDiscoverySection: View {
    @ObservedObject var viewModel: HubViewModel
    let onPlanSelect: (ReadingPlan) -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 32) {
            // Featured plans carousel
            VStack(alignment: .leading, spacing: 16) {
                Text("Featured Plans")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.textColor)
                    .padding(.horizontal, 20)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(Array(ReadingPlan.allPlans.prefix(4).enumerated()), id: \.element.id) { index, plan in
                            FeaturedPlanCard(plan: plan, animationDelay: Double(index) * 0.1) {
                                onPlanSelect(plan)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.top, 24)
            
            // Quick Start section (7-day plans)
            planCategorySection(
                title: "Quick Start",
                subtitle: "7-day journeys",
                plans: ReadingPlan.allPlans.filter { $0.duration == .week }
            )
            
            // Go Deeper section (30-day plans)
            planCategorySection(
                title: "Go Deeper",
                subtitle: "30-day experiences",
                plans: ReadingPlan.allPlans.filter { $0.duration == .month }
            )
            
            // Epic Journeys section (90+ day plans)
            planCategorySection(
                title: "Epic Journeys",
                subtitle: "90+ day adventures",
                plans: ReadingPlan.allPlans.filter { $0.duration == .quarter || $0.duration == .year }
            )
        }
        .padding(.bottom, 40)
    }
    
    private func planCategorySection(title: String, subtitle: String, plans: [ReadingPlan]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.textColor)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                ForEach(plans) { plan in
                    CompactPlanRow(
                        plan: plan,
                        hasProgress: viewModel.readingPlanProgress.contains { $0.planId == plan.id }
                    ) {
                        onPlanSelect(plan)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Featured Plan Card

struct FeaturedPlanCard: View {
    let plan: ReadingPlan
    var animationDelay: Double = 0
    let action: () -> Void
    
    @State private var hasAppeared = false
    
    var body: some View {
        Button(action: {
            HapticManager.shared.lightImpact()
            action()
        }) {
            ZStack(alignment: .bottomLeading) {
                // Gradient background
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: plan.theme.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Subtle pattern overlay
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        RadialGradient(
                            colors: [.white.opacity(0.1), .clear],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: 200
                        )
                    )
                
                // Content
                VStack(alignment: .leading, spacing: 12) {
                    Spacer()
                    
                    // Icon
                    Image(systemName: plan.theme.icon)
                        .font(.system(size: 36))
                        .foregroundColor(.white.opacity(0.9))
                    
                    // Title and tagline
                    VStack(alignment: .leading, spacing: 4) {
                        Text(plan.name)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text(plan.tagline)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(2)
                    }
                    
                    // Duration badge
                    Text(plan.duration.rawValue)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(.white.opacity(0.2))
                        )
                }
                .padding(20)
            }
            .frame(width: 200, height: 260)
            .shadow(
                color: plan.theme.color.opacity(0.4),
                radius: 15,
                x: 0,
                y: 8
            )
        }
        .buttonStyle(TilePressStyle())
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 20)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(animationDelay)) {
                hasAppeared = true
            }
        }
    }
}

// MARK: - Compact Plan Row

struct CompactPlanRow: View {
    let plan: ReadingPlan
    let hasProgress: Bool
    let action: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: {
            HapticManager.shared.lightImpact()
            action()
        }) {
            HStack(spacing: 16) {
                // Icon with gradient background
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: plan.theme.gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: plan.theme.icon)
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(plan.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(themeManager.textColor)
                        
                        if hasProgress {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                    }
                    
                    Text(plan.tagline)
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Duration and chevron
                VStack(alignment: .trailing, spacing: 2) {
                    Text(plan.duration.rawValue)
                        .font(.caption2)
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(themeManager.cardBackgroundColor)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Immersive Plan Detail Sheet

struct ImmersivePlanDetailSheet: View {
    let plan: ReadingPlan
    @ObservedObject var viewModel: HubViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var expandedDay: Int? = nil
    @State private var hasAppeared = false
    
    private var existingProgress: ReadingPlanProgress? {
        viewModel.readingPlanProgress.first { $0.planId == plan.id }
    }
    
    var body: some View {
        ZStack {
            // Background
            themeManager.backgroundColor.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Hero section
                    planHero
                    
                    // Content sections
                    VStack(spacing: 32) {
                        // Journey map
                        journeyMapSection
                        
                        // What you'll experience
                        whatYoullExperienceSection
                        
                        // Sample scripture
                        if let quote = plan.sampleQuote {
                            sampleQuoteSection(quote)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120)
                }
            }
            
            // Floating CTA
            VStack {
                Spacer()
                startButton
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
                    .foregroundColor(.white)
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2)) {
                hasAppeared = true
            }
        }
    }
    
    // MARK: - Hero
    
    private var planHero: some View {
        ZStack {
            // Gradient background
            AtmosphericBackground(colors: plan.theme.gradientColors)
                .frame(height: 340)
            
            VStack(spacing: 20) {
                Spacer()
                
                // Large icon
                Image(systemName: plan.theme.icon)
                    .font(.system(size: 56))
                    .foregroundColor(.white.opacity(0.9))
                    .opacity(hasAppeared ? 1 : 0)
                    .scaleEffect(hasAppeared ? 1 : 0.7)
                
                // Title
                Text(plan.name)
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : 20)
                
                // Tagline
                Text(plan.tagline)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.85))
                    .opacity(hasAppeared ? 1 : 0)
                
                // Stats
                HStack(spacing: 24) {
                    planStat(value: plan.duration.rawValue, label: "Duration", icon: "calendar")
                    planStat(value: "~\(plan.estimatedDailyMinutes)", label: "Min/Day", icon: "clock")
                    planStat(value: "\(plan.days.count)", label: "Days", icon: "text.book.closed")
                }
                .padding(.top, 8)
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : 15)
                
                Spacer()
            }
            .padding(.horizontal, 24)
        }
    }
    
    private func planStat(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            Text(value)
                .font(.headline)
                .foregroundColor(.white)
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
        }
    }
    
    // MARK: - Journey Map Section
    
    private var journeyMapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Journey")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(themeManager.textColor)
            
            JourneyMapView(
                totalDays: plan.days.count,
                completedDays: existingProgress?.completedDays ?? [],
                currentDay: existingProgress?.currentDay ?? 1,
                themeColor: plan.theme.color
            ) { day in
                withAnimation(.spring(response: 0.3)) {
                    expandedDay = expandedDay == day ? nil : day
                }
            }
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.cardBackgroundColor)
            )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(themeManager.backgroundColor)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: -5)
        )
        .padding(.top, -40)
    }
    
    // MARK: - What You'll Experience
    
    private var whatYoullExperienceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What You'll Experience")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(themeManager.textColor)
            
            Text(plan.heroDescription)
                .font(.body)
                .foregroundColor(themeManager.textColor)
                .lineSpacing(4)
            
            // Day previews
            VStack(spacing: 12) {
                ForEach(plan.days.prefix(5)) { day in
                    DayPreviewCard(
                        day: day,
                        isExpanded: expandedDay == day.dayNumber,
                        themeColor: plan.theme.color
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            expandedDay = expandedDay == day.dayNumber ? nil : day.dayNumber
                        }
                    }
                }
                
                if plan.days.count > 5 {
                    Text("+ \(plan.days.count - 5) more days...")
                        .font(.subheadline)
                        .foregroundColor(themeManager.secondaryTextColor)
                        .padding(.top, 4)
                }
            }
        }
    }
    
    // MARK: - Sample Quote
    
    private func sampleQuoteSection(_ quote: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("A Taste of What's Ahead")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(themeManager.textColor)
            
            ScriptureQuote(
                text: quote,
                reference: "Day 1 Reflection",
                accentColor: plan.theme.color
            )
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(plan.theme.color.opacity(0.08))
            )
        }
    }
    
    // MARK: - Start Button
    
    private var startButton: some View {
        VStack(spacing: 16) {
            if let progress = existingProgress {
                if progress.isCompleted {
                    Text("Completed!")
                        .font(.subheadline)
                        .foregroundColor(.green)
                } else {
                    Text("You're on Day \(progress.currentDay)")
                        .font(.subheadline)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
            
            FloatingActionButton(
                title: existingProgress != nil ? (existingProgress!.isCompleted ? "Start Again" : "Continue Plan") : "Start Plan",
                icon: existingProgress?.isCompleted == true ? "arrow.counterclockwise" : "play.fill",
                gradient: plan.theme.gradientColors
            ) {
                if existingProgress != nil && !existingProgress!.isCompleted {
                    viewModel.switchActivePlan(to: plan.id)
                } else {
                    viewModel.startPlan(plan)
                }
                dismiss()
            }
        }
        .padding(.bottom, 30)
    }
}

// MARK: - Day Preview Card

struct DayPreviewCard: View {
    let day: ReadingPlanDay
    let isExpanded: Bool
    let themeColor: Color
    let onTap: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack(spacing: 12) {
                    Text("Day \(day.dayNumber)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [themeColor, themeColor.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                    
                    Text(day.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.textColor)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                
                // Expanded content
                if isExpanded {
                    VStack(alignment: .leading, spacing: 12) {
                        // Readings
                        HStack(spacing: 8) {
                            ForEach(day.readings) { reading in
                                Text(reading.displayReference)
                                    .font(.caption)
                                    .foregroundColor(themeColor)
                            }
                        }
                        .padding(.top, 12)
                        
                        // Devotional thought
                        if let thought = day.devotionalThought {
                            Text(thought)
                                .font(.caption)
                                .foregroundColor(themeManager.secondaryTextColor)
                                .italic()
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.cardBackgroundColor)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Immersive Active Plan View

struct ImmersiveActivePlanView: View {
    let plan: ReadingPlan
    let progress: ReadingPlanProgress
    @ObservedObject var viewModel: HubViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedDayIndex: Int = 0
    @State private var noteText: String = ""
    @State private var showNoteEditor = false
    @State private var contentAppeared = false
    @State private var scrollProxy: ScrollViewProxy? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient that subtly matches theme
                LinearGradient(
                    colors: [
                        plan.theme.color.opacity(0.08),
                        themeManager.backgroundColor
                    ],
                    startPoint: .top,
                    endPoint: .center
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Swipeable day selector
                    daySelector
                    
                    // Day content with scroll reader
                    ScrollViewReader { proxy in
                        ScrollView {
                            if selectedDayIndex < plan.days.count {
                                dayContent(plan.days[selectedDayIndex])
                                    .id("dayContent")
                                    .opacity(contentAppeared ? 1 : 0)
                                    .offset(y: contentAppeared ? 0 : 20)
                            }
                        }
                        .onAppear {
                            scrollProxy = proxy
                        }
                    }
                }
            }
            .navigationTitle(plan.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(themeManager.accentColor)
                }
            }
            .sheet(isPresented: $showNoteEditor) {
                ReadingPlanNoteSheet(
                    dayNumber: plan.days[selectedDayIndex].dayNumber,
                    existingNote: progress.notes[plan.days[selectedDayIndex].dayNumber] ?? "",
                    themeColor: plan.theme.color,
                    onSave: { note in
                        viewModel.addReadingNote(note, for: plan.days[selectedDayIndex].dayNumber)
                    }
                )
            }
            .onAppear {
                selectedDayIndex = max(0, progress.currentDay - 1)
                withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
                    contentAppeared = true
                }
            }
            .onChange(of: selectedDayIndex) { _, _ in
                // Animate content when switching days
                contentAppeared = false
                withAnimation(.easeOut(duration: 0.3)) {
                    contentAppeared = true
                }
                // Scroll to top when changing days
                withAnimation {
                    scrollProxy?.scrollTo("dayContent", anchor: .top)
                }
            }
        }
    }
    
    // MARK: - Day Selector
    
    private var daySelector: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(plan.days.enumerated()), id: \.element.id) { index, day in
                        DayChip(
                            day: day,
                            isSelected: selectedDayIndex == index,
                            isCompleted: progress.completedDays.contains(day.dayNumber),
                            isCurrent: day.dayNumber == progress.currentDay,
                            themeColor: plan.theme.color
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                selectedDayIndex = index
                            }
                        }
                        .id(index)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(
                themeManager.cardBackgroundColor.opacity(0.8)
                    .background(.ultraThinMaterial)
            )
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation {
                        proxy.scrollTo(selectedDayIndex, anchor: .center)
                    }
                }
            }
            .onChange(of: selectedDayIndex) { _, newIndex in
                withAnimation {
                    proxy.scrollTo(newIndex, anchor: .center)
                }
            }
        }
    }
    
    // MARK: - Day Content
    
    private func dayContent(_ day: ReadingPlanDay) -> some View {
        VStack(alignment: .leading, spacing: 28) {
            // Day header
            VStack(alignment: .leading, spacing: 8) {
                Text("DAY \(day.dayNumber)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(plan.theme.color)
                    .tracking(1.5)
                
                Text(day.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.textColor)
            }
            .padding(.top, 8)
            
            // Historical Context (if available)
            if let context = day.historicalContext {
                ContentSectionCard(
                    icon: "book.closed.fill",
                    title: "Historical Context",
                    content: context,
                    accentColor: plan.theme.color,
                    style: .standard
                )
            }
            
            // Scripture readings with expandable cards
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "text.book.closed.fill")
                        .foregroundColor(plan.theme.color)
                    Text("Today's Scripture")
                        .font(.headline)
                        .foregroundColor(themeManager.textColor)
                }
                
                ForEach(day.readings) { reading in
                    ExpandableScriptureCard(
                        reading: reading,
                        themeColor: plan.theme.color
                    )
                }
            }
            
            // Devotional reflection
            if let thought = day.devotionalThought {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                        Text("Reflection")
                            .font(.headline)
                            .foregroundColor(themeManager.textColor)
                    }
                    
                    ScriptureQuote(
                        text: thought,
                        reference: "",
                        accentColor: plan.theme.color
                    )
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(plan.theme.color.opacity(0.08))
                    )
                }
            }
            
            // Guided Prayer (if available)
            if let prayer = day.guidedPrayer {
                ContentSectionCard(
                    icon: "hands.sparkles.fill",
                    title: "Guided Prayer",
                    content: prayer,
                    accentColor: ThemeManager.shared.accentColor,
                    style: .prayer
                )
            }
            
            // Today's Challenge (if available)
            if let challenge = day.todayChallenge {
                ContentSectionCard(
                    icon: "bolt.fill",
                    title: "Today's Challenge",
                    content: challenge,
                    accentColor: .orange,
                    style: .challenge
                )
            }
            
            // Cross-references (if available)
            if let crossRefs = day.crossReferences, !crossRefs.isEmpty {
                CrossReferenceChips(
                    references: crossRefs,
                    themeColor: plan.theme.color
                ) { ref in
                    // Would navigate to reference
                    print("Tapped cross-reference: \(ref)")
                }
            }
            
            // Daily Quiz (if available)
            if let questions = day.quizQuestions, !questions.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "questionmark.circle.fill")
                            .foregroundColor(plan.theme.color)
                        Text("Daily Quiz")
                            .font(.headline)
                            .foregroundColor(themeManager.textColor)
                    }
                    
                    ForEach(questions) { question in
                        QuizCard(
                            question: question,
                            themeColor: plan.theme.color
                        ) { answer in
                            // Handle answer
                            print("Answer: \(answer)")
                        }
                    }
                }
            }
            
            // Divider before personal section
            Rectangle()
                .fill(themeManager.dividerColor)
                .frame(height: 1)
                .padding(.vertical, 8)
            
            // Notes section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "pencil.line")
                            .foregroundColor(plan.theme.color)
                        Text("Your Thoughts")
                            .font(.headline)
                            .foregroundColor(themeManager.textColor)
                    }
                    
                    Spacer()
                    
                    Button {
                        showNoteEditor = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .font(.body)
                            .foregroundColor(plan.theme.color)
                    }
                }
                
                if let note = progress.notes[day.dayNumber], !note.isEmpty {
                    Text(note)
                        .font(.body)
                        .foregroundColor(themeManager.textColor)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(themeManager.cardBackgroundColor)
                        )
                } else {
                    Button {
                        showNoteEditor = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(plan.theme.color.opacity(0.5))
                            Text("Add your reflections...")
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                        .font(.subheadline)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(style: StrokeStyle(lineWidth: 1, dash: [6, 3]))
                                .foregroundColor(themeManager.dividerColor)
                        )
                    }
                }
            }
            
            // Complete button
            if !progress.completedDays.contains(day.dayNumber) {
                FloatingActionButton(
                    title: "Mark Day Complete",
                    icon: "checkmark.circle.fill",
                    gradient: [.green, Color(red: 0.2, green: 0.7, blue: 0.5)]
                ) {
                    viewModel.completeReadingDay(day.dayNumber)
                    HapticManager.shared.success()
                }
                .padding(.top, 8)
            } else {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                    Text("Day Completed")
                }
                .font(.headline)
                .foregroundColor(.green)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    Capsule()
                        .fill(Color.green.opacity(0.15))
                )
                .padding(.top, 8)
            }
        }
        .padding(20)
        .padding(.bottom, 20)
    }
}

// MARK: - Day Chip

struct DayChip: View {
    let day: ReadingPlanDay
    let isSelected: Bool
    let isCompleted: Bool
    let isCurrent: Bool
    let themeColor: Color
    let action: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: {
            HapticManager.shared.lightImpact()
            action()
        }) {
            VStack(spacing: 4) {
                // Day number with status
                ZStack {
                    Circle()
                        .fill(backgroundColor)
                        .frame(width: 44, height: 44)
                    
                    if isCompleted && !isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(isSelected ? .white : .green)
                    } else {
                        Text("\(day.dayNumber)")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(isSelected ? .white : (isCurrent ? themeColor : themeManager.textColor))
                    }
                }
                .overlay(
                    Circle()
                        .stroke(isCurrent && !isSelected ? themeColor : Color.clear, lineWidth: 2)
                )
                
                // Title (truncated)
                Text(day.title)
                    .font(.caption2)
                    .foregroundColor(isSelected ? themeColor : themeManager.secondaryTextColor)
                    .lineLimit(1)
                    .frame(width: 60)
            }
        }
        .buttonStyle(.plain)
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return themeColor
        } else if isCompleted {
            return Color.green.opacity(0.15)
        } else if isCurrent {
            return themeColor.opacity(0.15)
        } else {
            return themeManager.cardBackgroundColor
        }
    }
}

// MARK: - Reading Plan Note Sheet

struct ReadingPlanNoteSheet: View {
    let dayNumber: Int
    let existingNote: String
    let themeColor: Color
    let onSave: (String) -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var noteText: String = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Day \(dayNumber)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(themeColor)
                        
                        Text("Your Thoughts")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.textColor)
                    }
                    .padding(.top)
                    
                    // Text editor
                    ZStack(alignment: .topLeading) {
                        if noteText.isEmpty {
                            Text("What spoke to you today? What will you remember?")
                                .font(.body)
                                .foregroundColor(themeManager.secondaryTextColor)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        
                        TextEditor(text: $noteText)
                            .font(.body)
                            .foregroundColor(themeManager.textColor)
                            .scrollContentBackground(.hidden)
                            .focused($isFocused)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(themeManager.cardBackgroundColor)
                    )
                    .frame(minHeight: 200)
                    
                    Spacer()
                    
                    // Save button
                    FloatingActionButton(
                        title: "Save",
                        icon: "checkmark",
                        gradient: [themeColor, themeColor.opacity(0.8)]
                    ) {
                        onSave(noteText)
                        dismiss()
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(themeManager.accentColor)
                }
            }
            .onAppear {
                noteText = existingNote
                isFocused = true
            }
        }
    }
}

#Preview {
    ReadingPlansView(viewModel: HubViewModel())
}
