//
//  HomeView.swift
//  Bible v1
//
//  Advanced Bible Reader App
//

import SwiftUI

/// Main home view with tab navigation - Hub is now the default tab
struct HomeView: View {
    @StateObject private var bibleViewModel = BibleViewModel()
    @StateObject private var searchViewModel = SearchViewModel()
    @StateObject private var favoritesViewModel = FavoritesViewModel()
    @StateObject private var settingsViewModel = SettingsViewModel()
    @ObservedObject private var themeManager = ThemeManager.shared
    
    // Hub is now the default tab (index 0)
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Hub tab (Spiritual Growth Center) - NOW FIRST
            HubView()
                .tabItem {
                    Label("Hub", systemImage: "sparkles")
                }
                .tag(0)
            
            // Read tab (now contains segmented control for Reader/Journal)
            ReadTabContainerView(
                bibleViewModel: bibleViewModel,
                favoritesViewModel: favoritesViewModel
            )
            .tabItem {
                Label("Read", systemImage: "book.fill")
            }
            .tag(1)
            
            // Search tab
            SearchView(
                viewModel: searchViewModel,
                bibleViewModel: bibleViewModel
            )
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }
            .tag(2)
            
            // Favorites tab
            FavoritesView(
                viewModel: favoritesViewModel,
                bibleViewModel: bibleViewModel
            )
            .tabItem {
                Label("Saved", systemImage: "heart.fill")
            }
            .tag(3)
            
            // Settings tab
            SettingsView(
                viewModel: settingsViewModel,
                bibleViewModel: bibleViewModel
            )
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
            .tag(4)
        }
        .tint(themeManager.accentColor)
        .preferredColorScheme(themeManager.selectedTheme.colorScheme)
        .task {
            searchViewModel.bibleViewModel = bibleViewModel
            await bibleViewModel.loadInitialDataIfNeeded()
        }
    }
}

/// Welcome view for first-time users
struct WelcomeView: View {
    let onGetStarted: () -> Void
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    themeManager.accentColor.opacity(0.1),
                    themeManager.backgroundColor
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Icon
                Image(systemName: "book.circle.fill")
                    .font(.system(size: 100))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [themeManager.accentColor, themeManager.accentColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Title
                VStack(spacing: 12) {
                    Text("Welcome to Bible")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.textColor)
                    
                    Text("Your free Bible reading companion")
                        .font(.title3)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                
                // Features
                VStack(alignment: .leading, spacing: 20) {
                    FeatureRow(
                        icon: "globe",
                        title: "1000+ Translations",
                        description: "Read in your language",
                        themeManager: themeManager
                    )
                    
                    FeatureRow(
                        icon: "heart.fill",
                        title: "Save Favorites",
                        description: "Bookmark verses you love",
                        themeManager: themeManager
                    )
                    
                    FeatureRow(
                        icon: "highlighter",
                        title: "Highlight & Note",
                        description: "Mark and study scripture",
                        themeManager: themeManager
                    )
                    
                    FeatureRow(
                        icon: "icloud.slash",
                        title: "Offline Access",
                        description: "Download for reading anywhere",
                        themeManager: themeManager
                    )
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // Get Started button
                Button(action: onGetStarted) {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(themeManager.accentColor)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 40)
                
                // No account needed
                Text("No account needed • Always free • No ads")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .padding(.bottom, 24)
            }
        }
    }
}

/// Feature row for welcome view
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(themeManager.accentColor)
                .frame(width: 36)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
        }
    }
}

/// Quick verse card for home screen
struct QuickVerseCard: View {
    let verse: VerseReference
    let onTap: () -> Void
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                Text(verse.shortReference)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.accentColor)
                
                Text(verse.text)
                    .font(.body)
                    .foregroundColor(themeManager.textColor)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeView()
}

#Preview("Welcome") {
    WelcomeView(onGetStarted: {})
}
