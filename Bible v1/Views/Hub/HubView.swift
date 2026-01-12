//
//  HubView.swift
//  Bible v1
//
//  Spiritual Hub - Main Dashboard View (Redesigned)
//

import SwiftUI

/// Main Hub view with animated grid-based dashboard
struct HubView: View {
    @StateObject private var viewModel = HubViewModel()
    @StateObject private var navigationManager = HubNavigationManager()
    @ObservedObject private var themeManager = ThemeManager.shared
    
    @State private var showingAIPlaceholder = false
    
    var body: some View {
        NavigationStack(path: $navigationManager.navigationPath) {
            ZStack(alignment: .topTrailing) {
                ScrollView {
                    VStack(spacing: 24) {
                        // Header with greeting and verse of the day
                        HubHeaderView(
                            greeting: viewModel.greeting,
                            summary: viewModel.todaySummary,
                            verseText: viewModel.verseOfTheDay.text,
                            verseReference: viewModel.verseOfTheDay.reference,
                            onVerseOfDayTap: {
                                navigationManager.present(.verseOfDay)
                            }
                        )
                        
                        // Quick stats bar
                        HubQuickStats(
                            stats: HubStatsFactory.createStats(from: viewModel)
                        )
                        
                        // Animated feature grid
                        HubGridView(viewModel: viewModel) { destination in
                            navigationManager.present(destination)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
                .background(themeManager.backgroundColor.ignoresSafeArea())
                
                // AI Floating Button
                AIFloatingButton {
                    showingAIPlaceholder = true
                }
                .padding(.top, 8)
                .padding(.trailing, 16)
            }
            .navigationTitle("Hub")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                viewModel.refreshData()
            }
            .refreshable {
                viewModel.refreshData()
            }
            // Single sheet presentation based on navigation state
            .sheet(item: $navigationManager.presentedSheet) { destination in
                destinationView(for: destination)
            }
            .sheet(isPresented: $showingAIPlaceholder) {
                AIPlaceholderView()
            }
        }
    }
    
    /// Builds the appropriate view for each destination
    @ViewBuilder
    private func destinationView(for destination: HubDestination) -> some View {
        switch destination {
        case .prayerJournal:
            PrayerJournalView(viewModel: viewModel)
            
        case .guidedPrayer:
            GuidedPrayerView(viewModel: viewModel)
            
        case .addPrayer:
            PrayerEntryEditorView(viewModel: viewModel, prayer: nil)
            
        case .scripturePrayer:
            NavigationStack {
                ScripturePrayerView()
            }
            
        case .prayerLibrary:
            NavigationStack {
                PrayerLibraryView()
            }
            
        case .prayerSchedule:
            PrayerScheduleView()
            
        case .audioPrayers:
            AudioPrayersView()
            
        case .habitsTracker:
            HabitsTrackerView(viewModel: viewModel)
            
        case .gratitudeTracker:
            GratitudeTrackerView(viewModel: viewModel)
            
        case .moodCheckIn:
            MoodCheckInView(viewModel: viewModel)
            
        case .readingPlans:
            ReadingPlansView(viewModel: viewModel)
            
        case .devotionals:
            NavigationStack {
                DevotionalsView()
            }
            
        case .verseOfDay:
            NavigationStack {
                VerseOfDayView()
            }
            
        case .dailyRoutine:
            DailyRoutineView(viewModel: viewModel)
            
        case .routineManager:
            RoutineManagerView(viewModel: viewModel, selectedConfiguration: .constant(nil))
            
        case .routineAnalytics:
            RoutineAnalyticsView(viewModel: viewModel)
            
        case .weeklyRecap:
            WeeklyRecapView(viewModel: viewModel)
            
        case .fasting:
            NavigationStack {
                FastingTrackerView()
            }
            
        case .missions:
            NavigationStack {
                MissionsView()
            }
            
        case .widgets:
            WidgetStudioView()
        }
    }
}

#Preview {
    HubView()
}
